@tool
class_name FacilityHUD
extends Control

signal back_requested

@export var facility_title := "设施":
	set(value):
		facility_title = value
		if is_node_ready():
			_title_label.text = facility_title

@export var title_color := Color.WHITE:
	set(value):
		title_color = value
		if is_node_ready():
			_apply_colors()

@export var detail_color := Color(0.76, 0.72, 0.66):
	set(value):
		detail_color = value
		if is_node_ready():
			_apply_colors()

@onready var _title_label: Label = $Title
@onready var _world_label: Label = $WorldLabel
@onready var _shift_hint: Label = $ShiftHint
@onready var _back_button: Button = $BackButton


func _ready() -> void:
	_title_label.text = facility_title
	_apply_colors()
	_back_button.pressed.connect(back_requested.emit)


func set_inner_world(is_inner_world: bool) -> void:
	_world_label.text = "里世界" if is_inner_world else "表世界"


func _apply_colors() -> void:
	_title_label.add_theme_color_override(&"font_color", title_color)
	_world_label.add_theme_color_override(&"font_color", detail_color)
	_shift_hint.add_theme_color_override(&"font_color", detail_color)
	_back_button.add_theme_color_override(&"font_color", title_color)
	_back_button.add_theme_color_override(&"font_hover_color", title_color.lightened(0.25))
	_back_button.add_theme_color_override(&"font_pressed_color", title_color)
