extends "res://views/facilities/facility_room.gd"

@export var npc_id: StringName

@onready var _researcher: SpriteHotspot = %Researcher


func _ready() -> void:
	super._ready()
	_researcher.activated.connect(_talk_to_npc)


func _talk_to_npc() -> void:
	DialogueSystem.start(npc_id, facility_id, world, {
		"regulator_repaired": FacilityState.regulator_repaired,
	})
