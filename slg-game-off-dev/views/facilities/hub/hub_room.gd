extends "res://views/facilities/facility_room.gd"

const NPC_DIALOGUES := {
	&"researcher": preload("res://views/dialogue/researcher_dialogue.gd"),
}

@export var npc_id: StringName


func _ready() -> void:
	super._ready()
	%NpcButton.pressed.connect(_talk_to_npc)


func _talk_to_npc() -> void:
	var dialogue: GDScript = NPC_DIALOGUES[npc_id]
	var session = dialogue.create_session(world, FacilityState.regulator_repaired)
	UIManager.open_dialogue(session, facility_id, world)
