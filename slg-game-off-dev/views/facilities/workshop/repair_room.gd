extends "res://views/facilities/facility_room.gd"

@onready var _mechanic: SpriteHotspot = %Mechanic


func _ready() -> void:
	super._ready()
	_mechanic.activated.connect(_talk_to_mechanic)
	_update_regulator()


func _talk_to_mechanic() -> void:
	var already_repaired := GameSession.regulator_repaired()
	var opened := DialogueSystem.start(&"mechanic", facility_id, world, {
		"regulator_repaired": already_repaired,
	})
	if opened and not already_repaired and GameSession.submit_action(&"repair_regulator"):
		_update_regulator()


func _update_regulator() -> void:
	if GameSession.regulator_repaired():
		_mechanic.display_name = "机修师 · 稳流器已修复"
