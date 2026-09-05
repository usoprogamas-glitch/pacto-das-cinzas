class_name CapturedSouls
extends RefCounted

# Souls captured in a single fight, eligible for the post-battle naming modal.
# One nameable slot per soul type (avoids UI spam when multiple of a kind die).
var souls: Array[Dictionary] = []

func add(soul_type: String, display_name: String) -> void:
 if soul_type == "":
  return
 for s in souls:
  if s["type"] == soul_type:
   return
 souls.append({"type": soul_type, "display_name": display_name})

func has_captured() -> bool:
 return not souls.is_empty()

func clear() -> void:
 souls.clear()
