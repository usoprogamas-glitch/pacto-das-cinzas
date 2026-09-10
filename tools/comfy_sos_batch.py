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
import zlib
import os
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
    "valera": ("valera, valiant knight of the fallen order with silver pauldrons, "
               "brown short hair, scarred left cheek, blue tabard with gold trim, resolute face"),
    "brugaves": ("brugaves, wise old merchant with round spectacles, gray beard, "
                 "velvet green coat with pockets full of trinkets, kind smile"),
    "garm": ("garm, one-eyed giant gray wolf, torn left ear, broken chains hanging "
             "from its neck, glowing pale blue remaining eye, scarred muzzle, fierce "
             "proud posture"),
    "lira": ("lira, ancient forest dryad priestess with bark-textured skin, "
             "leafy antler crown, moss-covered robes, gentle green glowing eyes"),
    "thalkor": ("thalkor, elder forge-priest with bald head, runic tattoos and "
                "bronze mask half-raised"),
}

# Personagens do jogo (full-body pixel-art, vista lateral-frontal p/ combate).
# Prompt template aprendido: prédio/personagem ÚNICO, fundo flat navy, corpo inteiro.
# Poses de MOVIMENTO por personagem (mesma seed + texto de pose variando):
# ciclo de caminhada em 4 keyframes + pose de ataque (molde SoS D/F).
CHARACTER_POSES = {
    "walk_a": "walking pose, left leg stepped forward, right arm swinging back",
    "walk_b": "walking pose, legs together passing, body upright mid-stride",
    "walk_c": "walking pose, right leg stepped forward, left arm swinging back",
    "walk_d": "walking pose, legs together passing, slight upward bob",
    "attack": "attack pose, lunging forward, weapon raised mid-swing",
}

CHARACTERS = {
    "npc_kaelen": "ONE single full body game character, spectral analytical ghost manifestation, translucent blue hooded figure with glowing cyan eyes, floating slightly above ground, fragments of light orbiting, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible, no crop, no ui, no grid, no other objects",
    "char_kael": "ONE single full body game character, small fractured cherubim angel creature, broken golden halo above head, white and gold body with dark ether wings, glowing eyes, standing idle pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_kroug": "ONE single full body game character, hobgoblin warrior, green skin, muscular, leather armor and shoulder pads, holding a wooden club, standing idle pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_mercenario": "ONE single full body game character, brutal human mercenary, leather armor, iron helmet, large sword on shoulder, standing idle pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_cacador": "ONE single full body game character, hooded ranger hunter, dark green cloak, wooden bow in hand, quiver on back, standing idle pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_esqueleto": "ONE single full body game character, skeleton warrior, rusty sword, tattered leather straps, cracked skull, standing idle pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_troll": "ONE single full body game character, massive gray-green troll monster, hunched posture, long arms, crude stone club, standing idle pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_lobo_sombrio": "ONE single full body game creature, dark shadow wolf with glowing pale eyes, smoky black fur, standing idle pose, side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_aranha_gigante": "ONE single full body game creature, giant spider monster, dark purple body with pale markings, eight legs, glowing eyes, standing idle pose, side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_paladino": "ONE single full body game character, solar paladin knight, golden plate armor, white cape, sun emblem shield and longsword, standing idle pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_inquisidor": "ONE single full body game character, solar church inquisitor mage, white and gold ceremonial robes, tall staff with sun emblem, standing idle pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_santo_cardeal": "ONE single full body game character, holy cardinal boss, white and gold ornate vestments, solar halo disc behind head, bishop staff, imposing pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_chefe_orc": "ONE single full body game character, orc chief, massive green orc with war paint, bone necklace, huge double axe, standing idle pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_cardeal_ignis": "ONE single full body game character, fire cardinal boss, red and black robes with flame patterns, fire crown, molten cracks on skin, imposing pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_cardeal_zephyr": "ONE single full body game character, wind cardinal boss, pale teal flowing robes, wind swirl aura, feathered mantle, imposing pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_cardeal_aqua": "ONE single full body game character, water cardinal boss, deep blue robes with coral ornaments, water orb in hand, imposing pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_cardeal_terra": "ONE single full body game character, earth cardinal boss, heavy stone armor, moss and crystal growths, massive gauntlets, imposing pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_cardeal_umbra": "ONE single full body game character, shadow cardinal boss, black and violet robes, face obscured by hood with purple eyes, shadow tendrils, imposing pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_aurius_fase1": "ONE single full body game character, false demigod on monumental throne, golden divine armor, cracked halo, solar scepter, sitting pose on throne, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire throne and body visible, no crop, no ui, no grid, no other objects",
    "char_aurius_fase2": "ONE single full body game character, seraph tyrant with six solar wings, golden divine armor, radiant crown, holding light lance, standing imposing pose, front-side view, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire body visible with feet on the ground, no crop, no ui, no grid, no other objects",
    "char_aurius_fase3": "ONE single single full body game character, desperate light core, unstable sphere of pure golden light with dark cracks, floating geometric rings around it, pixel art game character, sea of stars style, isolated on a plain flat dark navy background, entire object visible, no crop, no ui, no grid, no other objects",
}

ICONS = {
    "corte": "a single sword, one weapon only, vertical diagonal composition, pixel art game icon, steel blade with warm gold guard, centered on a plain flat dark navy background, isolated object, no ui, no menu, no items, no chests, no coins",
    "eter": "a single glowing arcane orb, one sphere only, pixel art game icon, cobalt blue core with white spark swirl, centered on a plain flat dark navy background, isolated object, no ui, no faces, no grid",
    "loja_mercador": "ONE single small shop building, exterior FRONT view, complete building with pointed roof, wooden walls, open counter window, hanging lantern, sea of stars style pixel art, centered, isolated on plain flat dark navy background, nothing else in scene, no interior, no items, no chests, no tree",
    "forja_camp": "a complete medieval blacksmith forge building, open front with glowing furnace, anvil, hanging tools, stone and wood construction, pixel art game building, sea of stars style, isolated on a plain flat dark navy background, entire building visible with roof and base, no crop, no ui, no characters, no grid",
    "casa_vila": "ONE single small cottage house, exterior FRONT view, complete building with thatched roof and chimney, wooden walls, warm window light, sea of stars style pixel art, centered, isolated on plain flat dark navy background, nothing else in scene, no interior, no items, no tree, no grid",
    "taverna": "a complete two-story medieval fantasy tavern building, full facade side view, wooden walls, red clay tile roof, two warm glowing windows, wooden door with small porch, chimney with light smoke, pixel art game building, sea of stars style, isolated on a plain flat dark navy background, entire building visible with roof and base, no crop, no ui, no characters, no grid",
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


def build_workflow(prompt, width, height, seed, use_lora, prefix, init_image=None, denoise=1.0,
                   sampler="dpmpp_2m", scheduler="karras", steps=16, cfg=6.0, lora_weight=1.0):
    wf = {"1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}}}
    model = ["1", 0]
    clip = ["1", 1]
    if use_lora:
        wf["2"] = {"class_type": "LoraLoader", "inputs": {
            "lora_name": LORA, "strength_model": lora_weight, "strength_clip": lora_weight,
            "model": ["1", 0], "clip": ["1", 1]}}
        model, clip = ["2", 0], ["2", 1]
    wf["10"] = {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": clip}}
    wf["11"] = {"class_type": "CLIPTextEncode", "inputs": {"text": NEG, "clip": clip}}
    if init_image:
        # img2img: latent da imagem base — denoise moderado varia a pose
        # mantendo a silhueta/identidade do personagem (anti-flicker de ciclo).
        wf["20"] = {"class_type": "LoadImage", "inputs": {"image": init_image}}
        wf["21"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["20", 0], "vae": ["1", 2]}}
        latent = ["21", 0]
    else:
        wf["12"] = {"class_type": "EmptyLatentImage", "inputs": {
            "width": width, "height": height, "batch_size": 1}}
        latent = ["12", 0]
    wf["13"] = {"class_type": "KSampler", "inputs": {
        "seed": seed, "steps": steps, "cfg": cfg, "sampler_name": sampler,
        "scheduler": scheduler, "denoise": denoise,
        "model": model, "positive": ["10", 0], "negative": ["11", 0],
        "latent_image": latent}}
    wf["14"] = {"class_type": "VAEDecode", "inputs": {"samples": ["13", 0], "vae": ["1", 2]}}
    wf["15"] = {"class_type": "SaveImage", "inputs": {"images": ["14", 0], "filename_prefix": prefix}}
    return wf


def upload_image(path):
    """Upload multipart para /upload/image; retorna o nome referenciável."""
    import mimetypes
    import uuid
    boundary = uuid.uuid4().hex
    filename = os.path.basename(path)
    with open(path, "rb") as f:
        data = f.read()
    body = (
        ("--%s\r\n" % boundary).encode()
        + ('Content-Disposition: form-data; name="image"; filename="%s"\r\n' % filename).encode()
        + ("Content-Type: %s\r\n\r\n" % (mimetypes.guess_type(filename)[0] or "application/octet-stream")).encode()
        + data
        + ("\r\n--%s--\r\n" % boundary).encode()
    )
    req = urllib.request.Request(
        BASE + "/upload/image", data=body,
        headers={"Content-Type": "multipart/form-data; boundary=%s" % boundary})
    with urllib.request.urlopen(req) as r:
        res = json.loads(r.read())
    return res.get("name", filename)


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
    if out_path.startswith("res://"):
        out_path = out_path[len("res://"):]
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


def run_poses(use_lora, only=None):
    """Gera poses de movimento. only = lista de chars (vazio = todos com poses)."""
    base_chars = dict(CHARACTERS)
    base_chars.update({k: v for k, v in CHARACTERS.items()})
    chars = sorted(set(base_chars.keys()))
    if only:
        chars = [c for c in chars if c in only]
    for char in chars:
        if not char.startswith("char_"):
            continue
        char_seed = int(zlib.crc32(("pose_" + char).encode())) % 10**8
        for pose, pose_desc in CHARACTER_POSES.items():
            out_dir = "res://assets/px/poses/%s" % char
            out_png = os.path.join(out_dir.replace("res://", ""), "%s_%s.png" % (char, pose))
            if os.path.exists(out_png):
                print("SKIP (já existe):", out_png, flush=True)
                continue
            base_raw = os.path.join(RAW_DIR, "%s.png" % char)
            init_name = None
            if os.path.exists(base_raw):
                init_name = upload_image(base_raw)
            prompt = base_chars[char] + ", " + pose_desc
            wf = build_workflow(prompt, 768, 768, char_seed, use_lora, "sos_pose",
                                init_image=init_name, denoise=0.5)
            outputs = submit_and_wait(wf)
            collect(outputs, "%s/%s_%s.png" % (RAW_DIR, char, pose),
                    "res://assets/px/poses/%s/%s_%s.png" % (char, char, pose), 192, 32)


def run_chars(use_lora, only=None):
    items = CHARACTERS.items() if not only else [(k, CHARACTERS[k]) for k in only if k in CHARACTERS]
    for name, desc in items:
        prompt = desc
        wf = build_workflow(prompt, 768, 768, abs(hash("char" + name)) % 10**8, use_lora, "sos_char")
        outputs = submit_and_wait(wf)
        collect(outputs, "%s/%s.png" % (RAW_DIR, name),
                "res://assets/px/%s.png" % name.replace("char_", "char_"), 192, 32)


def run_icons(use_lora, only=None):
    items = ICONS.items() if not only else [(k, ICONS[k]) for k in only if k in ICONS]
    for name, desc in items:
        prompt = (STYLE + "pixel art game ui icon, " + desc +
                  ", on plain flat dark navy square background, centered, chunky pixels")
        size = 768 if name == "taverna" else 512
        wf = build_workflow(prompt, size, size, abs(hash("icon" + name)) % 10**8, use_lora, "sos_icon")
        outputs = submit_and_wait(wf)
        thumb = 128 if name == "taverna" else 64
        collect(outputs, "%s/icon_%s.png" % (RAW_DIR, name),
                OUT_ICON % name, thumb, 24 if name == "taverna" else 16)


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
        targets = sys.argv[2:] if len(sys.argv) > 2 else None
        run_icons(lora, targets)
    elif mode == "chars":
        targets = sys.argv[2:] if len(sys.argv) > 2 else None
        run_chars(lora, targets)
    elif mode == "poses":
        targets = sys.argv[2:] if len(sys.argv) > 2 else None
        run_poses(lora, targets)
    elif mode == "tiles":
        run_tiles(lora)
    else:
        print("modo desconhecido:", mode)
        sys.exit(1)
    print("BATCH_OK", mode, flush=True)
