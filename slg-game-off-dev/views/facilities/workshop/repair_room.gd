extends "res://views/facilities/facility_room.gd"

@onready var _repair_button: Button = %RepairButton


func _ready() -> void:
	super._ready()
	_repair_button.pressed.connect(_repair_regulator)
	_update_regulator()


func _repair_regulator() -> void:
	if SceneRouter.is_changing_scene():
		return

	FacilityState.regulator_repaired = true
	_update_regulator()


func _update_regulator() -> void:
	if FacilityState.regulator_repaired:
		_repair_button.disabled = true
		_repair_button.text = "稳流器已修复"
