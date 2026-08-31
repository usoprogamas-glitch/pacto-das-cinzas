#!/usr/bin/env python3
"""
Geracao em lote de sprites — O Pacto das Cinzas
===============================================
Le tools/sprite_generation_manifest.json e gera cada sprite via ComfyUI local
(localhost:8188, API REST), salvando em assets/sprites/<key>.png — mesma API
usada por comfy_automate.py, template de grafo igual a kroug_workflow.json
(SDXL 1024x1024, euler 30 steps).

Uso:
  python tools/generate_sprites.py            # gera os que faltam
  python tools/generate_sprites.py --all      # regenera todos
"""

import os
import json
import time
import sys
import urllib.request

BASE_URL = os.getenv("COMFY_BASE_URL", "http://localhost:8188")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "tools", "sprite_generation_manifest.json")
OUT_DIR = os.path.join(ROOT, "assets", "sprites")


def build_graph(cfg, prompt, negative, filename_prefix, seed):
    """Grafo ComfyUI API (mesma topologia de kroug_workflow.json)."""
    w, h = cfg["size"]
    return {
        "0": {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}},
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": cfg["model"]}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": ["1", 1]}},
        "4": {"class_type": "KSampler", "inputs": {
            "seed": seed, "steps": 30, "cfg": 7, "sampler_name": "euler",
            "scheduler": "normal", "denoise": 1,
            "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0],
            "latent_image": ["0", 0]}},
        "5": {"class_type": "VAEDecode", "inputs": {"samples": ["4", 0], "vae": ["1", 2]}},
        "6": {"class_type": "SaveImage", "inputs": {"filename_prefix": filename_prefix, "images": ["5", 0]}},
    }


def post_prompt(graph):
    payload = json.dumps({"prompt": graph}).encode("utf-8")
    req = urllib.request.Request(f"{BASE_URL}/prompt", data=payload,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())["prompt_id"]


def wait_and_download(prompt_id, filename_prefix):
    start = time.time()
    while time.time() - start < 300:
        with urllib.request.urlopen(f"{BASE_URL}/history/{prompt_id}", timeout=30) as r:
            history = json.loads(r.read())
        if prompt_id not in history:
            time.sleep(3)
            continue
        entry = history[prompt_id]
        status = entry.get("status", {})
        if status.get("status_str") == "error" or status.get("completed") is False:
            raise RuntimeError(f"ComfyUI reportou erro: {status.get('errors')}")
        if status.get("completed") or status.get("status_str") in ("success", "completed"):
            os.makedirs(OUT_DIR, exist_ok=True)
            for node_out in entry.get("outputs", {}).values():
                for img in node_out.get("images", []):
                    fname = img.get("filename")
                    if fname and fname.startswith(filename_prefix):
                        dest = os.path.join(OUT_DIR, filename_prefix + ".png")
                        src = f"{BASE_URL}/view?filename={fname}&type=output"
                        urllib.request.urlretrieve(src, dest)
                        return dest
            raise RuntimeError("job concluido sem imagem no output")
        time.sleep(3)
    raise TimeoutError("timeout aguardando ComfyUI")


def main():
    regenerate_all = "--all" in sys.argv
    with open(MANIFEST, encoding="utf-8") as f:
        cfg = json.load(f)

    # Servidor online?
    try:
        with urllib.request.urlopen(f"{BASE_URL}/system_stats", timeout=5) as r:
            stats = json.loads(r.read())
        print(f"[OK] ComfyUI em {BASE_URL} — {stats.get('version', '?')}")
    except Exception as e:
        print(f"[ERRO] ComfyUI offline em {BASE_URL}: {e}")
        print("Inicie o ComfyUI e rode novamente.")
        sys.exit(1)

    todo = []
    for sprite in cfg["sprites"]:
        dest = os.path.join(OUT_DIR, sprite["key"] + ".png")
        if regenerate_all or not os.path.exists(dest):
            todo.append(sprite)
        else:
            print(f"[SKIP] {sprite['key']}.png ja existe")

    print(f"[INFO] {len(todo)} sprite(s) a gerar\n")
    failures = []
    for i, sprite in enumerate(todo, 1):
        key = sprite["key"]
        print(f"[{i}/{len(todo)}] {key} ({sprite['unit_name']})...")
        graph = build_graph(cfg, sprite["prompt"] + ", " + cfg["style_positive"],
                            cfg["style_negative"], key, seed=42 + i)
        try:
            pid = post_prompt(graph)
            dest = wait_and_download(pid, key)
            print(f"       [OK] {dest}")
        except Exception as e:
            print(f"       [ERRO] {e}")
            failures.append(key)

    print(f"\n[DONE] {len(todo) - len(failures)} ok, {len(failures)} falha(s)")
    if failures:
        print("Falharam:", ", ".join(failures))
        sys.exit(1)


if __name__ == "__main__":
    main()
