#!/usr/bin/env python3
"""Inimigos em pixel art estilo SoS (referência do usuário): pose de combate
limpa, outline forte, cores vivas — um por tipo de inimigo do jogo.
Idle 2 frames por inimigo (frame A = pose, frame B = seed vizinha para sway)."""
import os
import json
import time
import sys
import urllib.request
from PIL import Image

BASE = "http://127.0.0.1:8188"
OUT = os.path.join(os.path.dirname(__file__), "sheets", "enemies")

STYLE = ("clean pixel art sprite, crisp pixels, strong black outline, vivid colors, "
         "side view battle pose, full body, centered, game ready character sprite, "
         "flat dark background, style of modern indie RPG hero sprites")
NEG = ("text, watermark, background, scenery, blurry, sketch, rough strokes, "
       "painterly, soft shading, multiple characters, cropped")

ENEMIES = [
    {"game": "mercenario", "char": "StrifeMinion",  "look": "lean human mercenary with hood and curved sword, grey and crimson armor", "seed": 4101},
    {"game": "cacador",    "char": "Owlsassin",     "look": "masked hunter with feathered hood and twin daggers, dark green cloak", "seed": 4202},
    {"game": "esqueleto",  "char": "BilePile",      "look": "angry skeleton warrior with rusted shield and helmet", "seed": 4303},
    {"game": "mago",       "char": "Keymouseter",   "look": "tiny mage in oversized blue wizard hat holding a glowing key staff", "seed": 4404},
    {"game": "inquisidor", "char": "AcolyteCrimson","look": "fanatic red-robed inquisitor with glowing book and chains", "seed": 4505},
    {"game": "paladino",   "char": "AcolytePale",   "look": "heavy paladin in white and gold plate armor with tower shield", "seed": 4606},
    {"game": "orc_chefe",  "char": "BoulderChief",  "look": "huge orc chieftain boss with warhammer and horned pauldrons", "seed": 4707},
    {"game": "troll",      "char": "BoulderGoat",   "look": "hulking rock troll with mossy shoulders and club", "seed": 4808},
]

SIZE = 384
STEPS = 16


def queue(prompt, seed, prefix):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": f"{prompt}, {STYLE}", "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": ["1", 1]}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": SIZE, "height": SIZE, "batch_size": 1}},
        "5": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": STEPS, "cfg": 7.0, "sampler_name": "dpmpp_2m",
            "scheduler": "karras", "denoise": 1.0,
            "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]}},
        "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
        "7": {"class_type": "SaveImage", "inputs": {"images": ["6", 0], "filename_prefix": prefix}},
    }
    req = urllib.request.Request(f"{BASE}/prompt", data=json.dumps({"prompt": wf}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())["prompt_id"]


def wait(pid, timeout_s=300):
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
                raise RuntimeError("erro")
        time.sleep(3)
    raise TimeoutError(pid)


def postprocess(src, dst):
    """Downscale forte (pixel-art de verdade) + chroma-key do fundo escuro."""
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    img = img.crop((int(w * 0.12), int(h * 0.05), int(w * 0.88), int(h * 0.98)))
    img = img.resize((64, 96), Image.LANCZOS)
    # Quantiza para paleta limitada (crisp pixels) mantendo alpha
    q = img.quantize(colors=24)
    img = q.convert("RGBA")
    px = img.load()
    w2, h2 = img.size
    seen = set()
    from collections import deque
    q2 = deque()
    for x in range(w2):
        q2.append((x, 0)); q2.append((x, h2 - 1))
    for y in range(h2):
        q2.append((0, y)); q2.append((w2 - 1, y))
    # fundo = cor do canto superior esquerdo
    tr, tg, tb = px[0, 0][:3]
    while q2:
        x, y = q2.popleft()
        if (x, y) in seen or x < 0 or y < 0 or x >= w2 or y >= h2:
            continue
        seen.add((x, y))
        r, g, b, a = px[x, y]
        if abs(r - tr) > 28 or abs(g - tg) > 28 or abs(b - tb) > 28:
            continue
        px[x, y] = (0, 0, 0, 0)
        q2.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    img.save(dst)


def main():
    os.makedirs(OUT, exist_ok=True)
    jobs = {}
    for e in ENEMIES:
        prompt = f"{e['look']}, {STYLE}"
        prefix = f"enemy_{e['game']}"
        jobs[queue(prompt, e["seed"], prefix)] = (e, prefix)
        print("ENFILEIRADO", e["game"], flush=True)
    while jobs:
        try:
            with urllib.request.urlopen(f"{BASE}/history", timeout=5) as r:
                history = json.loads(r.read())
        except Exception:
            time.sleep(5)
            continue
        for pid, (e, prefix) in list(jobs.items()):
            if pid not in history:
                continue
            st = history[pid].get("status", {}).get("status_str", "")
            if st == "error":
                print("ERRO", e["game"], flush=True)
                del jobs[pid]
                continue
            if st not in ("success", "completed"):
                continue
            for out in history[pid].get("outputs", {}).values():
                for img in out.get("images", []):
                    src = os.path.join(OUT, img["filename"])
                    urllib.request.urlretrieve(f"{BASE}/view?filename={img['filename']}&type=output", src)
                    dst = os.path.join(OUT, f"{e['game']}.png")
                    postprocess(src, dst)
                    print(f"OK {e['game']} -> {dst}", flush=True)
            del jobs[pid]
    print("INIMIGOS OK", flush=True)


if __name__ == "__main__":
    main()
