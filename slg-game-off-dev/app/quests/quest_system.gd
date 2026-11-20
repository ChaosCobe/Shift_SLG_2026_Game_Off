extends RefCounted

const QUEST_DIRECTORY := "res://data/quests"
const DIALOGUE_DIRECTORY := "res://data/dialogue"

var _definitions: Dictionary[StringName, Dictionary] = {}


func load_quest(quest_id: StringName) -> bool:
	if _definitions.has(quest_id):
		return true

	var file_name := String(quest_id)
	if not file_name.is_valid_filename():
		push_error("Invalid quest ID: %s" % quest_id)
		return false

	var path := QUEST_DIRECTORY.path_join(file_name + ".json")
	if not ResourceLoader.exists(path, "JSON"):
		push_error("Quest definition not found: %s" % path)
		return false

	var resource := ResourceLoader.load(path, "JSON") as JSON
	if resource == null or not resource.data is Dictionary:
		push_error("%s must contain a quest object." % path)
		return false
	var definition: Dictionary = resource.data
	var problem := _validation_error(definition, file_name)
	if not problem.is_empty():
		push_error("%s: %s" % [path, problem])
		return false

	_definitions[quest_id] = definition
	return true


func get_view(quest_id: StringName, state: Dictionary, locale: String) -> Dictionary:
	var definition: Dictionary = _definitions.get(quest_id, {})
	if definition.is_empty():
		return {}

	var progress := _progress(quest_id, state)
	var status: String = progress.get("phase", "offered")
	var route: Dictionary
	if status == "accepted":
		route = _matching_route(definition, state)
		status = "ready" if not route.is_empty() else "active"
	elif status == "succeeded":
		route = _find_route(quest_id, progress.get("settled_route", ""))

	var english := TranslationServer.standardize_locale(locale).get_slice("_", 0) == "en"
	return {
		"id": String(quest_id),
		"title": _localized(definition["title"], english),
		"objective": _localized(definition["objective"], english),
		"status": status,
		"route_label": _localized(route["label"], english) if not route.is_empty() else "",
	}


func evaluate_accept(quest_id: StringName, state: Dictionary, world: String, issuer: StringName) -> Dictionary:
	var reason := _context_error(quest_id, world, issuer)
	if not reason.is_empty():
		return {"ok": false, "reason": reason}

	var phase: String = _progress(quest_id, state).get("phase", "offered")
	if phase == "succeeded":
		return {"ok": false, "reason": &"already_settled"}
	if phase != "offered":
		return {"ok": false, "reason": &"already_accepted"}
	return {"ok": true}


func evaluate_turn_in(quest_id: StringName, state: Dictionary, world: String, issuer: StringName) -> Dictionary:
	var reason := _context_error(quest_id, world, issuer)
	if not reason.is_empty():
		return {"ok": false, "reason": reason}

	var phase: String = _progress(quest_id, state).get("phase", "offered")
	if phase == "succeeded":
		return {"ok": false, "reason": &"already_settled"}
	if phase != "accepted":
		return {"ok": false, "reason": &"not_accepted"}

	var route := _matching_route(_definitions[quest_id], state)
	if route.is_empty():
		return {"ok": false, "reason": &"not_ready"}
	return {
		"ok": true,
		"route_id": route["id"],
		"feedback_dialogue_id": route["feedback_dialogue_id"],
		"reward_tokens": int(route["reward_tokens"]),
	}


func has_route(quest_id: StringName, route_id: String) -> bool:
	return not _find_route(quest_id, route_id).is_empty()


static func fact_value(state: Dictionary, path: String) -> Variant:
	var value: Variant = state
	for segment in path.split("."):
		if not value is Dictionary or not value.has(segment):
			return null
		value = value[segment]
	return value


func _context_error(quest_id: StringName, world: String, issuer: StringName) -> StringName:
	if not _definitions.has(quest_id):
		return &"unknown_quest"
	var definition := _definitions[quest_id]
	if world != definition["world"]:
		return &"wrong_world"
	if String(issuer) != definition["issuer_npc_id"]:
		return &"wrong_issuer"
	return &""


func _find_route(quest_id: StringName, route_id: String) -> Dictionary:
	var definition: Dictionary = _definitions.get(quest_id, {})
	for route: Dictionary in definition.get("routes", []):
		if route["id"] == route_id:
			return route
	return {}


static func _progress(quest_id: StringName, state: Dictionary) -> Dictionary:
	return state.get("quests", {}).get(String(quest_id), {})


static func _matching_route(definition: Dictionary, state: Dictionary) -> Dictionary:
	for route: Dictionary in definition["routes"]:
		if _matches_all(route["all"], state):
			return route
	return {}


static func _matches_all(conditions: Dictionary, state: Dictionary) -> bool:
	for path: String in conditions:
		if fact_value(state, path) != conditions[path]:
			return false
	return true


static func _localized(text: Dictionary, english: bool) -> String:
	var translated: String = text.get("en", "")
	return translated if english and not translated.strip_edges().is_empty() else text["zh_CN"]


static func _has_localized_text(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var chinese: Variant = value.get("zh_CN")
	return chinese is String and not chinese.strip_edges().is_empty() and value.get("en", "") is String


static func _validation_error(definition: Dictionary, file_name: String) -> String:
	if definition.get("id") != file_name:
		return "id must match the file name."
	if definition.get("world") != "surface":
		return "world must be surface for formal commissions."
	var issuer: Variant = definition.get("issuer_npc_id")
	if not issuer is String or issuer.is_empty():
		return "issuer_npc_id must be a nonempty string."
	if not _has_localized_text(definition.get("title")) or not _has_localized_text(definition.get("objective")):
		return "title and objective require zh_CN text and optional en text."

	var routes: Variant = definition.get("routes")
	if not routes is Array or routes.is_empty():
		return "routes must be a nonempty array."

	var seen_ids: Dictionary[String, bool] = {}
	for index in routes.size():
		var route: Variant = routes[index]
		var problem := _route_error(route)
		if not problem.is_empty():
			return "routes[%d]: %s" % [index, problem]
		var route_id: String = route["id"]
		if seen_ids.has(route_id):
			return "Duplicate route ID: %s" % route_id
		seen_ids[route_id] = true
	return ""


static func _route_error(route: Variant) -> String:
	if not route is Dictionary:
		return "must be an object."
	var route_id: Variant = route.get("id")
	if not route_id is String or route_id.is_empty():
		return "id must be a nonempty string."
	if not _has_localized_text(route.get("label")):
		return "label requires zh_CN text and optional en text."
	var conditions: Variant = route.get("all")
	if not conditions is Dictionary or conditions.is_empty():
		return "all must contain at least one state condition."
	for path: String in conditions:
		if "" in path.split(".") or typeof(conditions[path]) not in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]:
			return "all conditions require dotted state paths and scalar values."
	var feedback: Variant = route.get("feedback_dialogue_id")
	if not feedback is String or not feedback.is_valid_filename() \
			or not ResourceLoader.exists(DIALOGUE_DIRECTORY.path_join(feedback + ".json"), "JSON"):
		return "feedback_dialogue_id must refer to an existing dialogue."
	var reward: Variant = route.get("reward_tokens")
	if typeof(reward) not in [TYPE_INT, TYPE_FLOAT] or reward < 0 or reward != int(reward):
		return "reward_tokens must be a nonnegative integer."
	return ""
