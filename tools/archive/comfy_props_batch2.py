#!/usr/bin/env python3
"""Lote 2 de props para O Pacto das Cinzas via ComfyUI local.
Enfileira todos os jobs primeiro, depois coleta/pós-processa em polling.
448px / 18 steps (VRAM baixa: RTX 3070 compartilhada)."""
import os
import json
import time
import urllib.request
from PIL import Image

BASE = "http://127.0.0.1:8188"
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "props_raw")
FINAL_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "props")
FINAL = 96

STYLE = ("game prop sprite, dark fantasy RPG, ash-covered world, muted palette "
         "(charcoal grey, ember orange, bone white), painterly, single object, "
         "centered, isolated game asset on plain uniform dark background, "
         "no text, no watermark, no character")
NEG = ("text, watermark, people, creatures, multiple objects, ground, grass, sky, "
       "clouds, bright white, high contrast stripes, pattern background, frame, "
       "border, blurry, cropped")

PROPS = [
    {"id": "barris_cinzas",    "prefix": "propBarris",  "prompt": "stack of old wooden barrels and crates, ash dust, iron bands", "seed": 511},
    {"id": "fogueira_acamp",   "prefix": "propFogueira", "prompt": "small campfire with stones circle and cooking pot, glowing embers, low flame", "seed": 522},
    {"id": "calice_corrosivo", "prefix": "propCalice",  "prompt": "large corroded bronze chalice overflowing with glowing green liquid, dripping", "seed": 533},
    {"id": "portal_solaria",   "prefix": "propPortal",  "prompt": "tall golden stone portal arch with glowing white solar runes, broken base", "seed": 544},
]

SIZE = 448
STEPS = 18


def build_workflow(prompt: str, seed: int, prefix: str) -> dict:
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt + ", " + STYLE, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": SIZE, "height": SIZE, "batch_size": 1}},
        "5": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": STEPS, "cfg": 6.5, "sampler_name": "dpmpp_2m",
            "scheduler": "karras", "denoise": 1.0,
            "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        "7": {"class_type": "SaveImage", "inputs": {"images": ["6", 0], "filename_prefix": prefix}},
    }


def postprocess(src: str, prop_id: str) -> str:
    img = Image.open(src).convert("RGB")
    img.thumbnail((FINAL, FINAL), Image.LANCZOS)
    quant = img.quantize(colors=24, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
    path = os.path.join(FINAL_DIR, f"{prop_id}.png")
    quant.save(path)
    return path


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(FINAL_DIR, exist_ok=True)

    # 1) Enfileira tudo
    jobs = {}  # prefix -> prop_id
    for prop in PROPS:
        req = urllib.request.Request(
            f"{BASE}/prompt",
            data=json.dumps({"prompt": build_workflow(prop["prompt"], prop["seed"], prop["prefix"])}).encode(),
            headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req) as r:
            pid = json.loads(r.read())["prompt_id"]
        jobs[pid] = prop
        print(f"ENFILEIRADO {prop['id']} -> {pid}", flush=True)

    # 2) Coleta por prefixo
    done = {}
    start = time.time()
    timeout_s = 2400
    while len(done) < len(PROPS) and time.time() - start < timeout_s:
        try:
            with urllib.request.urlopen(f"{BASE}/history", timeout=5) as r:
                history = json.loads(r.read())
        except Exception:
            time.sleep(10)
            continue
        for pid, prop in jobs.items():
            if pid in done or pid not in history:
                continue
            entry = history[pid]
            if entry.get("status", {}).get("status_str") not in ("success", "completed"):
                if entry.get("status", {}).get("status_str") == "error":
                    print(f"ERRO {prop['id']}: {entry['status'].get('errors')}", flush=True)
                    done[pid] = None
                continue
            for node_out in entry.get("outputs", {}).values():
                for img in node_out.get("images", []):
                    fname = img["filename"]
                    dest = os.path.join(OUT_DIR, fname)
                    urllib.request.urlretrieve(f"{BASE}/view?filename={fname}&type=output", dest)
                    final = postprocess(dest, prop["id"])
                    done[pid] = final
                    print(f"COLETADO {prop['id']} -> {final}", flush=True)
        time.sleep(10)
    print(f"LOTE OK: {sum(1 for v in done.values() if v)}/{len(PROPS)}", flush=True)


if __name__ == "__main__":
    main()
