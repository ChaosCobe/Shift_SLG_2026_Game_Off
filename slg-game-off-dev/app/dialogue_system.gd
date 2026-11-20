extends Node

const DialogueSession := preload("res://app/dialogue/dialogue_session.gd")
const DialogueData := preload("res://app/dialogue/dialogue_data.gd")
const DialogueBox := preload("res://views/dialogue/dialogue_box.gd")
const BOX_SCENE := preload("res://views/dialogue/dialogue_box.tscn")

var _session: DialogueSession
var _box: DialogueBox
var _facility_id: StringName
var _world: int


func _ready() -> void:
	SceneRouter.world_changed.connect(_on_world_changed)


func start(dialogue_id: StringName, facility_id: StringName, world: int, facts: Dictionary = {}) -> bool:
	if UIManager.has_modal() or SceneRouter.is_changing_scene():
		return false

	var session := DialogueData.load_session(dialogue_id, world, facts, TranslationServer.get_locale())
	if session == null:
		return false

	_session = session
	_facility_id = facility_id
	_world = world
	_box = BOX_SCENE.instantiate() as DialogueBox
	_box.advance_requested.connect(_advance)
	_box.choice_selected.connect(_choose)
	_box.player_reply_finished.connect(_on_player_reply_finished)
	_box.shift_confirmed.connect(_shift_during_dialogue)
	UIManager.mount_modal(_box, _handle_modal_input)
	_box.set_speaker(_session.speaker_name)
	_box.set_portrait(_session.portrait_for(world))
	_show_line()
	return true


func is_open() -> bool:
	return _box != null


func close() -> void:
	if not is_open():
		return

	var box := _box
	_box = null
	_session = null
	UIManager.unmount_modal(box)
	box.queue_free()


func _show_line() -> void:
	_box.show_line(
		_session.current_text(),
		_session.is_player_line(),
		_session.option_labels(),
		_session.has_next_line(),
	)


func _advance() -> void:
	if _session.advance():
		_show_line()
	else:
		close()


func _choose(index: int) -> void:
	_session.choose(index)
	_show_line()


func _on_player_reply_finished() -> void:
	if _session.has_next_line() and not _session.has_choices():
		_advance()


func _handle_modal_input(event: InputEvent) -> bool:
	if not event.is_action(&"shift_world"):
		return false

	if event.is_action_pressed(&"shift_world") and not SceneRouter.is_changing_scene():
		_box.show_shift_prompt()
	return true


func _shift_during_dialogue() -> void:
	var box := _box
	await SceneRouter.shift_facility(_facility_id, _world)
	# A scene change can outlive the dialogue that requested it.
	if is_open() and _box == box:
		_on_world_changed(SceneRouter.current_world)
		_box.dismiss_shift_prompt()


func _on_world_changed(world: int) -> void:
	if is_open() and _world != world:
		_world = world
		_box.set_portrait(_session.portrait_for(world))
