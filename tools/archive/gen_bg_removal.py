# -*- coding: utf-8 -*-
"""Remove fundo dos sprites HD 2D via ComfyUI BiRefNet → RGBA transparente.

ComfyUI gera a MÁSCARA (SaveImage preto/branco); a composição em alpha é feita
em Python/PIL — o SaveImage do ComfyUI sempre grava RGB sem canal alpha, então
PorterDuff ali não produz PNG transparente. Sobrescreve assets/sprites/*.png."""
import io, json, os, shutil, sys, time, urllib.parse, urllib.request
from PIL import Image

LOCAL = "http://localhost:8188"
INPUT_DIR = os.path.expandvars(r"%LOCALAPPDATA%\Comfy-Desktop\ComfyUI-Installs\ComfyUI\ComfyUI\input")
SPRITES = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")


def workflow_for(src):
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": src}},
        "2": {"class_type": "LoadBackgroundRemovalModel", "inputs": {"bg_removal_name": "birefnet_m.safetensors"}},
        "3": {"class_type": "RemoveBackground", "inputs": {"bg_removal_model": ["2", 0], "image": ["1", 0]}},
        "4": {"class_type": "MaskToImage", "inputs": {"mask": ["3", 0]}},
        "5": {"class_type": "SaveImage", "inputs": {"filename_prefix": "pacto_mask", "images": ["4", 0]}},
    }


def submit(workflow):
    payload = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request(f"{LOCAL}/prompt", data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())


def wait_for_job(pid, timeout=360, interval=3):
    start = time.time()
    while time.time() - start < timeout:
        with urllib.request.urlopen(f"{LOCAL}/history/{pid}") as r:
            history = json.loads(r.read())
        if pid in history:
            status = history[pid].get("status", {})
            if status.get("completed") or status.get("status_str") in ("success", "error"):
                return history[pid]
        time.sleep(interval)
    raise TimeoutError(f"Job {pid} timed out")


def download(filename, subfolder, type_):
    url = f"{LOCAL}/view?filename={urllib.parse.quote(filename)}&type={type_}"
    if subfolder:
        url += f"&subfolder={urllib.parse.quote(subfolder)}"
    with urllib.request.urlopen(url) as r:
        return r.read()


def apply_alpha(img_path, mask_data, out_path):
    img = Image.open(img_path).convert("RGBA")
    mask = Image.open(io.BytesIO(mask_data)).convert("L").resize(img.size, Image.LANCZOS)
    img.putalpha(mask)
    img.save(out_path)
    bbox = mask.getbbox()
    print(f"OK {os.path.basename(out_path)} alpha bbox={bbox} opaque={sum(1 for p in mask.getdata() if p >= 128)}px", flush=True)


def main():
    only = sys.argv[1:] if len(sys.argv) > 1 else None
    os.makedirs(INPUT_DIR, exist_ok=True)
    names = sorted(f for f in os.listdir(SPRITES) if f.endswith(".png"))
    if only:
        names = [n for n in names if n[:-4] in only]
    if not names:
        print("nenhum sprite alvo")
        return

    for name in names:
        src_path = os.path.join(SPRITES, name)
        shutil.copyfile(src_path, os.path.join(INPUT_DIR, name))
        resp = submit(workflow_for(name))
        pid = resp["prompt_id"]
        print(f"submetido {name} id={pid[:8]}", flush=True)
        entry = wait_for_job(pid)
        if entry.get("status", {}).get("status_str") == "error":
            print(f"ERRO {name}: {json.dumps(entry.get('status', {}))[:300]}", flush=True)
            continue
        img = None
        for oid in entry.get("outputs", {}):
            for im in entry["outputs"][oid].get("images", []):
                img = im
        if not img:
            print(f"sem imagem para {name}", flush=True)
            continue
        mask_data = download(img["filename"], img.get("subfolder", ""), img.get("type", "output"))
        apply_alpha(src_path, mask_data, src_path)


if __name__ == "__main__":
    main()