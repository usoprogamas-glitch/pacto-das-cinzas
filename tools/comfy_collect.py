#!/usr/bin/env python3
"""Coleta outputs de props do ComfyUI (polling /history), baixa e pos-processa.
Roda até coletar 4 props ou estourar o timeout."""
import os
import json
import time
import urllib.request
from PIL import Image

BASE = "http://127.0.0.1:8188"
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "props_raw")
FINAL_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "props")
FINAL = 96
TARGET = 4

PROPS_BY_PREFIX = {
    "prop": "prop",  # prefixo comum do SaveImage
}
NAMES = ["taverna_fachada", "fornalha_vulcanica", "estatua_templo", "arvore_queimada"]


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
    collected = set()
    start = time.time()
    timeout_s = 900
    seen_ids = set()
    while len(collected) < TARGET and time.time() - start < timeout_s:
        try:
            with urllib.request.urlopen(f"{BASE}/history", timeout=5) as r:
                history = json.loads(r.read())
        except Exception:
            time.sleep(5)
            continue
        for pid, entry in history.items():
            if pid in seen_ids:
                continue
            if entry.get("status", {}).get("status_str") not in ("success", "completed"):
                continue
            outputs = entry.get("outputs", {})
            for node_out in outputs.values():
                for img in node_out.get("images", []):
                    fname = img.get("filename", "")
                    if fname.startswith("prop_") and fname.endswith(".png"):
                        idx = len(collected)
                        if idx >= len(NAMES):
                            idx = len(NAMES) - 1
                        prop_id = NAMES[idx]
                        dest = os.path.join(OUT_DIR, fname)
                        try:
                            urllib.request.urlretrieve(
                                f"{BASE}/view?filename={fname}&type=output", dest)
                            final = postprocess(dest, prop_id)
                            collected.add(fname)
                            seen_ids.add(pid)
                            print(f"COLETADO {fname} -> {final}", flush=True)
                        except Exception as e:
                            print(f"ERRO baixando {fname}: {e}", flush=True)
        time.sleep(10)
    print(f"Fim. Coletados: {len(collected)}/{TARGET}", flush=True)


if __name__ == "__main__":
    main()
