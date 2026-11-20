extends "res://views/facilities/facility_room.gd"

@onready var _weather: Label = %AirportWeather
@onready var _ritual_action: Button = %WeatherRitualAction


func _ready() -> void:
	super._ready()
	_ritual_action.pressed.connect(_toggle_ritual)
	GameSession.state_changed.connect(_refresh_weather)
	_refresh_weather()


func _toggle_ritual() -> void:
	if UIManager.has_modal() or SceneRouter.is_changing_scene():
		return
	var action := &"release_airport_weather" if _is_clear() else &"clear_airport_weather"
	GameSession.submit_action(action)


func _refresh_weather() -> void:
	var clear := _is_clear()
	_weather.text = "表世界空港 · 晴朗" if clear else "表世界空港 · 强风"
	_ritual_action.text = "解除术式" if clear else "施术放晴"


func _is_clear() -> bool:
	return GameSession.airport_weather() == "clear"
