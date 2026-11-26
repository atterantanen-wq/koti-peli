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
const BOUNCE_HEIGHT := 0.7
const BOUNCE_TIME := 0.6
## Hyppy esineen päälle tai alas (esim. sängylle).
const HOP_TIME := 0.45
const HOP_HEIGHT := 0.35
## Kuinka paljon kädet ja jalat heiluvat kävellessä (radiaaneina).
const LIMB_SWING := 0.55

var jump_count := 0
var hug_count := 0
var last_action := ""
var _path := PackedVector3Array()
var _next := 0
var _speed := WALK_SPEED
var _walk_time := 0.0
var _jump_tween: Tween
var _pose_tween: Tween
var _hold := 0.0  # hypyn aikana hahmo ei lähde kävelemään
var _arms_up := 0.0  # kädet ylhäällä (pomppu, iloinen venytys)

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
	_update_limbs(delta)
	if _hold > 0.0:
		_hold -= delta
		return
	if not is_walking():
		_walk_time = 0.0
		if _jump_tween == null or not _jump_tween.is_running():
			body.position = body.position.lerp(Vector3.ZERO, minf(1.0, delta * 10.0))
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
		body.position = Vector3(0, absf(sin(_walk_time * _speed * 4.0)) * 0.06, 0)
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
	_arms_up = JUMP_TIME
	if not is_inside_tree():
		return
	_jump_tween = create_tween()
	_jump_tween.tween_property(body, "position:y", JUMP_HEIGHT, JUMP_TIME * 0.45) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_jump_tween.tween_property(body, "position:y", 0.0, JUMP_TIME * 0.55) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Isompi pomppu (esim. sängyllä). Uusi pomppu alkaa heti, vaikka edellinen olisi kesken.
func bounce() -> void:
	jump_count += 1
	if not is_inside_tree():
		return
	if _jump_tween != null:
		_jump_tween.kill()
	var start := body.position.y
	_jump_tween = create_tween()
	_jump_tween.tween_property(body, "position:y", BOUNCE_HEIGHT, BOUNCE_TIME * 0.45) \
			.from(start).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_jump_tween.tween_property(body, "position:y", 0.0, BOUNCE_TIME * 0.55) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pose(Vector3(1.12, 0.85, 1.12), 0.0, BOUNCE_TIME)
	_arms_up = BOUNCE_TIME


## Hyppää kohtaan (esim. sängyn päälle tai sieltä alas). Hahmo on heti uudessa paikassa,
## ja vain sen kuva lentää kaarena perille. Hypyn aikana hahmo ei kävele.
func hop_to(point: Vector3) -> void:
	stop()
	var from := global_position
	face_towards(point)
	global_position = point
	_hold = HOP_TIME
	if not is_inside_tree():
		body.position = Vector3.ZERO
		return
	if _jump_tween != null:
		_jump_tween.kill()
	var offset := global_transform.basis.inverse() * (from - point)
	_jump_tween = create_tween()
	_jump_tween.tween_method(func(t: float) -> void:
		body.position = offset.lerp(Vector3.ZERO, t) + Vector3(0, sin(t * PI) * HOP_HEIGHT, 0),
		0.0, 1.0, HOP_TIME)


## Onko hahmo kesken hypyn esineen päälle tai alas.
func is_hopping() -> bool:
	return _hold > 0.0


## Halaus: hahmo kumartuu eteenpäin ja rutistuu.
func hug() -> void:
	hug_count += 1
	_pose(Vector3(1.15, 0.9, 0.9), 0.35, 0.8)


## Iloinen venytys.
func cheer() -> void:
	_pose(Vector3(0.9, 1.15, 0.9), 0.0, 0.5)
	_arms_up = 0.5


## Esineen pyytämä liike: "hug", "jump", "bounce" tai "cheer".
func do_action(action: String) -> void:
	last_action = action
	match action:
		"hug": hug()
		"jump": jump()
		"bounce": bounce()
		"cheer": cheer()


func _pose(squash: Vector3, lean: float, time: float) -> void:
	if not is_inside_tree():
		return
	if _pose_tween != null:
		_pose_tween.kill()
	body.scale = Vector3.ONE
	body.rotation.x = 0.0
	_pose_tween = create_tween()
	_pose_tween.tween_property(body, "scale", squash, time * 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pose_tween.parallel().tween_property(body, "rotation:x", lean, time * 0.3)
	_pose_tween.tween_interval(time * 0.2)
	_pose_tween.tween_property(body, "scale", Vector3.ONE, time * 0.5) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_pose_tween.parallel().tween_property(body, "rotation:x", 0.0, time * 0.5)


## Heiluttaa käsiä ja jalkoja kävellessä; pompatessa kädet nousevat ylös.
func _update_limbs(delta: float) -> void:
	var swing := 0.0
	if is_walking() and _hold <= 0.0:
		swing = sin(_walk_time * _speed * 4.0) * LIMB_SWING
	_arms_up = maxf(0.0, _arms_up - delta)
	var raise := 2.4 if _arms_up > 0.0 or is_hopping() else 0.0
	var k := minf(1.0, delta * 14.0)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var arm := body.get_node_or_null("ArmLeft" if i == 0 else "ArmRight") as Node3D
		if arm != null:
			arm.rotation.x = lerpf(arm.rotation.x, swing * side, k)
			arm.rotation.z = lerpf(arm.rotation.z, (0.18 + raise) * side, k)
		var leg := body.get_node_or_null("LegLeft" if i == 0 else "LegRight") as Node3D
		if leg != null:
			leg.rotation.x = lerpf(leg.rotation.x, -swing * side, k)


## Kuinka paljon hahmon kädet ovat nousseet (0 = alhaalla). Testejä varten.
func arm_raise() -> float:
	var arm := body.get_node_or_null("ArmRight") as Node3D
	return 0.0 if arm == null else arm.rotation.z - 0.18
