#!/usr/bin/env python3
"""Geração de assets SoS-style (direção de arte docs/direcao_arte.md) no ComfyUI local.

Usa o LoRA pixel-art-xl (baixado para ComfyUI-Shared/models/loras) sobre o
SDXL base. Sem o LoRA no server, cai num fallback com tokens de prompt
reforçados (mesma receita visual).

Uso:
  python tools/comfy_sos_batch.py test       # 1 geração de prova de estilo
  python tools/comfy_sos_batch.py portraits  # 5 retratos pixel do elenco
  python tools/comfy_sos_batch.py icons      # ícones CORTE/ÉTER (slot EFEITO)
  python tools/comfy_sos_batch.py tiles      # tiles de bioma (1 por terreno)
"""
import json
import time
import urllib.request
import sys
from PIL import Image

BASE = "http://127.0.0.1:8188"
LORA = "pixel-art-xl.safetensors"
CKPT = "sd_xl_base_1.0.safetensors"
RAW_DIR = "assets/sos_raw"
OUT_PORTRAIT = "assets/portraits/pixel_%s.png"
OUT_ICON = "assets/pixel/icon_%s.png"
OUT_TILE = "assets/pixel/tile_%s.png"

NEG = ("blurry, painterly, photorealistic, 3d render, text, watermark, signature, "
       "frame, border, gradient background, jpeg artifacts, oversaturated")

# Elenco (GDD v2) → prompt de busto pixel-art
PORTRAITS = {
    "kael": ("kael, young ash paladin with broken halo ring, short dark hair, "
             "scarred cheek, grey-blue cloak with gold trim, determined expression"),
    "kroug": ("kroug, bulky scarred mercenary with braided beard and iron pauldron, "
              "gruff expression, dark leather armor"),
    "lira": ("lira, lithe scout with hooded green cloak and short copper hair, "
             "sharp watchful eyes"),
    "aqua": ("aqua, tide-born mystic with flowing teal hair and pearl ornaments, "
             "serene expression"),
    "thalkor": ("thalkor, elder forge-priest with bald head, runic tattoos and "
                "bronze mask half-raised"),
}

ICONS = {
    "corte": "sword slash icon, single blade diagonal, steel grey with warm gold edge",
    "eter": "swirling arcane ether orb icon, cobalt blue core with white spark",
}

TILES = {
    "fronteira": "top-down rpg ground tile, dry ashen meadow with pale grass tufts and cracked dirt, muted green-grey palette",
    "cave": "top-down rpg cave floor tile, dark blue stone with glowing cyan crystal veins, cold shadow palette",
    "volcanic": "top-down rpg volcanic ground tile, charred basalt with ember cracks and ash drifts, warm orange glow accents",
    "castle": "top-down rpg castle stone floor tile, cold grey flagstones with moss in seams, moonlit palette",
    "forest": "top-down rpg forest floor tile, lush moss and ferns with dappled sunlight spots, deep green palette",
}


def api_get(path):
    with urllib.request.urlopen(BASE + path) as r:
        return json.loads(r.read())


def has_lora():
    try:
        d = api_get("/object_info/LoraLoader")
        return LORA in d["LoraLoader"]["input"]["required"]["lora_name"][0]
    except Exception as exc:
        print("WARN: /object_info falhou (%s) — assumindo sem LoRA" % exc)
        return False


def build_workflow(prompt, width, height, seed, use_lora, prefix):
    wf = {"1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}}}
    model = ["1", 0]
    clip = ["1", 1]
    if use_lora:
        wf["2"] = {"class_type": "LoraLoader", "inputs": {
            "lora_name": LORA, "strength_model": 1.0, "strength_clip": 1.0,
            "model": ["1", 0], "clip": ["1", 1]}}
        model, clip = ["2", 0], ["2", 1]
    wf["10"] = {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": clip}}
    wf["11"] = {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": clip}}
    wf["12"] = {"class_type": "EmptyLatentImage", "inputs": {
        "width": width, "height": height, "batch_size": 1}}
    wf["13"] = {"class_type": "KSampler", "inputs": {
        "seed": seed, "steps": 16, "cfg": 6.0, "sampler_name": "dpmpp_2m",
        "scheduler": "karras", "denoise": 1.0,
        "model": model, "positive": ["10", 0], "negative": ["11", 0],
        "latent_image": ["12", 0]}}
    wf["14"] = {"class_type": "VAEDecode", "inputs": {"samples": ["13", 0], "vae": ["1", 2]}}
    wf["15"] = {"class_type": "SaveImage", "inputs": {"images": ["14", 0], "filename_prefix": prefix}}
    return wf


def submit_and_wait(wf, timeout=1500):
    req = urllib.request.Request(BASE + "/prompt", data=json.dumps({"prompt": wf}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        pid = json.loads(r.read())["prompt_id"]
    start = time.time()
    while time.time() - start < timeout:
        hist = api_get("/history/%s" % pid)
        if pid in hist:
            st = hist[pid].get("status", {})
            if st.get("status_str") in ("success", "completed"):
                return hist[pid]["outputs"]
            if st.get("status_str") == "error":
                raise RuntimeError(st.get("errors"))
        time.sleep(3)
    raise TimeoutError("job %s" % pid)


def collect(outputs, dest, out_path, thumb, colors):
    import os
    if os.path.exists(out_path):
        print("SKIP (já existe):", out_path, flush=True)
        return True
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    for node_out in outputs.values():
        for img in node_out.get("images", []):
            fname = img["filename"]
            urllib.request.urlretrieve(
                "%s/view?filename=%s&type=output" % (BASE, fname), dest)
            im = Image.open(dest).convert("RGB")
            im.thumbnail((thumb, thumb), Image.LANCZOS)
            q = im.quantize(colors=colors, method=Image.MEDIANCUT,
                            dither=Image.NONE).convert("RGB")
            q.save(out_path)
            print("OK ->", out_path, flush=True)
            return True
    return False


STYLE = ("16-bit pixel art, sea of stars game style, crisp pixel clusters, "
         "limited palette, clean readable silhouette, ")


def run_portraits(use_lora):
    for name, desc in PORTRAITS.items():
        prompt = (STYLE + "pixel art portrait bust of " + desc +
                  ", plain dark navy background, centered, head and shoulders")
        wf = build_workflow(prompt, 1024, 1024, abs(hash(name)) % 10**8, use_lora, "sos_portrait")
        outputs = submit_and_wait(wf)
        collect(outputs, "%s/portrait_%s.png" % (RAW_DIR, name),
                OUT_PORTRAIT % name, 96, 24)


def run_icons(use_lora):
    for name, desc in ICONS.items():
        prompt = (STYLE + "pixel art game ui icon, " + desc +
                  ", on plain flat dark navy square background, centered, chunky pixels")
        wf = build_workflow(prompt, 512, 512, abs(hash("icon" + name)) % 10**8, use_lora, "sos_icon")
        outputs = submit_and_wait(wf)
        collect(outputs, "%s/icon_%s.png" % (RAW_DIR, name),
                OUT_ICON % name, 64, 16)


def run_tiles(use_lora):
    for name, desc in TILES.items():
        prompt = (STYLE + "pixel art seamless " + desc +
                  ", even lighting, no horizon, no text")
        wf = build_workflow(prompt, 1024, 1024, abs(hash("tile" + name)) % 10**8, use_lora, "sos_tile")
        outputs = submit_and_wait(wf)
        collect(outputs, "%s/tile_%s.png" % (RAW_DIR, name),
                OUT_TILE % name, 96, 24)


def run_test(use_lora):
    prompt = (STYLE + "pixel art battle scene on a dark library floor, hooded hero "
              "facing a shadow wisp, warm candle glow accents, sea of stars style")
    wf = build_workflow(prompt, 768, 768, 42, use_lora, "sos_test")
    outputs = submit_and_wait(wf)
    collect(outputs, "%s/test.png" % RAW_DIR, "%s/test.png" % RAW_DIR, 512, 48)


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "test"
    lora = has_lora()
    print("LoRA %s: %s" % (LORA, "OK" if lora else "AUSENTE (fallback)"), flush=True)
    if mode == "test":
        run_test(lora)
    elif mode == "portraits":
        run_portraits(lora)
    elif mode == "icons":
        run_icons(lora)
    elif mode == "tiles":
        run_tiles(lora)
    else:
        print("modo desconhecido:", mode)
        sys.exit(1)
    print("BATCH_OK", mode, flush=True)
