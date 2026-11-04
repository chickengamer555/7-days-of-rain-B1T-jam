class_name VersionedSaveFile
extends RefCounted
## Saves one Dictionary to one file, so that a crash or a bad file can't cost the player their save.
##
## Writes go to a temporary file, get read back and checked, then replace the real file in one step.
## Each file carries a checksum and a version. Bad files are refused without decoding them, and old
## versions go through your migration function when loaded. Objects aren't decoded, and a file
## holding an object id, Callable, Signal or RID is refused as corrupt.
##
## Heavily adapted from gdquest-demos/godot-4-savegame. See RECIPE.md.

enum Status {
	LOADED, ## read() returned the save.
	MISSING, ## There is no save at this path.
	CORRUPT, ## The file is damaged or isn't a save. It was left where it is.
	TOO_NEW, ## A newer version of the game wrote this save. It was left where it is.
	MIGRATION_FAILED, ## This older save couldn't be upgraded. It was left where it is.
}

const TEMP_SUFFIX := ".tmp"
const CORRUPT_SUFFIX := ".corrupt"

## Marks the file as one of ours. A version change in this layout would change this too.
const MAGIC := "GVS1"
const HASH_SIZE := 32
const KEY_VERSION := "version"
const KEY_DATA := "data"

var path: String
var current_version: int
## Called once for each step, so a version 1 save loading in version 3 calls it twice.
## Signature: func(data: Dictionary, from_version: int) -> Dictionary. Return the upgraded data.
## Return anything other than a Dictionary to refuse, which gives MIGRATION_FAILED.
var migrate: Callable
## The outcome of the last read().
var last_status: Status = Status.MISSING
## The version the last read() found in the file, before migrating. 0 if it found none.
var saved_version: int = 0


func _init(
		save_path: String = "user://save.dat",
		version: int = 1,
		migration: Callable = Callable(),
) -> void:
	path = save_path
	current_version = version
	migrate = migration


func exists() -> bool:
	return FileAccess.file_exists(path)


## Replaces the save with data. On any failure the existing save is untouched, and this returns:
## ERR_INVALID_DATA if data holds objects, Callables, Signals or RIDs, which can't be saved.
## ERR_ALREADY_IN_USE if the existing save is from a newer version, which this would destroy.
## Otherwise the file error. A corrupt existing save is kept beside it with CORRUPT_SUFFIX.
func write(data: Dictionary) -> Error:
	if not _can_save(data):
		return ERR_INVALID_DATA
	if _parse(path).get("status") == Status.TOO_NEW:
		return ERR_ALREADY_IN_USE
	# If this fails, opening the temp file fails too and reports the error.
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var temp_path: String = path + TEMP_SUFFIX
	var write_result: Error = _write_file(temp_path, {KEY_VERSION: current_version, KEY_DATA: data})
	if write_result != OK:
		_remove_file(temp_path)
		return write_result
	if _parse(temp_path).get("status") != Status.LOADED:
		_remove_file(temp_path)
		return ERR_FILE_CORRUPT
	if exists() and _parse(path).get("status") == Status.CORRUPT:
		DirAccess.rename_absolute(path, path + CORRUPT_SUFFIX)
	var rename_result: Error = DirAccess.rename_absolute(temp_path, path)
	if rename_result != OK:
		_remove_file(temp_path)
	return rename_result


## Returns the saved data, migrated to current_version, or an empty Dictionary if it couldn't.
## Check last_status to find out why. This never changes the file, so call write() to keep an
## upgrade.
func read() -> Dictionary:
	saved_version = 0
	var parsed: Dictionary = _parse(path)
	last_status = parsed["status"]
	saved_version = parsed.get("version", 0)
	if last_status != Status.LOADED:
		return {}
	var data: Dictionary = parsed["data"]
	for from_version: int in range(saved_version, current_version):
		if not migrate.is_valid():
			last_status = Status.MIGRATION_FAILED
			return {}
		var upgraded: Variant = migrate.call(data, from_version)
		if not upgraded is Dictionary:
			last_status = Status.MIGRATION_FAILED
			return {}
		data = upgraded
	return data


## Removes the save and any leftover temporary or corrupt copy beside it.
func delete() -> void:
	for file_path: String in [path, path + TEMP_SUFFIX, path + CORRUPT_SUFFIX]:
		_remove_file(file_path)


func _write_file(file_path: String, envelope: Dictionary) -> Error:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var body: PackedByteArray = var_to_bytes(envelope)
	file.store_buffer(MAGIC.to_ascii_buffer())
	file.store_32(body.size())
	file.store_buffer(_hash_of(body))
	file.store_var(envelope, false)
	file.flush()
	var result: Error = file.get_error()
	file.close()
	return result


## Checks the file before decoding it, so that a bad file produces a status and no engine errors.
## The result always has "status". It has "version" and "data" once the file is known to be good.
func _parse(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {"status": Status.MISSING}
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {"status": Status.CORRUPT}
	if file.get_buffer(MAGIC.length()).get_string_from_ascii() != MAGIC:
		return {"status": Status.CORRUPT}
	var body_size: int = file.get_32()
	var expected_hash: PackedByteArray = file.get_buffer(HASH_SIZE)
	var var_start: int = file.get_position()
	# store_var writes its own 4 byte length in front of the body.
	if file.get_length() != var_start + 4 + body_size:
		return {"status": Status.CORRUPT}
	file.seek(var_start + 4)
	if _hash_of(file.get_buffer(body_size)) != expected_hash:
		return {"status": Status.CORRUPT}
	file.seek(var_start)
	# SECURITY: false means objects are refused. Never change this, and never use str_to_var, because
	# a shared save file could then run code on the player's machine.
	return _check_envelope(file.get_var(false))


func _check_envelope(envelope: Variant) -> Dictionary:
	if not envelope is Dictionary:
		return {"status": Status.CORRUPT}
	var version: Variant = (envelope as Dictionary).get(KEY_VERSION)
	var data: Variant = (envelope as Dictionary).get(KEY_DATA)
	if not version is int or not data is Dictionary or version < 1:
		return {"status": Status.CORRUPT}
	# get_var(false) still returns these: an object comes back as an EncodedObjectAsID. write() can't
	# produce them, so they mean an edited file.
	if not _can_save(data):
		return {"status": Status.CORRUPT}
	if version > current_version:
		return {"status": Status.TOO_NEW, "version": version}
	return {"status": Status.LOADED, "version": version, "data": data}


func _hash_of(bytes: PackedByteArray) -> PackedByteArray:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish()


func _can_save(value: Variant) -> bool:
	match typeof(value):
		TYPE_OBJECT, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID:
			return false
		TYPE_ARRAY:
			for item: Variant in value:
				if not _can_save(item):
					return false
		TYPE_DICTIONARY:
			for key: Variant in value:
				if not _can_save(key) or not _can_save(value[key]):
					return false
	return true


func _remove_file(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
