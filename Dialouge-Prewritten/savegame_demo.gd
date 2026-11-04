extends Control

## A tiny game state you can save and damage. Keys: G adds gold, S saves, L loads, C scrambles the
## save file so you can see it refused, D deletes the save.

const SAVE_PATH := "user://versioned_savegame_demo/save.dat"
const VERSION := 2

## Filled in by the tests. The demo itself doesn't read it.
var results: Dictionary = {}
var gold: int = 0
var save := VersionedSaveFile.new(SAVE_PATH, VERSION, migrate_save)

@onready var status_label: Label = $Status


## Version 1 saves called the gold "coins".
static func migrate_save(data: Dictionary, from_version: int) -> Dictionary:
	if from_version == 1:
		data["gold"] = data.get("coins", 0)
		data.erase("coins")
	return data


func _ready() -> void:
	set_meta("verify_unit", "VersionedSavegame")
	status_label.text = "G gold, S save, L load, C scramble, D delete"


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_G:
			gold += 1
			status_label.text = "Gold: %d" % gold
		KEY_S:
			var result: Error = save.write({"gold": gold})
			status_label.text = "Saved" if result == OK else error_string(result)
		KEY_L:
			load_game()
		KEY_C:
			_scramble_file()
		KEY_D:
			save.delete()
			status_label.text = "Deleted"


func load_game() -> void:
	var data: Dictionary = save.read()
	if save.last_status == VersionedSaveFile.Status.LOADED:
		gold = data.get("gold", 0)
		status_label.text = "Loaded %d gold" % gold
	else:
		status_label.text = "Not loaded: %s" % VersionedSaveFile.Status.find_key(save.last_status)


func _scramble_file() -> void:
	if not save.exists():
		status_label.text = "Nothing to scramble"
		return
	var file: FileAccess = FileAccess.open(save.path, FileAccess.WRITE)
	file.store_string("This isn't a save file")
	file.close()
	status_label.text = "Scrambled"
