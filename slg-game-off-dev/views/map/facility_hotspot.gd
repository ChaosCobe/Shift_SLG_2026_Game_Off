extends TextureRect

signal facility_selected(facility_id: StringName, display_name: String)

@export var facility_id: StringName
@export var display_name: String
@export var inner_display_name: String
@export var inner_texture: Texture2D

@onready var outline: TextureRect = $Outline
@onready var name_tag: Label = $NameTag
@onready var _surface_texture: Texture2D = texture

var _hit_mask := BitMap.new()


func _ready() -> void:
	name_tag.text = display_name
	# This mask and outline use the surface silhouette in both worlds.
	var building_image := _surface_texture.get_image() if _surface_texture else null
	if building_image == null or building_image.is_empty():
		push_warning("Facility '%s' needs a readable building texture." % facility_id)
		return

	_hit_mask.create_from_image_alpha(building_image)
	outline.texture = _make_outline()
	_update_outline_size()

	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	resized.connect(_update_outline_size)
	visibility_changed.connect(_on_visibility_changed)


func show_world(inner: bool) -> void:
	texture = inner_texture if inner and inner_texture else _surface_texture
	name_tag.text = inner_display_name if inner and not inner_display_name.is_empty() else display_name


func _has_point(point: Vector2) -> bool:
	var mask_size := _hit_mask.get_size()
	if mask_size == Vector2i.ZERO or not Rect2(Vector2.ZERO, size).has_point(point):
		return false

	# Godot supplies a point in this texture's local, scaled display space.
	var pixel := Vector2i(point / size * Vector2(mask_size))
	return _hit_mask.get_bitv(pixel)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _has_point(event.position):
			accept_event()
			facility_selected.emit(facility_id, name_tag.text)


func _make_outline() -> ImageTexture:
	var mask_size := _hit_mask.get_size()
	var image := Image.create_empty(mask_size.x + 2, mask_size.y + 2, false, Image.FORMAT_RGBA8)
	# Give every visible pixel a one-texel border. The original art is drawn on top.
	for y in range(mask_size.y):
		for x in range(mask_size.x):
			if _hit_mask.get_bit(x, y):
				image.fill_rect(Rect2i(x, y, 3, 3), Color.WHITE)
	return ImageTexture.create_from_image(image)


func _update_outline_size() -> void:
	var texel := size / Vector2(_hit_mask.get_size())
	outline.position = -texel
	outline.size = size + texel * 2.0


func _set_hovered(hovered: bool) -> void:
	outline.visible = hovered
	name_tag.visible = hovered


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_set_hovered(false)
