extends Control

signal finished
signal shift_confirmed

const DialogueSession := preload("res://views/dialogue/dialogue_session.gd")

var _session: DialogueSession
var _focused_action: Control

@onready var _speaker: Label = %Speaker
@onready var _portrait: TextureRect = %Portrait
@onready var _line: Label = %Line
@onready var _actions: HBoxContainer = %Actions
@onready var _shift_prompt: Control = %ShiftPrompt
@onready var _cancel_shift: Button = %CancelShift
@onready var _confirm_shift: Button = %ConfirmShift


func _ready() -> void:
	_cancel_shift.pressed.connect(dismiss_shift_prompt)
	_confirm_shift.pressed.connect(_confirm_world_shift)


func start(session: DialogueSession, world: int) -> void:
	_session = session
	_speaker.text = _session.speaker_name
	update_portrait(world)
	_show_line()


func update_portrait(world: int) -> void:
	_portrait.texture = _session.portrait_for(world)


func show_shift_prompt() -> void:
	if _shift_prompt.visible:
		return

	_focused_action = get_viewport().gui_get_focus_owner()
	for action: Button in _actions.get_children():
		action.disabled = true
	_shift_prompt.show()
	_cancel_shift.grab_focus()


func dismiss_shift_prompt() -> void:
	_shift_prompt.hide()
	_confirm_shift.disabled = false
	_cancel_shift.disabled = false
	for action: Button in _actions.get_children():
		action.disabled = false
	if is_instance_valid(_focused_action) and _focused_action.get_parent() == _actions:
		_focused_action.grab_focus()
	else:
		_focus_first_action()


func _confirm_world_shift() -> void:
	_confirm_shift.disabled = true
	_cancel_shift.disabled = true
	shift_confirmed.emit()


func _show_line() -> void:
	_line.text = _session.current_text()
	for action in _actions.get_children():
		_actions.remove_child(action)
		action.queue_free()

	var options := _session.options()
	if options.is_empty():
		var caption := "继续" if _session.has_next_line() else "结束对话"
		_add_action(caption, _advance)
	else:
		for option: String in options:
			_add_action(option, _choose.bind(option))
	_focus_first_action()


func _add_action(caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(92, 28)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	_actions.add_child(button)


func _focus_first_action() -> void:
	var first_action := _actions.get_child(0) as Button
	first_action.grab_focus()


func _advance() -> void:
	if _session.advance():
		_show_line()
	else:
		finished.emit()


func _choose(option: String) -> void:
	_session.choose(option)
	_show_line()
