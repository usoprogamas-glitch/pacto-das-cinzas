#!/usr/bin/env python3
"""Gera 1 prop no ComfyUI local com resolução menor (VRAM baixa) e coleta."""
import json
import time
import urllib.request
import sys
from PIL import Image

BASE = "http://127.0.0.1:8188"
OUT = "assets/props/arvore_queimada.png"
STYLE = ("game prop sprite, dark fantasy RPG, single dead tree with bare twisted branches, "
         "charred dark grey trunk, isolated game asset on plain uniform dark background, "
         "centered composition, soft painterly shading, muted ember orange accents, "
         "no text, no watermark")
NEG = "text, watermark, people, creatures, multiple trees, forest, ground, grass, sky, clouds, bright white, high contrast stripes, pattern background, frame, border, blurry"

wf = {
    "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"}},
    "2": {"class_type": "CLIPTextEncode", "inputs": {"text": STYLE, "clip": ["1", 1]}},
    "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
    "4": {"class_type": "EmptyLatentImage", "inputs": {"width": 512, "height": 512, "batch_size": 1}},
    "5": {"class_type": "KSampler", "inputs": {
        "seed": 987, "steps": 24, "cfg": 6.0, "sampler_name": "dpmpp_2m",
        "scheduler": "karras", "denoise": 1.0,
        "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]}},
    "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
    "7": {"class_type": "SaveImage", "inputs": {"images": ["6", 0], "filename_prefix": "prop_arvore"}},
}

req = urllib.request.Request(f"{BASE}/prompt", data=json.dumps({"prompt": wf}).encode(),
                             headers={"Content-Type": "application/json"})
with urllib.request.urlopen(req) as r:
    pid = json.loads(r.read())["prompt_id"]
print("Job:", pid, flush=True)
start = time.time()
while time.time() - start < 420:
    with urllib.request.urlopen(f"{BASE}/history/{pid}") as r:
        hist = json.loads(r.read())
    if pid in hist:
        entry = hist[pid]
        st = entry.get("status", {})
        if st.get("status_str") in ("success", "completed"):
            for node_out in entry.get("outputs", {}).values():
                for img in node_out.get("images", []):
                    fname = img["filename"]
                    dest = "assets/props_raw/" + fname
                    urllib.request.urlretrieve(f"{BASE}/view?filename={fname}&type=output", dest)
                    im = Image.open(dest).convert("RGB")
                    im.thumbnail((96, 96), Image.LANCZOS)
                    q = im.quantize(colors=24, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
                    q.save(OUT)
                    print("OK ->", OUT, flush=True)
                    sys.exit(0)
        if st.get("status_str") == "error":
            print("ERRO:", st.get("errors"), flush=True)
            sys.exit(1)
    time.sleep(3)
print("Timeout", flush=True)
