class_name Player
extends Node3D
## Pelihahmo: kävelee annettua reittiä pitkin, kääntyy kulkusuuntaan ja osaa hypätä.
## Pitkät matkat juostaan, jotta lapsen ei tarvitse odottaa.

signal arrived

const WALK_SPEED := 2.0   # metriä sekunnissa
const RUN_SPEED := 3.4
const RUN_DISTANCE := 2.5 # tätä pidempi matka juostaan
const TURN_SPEED := 12.0
const JUMP_HEIGHT := 0.45
const JUMP_TIME := 0.4

var jump_count := 0
var _path := PackedVector3Array()
var _next := 0
var _speed := WALK_SPEED
var _walk_time := 0.0
var _jump_tween: Tween

@onready var body: Node3D = $Body


## Lähtee kävelemään reittiä pitkin. Reitin ensimmäinen piste on nykyinen sijainti.
func walk_path(path: PackedVector3Array) -> void:
	_path = path
	_next = 1
	if _path.size() < 2:
		stop()
		return
	_speed = RUN_SPEED if path_length(path) > RUN_DISTANCE else WALK_SPEED


func stop() -> void:
	_path = PackedVector3Array()
	_next = 0


func is_walking() -> bool:
	return _next > 0 and _next < _path.size()


func target() -> Vector3:
	return _path[_path.size() - 1] if is_walking() else global_position


func speed() -> float:
	return _speed


static func path_length(path: PackedVector3Array) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i - 1].distance_to(path[i])
	return total


func _process(delta: float) -> void:
	advance(delta)


## Siirtää hahmoa yhden ruudunpäivityksen verran (testit kutsuvat tätä suoraan).
func advance(delta: float) -> void:
	if not is_walking():
		_walk_time = 0.0
		if _jump_tween == null or not _jump_tween.is_running():
			body.position.y = lerpf(body.position.y, 0.0, minf(1.0, delta * 10.0))
		return
	var step := _speed * delta
	var moved_dir := Vector3.ZERO
	while step > 0.0 and is_walking():
		var to := _path[_next] - global_position
		to.y = 0.0
		var dist := to.length()
		if dist <= step:
			global_position = Vector3(_path[_next].x, global_position.y, _path[_next].z)
			step -= dist
			_next += 1
		else:
			global_position += to / dist * step
			step = 0.0
		if dist > 0.001:
			moved_dir = to / dist
	if moved_dir != Vector3.ZERO:
		face_towards(global_position + moved_dir, delta)
	# Pieni pomppiva askellus.
	_walk_time += delta
	if _jump_tween == null or not _jump_tween.is_running():
		body.position.y = absf(sin(_walk_time * _speed * 4.0)) * 0.06
	if not is_walking():
		stop()
		arrived.emit()


## Kääntää hahmon katsomaan kohti annettua pistettä (delta < 0: heti).
func face_towards(point: Vector3, delta: float = -1.0) -> void:
	var dir := point - global_position
	dir.y = 0.0
	if dir.length() < 0.001:
		return
	var goal := atan2(dir.x, dir.z)
	if delta < 0.0:
		rotation.y = goal
	else:
		rotation.y = lerp_angle(rotation.y, goal, minf(1.0, delta * TURN_SPEED))


## Kulkusuunta (hahmon nenän suunta).
func facing() -> Vector3:
	return global_transform.basis.z.normalized()


## Iloinen hyppy paikallaan.
func jump() -> void:
	if _jump_tween != null and _jump_tween.is_running():
		return
	jump_count += 1
	if not is_inside_tree():
		return
	_jump_tween = create_tween()
	_jump_tween.tween_property(body, "position:y", JUMP_HEIGHT, JUMP_TIME * 0.45) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_jump_tween.tween_property(body, "position:y", 0.0, JUMP_TIME * 0.55) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
