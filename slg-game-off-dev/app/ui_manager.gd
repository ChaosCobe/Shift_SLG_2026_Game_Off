extends CanvasLayer

const DIALOGUE_BOX := preload("res://views/dialogue/dialogue_box.tscn")
const DialogueBox := preload("res://views/dialogue/dialogue_box.gd")
const DialogueSession := preload("res://views/dialogue/dialogue_session.gd")

var _dialogue: DialogueBox
var _dialogue_facility: StringName
var _dialogue_world: int


func _ready() -> void:
	layer = 20
	SceneRouter.world_changed.connect(_update_portrait)


func open_dialogue(session: DialogueSession, facility_id: StringName, world: int) -> void:
	if is_dialogue_open() or SceneRouter.is_changing_scene():
		return

	_dialogue_facility = facility_id
	_dialogue_world = world
	_dialogue = DIALOGUE_BOX.instantiate() as DialogueBox
	_dialogue.finished.connect(close_dialogue)
	_dialogue.shift_confirmed.connect(_shift_during_dialogue)
	add_child(_dialogue)
	_dialogue.start(session, world)


func close_dialogue() -> void:
	if is_dialogue_open():
		_dialogue.hide()
		_dialogue.queue_free()
		_dialogue = null


func is_dialogue_open() -> bool:
	return _dialogue != null


func _input(event: InputEvent) -> void:
	if not is_dialogue_open() or not event.is_action(&"shift_world"):
		return

	get_viewport().set_input_as_handled()
	if event.is_action_pressed(&"shift_world") and not SceneRouter.is_changing_scene():
		_dialogue.show_shift_prompt()


func _shift_during_dialogue() -> void:
	await SceneRouter.shift_facility(_dialogue_facility, _dialogue_world)
	if is_dialogue_open():
		_update_portrait(SceneRouter.current_world)
		_dialogue.dismiss_shift_prompt()


func _update_portrait(world: int) -> void:
	if is_dialogue_open() and world != _dialogue_world:
		_dialogue_world = world
		_dialogue.update_portrait(world)
