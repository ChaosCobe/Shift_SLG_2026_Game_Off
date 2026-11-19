extends RefCounted

var speaker_name: String
var _portraits: Dictionary
var _lines: Dictionary
var _line_id := &"opening"


func _init(display_name: String, portraits: Dictionary, lines: Dictionary) -> void:
	speaker_name = display_name
	_portraits = portraits
	_lines = lines


func portrait_for(world: int) -> Texture2D:
	return _portraits.get(world) as Texture2D


func current_text() -> String:
	return _lines[_line_id]["text"]


func options() -> Dictionary:
	return _lines[_line_id].get("options", {})


func has_next_line() -> bool:
	return _lines[_line_id].has("next")


func advance() -> bool:
	if not has_next_line():
		return false
	_line_id = _lines[_line_id]["next"]
	return true


func choose(option: String) -> void:
	_line_id = options()[option]
