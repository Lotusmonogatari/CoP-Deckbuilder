extends GutTest
## A tester's report (2026-11-25): the game was closed, restarted, Continue was pressed and the run was back at day one. At boot the
## game holds a blank default run; the phone pausing the game, or a button on the title screen, saved that blank run over the real
## save before Continue could load it. Nothing may be written until a run has really been started or loaded.

const PATH := "user://audit_boot_save.json"
const SECOND := "user://audit_boot_save.second.json"   # SaveManager.second_path() while save_path is PATH


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	SaveManager.enabled = true
	SaveManager.save_path = PATH
	DirAccess.remove_absolute(PATH)
	DirAccess.remove_absolute(PATH + ".bak")
	DirAccess.remove_absolute(SECOND)


func after_each() -> void:
	SaveManager.enabled = false
	SaveManager.save_path = SaveManager.SAVE_PATH
	DirAccess.remove_absolute(PATH)
	DirAccess.remove_absolute(PATH + ".bak")
	DirAccess.remove_absolute(SECOND)
	GameState.run_is_live = true


func _real_run_on_disk() -> void:
	GameState.xp = 777
	assert_true(SaveManager.save_game())


func _boot() -> void:
	# What the game looks like at the title screen: a blank default run, nothing started or loaded.
	GameState.start_new_run("PC01")
	GameState.run_is_live = false


func test_a_pause_at_the_title_screen_does_not_overwrite_the_save() -> void:
	_real_run_on_disk()
	_boot()
	SaveManager.autosave()
	SaveManager._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var saved := SaveManager.read_save(PATH)
	assert_eq(int(saved["xp"]), 777, "the real run is still there")


func test_a_title_screen_button_press_does_not_overwrite_the_save() -> void:
	_real_run_on_disk()
	_boot()
	SaveManager._save_for_click()
	assert_eq(int(SaveManager.read_save(PATH)["xp"]), 777)


func test_the_checkpoint_and_the_second_save_wait_too() -> void:
	_real_run_on_disk()
	_boot()
	SaveManager.save_checkpoint()
	assert_eq(int(SaveManager.read_save(PATH)["xp"]), 777)
	assert_false(FileAccess.file_exists(SaveManager.second_path()), "and the second save is not written either")


func test_continue_loads_the_run_and_saving_then_works() -> void:
	_real_run_on_disk()
	_boot()
	assert_true(SaveManager.load_game(PATH))
	assert_eq(GameState.xp, 777)
	assert_true(GameState.run_is_live)
	GameState.xp = 800
	SaveManager.autosave()
	assert_eq(int(SaveManager.read_save(PATH)["xp"]), 800)


func test_starting_a_new_game_makes_saving_live() -> void:
	_boot()
	GameState.start_new_run("PC01")
	assert_true(GameState.run_is_live)
	SaveManager.autosave()
	assert_true(FileAccess.file_exists(PATH))
