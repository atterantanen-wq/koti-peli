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
