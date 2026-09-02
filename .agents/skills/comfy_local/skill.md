---
name: comfy_local
description: Generate images and videos via the local ComfyUI server on port 8188. Use when the user wants to generate, create, or render images/video using a locally-running ComfyUI installation.
argument-hint: [prompt or description of what to generate]
allowed-tools: Bash, Read, Write, Glob, Grep, Agent, WebFetch
---

# ComfyUI Local Server Skill

You interact with a local ComfyUI server at `http://localhost:8188` to generate images and video headlessly via the REST API. **No auth** — the server is open on localhost.

## Local API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/prompt` | POST | Submit a workflow (`{"prompt": {...}}`) → `{"prompt_id": "..."}` |
| `/queue` | GET | Check queue status |
| `/history/{prompt_id}` | GET | Get job result/status (poll this) |
| `/object_info` | GET | List all available nodes (legacy COMBO format `[[opt, ...]]`) |
| `/object_info/{NodeType}` | GET | Get a single node's inputs/options |
| `/view?filename=X&type=output` | GET | Download output file (no auth, no redirect) |
| `/upload/image` | POST | Upload input image (multipart) |
| `/system_stats` | GET | GPU info, VRAM, ComfyUI version |

## Submitting & Polling

```python
import json, urllib.request, time

LOCAL = "http://localhost:8188"

def submit(workflow):
    payload = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request(f"{LOCAL}/prompt", data=payload,
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())  # {"prompt_id": "..."}

def wait_for_job(prompt_id, timeout=240, interval=2):
    """Poll /history/{id}; returns the history entry once available + complete."""
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
```

## Output Directory

Local ComfyUI writes to `C:/ai/ComfyUI/output/` by default. For the Pacto das Cinzas project, outputs can be copied to `assets/` folder.

## Error Handling

- **Server down:** tell the user to start ComfyUI (`python main.py` in ComfyUI directory)
- **Missing node type:** check `/object_info` to see if it's installed
- **Missing model file:** check `/object_info/{NodeType}` for available models

## Pacto das Cinzas Integration

When generating assets for "O Pacto das Cinzas":
- Use the GDD v2 descriptions for character forms (Querubim Fraturado, Serafim das Cinzas, etc.)
- Match the visual style: Dark fantasy, ethereal, cobalt blue energy, ash particles
- Output naming: `pacto_[character]_[form]_[variant].png`
- Copy to `assets/sprites/` or `assets/portraits/` as appropriate

## Example Usage

```bash
# Check if ComfyUI is running
curl -s http://localhost:8188/system_stats

# List available checkpoints
curl -s http://localhost:8188/object_info/CheckpointLoaderSimple | python -c "
import json,sys; d=json.load(sys.stdin)
for m in d['CheckpointLoaderSimple']['input']['required']['ckpt_name'][0]: print(m)"

# List available LoRAs
curl -s http://localhost:8188/object_info/LoraLoader | python -c "
import json,sys; d=json.load(sys.stdin)
for l in d['LoraLoader']['input']['required']['lora_name'][0]: print(l)"
```
