extends "res://addons/gut/test.gd"
## Testes GUT: versionamento + backup do save (AUDIT P2 #14)
## save_game()/load_game() fazem IO real em user:// — aqui usamos paths
## isolados por cópia dos dados (sem tocar no save do usuário).

const SAVE_PATH := "user://save_game.json"
const BACKUP_PATH := "user://save_game_backup.json"

func before_each() -> void:
	# isolar: garantir que o teste começa sem save prévio
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)

func after_each() -> void:
	# limpar o que o teste criou
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)

func test_save_carries_version():
	GameManager.save_game()
	assert_true(FileAccess.file_exists(SAVE_PATH), "save criado")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	assert_true(int(parsed.get("version", 0)) >= 2, "save versionado >= 2")

func test_backup_rotates_on_second_save():
	GameManager.save_game()
	assert_false(FileAccess.file_exists(BACKUP_PATH), "primeiro save não cria backup")
	GameManager.save_game()
	assert_true(FileAccess.file_exists(BACKUP_PATH), "segundo save rotaciona backup")

func test_load_falls_back_to_backup_when_save_corrupt():
	GameManager.save_game()
	GameManager.save_game()  # gera o backup
	# corromper o save principal
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string("{ isto nao e json ]")
	f.close()
	assert_true(GameManager.load_game(), "load cai no backup quando o save está corrompido")

func test_load_fails_cleanly_without_any_save():
	assert_false(GameManager.load_game(), "sem save nem backup → false, sem crash")
