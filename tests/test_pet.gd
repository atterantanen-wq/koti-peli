extends "res://tests/test_case.gd"
## Lemmikki: valinta pelin alussa, seuraaminen, silitys, omat touhut, junan jahtaus ja yöuni.

const STEP := 1.0 / 30.0


func _spawn_main(kind := "cat") -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	if kind != "":
		main.choose_pet(kind)
		(main.pet as Pet).rng.seed = 3
	return main


## Ajaa hahmoa ja lemmikkiä eteenpäin. stop: lopetetaan, kun se palauttaa true.
func _sim(main: Node, seconds: float, stop := Callable()) -> bool:
	var player := main.get_node("Player") as Player
	var pet := main.pet as Pet
	for i in int(seconds / STEP):
		player.advance(STEP)
		pet.advance(STEP)
		if stop.is_valid() and stop.call():
			return true
	return false


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func test_picker_shows_cat_and_dog_pictures() -> void:
	var main := _spawn_main("")
	var picker := main.picker as PetPicker
	check(picker != null and picker.is_inside_tree(), "valintaruutu näkyy pelin alussa")
	check(main.pet == null, "lemmikkiä ei ole ennen valintaa")
	check_eq(picker.kind_at(picker.card(0)[0]), "cat", "vasemmalla on kissa")
	check_eq(picker.kind_at(picker.card(1)[0]), "dog", "oikealla on koira")
	check_eq(picker.kind_at(Vector2(640, 40)), "", "tyhjä kohta ei valitse")
	check(picker.mouse_filter == Control.MOUSE_FILTER_STOP, "valintaruutu ottaa napautukset itselleen")
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	ev.position = picker.card(1)[0]
	picker._gui_input(ev)
	var pet := main.pet as Pet
	check(pet != null and pet.kind == "dog", "napautus koiran kuvaan valitsee koiran")
	# Toinen napautus ei vaihda lemmikkiä.
	ev.position = picker.card(0)[0]
	picker._gui_input(ev)
	check(main.pet == pet and pet.kind == "dog", "valinta tehdään vain kerran")
	main.free()


func test_both_pets_have_body_parts() -> void:
	for kind in ["cat", "dog"]:
		var art := PetArt.build(kind)
		for part in ["Body", "Body/Head", "Body/Head/Mouth", "Body/Tail", "Body/Head/EarL",
				"Body/Head/EarR", "LegFL", "LegFR", "LegBL", "LegBR"]:
			check(art.get_node_or_null(part) != null, "%s: osa %s löytyy" % [kind, part])
		var meshes := art.find_children("*", "MeshInstance3D", true, false).size()
		check(meshes > 20, "%s on tehty monesta osasta (%d)" % [kind, meshes])
		art.free()
	var cat := PetArt.build("cat")
	var dog := PetArt.build("dog")
	check(cat.get_node_or_null("Body/Collar") == null and dog.get_node_or_null("Body/Collar") != null,
			"koiralla on panta, kissalla ei")
	check((cat.get_node("Body/Head/EarL/Ear") as MeshInstance3D).mesh is CylinderMesh,
			"kissalla on suipot korvat")
	cat.free()
	dog.free()
	check(FloatingSymbol.shape_mesh("z").get_surface_count() > 0, "unen Z-kirjain piirtyy")


func test_pet_appears_next_to_player() -> void:
	var main := _spawn_main()
	var pet := main.pet as Pet
	var player := main.get_node("Player") as Player
	check(pet.is_inside_tree(), "lemmikki on huoneessa")
	check(pet.get_node_or_null("Shadow") != null, "lemmikillä on varjo")
	check(main.grid.is_walkable(pet.global_position), "lemmikki on vapaalla paikalla")
	check(_flat(pet.global_position, player.global_position) < 1.0, "lemmikki on hahmon vieressä")
	main.free()


func test_pet_follows_player_and_sits() -> void:
	var main := _spawn_main()
	var pet := main.pet as Pet
	var player := main.get_node("Player") as Player
	main.walk_to(Vector3(2.2, 0, 1.8))
	var walked := _sim(main, 1.0, func() -> bool: return pet.is_moving())
	check(walked, "lemmikki lähtee hahmon perään")
	_sim(main, 6.0, func() -> bool: return not player.is_walking() and not pet.is_moving())
	_sim(main, 1.0)
	check(_flat(pet.global_position, player.global_position) < Pet.SIT_RADIUS + 0.1,
			"lemmikki tulee hahmon viereen (%.2f m)" % _flat(pet.global_position, player.global_position))
	check(_flat(pet.global_position, player.global_position) > 0.3, "lemmikki ei mene hahmon päälle")
	check_eq(pet.activity, "follow", "lemmikki istuu ja odottaa")
	check(pet._sit > 0.8, "lemmikki istahtaa")
	main.free()


func test_tap_on_pet_pets_it() -> void:
	for kind in ["cat", "dog"]:
		var main := _spawn_main(kind)
		var pet := main.pet as Pet
		var player := main.get_node("Player") as Player
		var camera := main.get_node("Camera3D") as FollowCamera
		pet.global_position = main.grid.nearest_walkable(player.global_position + Vector3(1.2, 0, 0.2))
		camera.snap()
		var kind_tapped: String = main.tap_at_screen(camera.unproject_position(pet.focus_position()))
		check_eq(kind_tapped, "pet", "%s: napautus lemmikkiin" % kind)
		check_eq(pet.activity, "wait", "%s odottaa silittäjää" % kind)
		_sim(main, 3.0, func() -> bool: return pet.activity == "petted")
		check_eq(pet.activity, "petted", "%s: hahmo silittää" % kind)
		check_eq(pet.pet_count, 1, "%s: silityksiä 1" % kind)
		check_eq(player.last_action, "pet", "%s: hahmo tekee silitysliikkeen" % kind)
		check(_flat(pet.global_position, player.global_position) < 0.75, "%s: hahmo on lemmikin vieressä" % kind)
		check(main.get_node("Effects").get_child_count() > 0, "%s: sydämiä nousee" % kind)
		var rolled := [0.0]
		var hopped := [false]
		_sim(main, Pet.PET_TIME + 0.5, func() -> bool:
			rolled[0] = maxf(rolled[0], absf(pet.art.rotation.z))
			hopped[0] = hopped[0] or pet.is_hopping()
			return pet.activity != "petted")
		if kind == "cat":
			check(rolled[0] > 0.8, "kissa kieriskelee (%.2f)" % rolled[0])
		else:
			check(hopped[0], "koira hyppii")
		check_eq(pet.activity, "follow", "%s: silityksen jälkeen lemmikki jatkaa seuraamista" % kind)
		main.free()


func test_tap_on_player_still_jumps_with_pet_near() -> void:
	var main := _spawn_main()
	var player := main.get_node("Player") as Player
	var camera := main.get_node("Camera3D") as FollowCamera
	camera.snap()
	var tapped: String = main.tap_at_screen(camera.unproject_position(player.global_position + Vector3(0, 0.5, 0)))
	check_eq(tapped, "player", "hahmon napautus hyppää, vaikka lemmikki on vieressä")
	main.free()


func test_pet_finds_things_to_do_when_player_waits() -> void:
	var main := _spawn_main()
	var pet := main.pet as Pet
	var seen := {}
	pet.activity_changed.connect(func(a: String) -> void: seen[a] = true)
	_sim(main, 40.0)
	var own := 0
	for a in Pet.ACTIVITIES:
		if seen.has(a):
			own += 1
	check(own >= 3, "lemmikki keksii monenlaista tekemistä (%s)" % str(seen.keys()))
	main.free()


func test_every_activity_finishes() -> void:
	for a in Pet.ACTIVITIES:
		var main := _spawn_main()
		var pet := main.pet as Pet
		var lid := main.get_node("Room/ToyBox/Visual/LidPivot") as Node3D
		var lid_rest := lid.rotation.x
		var info := {"bed": false, "lid": 0.0, "curl": 0.0, "yawn": false, "spin": 0.0}
		var last_yaw := [pet.rotation.y]
		pet.start(a)
		var done := _sim(main, 20.0, func() -> bool:
			info["bed"] = info["bed"] or pet.on_bed
			info["lid"] = maxf(info["lid"], absf(lid.rotation.x - lid_rest))
			info["curl"] = maxf(info["curl"], pet._curl)
			info["yawn"] = info["yawn"] or (pet.art.get_node("Body/Head/Mouth") as Node3D).visible
			info["spin"] += absf(angle_difference(last_yaw[0], pet.rotation.y))
			last_yaw[0] = pet.rotation.y
			return pet.activity == "follow")
		check(done, "touhu %s loppuu ja lemmikki palaa hahmon luo" % a)
		match a:
			"play_bed": check(info["bed"], "lemmikki hyppää sängylle pomppimaan")
			"play_box": check(info["lid"] > 0.5, "lemmikki raottaa lelulaatikon kantta")
			"nap": check(info["curl"] > 0.8, "lemmikki käpertyy matolle nukkumaan")
			"yawn": check(info["yawn"], "lemmikki haukottelee")
			"tail": check(info["spin"] > TAU, "lemmikki pyörii häntänsä perässä")
		check(absf(lid.rotation.x - lid_rest) < 0.01, "%s: lelulaatikon kansi on taas kiinni" % a)
		check(not pet.on_bed, "%s: lemmikki on lopuksi lattialla" % a)
		main.free()


func test_pet_leaves_activity_when_player_walks_away() -> void:
	var main := _spawn_main()
	var pet := main.pet as Pet
	pet.start("nap")
	_sim(main, 4.0)
	main.walk_to(Vector3(2.4, 0, 1.8))
	_sim(main, 0.5)
	check_eq(pet.activity, "follow", "lemmikki herää ja lähtee hahmon perään")
	main.free()


func test_pet_chases_train() -> void:
	var main := _spawn_main()
	var pet := main.pet as Pet
	var train := Interactable.of(main.get_node("Room/Train"))
	main._use(train)
	check_eq(pet.activity, "chase_train", "lemmikki lähtee jahtaamaan junaa")
	var moved := _sim(main, 2.0, func() -> bool: return pet.is_moving())
	check(moved, "lemmikki juoksee junan perään")
	var back := _sim(main, 20.0, func() -> bool: return pet.activity == "follow")
	check(back, "junan pysähdyttyä lemmikki palaa hahmon luo")
	main.free()


func test_pet_sleeps_at_foot_of_bed_at_night() -> void:
	var main := _spawn_main("dog")
	var pet := main.pet as Pet
	var day_night := main.get_node("DayNight") as DayNight
	var bed := main.get_node("Room/Bed") as Node3D
	day_night.set_night(true)
	var slept := _sim(main, 15.0, func() -> bool: return pet.on_bed and pet._curl > 0.8)
	check(slept, "yöllä lemmikki käpertyy sängylle")
	check_eq(pet.activity, "night", "lemmikki nukkuu")
	var foot := bed.to_global(Pet.BED_FOOT)
	check(pet.global_position.distance_to(foot) < 0.05, "lemmikki on sängyn jalkopäässä")
	# Hahmon kävely ei herätä.
	main.walk_to(Vector3(2.0, 0, 1.5))
	_sim(main, 2.0)
	check(pet.on_bed and pet.activity == "night", "yöllä lemmikki jää nukkumaan")
	pet.pet_me()
	check_eq(pet.activity, "night", "silitys ei herätä lemmikkiä yöllä")
	day_night.set_night(false)
	var woke := _sim(main, 4.0, func() -> bool: return not pet.on_bed)
	check(woke, "aamulla lemmikki hyppää alas sängyltä")
	check_eq(pet.activity, "follow", "aamulla lemmikki seuraa taas hahmoa")
	main.free()
