extends "res://views/facilities/facility_room.gd"

const QUEST_PANEL := preload("res://views/quests/quest_panel.tscn")
const QuestPanel := preload("res://views/quests/quest_panel.gd")

@export var npc_id: StringName

@onready var _researcher: SpriteHotspot = %Researcher


func _ready() -> void:
	super._ready()
	_researcher.activated.connect(_talk_to_npc)
	if world == SceneRouter.World.SURFACE:
		%QuestButton.pressed.connect(_open_quest_panel)


func _talk_to_npc() -> void:
	DialogueSystem.start(npc_id, facility_id, world, {
		"regulator_repaired": GameSession.regulator_repaired(),
	})


func _open_quest_panel() -> void:
	if UIManager.has_modal() or SceneRouter.is_changing_scene():
		return
	var panel := QUEST_PANEL.instantiate() as QuestPanel
	panel.open(&"safe_flight", npc_id, facility_id, world)
