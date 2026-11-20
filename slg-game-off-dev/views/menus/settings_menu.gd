extends Control

signal closed

const GameSettings := preload("res://app/game_settings.gd")

var _settings: GameSettings

@onready var _volume: HSlider = %MasterVolume
@onready var _volume_value: Label = %VolumeValue
@onready var _fullscreen: CheckButton = %Fullscreen
@onready var _back: Button = %Back


func setup(settings: GameSettings) -> void:
	_settings = settings
	_volume.set_value_no_signal(_settings.master_volume)
	_update_volume_label(_settings.master_volume)
	_fullscreen.set_pressed_no_signal(_settings.fullscreen)
	_volume.value_changed.connect(_apply_volume)
	_fullscreen.toggled.connect(_apply_fullscreen)
	_back.pressed.connect(closed.emit)
	_volume.grab_focus()


func _apply_volume(value: float) -> void:
	_settings.master_volume = value
	_update_volume_label(value)


func _update_volume_label(value: float) -> void:
	_volume_value.text = "%d%%" % roundi(value)


func _apply_fullscreen(enabled: bool) -> void:
	_settings.fullscreen = enabled
