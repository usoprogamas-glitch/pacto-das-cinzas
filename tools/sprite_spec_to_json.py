# -*- coding: utf-8 -*-
"""Lê o spec oficial (docs/sprite_spec_sprites.csv) e emite JSON de geração:
docs/sprite_spec.json — consumido pelo comfy_sos_batch (modo spec)."""
import csv
import json
import io

rows = list(csv.DictReader(io.open(r"docs\sprite_spec_sprites.csv", encoding="utf-8-sig")))
spec = {
    "config": {
        "checkpoint": "SDXL Base",
        "lora": {"pixel_art": 0.8, "spritesheet": 0.7},
        "sampler": "euler_ancestral",
        "scheduler": "karras",
        "steps": 28,
        "cfg": 7.0,
        "size": [1024, 1024],
        "background": "chroma_green",
        "post": ["rembg", "chroma_key_green", "crop"],
    },
    "entries": [],
}
for r in rows:
    spec["entries"].append({
        "id": r["ID"],
        "categoria": r["Categoria"],
        "personagem": r["Personagem"],
        "fase": r["Fase / Evolução"],
        "anim": r["Tipo de Sprite / Animação"],
        "view": r["Perspectiva / Enquadramento"],
        "prompt": r["Prompt Positivo ComfyUI (CLIP Text Encode)"],
        "negative": r["Prompt Negativo ComfyUI"],
        "controlnet": r["ControlNet / IP-Adapter"],
    })
with io.open(r"docs\sprite_spec.json", "w", encoding="utf-8") as f:
    json.dump(spec, f, indent=1, ensure_ascii=False)
print("entries:", len(spec["entries"]))
for e in spec["entries"]:
    print(" ", e["id"], "|", e["personagem"], "|", e["anim"])
