@tool
class_name NpcRoute
extends Node2D

## NPC 路线节点：子节点用 Marker2D 表示航点（坐标 = 地图像素）。
## 编辑器里会画出 NPC 实际会走的轴对齐折线，所见即所得；运行时隐藏。
##
## 用法：
##   - 在地图/设施场景里新建一个 NpcRoute 节点，作为其子节点放若干 Marker2D。
##   - 把 NpcActor 的 route 属性指向本节点，或调用 start_route() 切换。
##   - speed 决定走这条路线时的速度；move_x_first 决定先横还是先竖。

## 走这条路线时的移动速度（像素/秒）。
@export var speed: float = 40.0:
	set(value):
		speed = value
		queue_redraw()

## 两个航点横纵都不同时，先走横向（X）还是纵向（Y）。
@export var move_x_first: bool = true:
	set(value):
		move_x_first = value
		queue_redraw()

## 折线颜色。
@export var path_color: Color = Color(1.0, 0.82, 0.3, 0.9):
	set(value):
		path_color = value
		queue_redraw()

## 航点标记颜色。
@export var point_color: Color = Color(1.0, 0.45, 0.3, 1.0):
	set(value):
		point_color = value
		queue_redraw()


func _ready() -> void:
	_apply_editor_visibility()
	queue_redraw()


func _process(_delta: float) -> void:
	# 编辑器里拖动航点后需要重绘。
	if Engine.is_editor_hint():
		queue_redraw()


func _apply_editor_visibility() -> void:
	# 编辑器里显示航点标记；运行时隐藏路线节点、航点，避免被玩家看到。
	var in_editor := Engine.is_editor_hint()
	visible = in_editor
	for child in get_children():
		if child is Marker2D:
			child.visible = in_editor


func get_waypoints() -> PackedVector2Array:
	var points := PackedVector2Array()
	for child in get_children():
		if child is Marker2D:
			points.append(child.position)
	return points


func _draw() -> void:
	var points := get_waypoints()
	if points.is_empty():
		return

	for i in points.size():
		draw_circle(points[i], 2.5, point_color)

	for i in points.size() - 1:
		_draw_axis_aligned_segment(points[i], points[i + 1])

	_draw_speed_label(points[0])


func _draw_speed_label(anchor: Vector2) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	draw_string(font, anchor + Vector2(4.0, -10.0), "%.0f px/s" % speed, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, point_color)


func _draw_axis_aligned_segment(a: Vector2, b: Vector2) -> void:
	var corner := Vector2(b.x, a.y) if move_x_first else Vector2(a.x, b.y)
	draw_line(a, corner, path_color, 1.5)
	draw_line(corner, b, path_color, 1.5)
