#!/usr/bin/env python3
"""CLI do Cartographer (ferramenta dev): gera mapas determinísticos por bioma
via Godot headless (CartographerCore) e salva JSON + preview PNG.

Uso:
  python tools/cartographer_cli.py --biome volcanic --w 12 --h 12 --seed 611 --out maps/vulcao
  python tools/cartographer_cli.py --all                      # preview de todos os biomas

Arquitetura: o Python escreve um job.json (args à prova de quirks de CLI do
Godot -s), roda o runner SceneTree que lê o job e chama CartographerCore.
"""
import json
import subprocess
import sys
import os

GODOT = r"C:\Godot43\Godot_v4.3-stable_win64_console.exe"
PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

RUNNER_GD = r"""
extends SceneTree

const CoreLib := preload("res://scripts/dev/cartographer_core.gd")

func _init():
	var f := FileAccess.open("res://tools/_cartographer_job.json", FileAccess.READ)
	var job: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	var core := CoreLib.new()
	var dir_out: String = job.get("out", "tools/cartographer_out")
	DirAccess.make_dir_recursive_absolute(dir_out)
	var seed: int = int(job.get("seed", 0))
	var biomes: Array = job.get("biomes", ["mixed"])
	var w: int = int(job.get("w", 10))
	var h: int = int(job.get("h", 10))
	for b in biomes:
		var res: Dictionary = core.generate({
			"terrain": b, "size": Vector2i(w, h), "seed": seed,
		})
		var json_path := "%s/%s_seed%d.json" % [dir_out, b, seed]
		var out := FileAccess.open(json_path, FileAccess.WRITE)
		out.store_string(JSON.stringify(res, "  "))
		out.close()
		var img: Image = core.render_preview(res["tiles"], 16)
		img.save_png("%s/%s_seed%d.png" % [dir_out, b, seed])
		print("CARTO_OK %s tiles=%dx%d stats=%s" % [b, w, h, JSON.stringify(res["stats"])])
	print("CARTO_DONE")
	quit()
"""


def main() -> None:
	runner = os.path.join(PROJ, "tools", "_cartographer_runner.gd")
	job_path = os.path.join(PROJ, "tools", "_cartographer_job.json")
	user_args = sys.argv[1:]

	def arg_value(flag: str, default):
		return user_args[user_args.index(flag) + 1] if flag in user_args and user_args.index(flag) + 1 < len(user_args) else default

	biome = arg_value("--biome", "mixed")
	out = arg_value("--out", "tools/cartographer_out")
	biomes = list(CARTO_BIOMES) if "--all" in user_args else [biome]
	job = {
		"biomes": biomes,
		"w": int(arg_value("--w", 10)),
		"h": int(arg_value("--h", 10)),
		"seed": int(arg_value("--seed", 0)),
		"out": out,
	}
	with open(runner, "w", encoding="utf-8") as f:
		f.write(RUNNER_GD)
	with open(job_path, "w", encoding="utf-8") as f:
		json.dump(job, f)
	proc = subprocess.Popen([GODOT, "--headless", "--path", PROJ, "-s", "tools/_cartographer_runner.gd"])
	try:
		proc.wait(timeout=60)
	except subprocess.TimeoutExpired:
		proc.kill()  # quirk: quit() do SceneTree headless pode não encerrar no Windows
		proc.wait()
	os.remove(runner)
	os.remove(job_path)
	sys.exit(0)


# Espelha CartographerCore.BIOMES (keys) para o modo --all sem boot do Godot.
CARTO_BIOMES = ["mixed", "forest", "cave", "castle", "volcanic"]


if __name__ == "__main__":
	main()
