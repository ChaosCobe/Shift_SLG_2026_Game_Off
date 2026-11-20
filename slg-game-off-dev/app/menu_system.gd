extends Node

const PAUSE_MENU := preload("res://views/menus/pause_menu.tscn")
const SETTINGS_MENU := preload("res://views/menus/settings_menu.tscn")
const GameSettings := preload("res://app/game_settings.gd")
const SettingsMenu := preload("res://views/menus/settings_menu.gd")

var _pause_menu: Control
var _settings_menu: SettingsMenu
var _menu_before_settings: Control
var _focus_before_pause: Control
var _focus_before_settings: Control
var _returning_home := false
var _settings := GameSettings.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings.restore()


func open_settings(source_menu: Control) -> void:
	if _settings_menu != null or _returning_home:
		return

	_focus_before_settings = get_viewport().gui_get_focus_owner()
	_menu_before_settings = source_menu
	source_menu.hide()
	_settings_menu = SETTINGS_MENU.instantiate() as SettingsMenu
	_settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_settings_menu.closed.connect(_close_settings)
	UIManager.mount_modal(_settings_menu, Callable())
	_settings_menu.setup(_settings)


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return

	if _returning_home or SceneRouter.is_changing_scene():
		get_viewport().set_input_as_handled()
	elif _settings_menu != null:
		get_viewport().set_input_as_handled()
		_close_settings()
	elif _pause_menu != null:
		var confirm_home: ConfirmationDialog = _pause_menu.get_node("%ConfirmHome")
		if confirm_home.visible:
			get_viewport().set_input_as_handled()
			confirm_home.hide()
			_pause_menu.get_node("%ReturnHome").grab_focus()
			return
		get_viewport().set_input_as_handled()
		_resume_game()
	elif not get_tree().paused and SceneRouter.is_in_game():
		get_viewport().set_input_as_handled()
		_open_pause_menu()


func _open_pause_menu() -> void:
	_focus_before_pause = get_viewport().gui_get_focus_owner()
	get_tree().paused = true
	_pause_menu = PAUSE_MENU.instantiate() as Control
	_pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	var resume_button: Button = _pause_menu.get_node("%ResumeGame")
	var settings_button: Button = _pause_menu.get_node("%Settings")
	var home_button: Button = _pause_menu.get_node("%ReturnHome")
	resume_button.pressed.connect(_resume_game)
	settings_button.pressed.connect(open_settings.bind(_pause_menu))
	var confirm_home: ConfirmationDialog = _pause_menu.get_node("%ConfirmHome")
	home_button.pressed.connect(confirm_home.popup_centered.bind(Vector2i(332, 120)))
	confirm_home.confirmed.connect(_return_to_home)
	UIManager.mount_modal(_pause_menu, Callable())
	resume_button.grab_focus()


func _resume_game() -> void:
	if not _returning_home:
		_close_pause_menu()
		_restore_focus(_focus_before_pause)
		_focus_before_pause = null


func _close_pause_menu() -> void:
	UIManager.unmount_modal(_pause_menu)
	_pause_menu.queue_free()
	_pause_menu = null
	get_tree().paused = false


func _return_to_home() -> void:
	if _returning_home:
		return

	_returning_home = true
	if await SceneRouter.open_home():
		DialogueSystem.close()
		_close_pause_menu()
		_focus_before_pause = null
	else:
		_pause_menu.get_node("%ReturnError").show()
	_returning_home = false


func _close_settings() -> void:
	_settings.save()
	UIManager.unmount_modal(_settings_menu)
	_settings_menu.queue_free()
	_settings_menu = null
	_menu_before_settings.show()
	_menu_before_settings = null
	_restore_focus(_focus_before_settings)
	_focus_before_settings = null


func _restore_focus(control: Control) -> void:
	if is_instance_valid(control) and control.is_visible_in_tree():
		control.grab_focus()
