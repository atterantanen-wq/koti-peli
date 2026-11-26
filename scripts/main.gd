extends Node3D
## Pelin aloituskohtaus (vaihe 1): harmaalaatikko-lastenhuone, hahmo ja napautusohjaus.
##
## Ohjaus 5-vuotiaalle:
## - Napautus lattiaan: hahmo kävelee sinne ja kohtaan ilmestyy tähti.
## - Napautus huonekaluun tai esineeseen: hahmo kävelee sen viereen ja käyttää sitä
##   (esineen omat temput, katso scripts/props/interactable.gd).
## - Sängyllä: hahmo kiipeää päälle, ja jokainen napautus on uusi pomppu.
##   Napautus muualle: hahmo hyppää alas ja lähtee sinne.
## - Napautus hahmoon (reilu alue hahmon ympärillä): hahmo hyppää.
## - Sormi painettuna ja liu'utus: hahmo seuraa sormea.
## - Kaksi sormea: nipistys lähentää tai loitontaa, kierto kääntää huonetta
##   (lähinnä aikuiselle, lapsen ei tarvitse osata).
## - Tempun ajaksi kamera tekee lähikuvan ja palaa sitten.
## Vain ensimmäinen ruudulla oleva sormi ohjaa hahmoa, joten toinen sormi ei sotke.
## Huom: iPhonen Safari antaa sormille isoja tunnisteita (ei 0, 1, ...), joten
## sormea ei tunnisteta numerosta vaan siitä, mikä painettiin ensimmäisenä.

const PLAYER_RADIUS := 0.25
## Hahmon napautusalue ruudulla (pelin perusresoluution pisteinä, noin 60 pt iPhonella).
const PLAYER_TAP_RADIUS := 90.0
## Näin paljon sormi saa liikkua, ennen kuin napautus tulkitaan liu'utukseksi.
const DRAG_THRESHOLD := 24.0
const DRAG_REPATH_INTERVAL := 0.1
## Jos napautus osuu lattiaan näin lähelle esinettä (ruudulla), käytetään esinettä.
const PROP_TAP_RADIUS := 70.0
const FLOOR_BOUNDS := Rect2(-3.0, -2.5, 6.0, 5.0)
## Jos toinen sormi tulee ruudulle näin pian ensimmäisen jälkeen, ensimmäisen
## sormen napautus perutaan (käyttäjä aloitti kahden sormen eleen).
const GESTURE_CANCEL_TIME := 0.35
## Hiiren rullan ja Macin kosketuslevyn zoomaus (kehittäjän kokeiluun).
const WHEEL_ZOOM_STEP := 1.1
## Lähikuva kestää vähintään näin kauan.
const CLOSEUP_MIN_TIME := 1.6

var grid: WalkGrid
var tap_count := 0
var last_tap_kind := ""
var _build_text := ""
var _finger := -1  # ohjaava sormi, -1 = ei sormea ruudulla
var _fingers_down := {}
var _dragging := false
var _press_pos := Vector2.ZERO
var _drag_pos := Vector2.ZERO
var _drag_timer := 0.0
var _pending_prop: Node3D
var _touch_pos := {}  # sormen tunniste -> paikka ruudulla
var _gesture := false  # kahden sormen ele käynnissä (tai sormet vielä ruudulla sen jälkeen)
var _gesture_start := {}
var _press_time := 0.0
## Esine, jonka temppua kamera katsoo lähikuvassa.
var _shot_inter: Interactable
## Esine, jonka päällä hahmo on (esim. sänky), tai null.
var climbed: Interactable
## Esineet, joita on kokeiltu (nimi -> käyttökerrat).
var tried := {}

@onready var player: Player = $Player
@onready var camera: FollowCamera = $Camera3D
@onready var markers: Node3D = $Markers
@onready var effects: Node3D = $Effects
@onready var info_label: Label = $UI/InfoLabel


func _ready() -> void:
	grid = WalkGrid.from_scene(get_tree(), FLOOR_BOUNDS, PLAYER_RADIUS)
	var spawn := get_node_or_null("Room/SpawnPoint") as Node3D
	if spawn != null:
		player.global_position = grid.nearest_walkable(spawn.global_position)
	camera.snap()
	player.arrived.connect(_on_player_arrived)
	_build_text = _read_build_info()
	_update_label()
	if OS.has_feature("web"):
		var timer := Timer.new()
		timer.wait_time = 0.2
		timer.autostart = true
		timer.timeout.connect(_publish_prop_positions)
		add_child(timer)


func _process(delta: float) -> void:
	if _shot_inter != null:
		if _shot_inter.is_playing() and camera.is_closeup():
			camera.extend_closeup(0.4)
		elif not camera.is_closeup():
			_shot_inter = null
	if _dragging:
		_drag_timer -= delta
		if _drag_timer <= 0.0:
			_drag_timer = DRAG_REPATH_INTERVAL
			_walk_towards_screen(_drag_pos, false)
	_update_label()


func _unhandled_input(event: InputEvent) -> void:
	# Hiiren napsautukset muuttuvat kosketuksiksi (project.godot), joten käsitellään vain kosketus.
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_fingers_down[touch.index] = true
			_touch_pos[touch.index] = touch.position
			if _fingers_down.size() >= 2:
				_start_gesture()
			elif not _gesture and (_finger == -1 or _finger == touch.index or _fingers_down.size() == 1):
				_finger = touch.index
				_dragging = false
				_press_pos = touch.position
				_press_time = _now()
				tap_at_screen(touch.position)
		else:
			_fingers_down.erase(touch.index)
			_touch_pos.erase(touch.index)
			if touch.index == _finger or _fingers_down.is_empty():
				_finger = -1
				_dragging = false
			if _fingers_down.is_empty():
				_gesture = false
			elif _gesture and _fingers_down.size() >= 2:
				_start_gesture()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_touch_pos[drag.index] = drag.position
		if _gesture:
			_update_gesture()
			get_viewport().set_input_as_handled()
			return
		if drag.index != _finger:
			return
		_drag_pos = drag.position
		if not _dragging and _drag_pos.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging = true
			_drag_timer = 0.0
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var button := (event as InputEventMouseButton).button_index
		if button == MOUSE_BUTTON_WHEEL_UP:
			camera.set_zoom(camera.zoom / WHEEL_ZOOM_STEP)
		elif button == MOUSE_BUTTON_WHEEL_DOWN:
			camera.set_zoom(camera.zoom * WHEEL_ZOOM_STEP)
	elif event is InputEventMagnifyGesture:
		camera.set_zoom(camera.zoom / maxf(0.1, (event as InputEventMagnifyGesture).factor))


## Kaksi sormea ruudulla: aloitetaan zoomaus ja kääntö. Hahmo ei seuraa sormia.
func _start_gesture() -> void:
	if not _gesture and _finger != -1 and _now() - _press_time < GESTURE_CANCEL_TIME:
		# Ensimmäinen sormi oli eleen alku, ei napautus: hahmo jää paikalleen.
		player.stop()
		_pending_prop = null
	_gesture = true
	_finger = -1
	_dragging = false
	camera.end_closeup()
	var pair := _gesture_pair()
	_gesture_start = {
		"distance": maxf(1.0, pair[0].distance_to(pair[1])),
		"angle": (pair[1] - pair[0]).angle(),
		"zoom": camera.zoom,
		"yaw": camera.yaw,
	}


func _update_gesture() -> void:
	if _gesture_start.is_empty() or _touch_pos.size() < 2:
		return
	var pair := _gesture_pair()
	var dist := maxf(1.0, pair[0].distance_to(pair[1]))
	# Sormet erilleen = lähemmäs.
	camera.set_zoom(_gesture_start["zoom"] * _gesture_start["distance"] / dist)
	# Sormien kierto myötäpäivään kääntää huonetta myötäpäivään.
	var turn := angle_difference(_gesture_start["angle"], (pair[1] - pair[0]).angle())
	camera.set_yaw(_gesture_start["yaw"] + turn)
	camera.follow_fingers()


## Kaksi ensimmäiseksi painettua sormea (pienimmät tunnisteet järjestyksessä).
func _gesture_pair() -> Array[Vector2]:
	var keys := _touch_pos.keys()
	keys.sort()
	var a: Vector2 = _touch_pos[keys[0]]
	var b: Vector2 = _touch_pos[keys[1]] if keys.size() > 1 else a
	return [a, b]


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Jos peli menettää kosketuksen kesken (esim. ilmoitus tai sovelluksen vaihto),
## unohdetaan sormet, jotta seuraava napautus toimii varmasti.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_fingers_down.clear()
		_touch_pos.clear()
		_gesture = false
		_finger = -1
		_dragging = false


## Napautus ruudun kohtaan. Palauttaa mitä napautettiin: "player", "prop" tai "floor".
func tap_at_screen(screen_pos: Vector2) -> String:
	tap_count += 1
	# Napautettu käytettävä esine voittaa hahmon reilun napautusalueen, paitsi jos
	# sormi on lähempänä hahmoa kuin esinettä. Näin hahmon vieressä olevaa lelua voi käyttää.
	var hit_prop := _prop_of(pick(screen_pos).get("collider"))
	var hit_inter := Interactable.of(hit_prop)
	if hit_inter == null or _screen_distance(player.global_position + Vector3(0, 0.5, 0), screen_pos) \
			< _screen_distance(hit_inter.focus_position(), screen_pos):
		hit_prop = null
	if climbed != null:
		if hit_prop == climbed.prop() or (hit_prop == null and is_near_player_on_screen(screen_pos)):
			_use(climbed)
			last_tap_kind = "prop"
			print("napautus %d: %s" % [tap_count, last_tap_kind])
			return last_tap_kind
		climb_down()
	if hit_prop == null and is_near_player_on_screen(screen_pos):
		player.stop()
		_pending_prop = null
		player.jump()
		last_tap_kind = "player"
	else:
		last_tap_kind = _walk_towards_screen(screen_pos, true)
	print("napautus %d: %s" % [tap_count, last_tap_kind])
	return last_tap_kind


func is_near_player_on_screen(screen_pos: Vector2) -> bool:
	# Verrataan hahmon keskikohtaan, jotta osuu kun napauttaa päätä, vatsaa tai jalkoja.
	return _screen_distance(player.global_position + Vector3(0, 0.5, 0), screen_pos) <= PLAYER_TAP_RADIUS


## Kuinka kaukana ruudulla kohta on napautuksesta (pisteinä).
func _screen_distance(point: Vector3, screen_pos: Vector2) -> float:
	if camera.is_position_behind(point):
		return INF
	return camera.unproject_position(point).distance_to(screen_pos)


func _walk_towards_screen(screen_pos: Vector2, show_marker: bool) -> String:
	var hit := pick(screen_pos)
	if hit.is_empty():
		return "none"
	var collider: Node = hit.get("collider")
	var prop := _prop_of(collider)
	if prop == null and show_marker:
		prop = nearest_prop_on_screen(screen_pos)
	if prop != null:
		if not show_marker:
			# Liu'utus esineen yli: kävellään vain kohti, ei käytetä esinettä.
			walk_to(hit["position"])
			return "floor"
		walk_to_prop(prop)
		return "prop"
	var point := walk_to(hit["position"])
	if show_marker:
		_spawn_marker(point)
	return "floor"


## Mihin ruudun kohta osuu huoneessa: {"position": Vector3, "collider": Node tai null}.
func pick(screen_pos: Vector2) -> Dictionary:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var space := get_world_3d().direct_space_state
	if space != null:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * 50.0)
		var result := space.intersect_ray(query)
		if not result.is_empty():
			return {"position": result["position"], "collider": result["collider"]}
	# Varalla: lattiataso y = 0.
	if absf(dir.y) < 0.0001:
		return {}
	var t := -origin.y / dir.y
	if t < 0.0:
		return {}
	return {"position": origin + dir * t, "collider": null}


## Kävelee lähimpään vapaaseen kohtaan. Palauttaa kohdan, johon hahmo on menossa.
func walk_to(point: Vector3) -> Vector3:
	_pending_prop = null
	_end_shot()
	climb_down()
	var path := grid.find_path(player.global_position, point)
	player.walk_path(path)
	return path[path.size() - 1] if not path.is_empty() else player.global_position


## Lähin esine, jonka keskikohta on ruudulla napautuksen lähellä (anteeksiantava napautus).
func nearest_prop_on_screen(screen_pos: Vector2) -> Node3D:
	var best: Node3D
	var best_dist := PROP_TAP_RADIUS
	for node in get_tree().get_nodes_in_group("prop"):
		var inter := Interactable.of(node)
		if inter == null:
			continue
		var center := inter.focus_position()
		if camera.is_position_behind(center):
			continue
		var d := camera.unproject_position(center).distance_to(screen_pos)
		if d < best_dist:
			best_dist = d
			best = node as Node3D
	return best


## Kohta lattialla esineen vieressä: sivulla, jotta hahmo ei peitä temppua kameralta.
func stand_point_for(prop: Node3D) -> Vector3:
	var goal := grid.nearest_walkable(prop.global_position)
	var rects := WalkGrid.obstacle_rects(prop)
	if not rects.is_empty():
		var footprint: Rect2 = rects[0]
		for r in rects:
			footprint = footprint.merge(r)
		var to_camera := camera.global_position - prop.global_position
		goal = grid.side_stand_point(footprint, player.global_position,
				Vector2(to_camera.x, to_camera.z))
	return goal


## Kävelee esineen viereen. Perillä hahmo käyttää esinettä.
func walk_to_prop(prop: Node3D) -> void:
	climb_down()
	_end_shot()
	var goal := stand_point_for(prop)
	var path := grid.find_path(player.global_position, goal)
	player.walk_path(path)
	_pending_prop = prop
	if not player.is_walking():
		_on_player_arrived()


func _prop_of(node: Node) -> Node3D:
	while node != null and node != self:
		if node.is_in_group("prop"):
			return node as Node3D
		node = node.get_parent()
	return null


func _on_player_arrived() -> void:
	if _pending_prop == null:
		return
	var prop := _pending_prop
	_pending_prop = null
	player.face_towards(prop.global_position)
	var inter := Interactable.of(prop)
	if inter != null:
		if inter.climbable:
			climb_onto(inter)
		else:
			_use(inter)
		return
	var visual := prop.get_node_or_null("Visual") as Node3D
	if visual != null and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(visual, "scale", Vector3(1.08, 0.9, 1.08), 0.1)
		tween.tween_property(visual, "scale", Vector3.ONE, 0.35) \
				.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Hahmo kiipeää esineen päälle (esim. sängylle).
func climb_onto(inter: Interactable) -> void:
	climbed = inter
	player.hop_to(inter.climb_position())
	_mark_tried(inter)


## Hahmo hyppää alas esineen päältä sen viereen.
func climb_down() -> void:
	if climbed == null:
		return
	var prop := climbed.prop()
	climbed = null
	player.hop_to(stand_point_for(prop))


func _use(inter: Interactable) -> void:
	var variant := inter.use(ReactionContext.new(inter.prop(), player, effects))
	_mark_tried(inter)
	# Sängyllä pomppiessa ei lähikuvaa: kamera pysyy paikallaan nopeiden pomppujen ajan.
	if not inter.climbable:
		_start_shot(inter, variant)
	print("temppu %s %d" % [inter.prop().name, variant])


func _mark_tried(inter: Interactable) -> void:
	var name := String(inter.prop().name)
	tried[name] = int(tried.get(name, 0)) + 1


## Lähikuva tempusta. Jos esine lentää tai ajaa ympäri huonetta (esim. siipiotus, juna),
## kamera näyttää koko reitin kerralla eikä heilu esineen perässä.
func _start_shot(inter: Interactable, variant: int) -> void:
	_shot_inter = inter
	var route := route_bounds(inter, variant)
	if route.size == Vector3.ZERO:
		var p := player
		camera.closeup(func() -> Vector3: return shot_point(inter, p.global_position),
				CLOSEUP_MIN_TIME, false, shot_yaw(inter))
		return
	var center := route.get_center()
	var extent := maxf(route.size.x, maxf(route.size.y, route.size.z))
	var point := Vector3(center.x, 0.5, center.z)
	camera.closeup(func() -> Vector3: return point, CLOSEUP_MIN_TIME, true, NAN,
			camera.zoom_to_fit(extent))


## Alue, jonka lentävä tai ajava temppu kulkee (tyhjä, jos esine pysyy paikallaan).
func route_bounds(inter: Interactable, variant: int) -> AABB:
	var box := AABB()
	if variant < 0 or variant >= inter.variants.size() or inter.variants[variant] == null:
		return box
	var ctx := ReactionContext.new(inter.prop(), player, effects)
	var first := true
	for reaction in inter.variants[variant].reactions:
		if not reaction is FlyPathReaction:
			continue
		var node := reaction.target_node(ctx)
		if node == null or not node.get_parent() is Node3D:
			continue
		var parent := node.get_parent() as Node3D
		var points: Array[Vector3] = [node.global_position]
		for offset in (reaction as FlyPathReaction).points:
			points.append(parent.global_transform * (node.position + offset))
		for q in points:
			if first:
				box = AABB(q, Vector3.ZERO)
				first = false
			else:
				box = box.expand(q)
	return box


## Lähikuvan katsepiste: hahmon ja esineen välissä, lähempänä esinettä.
func shot_point(inter: Interactable, player_pos: Vector3) -> Vector3:
	var chest := player_pos + Vector3(0, 0.45, 0)
	return chest.lerp(inter.focus_position(), 0.6)


## Lähikuvan kääntö: kamera katsoo hahmoa ja esinettä sivulta, jotta molemmat näkyvät
## vierekkäin. Käännetään vain puolet matkasta, ettei kuva heilahda liikaa.
func shot_yaw(inter: Interactable) -> float:
	var line := inter.prop().global_position - player.global_position
	line.y = 0.0
	if line.length() < 0.05:
		return NAN
	var current := camera.yaw
	# Kaksi kohtisuoraa suuntaa: valitaan se, joka on lähempänä nykyistä.
	var a := atan2(line.z, -line.x)
	var b := a + PI
	var goal := a if absf(angle_difference(current, a)) < absf(angle_difference(current, b)) else b
	return current + angle_difference(current, goal) * 0.5


func _end_shot() -> void:
	_shot_inter = null
	camera.end_closeup()


func _spawn_marker(point: Vector3) -> void:
	var marker := TapMarker.new()
	markers.add_child(marker)
	marker.global_position = point + Vector3(0, 0.02, 0)


## Esineiden paikat ruudulla (0..1) selaimen puolelle, jotta selaintesti osaa napauttaa niitä.
func prop_screen_positions() -> Dictionary:
	var size := get_viewport().get_visible_rect().size
	var out := {}
	for node in get_tree().get_nodes_in_group("prop"):
		var inter := Interactable.of(node)
		if inter == null or camera.is_position_behind(inter.focus_position()):
			continue
		var p := camera.unproject_position(inter.focus_position())
		if not Rect2(Vector2.ZERO, size).has_point(p):
			continue  # ruudun ulkopuolella
		out[String(node.name)] = [p.x / size.x, p.y / size.y]
	return out


func _publish_prop_positions() -> void:
	JavaScriptBridge.eval("window.kotiPeliProps = %s;" % JSON.stringify(prop_screen_positions()), true)


func _update_label() -> void:
	# Napautusten määrä näkyy, jotta iPhonella näkee, meneekö kosketus peliin asti.
	info_label.text = "Koti-peli %s  ·  %d fps  ·  napautuksia %d" % [
			_build_text, Engine.get_frames_per_second(), tap_count]


## Julkaisu kirjoittaa tiedostoon version tunnisteen, jotta näkee onko uusin versio auki.
func _read_build_info() -> String:
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	if FileAccess.file_exists("res://build_info.txt"):
		var build := FileAccess.get_file_as_string("res://build_info.txt").strip_edges()
		if build != "":
			return "%s (%s)" % [version, build]
	return version
