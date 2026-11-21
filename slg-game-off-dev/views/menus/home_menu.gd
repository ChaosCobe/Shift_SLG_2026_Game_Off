extends Control

@onready var _new_game: Button = %NewGame
@onready var _continue_game: Button = %ContinueGame
@onready var _replace_save: ConfirmationDialog = %ReplaceSave


func _ready() -> void:
	_new_game.pressed.connect(_request_new_game)
	_continue_game.pressed.connect(_continue_from_save)
	%Settings.pressed.connect(MenuSystem.open_settings.bind(self))
	_replace_save.confirmed.connect(GameSession.start_new_game)
	_continue_game.disabled = not GameSession.has_save()
	var initial_button := _new_game if _continue_game.disabled else _continue_game
	initial_button.grab_focus()


func _request_new_game() -> void:
	if SceneRouter.is_changing_scene():
		return
	if GameSession.has_save():
		_replace_save.popup_centered(Vector2i(324, 110))
	else:
		GameSession.start_new_game()


func _continue_from_save() -> void:
	var result := GameSession.load_game()
	if not result["ok"]:
		_continue_game.disabled = not GameSession.has_save()
		%LoadStatus.text = "当前无法读取存档，请重试。" if not _continue_game.disabled else "没有可用存档。"
