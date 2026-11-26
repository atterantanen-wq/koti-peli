class_name FollowCamera
extends Camera3D
## Kamera seuraa hahmoa pehmeästi läheltä yläviistosta.
##
## - Pysty- ja vaakanäytöllä näkyy suunnilleen yhtä paljon huonetta: ruudun lyhyempi
##   sivu saa aina saman näkökulman, joten esineet eivät kutistu vaakanäytöllä.
## - Kahdella sormella voi lähentää ja loitontaa (zoom) sekä kääntää huonetta (yaw).
##   Kääntö on rajattu niin, ettei kamera mene seinien taakse.
## - Lähikuva: tempun ajaksi kamera liukuu lähemmäs tempun kohtaan ja palaa sitten.

@export var target_path: NodePath
@export var look_height := 0.45
@export var follow_speed := 3.5
## Kameran etäisyys katsepisteestä, kun zoom on 1.
@export var distance := 3.3
## Kuinka jyrkästi kamera katsoo alas (asteina).
@export var pitch_degrees := 44.0
## Pystynäytöllä kamera katsoo jyrkemmin alas, jotta korkeaan ruutuun mahtuu lattiaa.
@export var portrait_pitch_degrees := 46.0
## Näkökulma ruudun lyhyemmän sivun suunnassa (asteina).
@export var short_side_fov := 52.0
@export var min_zoom := 0.55
@export var max_zoom := 1.7
@export var min_yaw_degrees := -20.0
@export var max_yaw_degrees := 65.0
## Alue, jonka sisällä kameran katsepiste pysyy (huoneen lattia, x ja z).
@export var focus_bounds := Rect2(-2.5, -2.0, 5.0, 4.3)
## Kamera ei mene seinien taakse: pienin sallittu x (vasen seinä) ja z (takaseinä).
@export var wall_limit := Vector2(-2.75, -2.25)
## Lattian etureuna (z). Ruudun alareunaan ei jätetä tyhjää lattian eteen:
## kamera siirtyy tarvittaessa taaemmas huoneeseen (lähinnä pystynäytöllä).
@export var floor_front_z := 2.5
## Lähikuvan zoom (pienempi = lähempänä).
@export var closeup_zoom := 0.72
## Lähikuvan zoom, kun esine lentää tai ajaa ympäri huonetta.
@export var moving_closeup_zoom := 0.9
## Lähikuva kestää korkeintaan näin kauan, vaikka temppu jatkuisi.
@export var closeup_max_time := 7.0

## Lapsen tai aikuisen sormilla valitsemat arvot.
var zoom := 1.0
var yaw := 0.0  # radiaaneina, 0 = kamera huoneen edessä

var _target: Node3D
var _focus := Vector3.ZERO
var _view_zoom := 1.0
var _view_yaw := 0.0
var _close_point := Callable()
var _close_zoom := 1.0
var _close_min_zoom := 0.0
var _close_yaw := NAN
var _close_left := 0.0
var _close_elapsed := 0.0


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	snap()


func _process(delta: float) -> void:
	advance(delta)


func focus_point() -> Vector3:
	if is_closeup():
		var p: Vector3 = _close_point.call()
		return _clamp_focus(p, p.y)
	if _target == null:
		return Vector3(0, look_height, 0)
	return _clamp_focus(_target.global_position, look_height)


func _clamp_focus(p: Vector3, height: float) -> Vector3:
	return Vector3(
			clampf(p.x, focus_bounds.position.x, focus_bounds.end.x),
			height,
			clampf(p.z, focus_bounds.position.y, focus_bounds.end.y))


## Hyppää suoraan oikeaan kohtaan (pelin alussa).
func snap() -> void:
	_focus = focus_point()
	_view_zoom = _wanted_zoom()
	_view_yaw = _wanted_yaw()
	_apply()


func advance(delta: float) -> void:
	if is_closeup():
		_close_left -= delta
		_close_elapsed += delta
		if _close_left <= 0.0 or _close_elapsed >= closeup_max_time:
			end_closeup()
	var k := 1.0 - exp(-follow_speed * delta)
	_focus = _focus.lerp(focus_point(), k)
	var k2 := 1.0 - exp(-follow_speed * 1.6 * delta)
	_view_zoom = lerpf(_view_zoom, _wanted_zoom(), k2)
	_view_yaw = lerp_angle(_view_yaw, _wanted_yaw(), k2)
	_apply()


## Asettaa zoomin (rajojen sisään). Isompi luku = kauempana.
func set_zoom(value: float) -> void:
	zoom = clampf(value, min_zoom, max_zoom)


## Asettaa käännön radiaaneina (rajojen sisään).
func set_yaw(value: float) -> void:
	yaw = clamp_yaw(value)


func clamp_yaw(value: float) -> float:
	return clampf(value, deg_to_rad(min_yaw_degrees), deg_to_rad(max_yaw_degrees))


## Sormieleen aikana kamera seuraa sormia heti (ei viivettä).
func follow_fingers() -> void:
	_view_zoom = _wanted_zoom()
	_view_yaw = _wanted_yaw()
	_apply()


## Lähikuva: point_fn palauttaa joka hetki kohdan, jota katsotaan (Vector3).
## Lähikuva kestää vähintään time sekuntia; extend_closeup() jatkaa sitä.
## look_yaw: kääntö lähikuvan ajaksi (NAN = ei käännetä).
## fit_zoom: lähikuva on vähintään näin kaukana (esim. jotta koko lentoreitti näkyy).
func closeup(point_fn: Callable, time: float, moving := false, look_yaw := NAN,
		fit_zoom := 0.0) -> void:
	_close_point = point_fn
	_close_left = time
	_close_elapsed = 0.0
	_close_zoom = moving_closeup_zoom if moving else closeup_zoom
	_close_min_zoom = fit_zoom
	_close_yaw = look_yaw if is_nan(look_yaw) else clamp_yaw(look_yaw)


func extend_closeup(time: float) -> void:
	if is_closeup():
		_close_left = maxf(_close_left, time)


func end_closeup() -> void:
	_close_point = Callable()
	_close_left = 0.0


func is_closeup() -> bool:
	return _close_point.is_valid() and _close_left > 0.0


## Kameran todellinen etäisyys katsepisteestä tällä hetkellä.
func current_distance() -> float:
	return distance * _view_zoom


func current_yaw() -> float:
	return _view_yaw


## Vaakasuunta katsepisteestä kameraa kohti (x, z).
func toward_camera() -> Vector2:
	return Vector2(sin(_view_yaw), cos(_view_yaw))


func _wanted_zoom() -> float:
	if not is_closeup():
		return zoom
	return clampf(maxf(zoom * _close_zoom, _close_min_zoom), min_zoom, max_zoom)


## Zoom, jolla noin size metrin kokoinen alue mahtuu ruudulle.
func zoom_to_fit(size: float) -> float:
	var visible_per_metre := 2.0 * tan(deg_to_rad(short_side_fov) * 0.5)
	return clampf(size * 1.1 / (visible_per_metre * distance), min_zoom, max_zoom)


func _wanted_yaw() -> float:
	if is_closeup() and not is_nan(_close_yaw):
		return _close_yaw
	return yaw


func _apply() -> void:
	var portrait := _fit_screen()
	var pitch := deg_to_rad(portrait_pitch_degrees if portrait else pitch_degrees)
	var d := current_distance()
	var flat := d * cos(pitch)
	var pos := _focus + Vector3(sin(_view_yaw) * flat, d * sin(pitch), cos(_view_yaw) * flat)
	pos.x = maxf(pos.x, wall_limit.x)
	pos.z = maxf(pos.z, wall_limit.y)
	global_position = pos
	look_at(_focus, Vector3.UP)
	_keep_floor_at_bottom()


## Jos ruudun alareunassa näkyisi tyhjää lattian edessä, siirretään kameraa huoneeseen päin.
func _keep_floor_at_bottom() -> void:
	if not is_inside_tree():
		return
	var size := get_viewport().get_visible_rect().size
	var dir := project_ray_normal(Vector2(size.x * 0.5, size.y))
	if dir.y > -0.05:
		return
	var hit := global_position + dir * (-global_position.y / dir.y)
	if hit.z > floor_front_z:
		global_position.z -= hit.z - floor_front_z


## Ruudun lyhyempi sivu saa aina saman näkökulman (pysty- ja vaakanäyttö).
## Palauttaa true, jos ruutu on pystyasennossa.
func _fit_screen() -> bool:
	fov = short_side_fov
	if not is_inside_tree():
		return false
	var size := get_viewport().get_visible_rect().size
	var portrait := size.x < size.y
	keep_aspect = Camera3D.KEEP_WIDTH if portrait else Camera3D.KEEP_HEIGHT
	return portrait
