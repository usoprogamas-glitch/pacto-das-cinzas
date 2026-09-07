# -*- coding: utf-8 -*-
"""Métricas de assets do Sea of Stars (referência de produção):
tipos, dimensões, paletas, naming — sem extrair/copy nenhum asset."""
import os
import sys
import io
import json
import collections
import traceback

import UnityPy

BUNDLES_DIR = r"D:\Games\Sea of Stars\SeaOfStars_Data\StreamingAssets\aa\StandaloneWindows64"
OUT_JSON = "tools/sos_asset_metrics.json"
LIMIT_BUNDLES = int(os.environ.get("SOS_LIMIT", "12"))
MAX_SAMPLES_PER_TEX = 40  # texturas amostradas para contagem de paleta

report = {
    "bundles": [],
    "type_counts": collections.Counter(),
    "texture_dims": collections.Counter(),
    "texture_named": [],      # [name, w, h]
    "sprite_names": [],       # naming conventions
    "audio_names": [],
    "textasset_names": [],
    "palette_sizes": [],      # [name, unique_colors]
    "shader_names": [],
}

bundle_files = sorted(
    (f for f in os.listdir(BUNDLES_DIR) if f.endswith(".bundle")),
    key=lambda f: -os.path.getsize(os.path.join(BUNDLES_DIR, f)),
)[:LIMIT_BUNDLES]

for bf in bundle_files:
    path = os.path.join(BUNDLES_DIR, bf)
    entry = {"file": bf, "mb": round(os.path.getsize(path) / 1e6, 1), "types": {}}
    try:
        env = UnityPy.load(path)
        sampled = 0
        for obj in env.objects:
            t = obj.type.name
            entry["types"][t] = entry["types"].get(t, 0) + 1
            report["type_counts"][t] += 1
            try:
                if t == "Texture2D":
                    d = obj.read()
                    name = d.m_Name
                    w, h = d.m_Width, d.m_Height
                    report["texture_dims"]["%dx%d" % (w, h)] += 1
                    report["texture_named"].append([name, w, h])
                    if sampled < MAX_SAMPLES_PER_TEX and w * h <= 512 * 512:
                        try:
                            img = d.image
                            colors = img.convert("RGB").getcolors(maxcolors=100000)
                            report["palette_sizes"].append([name, len(colors) if colors else 100001])
                            sampled += 1
                        except Exception:
                            pass
                elif t == "Sprite":
                    d = obj.read()
                    report["sprite_names"].append(d.m_Name)
                elif t == "AudioClip":
                    d = obj.read()
                    report["audio_names"].append(d.m_Name)
                elif t == "TextAsset":
                    d = obj.read()
                    report["textasset_names"].append(d.m_Name)
                elif t == "Shader":
                    d = obj.read()
                    report["shader_names"].append(d.m_Name)
            except Exception:
                continue
    except Exception as e:
        entry["error"] = str(e)[:200]
    report["bundles"].append(entry)
    print("BUNDLE OK %s (%.1f MB, %d objs)" % (bf, entry["mb"], sum(entry["types"].values())), flush=True)

# agregações de naming
def name_patterns(names):
    pat = collections.Counter()
    for n in names:
        m = re.match(r"^([A-Za-z]+)", n)
        if m:
            pat[m.group(1)] += 1
    return pat.most_common(25)

import re
report["sprite_name_patterns"] = name_patterns(report["sprite_names"])
report["texture_name_patterns"] = name_patterns(n for n, _, _ in report["texture_named"])
report["totals"] = {
    "bundles_scanned": len(bundle_files),
    "objects": sum(report["type_counts"].values()),
    "unique_texture_dims": len(report["texture_dims"]),
    "textures": len(report["texture_named"]),
    "sprites": len(report["sprite_names"]),
    "audio": len(report["audio_names"]),
}

with io.open(OUT_JSON, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=1, ensure_ascii=False)
print("METRICS_DONE", json.dumps(report["totals"]))
