#!/usr/bin/env python3
"""
Lote de props para O Pacto das Cinzas via ComfyUI local (127.0.0.1:8188).
Gera props estilizados com seed fixa (consistencia) e pos-processa:
downscale + quantizacao de paleta (look pixel-art coeso com o jogo).
"""
import os
import json
import time
import urllib.request
from PIL import Image

BASE = "http://127.0.0.1:8188"
OUT_DIR = os.path.join(os.path.dirname(__file__), "assets", "props_raw")
FINAL_DIR = os.path.join(os.path.dirname(__file__), "assets", "props")

STYLE = (
    "top-down RPG game asset, dark fantasy, ash-covered world, muted warm palette "
    "(charcoal grey, ember orange, bone white), painterly semi-realistic, "
    "single object, centered, full object visible, plain flat background "
    "solid #1a1512, no text, no watermark, no character"
)

NEGATIVE = "text, watermark, character, creature, person, multiple objects, blurry, cropped, oversized, detailed background, scenery, frame, border"

PROPS = [
    {"id": "taverna_fachada",   "prompt": "small wooden tavern building facade, two stories, smoking chimney, goblin skull sign, ash dust on roof", "seed": 411},
    {"id": "fornalha_vulcanica", "prompt": "volcanic stone forge furnace with glowing orange embers, iron pipes, anvil beside, dark stone", "seed": 422},
    {"id": "estatua_templo",    "prompt": "cracked stone temple statue of a robed figure, broken halo, ash deposits, weathered marble", "seed": 433},
    {"id": "arvore_queimada",   "prompt": "burnt dead tree, twisted black branches, faint ember glow inside trunk cracks", "seed": 444},
]

SIZE = 512   # geracao
FINAL = 96   # downscale final do prop (uso em cena: ~1.5 tiles)


def queue_prompt(workflow: dict) -> str:
    req = urllib.request.Request(
        f"{BASE}/prompt",
        data=json.dumps({"prompt": workflow}).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())["prompt_id"]


def wait_result(prompt_id: str, timeout_s: int = 240) -> str:
    start = time.time()
    while time.time() - start < timeout_s:
        with urllib.request.urlopen(f"{BASE}/history/{prompt_id}") as r:
            history = json.loads(r.read())
        if prompt_id in history:
            entry = history[prompt_id]
            status = entry.get("status", {})
            if status.get("status_str") in ("success", "completed"):
                outputs = entry.get("outputs", {})
                for node_out in outputs.values():
                    for img in node_out.get("images", []):
                        return img["filename"]
                raise RuntimeError("Sucesso sem imagens: %s" % outputs)
            if status.get("status_str") == "error":
                raise RuntimeError("Erro no job: %s" % status.get("errors"))
        time.sleep(2)
    raise TimeoutError("Timeout esperando %s" % prompt_id)


def download(fname: str) -> str:
    dest = os.path.join(OUT_DIR, fname)
    urllib.request.urlretrieve(f"{BASE}/view?filename={fname}&type=output", dest)
    return dest


def postprocess(src: str, prop_id: str) -> str:
    """Downscale + paleta reduzida: coesao pixel-art com o jogo."""
    img = Image.open(src).convert("RGB")
    img.thumbnail((FINAL, FINAL), Image.LANCZOS)
    quant = img.quantize(colors=24, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
    path = os.path.join(FINAL_DIR, f"{prop_id}.png")
    quant.save(path)
    return path


def build_workflow(prompt: str, seed: int) -> dict:
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt + ", " + STYLE, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEGATIVE, "clip": ["1", 1]}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": SIZE, "height": SIZE, "batch_size": 1}},
        "5": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 22, "cfg": 6.5, "sampler_name": "dpmpp_2m",
            "scheduler": "karras", "denoise": 1.0,
            "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        "7": {"class_type": "SaveImage", "inputs": {"images": ["6", 0], "filename_prefix": "prop"}},
    }


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(FINAL_DIR, exist_ok=True)
    for prop in PROPS:
        print(f"[PROP] {prop['id']} (seed {prop['seed']})...")
        try:
            pid = queue_prompt(build_workflow(prop["prompt"], prop["seed"]))
            fname = wait_result(pid)
            raw = download(fname)
            final = postprocess(raw, prop["id"])
            print(f"  OK -> {final}")
        except Exception as e:
            print(f"  FALHOU: {e}")
    print("Lote concluido.")


if __name__ == "__main__":
    main()
