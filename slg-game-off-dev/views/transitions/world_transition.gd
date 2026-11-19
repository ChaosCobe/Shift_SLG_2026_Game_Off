class_name WorldTransition
extends CanvasLayer

const COVER_TIME := 0.68
const HOLD_TIME := 0.08
const REVEAL_TIME := 0.61

@onready var _overlay: Control = $Overlay
@onready var _curtain: ShaderMaterial = $Overlay/Curtain.material


func cover() -> void:
	_set_progress(0.0)
	_overlay.show()

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_progress, 0.0, 1.0, COVER_TIME)
	await tween.finished


func reveal() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(HOLD_TIME)
	tween.tween_method(_set_progress, 1.0, 0.0, REVEAL_TIME)
	await tween.finished
	_overlay.hide()


func _set_progress(progress: float) -> void:
	_curtain.set_shader_parameter("progress", progress)
