extends Node

signal world_changed(world: int)

enum World { SURFACE, INNER }

const MAP_SCENE := "res://app/main.tscn"
const WORLD_TRANSITION := preload("res://views/transitions/world_transition.tscn")
const FACILITY_SCENES := {
	&"hub": {
		World.SURFACE: "res://views/facilities/hub/surface_hub.tscn",
		World.INNER: "res://views/facilities/hub/inner_hub.tscn",
	},
	&"workshop": {
		World.SURFACE: "res://views/facilities/workshop/surface_workshop.tscn",
		World.INNER: "res://views/facilities/workshop/inner_workshop.tscn",
	},
	&"restaurant": {
		World.SURFACE: "res://views/facilities/restaurant/surface_restaurant.tscn",
		World.INNER: "res://views/facilities/restaurant/inner_restaurant.tscn",
	},
	&"shop": {
		World.SURFACE: "res://views/facilities/shop/surface_shop.tscn",
		World.INNER: "res://views/facilities/shop/inner_shop.tscn",
	},
}

var current_world: int = World.SURFACE
var _changing_scene := false

@onready var _transition := WORLD_TRANSITION.instantiate() as WorldTransition


func _ready() -> void:
	add_child(_transition)


func open_facility(facility_id: StringName) -> void:
	_open_facility_in_world(facility_id, current_world)


func shift_map_world() -> void:
	# An empty scene path updates the loaded map without reloading it.
	_change_scene("", _other_world(current_world), true)


func shift_facility(facility_id: StringName, source_world: int) -> void:
	_open_facility_in_world(facility_id, _other_world(source_world), true)


func return_to_map(world: int) -> void:
	_change_scene(MAP_SCENE, world)


func _other_world(world: int) -> int:
	return World.INNER if world == World.SURFACE else World.SURFACE


func _open_facility_in_world(facility_id: StringName, world: int, play_shift := false) -> void:
	var scenes: Dictionary = FACILITY_SCENES.get(facility_id, {})
	var scene_path: String = scenes.get(world, "")
	if not scene_path.is_empty():
		_change_scene(scene_path, world, play_shift)


func _change_scene(scene_path: String, world: int, play_shift := false) -> void:
	if _changing_scene:
		return

	_changing_scene = true
	if play_shift:
		await _transition.cover()

	var previous_world := current_world
	if scene_path.is_empty():
		current_world = world
	else:
		var tree := get_tree()
		var result := tree.change_scene_to_file(scene_path)
		if result == OK:
			current_world = world
			await tree.scene_changed
		else:
			push_error("Could not open scene '%s': %s" % [scene_path, error_string(result)])

	if previous_world != current_world:
		world_changed.emit(current_world)

	if play_shift:
		await _transition.reveal()
	_changing_scene = false
