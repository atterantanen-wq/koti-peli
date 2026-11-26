extends "res://tests/test_case.gd"
## Tarkistaa lastenhuoneen muut esineet: lammasyövalo, juna, nukkekoti, lelulaatikko, viirinauha.

const STEP := 1.0 / 60.0
const ALL_PROPS := ["Bed", "Panda", "WingCreature", "SheepLight", "Train", "Dollhouse", "ToyBox", "Bunting"]


func _spawn_main() -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func _ctx(main: Node, name: String) -> ReactionContext:
	return ReactionContext.new(main.get_node("Room/" + name), main.get_node("Player"), main.get_node("Effects"))


## Ajaa esineen animaatioita eteenpäin (testit eivät odota oikeaa aikaa).
func _run(inter: Interactable, seconds: float, each: Callable = Callable()) -> void:
	for i in int(seconds / STEP):
		for t in inter._tweens:
			if t.is_valid():
				t.custom_step(STEP)
		if each.is_valid():
			each.call()


func test_every_prop_can_be_tapped_and_reached() -> void:
	# Jokaiseen esineeseen voi napauttaa (toinen esine ei ole edessä) ja hahmo pääsee viereen.
	var main := _spawn_main()
	var camera := main.get_node("Camera3D") as Camera3D
	var player := main.get_node("Player") as Player
	for name in ALL_PROPS:
		var prop := main.get_node("Room/" + name) as Node3D
		var inter := Interactable.of(prop)
		check(inter != null, "%s herää eloon (Interactable)" % name)
		if inter == null:
			continue
		var screen := camera.unproject_position(inter.focus_position())
		var hit: Dictionary = main.pick(screen)
		check(main._prop_of(hit.get("collider")) == prop, "napautus osuu esineeseen %s" % name)
		var goal: Vector3 = main.stand_point_for(prop)
		check(main.grid.is_walkable(goal), "esineen %s vieressä on tilaa seistä" % name)
		var footprint: Rect2 = WalkGrid.obstacle_rects(prop)[0]
		var g := Vector2(goal.x, goal.z)
		var gap := g.distance_to(g.clamp(footprint.position, footprint.end))
		check(gap < 0.9, "hahmo pääsee lähelle esinettä %s (väli %.2f m)" % [name, gap])
		var path: PackedVector3Array = main.grid.find_path(player.global_position, goal)
		check(path.size() >= 1, "reitti esineen %s luo löytyy" % name)
	main.free()


func test_sheep_light_toggles_day_and_night() -> void:
	var main := _spawn_main()
	var day_night := main.get_node("DayNight") as DayNight
	var glow := main.get_node("Room/SheepLight/NightGlow") as Node3D
	var sheep := Interactable.of(main.get_node("Room/SheepLight"))
	check(not day_night.is_night and not glow.visible, "peli alkaa päivällä")
	sheep.use(_ctx(main, "SheepLight"))
	check(day_night.is_night, "lammas vaihtaa yöksi")
	check(glow.visible, "yövalo syttyy")
	var stars := tree.get_nodes_in_group(DayNight.NIGHT_LIGHT_GROUP)
	check(stars.size() > 5, "yöllä seinille syttyy tähtiä (%d)" % stars.size())
	day_night._tween.custom_step(2.0)
	var env := (main.get_node("WorldEnvironment") as WorldEnvironment).environment
	check(env.ambient_light_energy > 0.2, "yö on lempeä eikä pimeä")
	check((main.get_node("Sun") as DirectionalLight3D).light_energy < 0.3, "aurinko himmenee yöllä")
	sheep.use(_ctx(main, "SheepLight"))
	day_night._tween.custom_step(2.0)
	check(not day_night.is_night and not glow.visible, "toinen napautus palauttaa päivän")
	check((main.get_node("Sun") as DirectionalLight3D).light_energy > 0.5, "aurinko palaa")
	main.free()


func test_train_rides_around_room_on_tracks() -> void:
	var main := _spawn_main()
	var train := Interactable.of(main.get_node("Room/Train"))
	var body := main.get_node("Room/Train/Visual/Train") as Node3D
	var tracks := main.get_node("Room/Train/Visual/Tracks") as Node3D
	var rest := body.global_transform
	check_eq(train.use(_ctx(main, "Train")), 0, "ensin juna puksuttaa lipaston päällä")
	_run(train, 2.0)
	check(body.global_transform.is_equal_approx(rest), "juna palaa paikalleen")
	check_eq(train.use(_ctx(main, "Train")), 1, "toisella kerralla juna lähtee kierrokselle")
	var lowest := [INF]
	var seen_tracks := [false]
	var room := Rect2(-3, -2.5, 6, 5)
	var inside := [true]
	_run(train, 10.0, func() -> void:
		var p := body.global_position
		lowest[0] = minf(lowest[0], p.y)
		seen_tracks[0] = seen_tracks[0] or tracks.visible
		inside[0] = inside[0] and room.has_point(Vector2(p.x, p.z)))
	check(lowest[0] < 0.05, "juna ajaa lattialla (%.2f)" % lowest[0])
	check(seen_tracks[0], "lattialle ilmestyy raiteet")
	check(inside[0], "juna pysyy huoneen sisällä")
	check(not tracks.visible, "raiteet katoavat lopuksi")
	check(body.global_transform.is_equal_approx(rest), "juna palaa lipaston päälle")
	main.free()


func test_dollhouse_lights_and_residents() -> void:
	var main := _spawn_main()
	var house := Interactable.of(main.get_node("Room/Dollhouse"))
	var light := main.get_node("Room/Dollhouse/Visual/Light0") as Node3D
	var resident := main.get_node("Room/Dollhouse/Visual/ResidentA") as Node3D
	check(not light.visible, "ikkunat ovat aluksi pimeinä")
	house.use(_ctx(main, "Dollhouse"))
	_run(house, 0.5)
	check(light.visible, "ikkunoihin syttyy valo")
	check(not resident.visible, "ensimmäisellä kerralla vain valot")
	_run(house, 4.0)
	check(not light.visible, "valot sammuvat hetken päästä")
	house.use(_ctx(main, "Dollhouse"))
	_run(house, 1.2)
	check(resident.visible, "toisella kerralla asukas kurkistaa ikkunasta")
	_run(house, 4.0)
	check(not resident.visible, "asukas menee takaisin sisään")
	main.free()


func test_toy_box_toys_jump_out_and_back() -> void:
	var main := _spawn_main()
	var box := Interactable.of(main.get_node("Room/ToyBox"))
	var ball := main.get_node("Room/ToyBox/Visual/Toys/Ball") as Node3D
	var lid := main.get_node("Room/ToyBox/Visual/LidPivot") as Node3D
	var rest := ball.global_transform
	var lid_rest := lid.transform
	for variant in 2:
		box.use(_ctx(main, "ToyBox"))
		var lowest := [INF]
		var farthest := [0.0]
		var lid_open := [false]
		_run(box, 5.0, func() -> void:
			if ball.visible:
				lowest[0] = minf(lowest[0], ball.global_position.y)
				farthest[0] = maxf(farthest[0], ball.global_position.distance_to(rest.origin))
			lid_open[0] = lid_open[0] or not lid.transform.is_equal_approx(lid_rest))
		check(lid_open[0], "kansi aukeaa (%d)" % variant)
		check(lowest[0] < 0.12, "pallo pomppaa lattialle (%.2f) (%d)" % [lowest[0], variant])
		check(farthest[0] > 0.5, "pallo pomppaa laatikon eteen (%.2f) (%d)" % [farthest[0], variant])
		check(not ball.visible, "pallo menee takaisin laatikkoon (%d)" % variant)
		check(ball.global_transform.is_equal_approx(rest), "pallo on paikallaan laatikossa (%d)" % variant)
		check(lid.transform.is_equal_approx(lid_rest), "kansi sulkeutuu (%d)" % variant)
	main.free()


func test_bunting_waves_and_changes_colors() -> void:
	var main := _spawn_main()
	var bunting := Interactable.of(main.get_node("Room/Bunting"))
	var flag := main.get_node("Room/Bunting/Visual/Flag3") as Node3D
	var mesh := main.get_node("Room/Bunting/Visual/Flag3/Mesh") as MeshInstance3D
	var other := main.get_node("Room/Bunting/Visual/Flag0/Mesh") as MeshInstance3D
	var rest := flag.transform
	var color := (mesh.get_surface_override_material(0) as StandardMaterial3D).albedo_color
	bunting.use(_ctx(main, "Bunting"))
	var moved := [false]
	_run(bunting, 2.5, func() -> void: moved[0] = moved[0] or not flag.transform.is_equal_approx(rest))
	check(moved[0], "viiri heilahtaa")
	check(flag.transform.is_equal_approx(rest), "viiri asettuu paikalleen")
	bunting.use(_ctx(main, "Bunting"))
	var changed := [false]
	_run(bunting, 0.6)
	var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
	changed[0] = not mat.albedo_color.is_equal_approx(color)
	check(changed[0], "viirit vaihtavat väriä")
	_run(bunting, 4.0)
	check(mat.albedo_color.is_equal_approx(color), "viiri palaa omaan väriinsä")
	check(mat != other.get_surface_override_material(0), "jokaisella viirillä on oma väri")
	main.free()
