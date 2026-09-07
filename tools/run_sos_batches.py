#!/usr/bin/env python3
"""Roda os 3 batches SoS em sequência (retratos, ícones, tiles). Ver tools/comfy_sos_batch.py."""
import subprocess
import sys

for mode in ["portraits", "icons", "tiles"]:
    rc = subprocess.call([sys.executable, "tools/comfy_sos_batch.py", mode])
    if rc != 0:
        print("FALHA no modo %s (rc=%d) — seguindo para o próximo" % (mode, rc))
print("SOS_ALL_DONE")
