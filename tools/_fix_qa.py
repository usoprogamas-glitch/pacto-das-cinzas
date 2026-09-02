path = "tools/qa_run.gd"
text = open(path, encoding="utf-8").read()
text = text.replace("GameManager.start_new_game()", 'gm().start_new_game()')
text = text.replace("GameManager.sync_current_map_from_campaign()", 'gm().sync_current_map_from_campaign()')
text = text.replace("GameManager.game_data", 'gm().game_data')
text = text.replace("GameManager.campaign_system", 'gm().campaign_system')
header = """
func gm() -> Node:
	return root.get_node("/root/GameManager")
"""
marker = "func _initialize()"
text = text.replace(marker, header.strip() + "\n\n\n" + marker, 1)
open(path, "w", encoding="utf-8", newline="").write(text)
print("ok")
