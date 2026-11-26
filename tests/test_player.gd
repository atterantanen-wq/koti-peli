extends "res://tests/test_case.gd"
## Tarkistaa hahmon kävelyn ja hypyn.


func _spawn_player() -> Player:
	var player: Player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	tree.root.add_child(player)
	return player


func test_walks_path_to_end() -> void:
	var player := _spawn_player()
	var arrived := [false]
	player.arrived.connect(func(): arrived[0] = true)
	player.walk_path(PackedVector3Array([Vector3.ZERO, Vector3(1, 0, 0), Vector3(1, 0, 1)]))
	check(player.is_walking(), "hahmo lähtee liikkeelle")
	for i in 120:
		player.advance(1.0 / 60.0)
	check(not player.is_walking(), "hahmo pysähtyy perillä")
	check(arrived[0], "perille saapumisesta tulee ilmoitus")
	check(player.global_position.distance_to(Vector3(1, 0, 1)) < 0.01, "hahmo on reitin päässä")
	check(player.facing().dot(Vector3(0, 0, 1)) > 0.7, "hahmo katsoo kulkusuuntaan")
	player.free()


func test_long_walk_runs() -> void:
	var player := _spawn_player()
	player.walk_path(PackedVector3Array([Vector3.ZERO, Vector3(1, 0, 0)]))
	check_eq(player.speed(), Player.WALK_SPEED, "lyhyt matka kävellään")
	player.walk_path(PackedVector3Array([Vector3.ZERO, Vector3(4, 0, 0)]))
	check_eq(player.speed(), Player.RUN_SPEED, "pitkä matka juostaan")
	player.free()


func test_jump_stays_in_place() -> void:
	var player := _spawn_player()
	player.global_position = Vector3(0.5, 0, 0.5)
	player.jump()
	check_eq(player.jump_count, 1, "hyppy laskettu")
	check_eq(player.global_position, Vector3(0.5, 0, 0.5), "hyppy ei siirrä hahmoa")
	player.free()


func test_has_face_arms_and_legs() -> void:
	var player := _spawn_player()
	var body := player.get_node("Body")
	for part in ["Head/Face", "Head/Hair", "Head/Eye", "Head/Smile", "ArmLeft/Hand", "ArmRight/Hand",
			"LegLeft/Shoe", "LegRight/Shoe", "Torso"]:
		check(body.get_node_or_null(part) is MeshInstance3D, "hahmolla on osa %s" % part)
	player.free()


func test_arms_and_legs_swing_when_walking() -> void:
	var player := _spawn_player()
	var leg := player.get_node("Body/LegLeft") as Node3D
	var arm := player.get_node("Body/ArmLeft") as Node3D
	player.walk_path(PackedVector3Array([Vector3.ZERO, Vector3(2, 0, 0)]))
	var max_leg := 0.0
	var max_arm := 0.0
	for i in 40:
		player.advance(1.0 / 60.0)
		max_leg = maxf(max_leg, absf(leg.rotation.x))
		max_arm = maxf(max_arm, absf(arm.rotation.x))
	check(max_leg > 0.3, "jalat heiluvat kävellessä (%.2f)" % max_leg)
	check(max_arm > 0.3, "kädet heiluvat kävellessä (%.2f)" % max_arm)
	player.stop()
	for i in 60:
		player.advance(1.0 / 60.0)
	check(absf(leg.rotation.x) < 0.05, "jalat palaavat paikoilleen pysähtyessä")
	player.free()


func test_arms_go_up_when_bouncing() -> void:
	var player := _spawn_player()
	player.bounce()
	for i in 10:
		player.advance(1.0 / 60.0)
	check(player.arm_raise() > 1.0, "pompatessa kädet nousevat ylös (%.2f)" % player.arm_raise())
	for i in 90:
		player.advance(1.0 / 60.0)
	check(player.arm_raise() < 0.2, "kädet laskeutuvat pompun jälkeen")
	player.free()
