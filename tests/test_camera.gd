extends "res://tests/test_case.gd"
## Kamera: seuraa hahmoa läheltä, zoomaus ja kääntö kahdella sormella,
## hahmo asettuu esineen sivulle ja tempusta tehdään lähikuva.



func _spawn_main() -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func _touch(index: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = pos
	ev.pressed = pressed
	return ev


func _drag(index: int, pos: Vector2) -> InputEventScreenDrag:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	return ev


func _settle(camera: FollowCamera, seconds: float = 3.0) -> void:
	for i in int(seconds * 60.0):
		camera.advance(1.0 / 60.0)


func test_camera_is_closer_than_before() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as FollowCamera
	var player := main.get_node("Player") as Node3D
	var dist := camera.global_position.distance_to(player.global_position)
	# Vanha kamera oli noin 5,5 m päässä, jolloin esineet näkyivät vaakanäytöllä pieninä.
	check(dist < 4.2, "kamera on lähellä hahmoa (%.2f m)" % dist)
	check(dist > 2.0, "kamera ei ole liian lähellä (%.2f m)" % dist)
	main.free()


func test_zoom_and_turn_are_limited() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as FollowCamera
	camera.set_zoom(100.0)
	check_eq(camera.zoom, camera.max_zoom, "zoomia ei voi loitontaa rajattomasti")
	camera.set_zoom(0.0)
	check_eq(camera.zoom, camera.min_zoom, "zoomia ei voi lähentää rajattomasti")
	camera.set_yaw(10.0)
	check(is_equal_approx(camera.yaw, deg_to_rad(camera.max_yaw_degrees)), "kääntö on rajattu")
	camera.set_yaw(-10.0)
	check(is_equal_approx(camera.yaw, deg_to_rad(camera.min_yaw_degrees)), "kääntö on rajattu toiseen suuntaan")
	main.free()


func test_camera_never_goes_behind_walls() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as FollowCamera
	var player := main.get_node("Player") as Node3D
	for corner in [Vector3(-2.7, 0, -2.2), Vector3(2.7, 0, -2.2), Vector3(-2.7, 0, 2.2), Vector3(2.7, 0, 2.2)]:
		player.global_position = corner
		for yaw in [camera.min_yaw_degrees, 0.0, camera.max_yaw_degrees]:
			for zoom in [camera.min_zoom, 1.0, camera.max_zoom]:
				camera.set_yaw(deg_to_rad(yaw))
				camera.set_zoom(zoom)
				camera.snap()
				var p := camera.global_position
				check(p.x >= camera.wall_limit.x - 0.001 and p.z >= camera.wall_limit.y - 0.001,
						"kamera pysyy seinien edessä (%s, kääntö %d)" % [p, yaw])
				check(p.y > 1.0, "kamera on ylhäällä (%s)" % p)
	main.free()


func test_pinch_zooms_and_twist_turns() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as FollowCamera
	var player := main.get_node("Player") as Player
	var center := Vector2(640, 360)
	main._unhandled_input(_touch(11, center - Vector2(100, 0), true))
	main._unhandled_input(_touch(12, center + Vector2(100, 0), true))
	check_eq(main.tap_count, 1, "toinen sormi ei ole napautus")
	check(not player.is_walking(), "hahmo jää paikalleen, kun alkaa kahden sormen ele")
	var before := camera.current_distance()
	# Sormet erilleen: lähemmäs.
	main._unhandled_input(_drag(11, center - Vector2(200, 0)))
	main._unhandled_input(_drag(12, center + Vector2(200, 0)))
	check(camera.zoom < 0.7, "sormet erilleen lähentää (zoom %.2f)" % camera.zoom)
	check(camera.current_distance() < before, "kamera tulee heti lähemmäs")
	check(not player.is_walking(), "hahmo ei lähde sormien perään")
	# Sormien kierto myötäpäivään kääntää huonetta.
	main._unhandled_input(_drag(11, center + Vector2(-140, -140)))
	main._unhandled_input(_drag(12, center + Vector2(140, 140)))
	check(camera.yaw > 0.3, "kierto kääntää kameraa (%.2f rad)" % camera.yaw)
	main._unhandled_input(_touch(11, center, false))
	# Toinen sormi jää ruudulle: se ei liikuta hahmoa.
	main._unhandled_input(_drag(12, center + Vector2(300, 100)))
	check(not player.is_walking(), "jäljelle jäänyt sormi ei liikuta hahmoa")
	main._unhandled_input(_touch(12, center, false))
	check_eq(main.tap_count, 1, "ele ei tehnyt ylimääräisiä napautuksia")
	# Eleen jälkeen napautus toimii tavalliseen tapaan.
	var pos := camera.unproject_position(Vector3(1.2, 0, 1.6))
	main._unhandled_input(_touch(13, pos, true))
	main._unhandled_input(_touch(13, pos, false))
	check_eq(main.tap_count, 2, "eleen jälkeen napautus toimii")
	check(player.is_walking(), "hahmo kävelee napautukseen")
	main.free()


func test_player_stands_beside_props_not_in_front() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as FollowCamera
	var player := main.get_node("Player") as Player
	# Lattialla olevat esineet. Lipaston päällä olevien (juna, nukkekoti) eteen on pakko mennä,
	# mutta ne ovat korkealla, joten hahmo ei peitä niitä.
	for name in ["Panda", "ToyBox", "SheepLight"]:
		player.global_position = main.grid.nearest_walkable(Vector3(0.3, 0, 0.8))
		var prop := main.get_node("Room/" + name) as Node3D
		var point: Vector3 = main.stand_point_for(prop)
		var to_camera := camera.global_position - prop.global_position
		var side := Vector2(point.x - prop.global_position.x, point.z - prop.global_position.z)
		var front := side.normalized().dot(Vector2(to_camera.x, to_camera.z).normalized())
		check(front < 0.6, "hahmo ei mene esineen %s eteen (%.2f)" % [name, front])
	main.free()


func test_trick_gets_closeup_and_camera_returns() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as FollowCamera
	var player := main.get_node("Player") as Player
	var panda := main.get_node("Room/Panda") as Node3D
	_settle(camera)
	var normal := camera.current_distance()
	main.walk_to_prop(panda)
	for i in 600:
		player.advance(1.0 / 60.0)
		if not player.is_walking():
			break
	check(camera.is_closeup(), "tempun alkaessa kamera tekee lähikuvan")
	_settle(camera, 0.8)
	check(camera.current_distance() < normal * 0.85, "lähikuva on lähempänä (%.2f < %.2f)" % [camera.current_distance(), normal])
	var to_panda := (panda.global_position - camera.global_position).normalized()
	check((-camera.global_transform.basis.z).dot(to_panda) > 0.9, "panda näkyy lähikuvassa")
	_settle(camera, 10.0)
	check(not camera.is_closeup(), "lähikuva loppuu")
	check(absf(camera.current_distance() - normal) < 0.05, "kamera palaa takaisin")
	main.free()


func test_walking_away_ends_closeup() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as FollowCamera
	var player := main.get_node("Player") as Player
	main.walk_to_prop(main.get_node("Room/Panda"))
	for i in 600:
		player.advance(1.0 / 60.0)
		if not player.is_walking():
			break
	check(camera.is_closeup(), "lähikuva alkaa")
	main.walk_to(Vector3(1.5, 0, 1.5))
	check(not camera.is_closeup(), "kävely muualle lopettaa lähikuvan heti")
	main.free()


func test_flying_trick_camera_follows_the_flyer() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as FollowCamera
	var creature := main.get_node("Room/WingCreature") as Node3D
	var inter := Interactable.of(creature)
	# Etsitään lentävä temppu ja käynnistetään se.
	var flying := -1
	for i in inter.variants.size():
		for reaction in inter.variants[i].reactions:
			if reaction is FlyPathReaction:
				flying = i
	check(flying >= 0, "siipiotuksella on lentotemppu")
	inter.use_count = flying
	main._use(inter)
	check(camera.is_closeup(), "lento saa lähikuvan")
	var route: AABB = main.route_bounds(inter, flying)
	check(route.size.length() > 1.0, "lentoreitti löytyy (%s)" % route)
	_settle(camera, 1.0)
	# Kamera katsoo reitin keskelle eikä heilu otuksen perässä.
	var size := tree.root.get_visible_rect().size
	var screen := Rect2(Vector2.ZERO, size)
	var mid := camera.unproject_position(route.get_center())
	check(screen.grow(-size.y * 0.2).has_point(mid), "lentoreitti on kuvan keskellä (%s)" % mid)
	check(camera.current_distance() > camera.distance * 1.2,
			"kamera loitontaa, jotta lento näkyy (%.2f m)" % camera.current_distance())
	main.free()


func test_every_prop_still_tappable_after_turning() -> void:
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as FollowCamera
	camera.set_yaw(deg_to_rad(40.0))
	camera.set_zoom(camera.max_zoom)
	camera.snap()
	var seen: Dictionary = main.prop_screen_positions()
	check(seen.size() >= 4, "käännetystä kuvakulmasta näkyy useita esineitä (%d)" % seen.size())
	main.free()
