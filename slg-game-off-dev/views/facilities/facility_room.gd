extends Node2D

@export var facility_id: StringName
@export_enum("Surface", "Inner") var world: int = 0


func _ready() -> void:
	%BackButton.pressed.connect(_return_to_map)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"shift_world"):
		get_viewport().set_input_as_handled()
		SceneRouter.shift_facility(facility_id, world)


func _return_to_map() -> void:
	SceneRouter.return_to_map(world)
