extends SpriteHotspot

signal facility_selected(facility_id: StringName, display_name: String)

@export var facility_id: StringName
@export var inner_display_name: String
@export var inner_texture: Texture2D

@onready var _surface_texture: Texture2D = texture


func _ready() -> void:
	# This mask and outline use the surface silhouette in both worlds.
	super._ready()
	activated.connect(_select_facility)


func show_world(inner: bool) -> void:
	texture = inner_texture if inner and inner_texture else _surface_texture
	name_tag.text = inner_display_name if inner and not inner_display_name.is_empty() else display_name


func _select_facility() -> void:
	facility_selected.emit(facility_id, name_tag.text)
