extends RefCounted

const SETTINGS_PATH := "user://settings.cfg"

var master_volume := 100.0:
	set(value):
		master_volume = clampf(value, 0.0, 100.0)
		AudioServer.set_bus_volume_linear(0, master_volume / 100.0)
var fullscreen := false:
	set(value):
		fullscreen = value
		if DisplayServer.get_name() != "headless":
			var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED
			DisplayServer.window_set_mode(mode)


func restore() -> void:
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		return

	var volume: Variant = file.get_value("audio", "master_volume", 100.0)
	if (volume is float or volume is int) and is_finite(float(volume)):
		master_volume = float(volume)

	var display_mode: Variant = file.get_value("display", "fullscreen", false)
	if display_mode is bool:
		fullscreen = display_mode


func save() -> void:
	var file := ConfigFile.new()
	file.set_value("audio", "master_volume", master_volume)
	file.set_value("display", "fullscreen", fullscreen)
	var result := file.save(SETTINGS_PATH)
	if result != OK:
		push_warning("Could not save the settings: %s" % error_string(result))
