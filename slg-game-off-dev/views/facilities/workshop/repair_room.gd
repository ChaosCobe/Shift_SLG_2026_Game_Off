extends "res://views/facilities/facility_room.gd"

const MechanicDialogue := preload("res://views/dialogue/mechanic_dialogue.gd")

@onready var _mechanic: SpriteHotspot = %Mechanic


func _ready() -> void:
	super._ready()
	_mechanic.activated.connect(_talk_to_mechanic)
	_update_regulator()


func _talk_to_mechanic() -> void:
	if SceneRouter.is_changing_scene() or UIManager.is_dialogue_open():
		return

	var session := MechanicDialogue.create_session(FacilityState.regulator_repaired)
	if not FacilityState.regulator_repaired:
		FacilityState.regulator_repaired = true
		_update_regulator()
	UIManager.open_dialogue(session, facility_id, world)


func _update_regulator() -> void:
	if FacilityState.regulator_repaired:
		_mechanic.display_name = "机修师 · 稳流器已修复"
