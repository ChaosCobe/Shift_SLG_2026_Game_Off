extends Control

@export var inner_background: Texture2D

@onready var _background: TextureRect = $Background
@onready var _surface_background: Texture2D = _background.texture
@onready var _weather_status: Label = %WeatherStatus


func _ready() -> void:
	SceneRouter.world_changed.connect(_apply_world)
	GameSession.state_changed.connect(_refresh_weather_status)
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
