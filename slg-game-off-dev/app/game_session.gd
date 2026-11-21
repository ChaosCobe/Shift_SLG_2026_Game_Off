extends Node

signal state_changed

const QuestSystem := preload("res://app/quests/quest_system.gd")
const SaveIO := preload("res://app/save_io.gd")
const SAFE_FLIGHT := &"safe_flight"
const SAVE_VERSION := 1
const WORLD_IDS := {
	SceneRouter.World.SURFACE: "surface",
	SceneRouter.World.INNER: "inner",
}
const INITIAL_STATE := {
	"day_id": "day_01",
	"facilities": {"surface": {"workshop": {"regulator_repaired": false}}},
	"environment": {"surface": {"airport": {"weather": "windy"}}},
	"quests": {"safe_flight": {"phase": "offered"}},
	"inventory": {"flight_token": 0},
}

var _quest_system := QuestSystem.new()
var _state := INITIAL_STATE.duplicate(true)


func _ready() -> void:
	_quest_system.load_quest(SAFE_FLIGHT)


func regulator_repaired() -> bool:
	return _state["facilities"]["surface"]["workshop"]["regulator_repaired"]


func airport_weather() -> String:
	return _state["environment"]["surface"]["airport"]["weather"]


func flight_token_count() -> int:
	return _state["inventory"]["flight_token"]


func submit_action(action_id: StringName) -> bool:
	if SceneRouter.is_changing_scene():
		return false

	match action_id:
		&"repair_regulator":
			if not SceneRouter.is_in_facility(&"workshop", SceneRouter.World.SURFACE) or regulator_repaired():
				return false
			_state["facilities"]["surface"]["workshop"]["regulator_repaired"] = true
		&"clear_airport_weather", &"release_airport_weather":
			if UIManager.has_modal() or not SceneRouter.is_in_facility(&"workshop", SceneRouter.World.INNER):
				return false
			var weather := "clear" if action_id == &"clear_airport_weather" else "windy"
			if airport_weather() == weather:
				return false
			_state["environment"]["surface"]["airport"]["weather"] = weather
		_:
			return false

	state_changed.emit()
	return true


func quest_view(quest_id: StringName) -> Dictionary:
	return _quest_system.get_view(quest_id, _state, TranslationServer.get_locale())


func accept_quest(quest_id: StringName, issuer: StringName) -> Dictionary:
	if SceneRouter.is_changing_scene():
		return {"ok": false, "reason": &"busy"}

	var world: String = WORLD_IDS[SceneRouter.current_world]
	var result := _quest_system.evaluate_accept(quest_id, _state, world, issuer)
	if result["ok"]:
		_state["quests"][String(quest_id)] = {"phase": "accepted"}
		state_changed.emit()
	return result


func turn_in_quest(quest_id: StringName, issuer: StringName) -> Dictionary:
	if SceneRouter.is_changing_scene():
		return {"ok": false, "reason": &"busy"}

	var world: String = WORLD_IDS[SceneRouter.current_world]
	var result := _quest_system.evaluate_turn_in(quest_id, _state, world, issuer)
	if result["ok"]:
		_state["quests"][String(quest_id)] = {
			"phase": "succeeded",
			"settled_route": result["route_id"],
		}
		_state["inventory"]["flight_token"] += result["reward_tokens"]
		state_changed.emit()
	return result


func has_save() -> bool:
	return SaveIO.load_snapshot(_valid_snapshot)["ok"]


func start_new_game() -> void:
	if not SceneRouter.is_on_home() or SceneRouter.is_changing_scene() or UIManager.has_modal():
		return
	_state = INITIAL_STATE.duplicate(true)
	SceneRouter.return_to_map(SceneRouter.World.SURFACE)
	state_changed.emit()


func save_game(pause_menu: Control = null) -> Error:
	if not _can_access_save(pause_menu):
		return ERR_BUSY

	var snapshot := _state.duplicate(true)
	snapshot["schema_version"] = SAVE_VERSION
	snapshot["current_world"] = WORLD_IDS[SceneRouter.current_world]
	return SaveIO.save_snapshot(snapshot, _valid_snapshot)


func load_game(pause_menu: Control = null) -> Dictionary:
	var on_home := SceneRouter.is_on_home() and not SceneRouter.is_changing_scene() and not UIManager.has_modal()
	if not on_home and not _can_access_save(pause_menu):
		return {"ok": false, "reason": &"busy"}

	var result := SaveIO.load_snapshot(_valid_snapshot)
	if not result["ok"]:
		return result

	var snapshot: Dictionary = result["snapshot"]
	var world: int = WORLD_IDS.find_key(snapshot["current_world"])
	_state = snapshot.duplicate(true)
	_state.erase("schema_version")
	_state.erase("current_world")
	_state["inventory"]["flight_token"] = int(_state["inventory"]["flight_token"])
	SceneRouter.return_to_map(world)
	state_changed.emit()
	return {"ok": true, "used_backup": result["used_backup"]}


func _can_access_save(pause_menu: Control) -> bool:
	return SceneRouter.is_on_map() and not SceneRouter.is_changing_scene() and not UIManager.has_modal(pause_menu)


func _valid_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.get("schema_version") != SAVE_VERSION or snapshot.get("current_world") not in WORLD_IDS.values():
		return false
	var day: Variant = snapshot.get("day_id")
	if not day is String or day.is_empty():
		return false
	var repaired: Variant = QuestSystem.fact_value(snapshot, "facilities.surface.workshop.regulator_repaired")
	var weather: Variant = QuestSystem.fact_value(snapshot, "environment.surface.airport.weather")
	if not repaired is bool or weather not in ["windy", "clear"]:
		return false
	var tokens: Variant = QuestSystem.fact_value(snapshot, "inventory.flight_token")
	if not (tokens is int or tokens is float) or tokens < 0 or tokens > 2147483647 or tokens != floor(tokens):
		return false
	var quest: Variant = QuestSystem.fact_value(snapshot, "quests.safe_flight")
	if not quest is Dictionary or quest.get("phase") not in ["offered", "accepted", "succeeded"]:
		return false
	if quest["phase"] != "succeeded":
		return not quest.has("settled_route")
	var route: Variant = quest.get("settled_route")
	return route is String and _quest_system.has_route(SAFE_FLIGHT, route)
