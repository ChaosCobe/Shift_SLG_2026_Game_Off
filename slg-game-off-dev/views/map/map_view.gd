extends Control

@export var inner_background: Texture2D

@onready var _background: TextureRect = $Background
@onready var _surface_background: Texture2D = _background.texture
@onready var _weather_status: Label = %WeatherStatus
@onready var _save_status: Label = %SaveStatus


func _ready() -> void:
	SceneRouter.world_changed.connect(_apply_world)
	GameSession.state_changed.connect(_refresh_weather_status)
	%SaveButton.pressed.connect(_save_game)
	%LoadButton.pressed.connect(_load_game)
	_apply_world(SceneRouter.current_world)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"shift_world"):
		get_viewport().set_input_as_handled()
		SceneRouter.shift_map_world()


func _apply_world(world: int) -> void:
	var inner := world == SceneRouter.World.INNER
	_background.texture = inner_background if inner else _surface_background
	$MapTitle.text = "里世界 · 空港聚落" if inner else "表世界 · 空港聚落"
	_weather_status.visible = not inner
	_refresh_weather_status()
	for hotspot in $Facilities.get_children():
		hotspot.show_world(inner)


func _on_facility_selected(facility_id: StringName, _display_name: String) -> void:
	SceneRouter.open_facility(facility_id)


func _refresh_weather_status() -> void:
	_weather_status.text = "空港天气 · 晴朗" if GameSession.airport_weather() == "clear" else "空港天气 · 强风"


func _save_game() -> void:
	var result := GameSession.save_game()
	_save_status.text = "已保存进度" if result == OK else "当前无法保存进度"


func _load_game() -> void:
	var result := GameSession.load_game()
	if result["ok"]:
		_save_status.text = "已读取备份存档" if result["used_backup"] else "已读取进度"
		return

	match result["reason"]:
		&"missing_save":
			_save_status.text = "还没有存档"
		&"invalid_save":
			_save_status.text = "存档损坏或版本不兼容"
		_:
			_save_status.text = "当前无法读取进度"
