@tool
class_name NpcActor
extends CharacterBody2D

## 四方向行走 NPC 运动模板。
## 沿一条由 Marker2D 航点组成的路线行走；运动方向只限上下左右，
## 并根据当前方向自动切换对应的行走 / 待机动画。
##
## 用法：
##   - 实例化本场景放到地图/设施场景里。
##   - 在场景里放一个 NpcRoute 节点（子节点用 Marker2D 表示航点）。
##   - W0（第一个航点）即 NPC 出生点：NPC 始终从 W0 出发，拖动 W0 会带着 NPC 一起动。
##   - 把本节点的 route 指向该 NpcRoute，或运行时调用 start_route() 切换路线。
##   - 速度在 NpcRoute 上设置（每条路线独立）；路线/航点/速度仅编辑器可见。
##   - finished 信号在走完停下时发出；waypoint_reached 在走到每个航点（从 W1 起）时发出。
##   - 替换 AnimatedSprite2D 的 SpriteFrames 为真实四方向行走图集，
##     动画名保持 walk_down / walk_left / walk_up / walk_right 和
##     idle_down / idle_left / idle_up / idle_right。

signal waypoint_reached(index: int)
signal finished

enum Dir { DOWN, LEFT, UP, RIGHT }

const WALK_ANIMS := {
	Dir.DOWN: &"walk_down",
	Dir.LEFT: &"walk_left",
	Dir.UP: &"walk_up",
	Dir.RIGHT: &"walk_right",
}
const IDLE_ANIMS := {
	Dir.DOWN: &"idle_down",
	Dir.LEFT: &"idle_left",
	Dir.UP: &"idle_up",
	Dir.RIGHT: &"idle_right",
}
const ARRIVE_EPSILON := 0.6
const DEFAULT_SPEED := 40.0
const ARRIVE_FACTOR := 0.06

## 初始路线（NpcRoute）路径；运行时可调用 start_route() 切换路线。
## 行走速度在 NpcRoute 上设置（每条路线独立）。
@export var route: NodePath
## 是否循环巡逻；关闭（默认）则走到终点后停下。
@export var loop: bool = false
## 每到达一个航点时停留的秒数。
@export var wait_time: float = 0.0
## 初始朝向，也是待机时保持的朝向。
@export var facing: Dir = Dir.DOWN:
	set(value):
		facing = value
		if _sprite != null:
			_update_animation()

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _active_route: Node
var _points: PackedVector2Array
var _speed := DEFAULT_SPEED
var _x_first := true
var _target_index := 0
var _direction := 1
var _moving := false
var _wait_timer := 0.0
var _finished := false
var _previous_anim: StringName = &""


func _ready() -> void:
	_collect_route()
	_spawn_at_start()
	_update_animation()


## 切换到指定路线并重新开始行走（可用于触发条件切换路线）。
func start_route(route_node: Node) -> bool:
	if route_node == null:
		return false
	_active_route = route_node
	_collect_route_from(route_node)
	_finished = false
	_direction = 1
	_wait_timer = 0.0
	_spawn_at_start()
	_set_moving(false)
	_update_animation()
	return true


func _process(_delta: float) -> void:
	# 编辑器里让 NPC 跟随 W0：拖动 W0 时 NPC 一起移动。
	if not Engine.is_editor_hint():
		return
	var route_node := _resolve_route()
	if route_node == null:
		return
	for child in route_node.get_children():
		if child is Marker2D:
			var spawn: Vector2 = child.global_position
			if global_position != spawn:
				global_position = spawn
			break


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _finished or _points.is_empty():
		return

	if _wait_timer > 0.0:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_advance_target()
		_set_moving(false)
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target := _points[_target_index]
	var axis := _movement_axis(target - global_position)
	if axis == Vector2.ZERO:
		_arrive_at_waypoint()
		return

	var dir := _direction_from_axis(axis)
	if dir != facing:
		facing = dir
	velocity = axis * _speed
	_set_moving(true)
	move_and_slide()


func _collect_route() -> void:
	_collect_route_from(_resolve_route())


func _resolve_route() -> Node:
	if _active_route != null:
		return _active_route
	if route.is_empty():
		return null
	var route_node := get_node_or_null(route)
	if route_node == null:
		push_warning("NpcActor '%s': route node not found at '%s'." % [name, route])
	return route_node


func _collect_route_from(route_node: Node) -> void:
	_points = PackedVector2Array()
	_speed = DEFAULT_SPEED
	_x_first = true
	if route_node == null:
		return

	var route_speed: Variant = route_node.get("speed")
	if route_speed is float or route_speed is int:
		_speed = float(route_speed)
	var x_first: Variant = route_node.get("move_x_first")
	_x_first = x_first if x_first is bool else true
	for child in route_node.get_children():
		if child is Marker2D:
			_points.append(child.global_position)


## 把 NPC 吸附到 W0（出生点）并从 W1 开始行走，避免先走到 W0 再折返。
func _spawn_at_start() -> void:
	if _points.is_empty():
		return
	global_position = _points[0]
	_target_index = 1 if _points.size() > 1 else 0


func _movement_axis(offset: Vector2) -> Vector2:
	# 每个时刻只朝一个轴向移动，绝不斜走。
	# 阈值随速度缩放，避免高速下每帧步长超过阈值导致来回震荡。
	var threshold := maxf(_speed * ARRIVE_FACTOR, ARRIVE_EPSILON)
	var horiz := Vector2.ZERO
	var vert := Vector2.ZERO
	if absf(offset.x) > threshold:
		horiz = Vector2(signf(offset.x), 0.0)
	if absf(offset.y) > threshold:
		vert = Vector2(0.0, signf(offset.y))

	if _x_first:
		return horiz if horiz != Vector2.ZERO else vert
	return vert if vert != Vector2.ZERO else horiz


func _direction_from_axis(axis: Vector2) -> Dir:
	if axis.x != 0.0:
		return Dir.LEFT if axis.x < 0.0 else Dir.RIGHT
	return Dir.UP if axis.y < 0.0 else Dir.DOWN


func _arrive_at_waypoint() -> void:
	global_position = _points[_target_index]
	_set_moving(false)
	velocity = Vector2.ZERO
	move_and_slide()

	waypoint_reached.emit(_target_index)

	if _target_index == _points.size() - 1 and not loop:
		_finished = true
		finished.emit()
		return

	if wait_time > 0.0:
		_wait_timer = wait_time
	else:
		_advance_target()


func _advance_target() -> void:
	if _points.size() <= 1:
		return
	var next := _target_index + _direction
	if next >= _points.size():
		_target_index = _points.size() - 2
		_direction = -1
	elif next < 0:
		_target_index = 1
		_direction = 1
	else:
		_target_index = next


func _set_moving(moving: bool) -> void:
	if _moving != moving:
		_moving = moving
		_update_animation()


func _update_animation() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return

	var anims: Dictionary = WALK_ANIMS if _moving else IDLE_ANIMS
	var anim: StringName = anims.get(facing, &"")
	var frames := _sprite.sprite_frames
	if not frames.has_animation(anim):
		var names := frames.get_animation_names()
		anim = StringName(names[0]) if not names.is_empty() else &""

	if anim.is_empty():
		_sprite.stop()
		_previous_anim = &""
		return

	# 只有动画改变时才重新播放，避免每帧重启。
	if anim != _previous_anim:
		_sprite.play(anim)
		_previous_anim = anim
