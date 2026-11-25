class_name FollowCamera
extends Camera3D
## Kamera seuraa hahmoa pehmeästi hieman yläviistosta. Lapsen ei tarvitse kääntää sitä.
## Kamera ei käänny, joten seinät pysyvät aina hahmon takana eivätkä peitä sitä.

@export var target_path: NodePath
@export var offset := Vector3(0.0, 3.7, 4.0)
@export var look_height := 0.5
@export var follow_speed := 3.5
## Alue, jonka sisällä kameran katsepiste pysyy (huoneen lattia, x ja z).
@export var focus_bounds := Rect2(-1.5, -1.2, 3.0, 2.6)

var _target: Node3D
var _focus := Vector3.ZERO


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	snap()


func _process(delta: float) -> void:
	advance(delta)


func focus_point() -> Vector3:
	if _target == null:
		return Vector3(0, look_height, 0)
	var p := _target.global_position
	return Vector3(
			clampf(p.x, focus_bounds.position.x, focus_bounds.end.x),
			look_height,
			clampf(p.z, focus_bounds.position.y, focus_bounds.end.y))


## Hyppää suoraan oikeaan kohtaan (pelin alussa).
func snap() -> void:
	_focus = focus_point()
	_apply()


func advance(delta: float) -> void:
	_focus = _focus.lerp(focus_point(), 1.0 - exp(-follow_speed * delta))
	_apply()


func _apply() -> void:
	global_position = _focus + offset
	look_at(_focus, Vector3.UP)
