#!/usr/bin/env python3
"""Gera sprite sheet de personagem via ComfyUI (consistência por seed fixa).
4 poses de walk + 1 idle por chamada; frames 512px -> 256px centralizados.
Rodar: python tools/comfy_spritesheet.py [nome_personagem]
Output: tools/sheets/<nome>/idle_0.png, walk_0..3.png"""
import os
import json
import time
import sys
import urllib.request
from PIL import Image

BASE = "http://127.0.0.1:8188"
OUT_ROOT = os.path.join(os.path.dirname(__file__), "sheets")
OUT_DIR = OUT_ROOT

CHARS = {
    "kael": {
        "look": "young warrior with short dark hair and tattered green cloak, small sword on back, determined face, 3/4 top-down RPG view",
        "seed": 2001,
    },
    "kroug": {
        "look": "burly orange orc warrior with tusks and leather armor, 3/4 top-down RPG view",
        "seed": 2002,
    },
}

NEG = ("text, watermark, background, scenery, ground, shadow on ground, frame, border, "
       "multiple characters, deformed hands, extra limbs, blurry, low quality")

POSES = [
    ("idle_0", "standing idle, front facing, relaxed arms"),
    ("walk_0", "walking cycle frame 1: left leg forward, right arm back, mid-stride"),
    ("walk_1", "walking cycle frame 2: legs passing, body upright, arms at sides"),
    ("walk_2", "walking cycle frame 3: right leg forward, left arm back, mid-stride"),
    ("walk_3", "walking cycle frame 4: legs passing, body slightly bobbing"),
]


def queue(prompt: str, seed: int, prefix: str) -> str:
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": 512, "height": 512, "batch_size": 1}},
        "5": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 20, "cfg": 6.5, "sampler_name": "dpmpp_2m",
            "scheduler": "karras", "denoise": 1.0,
            "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        "7": {"class_type": "SaveImage", "inputs": {"images": ["6", 0], "filename_prefix": prefix}},
    }
    req = urllib.request.Request(f"{BASE}/prompt", data=json.dumps({"prompt": wf}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())["prompt_id"]


def wait(pid: str, timeout_s: int = 300) -> str:
    start = time.time()
    while time.time() - start < timeout_s:
        with urllib.request.urlopen(f"{BASE}/history/{pid}") as r:
            hist = json.loads(r.read())
        if pid in hist:
            st = hist[pid].get("status", {}).get("status_str", "")
            if st in ("success", "completed"):
                for out in hist[pid].get("outputs", {}).values():
                    for img in out.get("images", []):
                        return img["filename"]
                raise RuntimeError("sem imagens")
            if st == "error":
                raise RuntimeError("erro no job")
        time.sleep(3)
    raise TimeoutError(pid)


def process(src: str, dst: str) -> None:
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    # Crop central 70% (remove bordas do fundo) e resize 256 (MotionLib).
    img = img.crop((int(w * 0.15), int(h * 0.05), int(w * 0.85), int(h * 0.95)))
    img.thumbnail((256, 256), Image.LANCZOS)
    img.save(dst)


def main() -> None:
    name = sys.argv[1] if len(sys.argv) > 1 else "kael"
    if name not in CHARS:
        print("personagem desconhecido:", name)
        sys.exit(1)
    char = CHARS[name]
    out_dir = os.path.join(OUT_ROOT, name)
    os.makedirs(out_dir, exist_ok=True)

    jobs = {}
    for pose_name, pose_desc in POSES:
        prompt = f"{char['look']}, {pose_desc}, full body, pixel art style game character"
        seed = char["seed"] + POSES.index((pose_name, pose_desc))
        jobs[queue(prompt, seed, f"sheet_{name}_{pose_name}")] = (pose_name, seed)

    while jobs:
        try:
            with urllib.request.urlopen(f"{BASE}/history", timeout=5) as r:
                history = json.loads(r.read())
        except Exception:
            time.sleep(5)
            continue
        for pid, (pose_name, seed) in list(jobs.items()):
            if pid not in history:
                continue
            entry = history[pid]
            st = entry.get("status", {}).get("status_str", "")
            if st not in ("success", "completed"):
                if st == "error":
                    print(f"ERRO {pose_name}", flush=True)
                    del jobs[pid]
                continue
            for out in entry.get("outputs", {}).values():
                for img in out.get("images", []):
                    dest = os.path.join(OUT_DIR, f"{pose_name}.png")
                    urllib.request.urlretrieve(
                        f"{BASE}/view?filename={img['filename']}&type=output", dest)
                    process(dest, dest)
                    print(f"OK {pose_name} (seed {seed}) -> {dest}", flush=True)
            del jobs[pid]
    print("SHEET OK", flush=True)


if __name__ == "__main__":
    main()
