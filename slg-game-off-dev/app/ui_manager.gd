extends CanvasLayer

var _input_handlers: Dictionary[Control, Callable] = {}

@onready var _modal_layer: Control = $ModalLayer


func mount_modal(view: Control, handle_input: Callable) -> void:
	_input_handlers[view] = handle_input
	_modal_layer.add_child(view)


func unmount_modal(view: Control) -> void:
	_input_handlers.erase(view)
	_modal_layer.remove_child(view)


func has_modal(ignored_modal: Control = null) -> bool:
	var modal_count := _modal_layer.get_child_count()
	if ignored_modal != null and ignored_modal.get_parent() == _modal_layer:
		modal_count -= 1
	return modal_count > 0


func _input(event: InputEvent) -> void:
	if not has_modal():
		return

	var top_modal := _modal_layer.get_child(-1) as Control
	var handle_input := _input_handlers[top_modal]
	if handle_input.is_valid() and handle_input.call(event):
		get_viewport().set_input_as_handled()
