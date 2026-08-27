# -*- coding: utf-8 -*-
"""Gera sprites HD 2D para as unidades do Pacto das Cinzas via ComfyUI local.
Reusa kroug_workflow.json como template; troca prompt (node 2) e prefixo (node 6)."""
import json, os, sys, time, urllib.request

LOCAL = "http://localhost:8188"
BASE = os.path.join(os.path.dirname(__file__), "..", "kroug_workflow.json")
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")

HD2D = ("HD 2D game art of {subject}, high-quality hand-painted 2D illustration "
        "in the style of Ori and the Will of the Wisps, cinematic in-game unit portrait, "
        "dramatic rim light, rich color palette, masterpiece, ultra detailed, 8k concept art")
NEG = ("ugly, deformed, noisy, blurry, low quality, watermark, text, modern clothes, "
       "sci-fi, photorealistic, 3d render, neon, cartoon")

# char_key -> (nome visível, sujeito do prompt, seed)
ROSTER = [
    ("kael", "Kael, Querubim Fraturado", "a shattered little cherub imp, ethereal fractured beauty, broken ivory cherub wings, glowing amber soul ember in its chest, ash and stardust floating around, tragic divine remnant"),
    ("lira", "Lira, Sacerdotisa da Floresta", "an ancestral shadow dryad priestess, moss and bark skin, glowing green heart, vines and thorn bow, melancholic poetic posture, small flowers blooming"),
    ("thalkor", "Thal'kor, Lâmina Cega", "a blind fallen angel assassin, black seraph with six razor wings of steel feathers, bandaged cracked eyes, twin feather blade katanas, dark wind",),
    ("querubim", "Querubim (forma divina)", "a radiant fractured cherub angel, broken glowing halo, white-gold feathers, divine silver light cracks, majestic yet broken"),
    ("mercenario", "Mercenário", "a battle-worn human mercenary warrior, steel vanguard armor, mud-stained cloak, scarred grim face, sword and round shield"),
    ("cacador", "Caçador", "a human hunter archer, leather hunting gear, longbow, hood, sharp keen eyes, forest ambush stance"),
    ("inquisidor", "Inquisidor de Aço", "a steel inquisitor of a solar church, heavy ornate armor with sun sigil, runic chains, masked helm, glowing golden visor, iron flail"),
    ("paladino", "Paladino da Alvorada", "a paladin of the dawn, gleaming golden-white armor, holy longsword, radiant sun crest shield, righteous stance"),
    ("troll", "Troll", "a hulking swamp troll, mossy rocky skin, tusked jaw, heavy iron club, massive brute"),
    ("lobo_sombrio", "Lobo Sombrio", "a shadow wolf, thick black fur, glowing ember eyes, ash trail like smoke behind it, feral snarl"),
    ("aranha_gigante", "Aranha Gigante", "a giant cave spider, chitinous armor plating, glowing venom sacks, dripping web threads"),
    ("esqueleto", "Esqueleto", "a reanimated skeleton soldier, tattered priest robes over bare bone, rusted holy sigil, cold glowing eyes"),
    ("cardeal", "Santo Cardeal", "a saint cardinal boss of the solar church, ornate crimson and gold cardinal robes, radiant solar halo, runic staff, imposing divine wrath"),
]


def submit(workflow):
    payload = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request(f"{LOCAL}/prompt", data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())


def wait_for_job(prompt_id, timeout=360, interval=3):
    start = time.time()
    while time.time() - start < timeout:
        with urllib.request.urlopen(f"{LOCAL}/history/{prompt_id}") as r:
            history = json.loads(r.read())
        if prompt_id in history:
            status = history[prompt_id].get("status", {})
            if status.get("completed") or status.get("status_str") in ("success", "error"):
                return history[prompt_id]
        time.sleep(interval)
    raise TimeoutError(f"Job {prompt_id} timed out")


def download(filename, prefix):
    url = f"{LOCAL}/view?filename={urllib.parse.quote(filename)}&type=output"
    with urllib.request.urlopen(url) as r:
        data = r.read()
    path = os.path.join(OUT, prefix + ".png")
    with open(path, "wb") as f:
        f.write(data)
    print(f"OK {prefix}.png ({len(data)//1024} KB)", flush=True)


urlparse = urllib.parse  # noqa


def main():
    import urllib.parse
    with open(BASE, encoding="utf-8") as f:
        wf = json.load(f)
    os.makedirs(OUT, exist_ok=True)

    only = sys.argv[1:] if len(sys.argv) > 1 else None
    for i, (key, label, subject) in enumerate(ROSTER):
        if only and key not in only:
            continue
        w = json.loads(json.dumps(wf))  # deep copy
        w["2"]["inputs"]["text"] = HD2D.format(subject=subject)
        w["3"]["inputs"]["text"] = NEG
        w["4"]["inputs"]["seed"] = 1000 + i + 42
        w["6"]["inputs"]["filename_prefix"] = f"pacto_{key}_"
        resp = submit(w)
        pid = resp["prompt_id"]
        print(f"submetido {key} ({label}) id={pid[:8]}", flush=True)
        entry = wait_for_job(pid)
        if entry.get("status", {}).get("status_str") == "error":
            print(f"ERRO {key}: {json.dumps(entry.get('status', {}))[:200]}", flush=True)
            continue
        img = None
        for oid in entry["outputs"]:
            for im in entry["outputs"][oid].get("images", []):
                img = im
        if img:
            download(img["filename"], key)
        else:
            print(f"sem imagem para {key}", flush=True)


if __name__ == "__main__":
    main()