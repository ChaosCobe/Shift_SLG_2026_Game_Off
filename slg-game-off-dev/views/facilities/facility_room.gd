extends Node2D

@export var facility_id: StringName
@export_enum("Surface", "Inner") var world: int = 0

@onready var _hud: FacilityHUD = $Interface/FacilityHUD


func _ready() -> void:
	_hud.set_inner_world(world == SceneRouter.World.INNER)
	_hud.back_requested.connect(_return_to_map)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"shift_world"):
		get_viewport().set_input_as_handled()
		SceneRouter.shift_facility(facility_id, world)


func _return_to_map() -> void:
	if not UIManager.is_dialogue_open():
		SceneRouter.return_to_map(world)
