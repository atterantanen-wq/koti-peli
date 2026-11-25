extends "res://tests/test_case.gd"
## Tarkistaa, että lastenhuone käynnistyy ja napautusohjaus toimii.

const PROPS := ["Bed", "ToyBox", "SheepLight"]


func _spawn_main() -> Node:
	var scene: PackedScene = load("res://scenes/main/main.tscn")
	var main := scene.instantiate()
	tree.root.add_child(main)
	check(main.is_node_ready(), "kohtaus käynnistyy (_ready ajettu)")
	return main


func test_scene_has_room_player_and_camera() -> void:
	var main := _spawn_main()
	check(main.get_node_or_null("Camera3D") is Camera3D, "kamera löytyy")
	check(main.get_node_or_null("Player") is Player, "hahmo löytyy")
	check(main.get_node_or_null("UI/InfoLabel") != null, "tekstikenttä löytyy")
	for name in PROPS:
		var prop := main.get_node_or_null("Room/" + name)
		check(prop != null and prop.is_in_group("prop"), "esine %s löytyy" % name)
	main.free()


func test_camera_sees_player() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as Camera3D
	var player := main.get_node("Player") as Node3D
	var forward := -camera.global_transform.basis.z
	check(forward.y < -0.3, "kamera katsoo yläviistosta alas")
	var to_player := (player.global_position - camera.global_position).normalized()
	check(forward.dot(to_player) > 0.97, "hahmo on kameran kuvan keskellä")
	var sun := main.get_node("Sun") as Node3D
	check((-sun.global_transform.basis.z).y < -0.5, "aurinko paistaa ylhäältä")
	# Reaaliaikaiset varjot vaalensivat kuvan lähes valkoiseksi selaimessa ja ovat raskaita
	# vanhoille iPhoneille. Hahmolla on sen sijaan oma pehmeä varjoläiskä.
	check(not (sun as DirectionalLight3D).shadow_enabled, "auringon varjot pois päältä")
	check(main.get_node_or_null("Player/Shadow") != null, "hahmolla on varjoläiskä")
	main.free()


func test_player_can_reach_whole_room() -> void:
	var main := _spawn_main()
	var grid: WalkGrid = main.grid
	var player := main.get_node("Player") as Node3D
	check(grid.is_walkable(player.global_position), "hahmo aloittaa vapaalta paikalta")
	var reachable := grid.reachable_cells(player.global_position).size()
	check(reachable > 200, "huoneessa on tilaa kävellä (%d ruutua)" % reachable)
	check_eq(reachable, grid.walkable_cell_count(), "hahmo pääsee kaikkialle huoneessa")
	main.free()


func test_furniture_blocks_walking() -> void:
	var main := _spawn_main()
	var grid: WalkGrid = main.grid
	for name in PROPS + ["Dresser", "Basket"]:
		var p := (main.get_node("Room/" + name) as Node3D).global_position
		check(not grid.is_walkable(p), "%s on este" % name)
	main.free()


func test_every_prop_reachable() -> void:
	var main := _spawn_main()
	var player := main.get_node("Player") as Player
	for name in PROPS:
		var prop := main.get_node("Room/" + name) as Node3D
		main.walk_to_prop(prop)
		var goal := player.target()
		var footprint: Rect2 = WalkGrid.obstacle_rects(prop)[0]
		var goal2 := Vector2(goal.x, goal.z)
		var gap := goal2.distance_to(goal2.clamp(footprint.position, footprint.end))
		check(gap < 0.5, "hahmo pääsee esineen %s viereen (väli %.2f m)" % [name, gap])
		for i in 600:
			player.advance(1.0 / 60.0)
			if not player.is_walking():
				break
		check(not player.is_walking(), "hahmo ehtii esineen %s luo" % name)
		check(player.global_position.distance_to(goal) < 0.01, "hahmo on perillä (%s)" % name)
	main.free()


func test_tap_floor_walks_and_shows_star() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as Camera3D
	var player := main.get_node("Player") as Player
	var goal := Vector3(1.2, 0, 1.6)
	var kind: String = main.tap_at_screen(camera.unproject_position(goal))
	check_eq(kind, "floor", "napautus osuu lattiaan")
	check(player.is_walking(), "hahmo lähtee kävelemään")
	check(player.target().distance_to(goal) < 0.2, "hahmo menee napautettuun kohtaan")
	check_eq(main.get_node("Markers").get_child_count(), 1, "kohtaan ilmestyy tähti")
	main.free()


func test_tap_player_jumps() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as Camera3D
	var player := main.get_node("Player") as Player
	# Napautus hieman hahmon viereen: alue on anteeksiantava.
	var screen := camera.unproject_position(player.global_position + Vector3(0, 0.5, 0))
	var kind: String = main.tap_at_screen(screen + Vector2(40, 30))
	check_eq(kind, "player", "napautus osuu hahmoon")
	check_eq(player.jump_count, 1, "hahmo hyppää")
	check(not player.is_walking(), "hahmo ei lähde kävelemään")
	main.free()


func test_tap_into_wall_walks_near_it() -> void:
	var main := _spawn_main()
	var player := main.get_node("Player") as Player
	var grid: WalkGrid = main.grid
	var point: Vector3 = main.walk_to(Vector3(0.5, 0, -2.6))
	check(grid.is_walkable(point), "seinään napautus vie seinän viereen")
	check(point.z > -2.5 and point.z < -1.8, "kohde on seinän edessä (%s)" % point)
	check(player.is_walking(), "hahmo lähtee kävelemään")
	main.free()


func test_tap_marker_star_mesh() -> void:
	var mesh := TapMarker.make_star_mesh(0.2, 0.1, 5)
	check_eq(mesh.get_surface_count(), 1, "tähti on yksi pinta")
	var aabb := mesh.get_aabb()
	check(aabb.size.x > 0.3 and aabb.size.y < 0.01, "tähti on litteä ja oikean kokoinen")
