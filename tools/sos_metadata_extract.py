# -*- coding: utf-8 -*-
"""Cartographer de referência: extrai arquitetura do Sea of Stars (metadados IL2CPP)
para aprendizado de design de código — apenas nomes/estrutura, sem assets."""
import re
import collections
import io

RAW = open(r"D:\Games\Sea of Stars\SeaOfStars_Data\il2cpp_data\Metadata\global-metadata.dat", "rb").read()
strs = [s.decode() for s in re.findall(rb"[A-Za-z_][A-Za-z0-9_.<>]{7,90}", RAW)]

out = io.open(r"docs\sos_reference_architecture.md", "w", encoding="utf-8")
out.write("# Referência de arquitetura — Sea of Stars (extraído de metadados IL2CPP)\n\n")
out.write("> Apenas NOMES de namespaces/classes de código (estrutura), sem assets.\n")
out.write("> Uso: aprender padrões do estúdio para aplicar no Pacto das Cinzas.\n\n")

# 1) gameplay namespaces
own = collections.Counter()
for s in strs:
    m = re.match(r"^(Sabotage\.(?:SeaOfStars\.Script|Gameplay)[A-Za-z0-9_.]*)$", s)
    if m:
        own[m.group(1)] += 1
out.write("## Namespaces de gameplay (Sabotage.SeaOfStars.Script.* / Sabotage.Gameplay.*)\n\n")
for s in sorted(own):
    out.write("- `%s`\n" % s)

# 2) state machine / behavior tree / graph patterns (o coração do SoS)
out.write("\n## Padrões de arquitetura detectados\n\n")
patterns = {
    "Behavior Tree (Sabotage.Graph.BehaviorTree)": r"^Sabotage\.Graph\.BehaviorTree",
    "State Machine": r"StateMachine",
    "Timeline (cutscenes/sequências)": r"Timeline",
    "Pooling": r"Pooling",
    "Additive Level Loading (cenas contínuas)": r"AdditiveLevelLoader|LoadWorldMapSection|StreamingWorld",
    "Parallax": r"Parallax",
    "Ocean/água shader-based": r"Ocean",
    "Pixel Perfect": r"PixelPerfect",
    "GameplayConditions (gating por estado de jogo)": r"GameplayConditions",
    "Cross-scene refs": r"CrossScene",
    "ScriptableObject com Id (data-driven)": r"ScriptableObjectWithId",
    "Localization própria": r"Sabotage\.Localization",
    "Time of Day": r"TimeOfDay",
    "Verlet rope (cordas/efeitos físicos)": r"VerletRope",
    "Boids (cardumes)": r"Boids",
}
for label, pat in patterns.items():
    n = sum(1 for s in strs if re.search(pat, s))
    out.write("- **%s**: %d símbolos\n" % (label, n))

# 3) gameplay classes notáveis
notable_kw = ["TimedHit", "Timing", "LiveMana", "Combo", "Lock", "Relic", "Cooking", "Campfire",
              "Fishing", "WorldMap", "Teleporter", "Cutscene", "Quest", "Dialog", "Party",
              "Skill", "Spell", "EnemyPattern", "Hitstop", "Shake", "Boost", "Dungeon", "Encounter"]
out.write("\n## Sistemas de gameplay (classes por palavra-chave)\n\n")
for kw in notable_kw:
    cls = sorted(set(s for s in strs if kw.lower() in s.lower()
                     and re.match(r"^[A-Z][A-Za-z0-9_.]{7,60}$", s)
                     and "UnityEngine" not in s and "System" not in s[:8]
                     and "Rewired" not in s))[:12]
    if cls:
        out.write("### %s\n" % kw)
        for c in cls:
            out.write("- `%s`\n" % c)
out.close()
print("OK docs/sos_reference_architecture.md")
