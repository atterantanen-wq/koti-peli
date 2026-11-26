class_name Pet
extends Node3D
## Lemmikki (kissanpentu tai koiranpentu), joka asuu lastenhuoneessa.
##
## - Seuraa hahmoa ja istahtaa sen viereen.
## - Napautus: hahmo silittää. Kissa kehrää (värisee) ja kieriskelee, koira heiluttaa
##   häntää ja hyppii. Sydämiä nousee ilmaan.
## - Kun hahmo seisoo hetken paikallaan, lemmikki keksii omaa tekemistä: pomppii
##   sängyllä, kurkkii lelulaatikkoon, nukahtaa matolle, haukottelee tai jahtaa häntäänsä.
## - Kun juna lähtee liikkeelle, lemmikki jahtaa sitä.
## - Yöllä lemmikki käpertyy sängyn jalkopäähän nukkumaan.
## Kaikki liike lasketaan advance()-funktiossa, jotta testit voivat ajaa sitä suoraan.

signal activity_changed(activity: String)

const WALK_SPEED := 1.9
const RUN_SPEED := 3.6
const RUN_DISTANCE := 1.8
const TURN_SPEED := 10.0
## Kuinka kaukana hahmosta lemmikki istuu.
const FOLLOW_GAP := 0.6
const SIT_RADIUS := 1.2
const REPATH_TIME := 0.25
const HOP_TIME := 0.42
## Istuma-asento: lantio laskeutuu ja selkä kallistuu.
const SIT_PITCH := 0.4
const SIT_DROP := 0.05
## Silityksen kesto.
const PET_TIME := 2.4
## Omat touhut alkavat, kun hahmo on seissyt paikallaan näin kauan (sekunteina).
const IDLE_MIN := 4.0
const IDLE_MAX := 7.0
const ACTIVITIES := ["play_bed", "play_box", "nap", "yawn", "tail"]
## Sängyn pinnan korkeus ja jalkopään paikka (sängyn omissa koordinaateissa).
const BED_TOP := 0.52
const BED_FOOT := Vector3(0.12, BED_TOP, 0.72)
const BED_PLAY := Vector3(0.0, BED_TOP, 0.15)

## "cat" tai "dog".
var kind := "cat"
## Mitä lemmikki tekee nyt: follow, wait, petted, chase_train, play_bed, play_box,
## nap, yawn, tail tai night.
var activity := "follow"
var pet_count := 0
var on_bed := false
var player: Player
var grid: WalkGrid
var effects: Node3D
var bed: Node3D
var toy_box: Node3D
var train: Node3D
var rug: Node3D
var day_night: DayNight
var rng := RandomNumberGenerator.new()
var art: Node3D

var _path := PackedVector3Array()
var _next := 0
var _speed := WALK_SPEED
var _repath := 0.0
var _goal := Vector3.INF
var _timer := 0.0
var _step := 0
var _count := 0
var _idle := 0.0
var _idle_wait := 5.0
var _last_activity := ""
var _fx := 0.0
var _hop_from := Vector3.ZERO
var _hop_to := Vector3.ZERO
var _hop_left := 0.0
var _hop_height := 0.0
var _walk_after_hop := false
var _anim := 0.0
var _lid_rest := NAN
# Asennot (0..1), joita kohti kuva liukuu pehmeästi.
var _sit := 0.0
var _curl := 0.0
var _rear := 0.0
var _roll := 0.0
var _yawn := 0.0
var _goal_sit := 0.0
var _goal_curl := 0.0
var _goal_rear := 0.0
var _goal_roll := 0.0
var _goal_yawn := 0.0


## Liittää lemmikin huoneeseen. room: lastenhuoneen solmu (sänky, lelulaatikko, juna, matto).
func setup(p_kind: String, p_player: Player, p_grid: WalkGrid, p_effects: Node3D, room: Node,
		p_day_night: DayNight) -> void:
	kind = p_kind
	player = p_player
	grid = p_grid
	effects = p_effects
	day_night = p_day_night
	if room != null:
		bed = room.get_node_or_null("Bed") as Node3D
		toy_box = room.get_node_or_null("ToyBox") as Node3D
		train = room.get_node_or_null("Train") as Node3D
		rug = room.get_node_or_null("Rugs/PinkRug") as Node3D
	var train_inter := Interactable.of(train)
	if train_inter != null:
		train_inter.used.connect(func(_v: int) -> void: chase_train())
	if art != null:
		art.free()
	art = PetArt.build(kind)
	add_child(art)
	if get_node_or_null("Shadow") == null:
		add_child(PetArt.shadow())
	_idle_wait = rng.randf_range(IDLE_MIN, IDLE_MAX)


func _process(delta: float) -> void:
	if player != null:
		advance(delta)


## Kohta, jota kohti napautus mitataan (lemmikin keskikohta).
func focus_position() -> Vector3:
	return global_position + Vector3(0, 0.25, 0)


func is_moving() -> bool:
	return _hop_left > 0.0 or (_next > 0 and _next < _path.size())


func is_hopping() -> bool:
	return _hop_left > 0.0


## Siirtää lemmikkiä yhden ruudunpäivityksen verran.
func advance(delta: float) -> void:
	_anim += delta
	_check_night()
	match activity:
		"follow": _do_follow(delta)
		"wait": _do_wait(delta)
		"petted": _do_petted(delta)
		"chase_train": _do_chase(delta)
		"play_bed": _do_play_bed(delta)
		"play_box": _do_play_box(delta)
		"nap": _do_nap(delta)
		"yawn": _do_yawn(delta)
		"tail": _do_tail(delta)
		"night": _do_night(delta)
	_move(delta)
	_update_pose(delta)


# --- Liikkuminen -------------------------------------------------------------

## Kävelee (tai juoksee) kohtaan. Sängyltä hypätään ensin alas.
func walk_to(point: Vector3) -> void:
	_goal = Vector3(point.x, 0.0, point.z)
	if on_bed:
		if _hop_left <= 0.0:
			hop_to(_floor_below())
		_walk_after_hop = true
		return
	_path = grid.find_path(global_position, _goal)
	_next = 1
	if _path.size() < 2:
		stop_walking()
		return
	_speed = RUN_SPEED if Player.path_length(_path) > RUN_DISTANCE else WALK_SPEED


func stop_walking() -> void:
	_path = PackedVector3Array()
	_next = 0


## Hyppää kaarena kohtaan (esim. sängylle, sieltä alas tai paikallaan ylös).
func hop_to(point: Vector3, height := 0.3) -> void:
	stop_walking()
	_walk_after_hop = false
	_hop_from = global_position
	_hop_to = point
	_hop_left = HOP_TIME
	_hop_height = height
	if Vector2(point.x - global_position.x, point.z - global_position.z).length() > 0.05:
		face_towards(point)


func face_towards(point: Vector3, delta := -1.0) -> void:
	var dir := point - global_position
	dir.y = 0.0
	if dir.length() < 0.001:
		return
	var goal := atan2(dir.x, dir.z)
	rotation.y = goal if delta < 0.0 else lerp_angle(rotation.y, goal, minf(1.0, delta * TURN_SPEED))


func _move(delta: float) -> void:
	if _hop_left > 0.0:
		_hop_left = maxf(0.0, _hop_left - delta)
		var t := 1.0 - _hop_left / HOP_TIME
		global_position = _hop_from.lerp(_hop_to, t) + Vector3(0, sin(t * PI) * _hop_height, 0)
		if _hop_left <= 0.0:
			global_position = _hop_to
			on_bed = _hop_to.y > 0.2
			if _walk_after_hop and not on_bed:
				_walk_after_hop = false
				walk_to(_goal)
		return
	if not (_next > 0 and _next < _path.size()):
		return
	var step := _speed * delta
	var moved := Vector3.ZERO
	while step > 0.0 and _next < _path.size():
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
			moved = to / dist
	if moved != Vector3.ZERO:
		face_towards(global_position + moved, delta)
	if _next >= _path.size():
		stop_walking()


func _floor_below() -> Vector3:
	if bed != null:
		return grid.nearest_walkable_to_rect(_rect_of(bed), _goal if _goal != Vector3.INF else global_position)
	return grid.nearest_walkable(Vector3(global_position.x, 0, global_position.z))


func _rect_of(node: Node3D) -> Rect2:
	var rects := WalkGrid.obstacle_rects(node)
	if rects.is_empty():
		return Rect2(Vector2(node.global_position.x, node.global_position.z), Vector2.ZERO)
	var r: Rect2 = rects[0]
	for other in rects:
		r = r.merge(other)
	return r


## Lattialla oleva kohta esineen vieressä, lähimpänä lemmikkiä.
func _beside(node: Node3D) -> Vector3:
	return grid.nearest_walkable_to_rect(_rect_of(node), global_position)


# --- Touhut ------------------------------------------------------------------

func start(next: String) -> void:
	_end_activity()
	activity = next
	_step = 0
	_timer = 0.0
	_count = 0
	_fx = 0.0
	_goal_sit = 0.0
	_goal_curl = 0.0
	_goal_rear = 0.0
	_goal_roll = 0.0
	_goal_yawn = 0.0
	if next in ACTIVITIES:
		_last_activity = next
	activity_changed.emit(next)
	print("lemmikki %s" % next)


func _end_activity() -> void:
	if activity == "play_box":
		_set_lid(0.0)


## Hahmo on tulossa silittämään: lemmikki jää odottamaan paikalleen.
func wait_for_player() -> void:
	if activity == "night":
		return
	start("wait")
	stop_walking()


## Hahmo silittää lemmikkiä.
func pet_me() -> void:
	pet_count += 1
	if activity == "night":
		# Unenpöpperöinen silitys: sydän nousee, mutta lemmikki jatkaa unia.
		_hearts(1)
		_timer = 0.0
		return
	start("petted")
	stop_walking()
	if player != null:
		face_towards(player.global_position)
	_hearts(2)


## Juna lähti liikkeelle: lemmikki lähtee perään.
func chase_train() -> void:
	if activity in ["night", "petted", "wait"]:
		return
	start("chase_train")


func _player_busy() -> bool:
	return player.is_walking() or player.is_hopping()


func _flat_distance_to(p: Vector3) -> float:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()


## Jos hahmo lähtee kauas, lemmikki jättää touhunsa ja lähtee perään.
func _player_left() -> bool:
	return _player_busy() and _flat_distance_to(player.target()) > SIT_RADIUS + 0.4


func _do_follow(delta: float) -> void:
	var dist := _flat_distance_to(player.global_position)
	if _player_busy() or dist > SIT_RADIUS:
		_idle = 0.0
		_goal_sit = 0.0
		_repath -= delta
		if _repath <= 0.0:
			_repath = REPATH_TIME
			var goal := _follow_point()
			if _flat_distance_to(goal) > 0.2:
				var end := _path[_path.size() - 1] if is_moving() and not _path.is_empty() else Vector3.INF
				if end == Vector3.INF or Vector2(end.x - goal.x, end.z - goal.z).length() > 0.25:
					walk_to(goal)
		return
	if is_moving():
		return
	_goal_sit = 1.0
	face_towards(player.global_position, delta)
	_idle += delta
	if _idle >= _idle_wait:
		_idle = 0.0
		_idle_wait = rng.randf_range(IDLE_MIN, IDLE_MAX)
		start(_pick_activity())


## Kohta hahmon vieressä (kävellessä hahmon perässä).
func _follow_point() -> Vector3:
	var p := player.global_position
	p.y = 0.0
	var fwd := player.facing()
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.BACK
	var goal: Vector3
	if player.is_walking():
		var end := player.target()
		var dir := end - p
		dir.y = 0.0
		fwd = dir.normalized() if dir.length() > 0.01 else fwd
		goal = Vector3(end.x, 0, end.z) - fwd * FOLLOW_GAP
		# Perillä istutaan vierelle, ei hahmon taakse kameran eteen.
		goal += fwd.cross(Vector3.UP) * _side() * 0.35
	else:
		goal = p + fwd.cross(Vector3.UP) * _side() * FOLLOW_GAP + fwd * 0.15
	return grid.nearest_walkable(goal)


## Kummalla puolella hahmoa lemmikki on (1 tai -1), jotta se ei kävele hahmon läpi.
func _side() -> float:
	var right := player.facing().cross(Vector3.UP)
	return 1.0 if (global_position - player.global_position).dot(right) >= 0.0 else -1.0


func _pick_activity() -> String:
	var options: Array = []
	for a in ACTIVITIES:
		if a == _last_activity:
			continue
		if a == "play_bed" and (bed == null or _bed_taken()):
			continue
		if a == "play_box" and toy_box == null:
			continue
		if a == "nap" and rug == null:
			continue
		options.append(a)
	if options.is_empty():
		return "yawn"
	return options[rng.randi_range(0, options.size() - 1)]


## Onko hahmo sängyllä (silloin lemmikki ei hyppää samaan kohtaan).
func _bed_taken() -> bool:
	return player.global_position.y > 0.2


func _do_wait(delta: float) -> void:
	_timer += delta
	_goal_sit = 1.0
	face_towards(player.global_position, delta)
	if _timer > 5.0:
		start("follow")


func _do_petted(delta: float) -> void:
	_timer += delta
	_fx -= delta
	if _fx <= 0.0:
		_fx = 0.6
		_hearts(1)
	if kind == "cat":
		# Kehrää ja kieriskelee selällään.
		_goal_roll = 1.0 if _timer > 0.3 else 0.0
	else:
		# Heiluttaa häntää ja hyppii iloisesti.
		_goal_sit = 0.0
		if not is_hopping() and _count < 3 and _timer > 0.2 + _count * 0.6:
			_count += 1
			hop_to(global_position, 0.18)
	if _timer >= PET_TIME:
		start("follow")


func _do_chase(delta: float) -> void:
	_timer += delta
	var inter := Interactable.of(train)
	var engine := train.get_node_or_null("Visual/Train") as Node3D if train != null else null
	if engine == null or _timer > 14.0 or (_timer > 1.0 and inter != null and not inter.is_playing()):
		_hearts(1, "star")
		start("follow")
		return
	_repath -= delta
	if _repath <= 0.0:
		_repath = REPATH_TIME
		var goal := grid.nearest_walkable(Vector3(engine.global_position.x, 0, engine.global_position.z))
		if _flat_distance_to(goal) > 0.35:
			walk_to(goal)
		elif not is_moving():
			face_towards(engine.global_position)
			hop_to(global_position, 0.15)


func _do_play_bed(_delta: float) -> void:
	if _player_left() or _bed_taken():
		start("follow")
		return
	match _step:
		0:
			walk_to(_beside(bed))
			_step = 1
		1:
			if not is_moving():
				hop_to(bed.to_global(BED_PLAY + Vector3(rng.randf_range(-0.15, 0.15), 0, 0)), 0.35)
				_step = 2
		2:
			if not is_hopping():
				if _count >= 3:
					walk_to(_beside(bed))
					_step = 3
				else:
					_count += 1
					hop_to(global_position, 0.3)
					_hearts(1, "star")
		3:
			if not is_moving():
				start("follow")


func _do_play_box(delta: float) -> void:
	if _player_left():
		start("follow")
		return
	match _step:
		0:
			walk_to(_beside(toy_box))
			_step = 1
		1:
			if not is_moving():
				face_towards(toy_box.global_position)
				_goal_rear = 1.0
				_step = 2
		2:
			_timer += delta
			face_towards(toy_box.global_position, delta)
			_set_lid(clampf(_timer / 0.4, 0.0, 1.0) * clampf((2.4 - _timer) / 0.4, 0.0, 1.0))
			if _timer > 1.0 and _count == 0:
				_count = 1
				_hearts(1, "star")
			if _timer >= 2.4:
				start("follow")


func _do_nap(delta: float) -> void:
	if _player_left():
		start("follow")
		return
	match _step:
		0:
			var spot := rug.global_position + Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.3, 0.3))
			walk_to(grid.nearest_walkable(spot))
			_step = 1
		1:
			if not is_moving():
				_goal_curl = 1.0
				_step = 2
		2:
			_timer += delta
			_sleep_fx(delta)
			if _timer > 7.0:
				start("follow")


func _do_yawn(delta: float) -> void:
	_timer += delta
	_goal_sit = 1.0
	_goal_yawn = 1.0 if _timer > 0.2 and _timer < 1.4 else 0.0
	if _timer > 1.8 or _player_left():
		start("follow")


func _do_tail(delta: float) -> void:
	_timer += delta
	rotation.y += delta * 9.0
	if _timer > 1.8 or _player_left():
		start("follow")


func _check_night() -> void:
	if day_night == null or bed == null:
		return
	if day_night.is_night and activity != "night":
		start("night")
	elif not day_night.is_night and activity == "night":
		_goal_curl = 0.0
		start("follow")


func _do_night(delta: float) -> void:
	match _step:
		0:
			if not on_bed:
				walk_to(_floor_near(bed.to_global(BED_FOOT)))
			_step = 1
		1:
			if not is_moving():
				hop_to(bed.to_global(BED_FOOT), 0.35)
				_step = 2
		2:
			if not is_hopping():
				rotation.y = bed.global_rotation.y + PI * 0.75
				_goal_curl = 1.0
				_step = 3
		3:
			_timer += delta
			_sleep_fx(delta)


func _floor_near(point: Vector3) -> Vector3:
	return grid.nearest_walkable(Vector3(point.x, 0, point.z))


# --- Kuva ja tehosteet -------------------------------------------------------

func _sleep_fx(delta: float) -> void:
	_fx -= delta
	if _fx <= 0.0:
		_fx = 1.4
		_spawn_symbol("z", Color(0.55, 0.65, 1.0), 0.1, Vector3(0.05, 0.35, 0.1))


func _hearts(n: int, shape := "heart") -> void:
	for i in n:
		var color := Color(1.0, 0.45, 0.6) if shape == "heart" else Color(1.0, 0.85, 0.3)
		_spawn_symbol(shape, color, 0.11, Vector3((i - (n - 1) * 0.5) * 0.15, 0.5, 0.0), i * 0.1)


func _spawn_symbol(shape: String, color: Color, size: float, offset: Vector3, delay := 0.0) -> void:
	if effects == null or not effects.is_inside_tree():
		return
	var s := FloatingSymbol.new(shape, color, size)
	s.start = global_position + offset
	s.rise = 0.45
	s.lifetime = 1.3
	s.start_delay = delay
	effects.add_child(s)


func _set_lid(open: float) -> void:
	var lid := toy_box.get_node_or_null("Visual/LidPivot") as Node3D if toy_box != null else null
	if lid == null:
		return
	if is_nan(_lid_rest):
		_lid_rest = lid.rotation.x
	lid.rotation.x = _lid_rest - 0.9 * open


func _update_pose(delta: float) -> void:
	if art == null:
		return
	var walking := is_moving() and not is_hopping()
	var k := minf(1.0, delta * 8.0)
	_sit = lerpf(_sit, 0.0 if walking else _goal_sit, k)
	_curl = lerpf(_curl, 0.0 if walking else _goal_curl, k)
	_rear = lerpf(_rear, 0.0 if walking else _goal_rear, k)
	_roll = lerpf(_roll, 0.0 if walking else _goal_roll, k * 0.6)
	_yawn = lerpf(_yawn, _goal_yawn, k)
	var body := art.get_node("Body") as Node3D
	var head := body.get_node("Head") as Node3D
	var tail := body.get_node("Tail") as Node3D
	var pitch := -SIT_PITCH * _sit - 0.85 * _rear
	body.rotation.x = pitch
	# Istuessa lantio laskeutuu lattiaa kohti.
	body.position.y = PetArt.HIP.y * (1.0 - 0.5 * _curl) - SIT_DROP * _sit
	body.scale = Vector3(1.0 + 0.12 * _curl, 1.0 - 0.3 * _curl, 1.0 - 0.15 * _curl)
	head.rotation.x = -pitch * 0.7 + 0.35 * _curl - 0.5 * _yawn
	head.rotation.z = sin(_anim * 1.3) * 0.08 * _sit
	var mouth := head.get_node("Mouth") as Node3D
	mouth.visible = _yawn > 0.05
	mouth.scale = Vector3(1.0, 0.15 + 0.9 * _yawn, 0.5)
	# Kissa kieriskelee kyljellään ja kehrää (pieni värinä).
	var purr := activity == "petted" and kind == "cat"
	art.rotation.z = _roll * (1.25 + sin(_anim * 3.0) * 0.3)
	art.position = Vector3(sin(_anim * 70.0) * 0.004 if purr else 0.0, 0.0, 0.0)
	# Häntä: koira heiluttaa, kissa keinuttaa hitaasti.
	var wag_speed := 18.0 if kind == "dog" else 3.0
	var wag_amount := 0.35
	if activity == "petted" or activity == "chase_train":
		wag_speed *= 1.6
		wag_amount = 0.7
	if _curl > 0.5:
		wag_amount = 0.08
		wag_speed = 1.5
	tail.rotation.y = sin(_anim * wag_speed) * wag_amount
	# Jalat: kävellessä vuorotellen, istuessa takajalat koukussa ja etujalat suorina.
	var swing := sin(_anim * _speed * 9.0) * 0.6 if walking else 0.0
	var rise := maxf(0.0, PetArt.SHOULDER_Z * sin(SIT_PITCH * _sit) - SIT_DROP * _sit)
	for leg_name in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var leg := art.get_node(leg_name) as Node3D
		var front: bool = leg_name.begins_with("LegF")
		var diag := 1.0 if leg_name in ["LegFL", "LegBR"] else -1.0
		leg.rotation.x = swing * diag
		var fold := 1.0 - 0.75 * _curl
		if front:
			leg.position.y = PetArt.LEG_TOP + rise
			leg.scale.y = (PetArt.LEG_TOP + rise) / PetArt.LEG_TOP * fold
			leg.rotation.x += -1.1 * _rear
		else:
			leg.scale.y = fold * (1.0 - 0.45 * _sit)
