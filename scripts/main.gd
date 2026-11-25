extends Node3D
## Pelin aloituskohtaus (vaihe 1): harmaalaatikko-lastenhuone, hahmo ja napautusohjaus.
##
## Ohjaus 5-vuotiaalle:
## - Napautus lattiaan: hahmo kävelee sinne ja kohtaan ilmestyy tähti.
## - Napautus huonekaluun tai esineeseen: hahmo kävelee sen viereen.
## - Napautus hahmoon (reilu alue hahmon ympärillä): hahmo hyppää.
## - Sormi painettuna ja liu'utus: hahmo seuraa sormea.
## Vain ensimmäinen ruudulla oleva sormi ohjaa, joten toinen sormi ei sotke.
## Huom: iPhonen Safari antaa sormille isoja tunnisteita (ei 0, 1, ...), joten
## sormea ei tunnisteta numerosta vaan siitä, mikä painettiin ensimmäisenä.

const PLAYER_RADIUS := 0.25
## Hahmon napautusalue ruudulla (pelin perusresoluution pisteinä, noin 60 pt iPhonella).
const PLAYER_TAP_RADIUS := 90.0
## Näin paljon sormi saa liikkua, ennen kuin napautus tulkitaan liu'utukseksi.
const DRAG_THRESHOLD := 24.0
const DRAG_REPATH_INTERVAL := 0.1
const FLOOR_BOUNDS := Rect2(-3.0, -2.5, 6.0, 5.0)

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

@onready var player: Player = $Player
@onready var camera: FollowCamera = $Camera3D
@onready var markers: Node3D = $Markers
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


func _process(delta: float) -> void:
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
			if _finger == -1 or _finger == touch.index or _fingers_down.size() == 1:
				_finger = touch.index
				_dragging = false
				_press_pos = touch.position
				tap_at_screen(touch.position)
		else:
			_fingers_down.erase(touch.index)
			if touch.index == _finger or _fingers_down.is_empty():
				_finger = -1
				_dragging = false
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _finger:
			return
		_drag_pos = drag.position
		if not _dragging and _drag_pos.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging = true
			_drag_timer = 0.0
		get_viewport().set_input_as_handled()


## Jos peli menettää kosketuksen kesken (esim. ilmoitus tai sovelluksen vaihto),
## unohdetaan sormet, jotta seuraava napautus toimii varmasti.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_fingers_down.clear()
		_finger = -1
		_dragging = false


## Napautus ruudun kohtaan. Palauttaa mitä napautettiin: "player", "prop" tai "floor".
func tap_at_screen(screen_pos: Vector2) -> String:
	tap_count += 1
	if is_near_player_on_screen(screen_pos):
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
	var center := player.global_position + Vector3(0, 0.5, 0)
	if camera.is_position_behind(center):
		return false
	return camera.unproject_position(center).distance_to(screen_pos) <= PLAYER_TAP_RADIUS


func _walk_towards_screen(screen_pos: Vector2, show_marker: bool) -> String:
	var hit := pick(screen_pos)
	if hit.is_empty():
		return "none"
	var collider: Node = hit.get("collider")
	var prop := _prop_of(collider)
	if prop != null:
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
	var path := grid.find_path(player.global_position, point)
	player.walk_path(path)
	return path[path.size() - 1] if not path.is_empty() else player.global_position


## Kävelee esineen viereen. Perillä esine heilahtaa (esineiden omat reaktiot tulevat myöhemmin).
func walk_to_prop(prop: Node3D) -> void:
	var goal := grid.nearest_walkable(prop.global_position)
	var rects := WalkGrid.obstacle_rects(prop)
	if not rects.is_empty():
		var footprint: Rect2 = rects[0]
		for r in rects:
			footprint = footprint.merge(r)
		goal = grid.nearest_walkable_to_rect(footprint, player.global_position)
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
	var visual := prop.get_node_or_null("Visual") as Node3D
	if visual != null and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(visual, "scale", Vector3(1.08, 0.9, 1.08), 0.1)
		tween.tween_property(visual, "scale", Vector3.ONE, 0.35) \
				.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _spawn_marker(point: Vector3) -> void:
	var marker := TapMarker.new()
	markers.add_child(marker)
	marker.global_position = point + Vector3(0, 0.02, 0)


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
