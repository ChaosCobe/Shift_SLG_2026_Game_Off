extends Control

signal advance_requested
signal choice_selected(index: int)
signal player_reply_finished
signal shift_confirmed

const PlayerReply := preload("res://views/dialogue/player_reply.gd")

var _focused_action: Control

@onready var _speaker: Label = %Speaker
@onready var _portrait: TextureRect = %Portrait
@onready var _line: Label = %Line
@onready var _player_reply: PlayerReply = $PlayerReply
@onready var _actions: HBoxContainer = %Actions
@onready var _shift_prompt: Control = %ShiftPrompt
@onready var _cancel_shift: Button = %CancelShift
@onready var _confirm_shift: Button = %ConfirmShift


func _ready() -> void:
	_player_reply.finished.connect(player_reply_finished.emit)
	_cancel_shift.pressed.connect(dismiss_shift_prompt)
	_confirm_shift.pressed.connect(_confirm_world_shift)


func set_speaker(display_name: String) -> void:
	_speaker.text = display_name


func set_portrait(portrait: Texture2D) -> void:
	_portrait.texture = portrait


func show_line(text: String, player_line: bool, choices: Array[String], has_next: bool) -> void:
	if player_line:
		_player_reply.present(text)
	else:
		_player_reply.dismiss()
		_line.text = text
	for action in _actions.get_children():
		_actions.remove_child(action)
		action.queue_free()

	if choices.is_empty():
		var caption := "继续" if has_next else "结束对话"
		_add_action(caption, advance_requested.emit)
	else:
		for index in choices.size():
			_add_action(choices[index], choice_selected.emit.bind(index))
	_focus_first_action()


func show_shift_prompt() -> void:
	if _shift_prompt.visible:
		return

	_focused_action = get_viewport().gui_get_focus_owner()
	_player_reply.set_suspended(true)
	for action: Button in _actions.get_children():
		action.disabled = true
	_shift_prompt.show()
	_cancel_shift.grab_focus()


func dismiss_shift_prompt() -> void:
	_shift_prompt.hide()
	_player_reply.set_suspended(false)
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
