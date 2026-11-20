extends RefCounted

const SAVE_DIRECTORY := "user://saves"
const SAVE_PATH := SAVE_DIRECTORY + "/slot_01.json"
const BACKUP_PATH := SAVE_PATH + ".bak"
const TEMP_PATH := SAVE_PATH + ".tmp"


static func save_snapshot(snapshot: Dictionary, validate: Callable) -> Error:
	var contents := JSON.stringify(snapshot, "\t") + "\n"
	if _decode_snapshot(contents, validate).is_empty():
		return ERR_INVALID_DATA

	if not DirAccess.dir_exists_absolute(SAVE_DIRECTORY):
		var directory_error := DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY)
		if directory_error != OK:
			return directory_error

	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	if not file.store_string(contents):
		file.close()
		return ERR_FILE_CANT_WRITE
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	if FileAccess.get_file_as_string(TEMP_PATH) != contents:
		return ERR_FILE_CANT_WRITE

	# Rotate only a valid primary. The backup remains readable if the final rename fails.
	if not _read_snapshot(SAVE_PATH, validate).is_empty():
		var backup_error := DirAccess.rename_absolute(SAVE_PATH, BACKUP_PATH)
		if backup_error != OK:
			return backup_error

	return DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)


static func load_snapshot(validate: Callable) -> Dictionary:
	var snapshot := _read_snapshot(SAVE_PATH, validate)
	if not snapshot.is_empty():
		return {"ok": true, "snapshot": snapshot, "used_backup": false}

	snapshot = _read_snapshot(BACKUP_PATH, validate)
	if not snapshot.is_empty():
		return {"ok": true, "snapshot": snapshot, "used_backup": true}

	var exists := FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)
	return {"ok": false, "reason": &"invalid_save" if exists else &"missing_save"}


static func _read_snapshot(path: String, validate: Callable) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	return _decode_snapshot(FileAccess.get_file_as_string(path), validate)


static func _decode_snapshot(contents: String, validate: Callable) -> Dictionary:
	var json := JSON.new()
	if json.parse(contents) != OK:
		return {}
	var data: Variant = json.data
	if not data is Dictionary or not validate.is_valid() or not validate.call(data):
		return {}
	return data
