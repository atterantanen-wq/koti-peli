extends "res://tests/test_case.gd"
## Tarkistaa esineiden temput: sängyllä pomppiminen, panda, siipiotus ja reaktiopalikat.

const STEP := 1.0 / 60.0


func _spawn_main() -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func _walk_until_arrived(main: Node) -> void:
	var player := main.get_node("Player") as Player
	for i in 900:
		player.advance(STEP)
		if not player.is_walking() and not player.is_hopping():
			break


func _prop_screen_pos(main: Node, name: String) -> Vector2:
	var camera := main.get_node("Camera3D") as Camera3D
	var inter := Interactable.of(main.get_node("Room/" + name))
	return camera.unproject_position(inter.focus_position())


func _effect_count(main: Node) -> int:
	return main.get_node("Effects").get_child_count()


func _touch(index: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = pos
	ev.pressed = pressed
	return ev


func test_every_interactable_has_several_tricks() -> void:
	var main := _spawn_main()
	var count := 0
	for node in tree.get_nodes_in_group("prop"):
		var inter := Interactable.of(node)
		if inter == null:
			continue
		count += 1
		check(inter.variants.size() >= 2, "%s osaa vähintään kaksi temppua" % node.name)
		for set in inter.variants:
			check(set != null and not set.reactions.is_empty(), "%s: temppu ei ole tyhjä" % node.name)
			for r in set.reactions:
				check(r != null, "%s: reaktio latautuu" % node.name)
				if r != null and not r is FloatEffectReaction and not r is PlayerActionReaction \
						and not r is FlapReaction:
					check(r.target_node(ReactionContext.new(node, null, null)) != null,
							"%s: reaktion kohde %s löytyy" % [node.name, r.target])
			if set != null:
				check(set.duration() < 10.0, "%s: temppu kestää alle 10 s" % node.name)
	check(count >= 3, "huoneessa on ainakin kolme heräävää esinettä (%d)" % count)
	main.free()


func test_bed_climb_and_bounce() -> void:
	var main := _spawn_main()
	var player := main.get_node("Player") as Player
	var bed := Interactable.of(main.get_node("Room/Bed"))
	var kind: String = main.tap_at_screen(_prop_screen_pos(main, "Bed"))
	check_eq(kind, "prop", "napautus sänkyyn osuu sänkyyn")
	_walk_until_arrived(main)
	check(main.climbed == bed, "hahmo kiipeää sängylle")
	check(player.global_position.y > 0.4, "hahmo on sängyn päällä (y %.2f)" % player.global_position.y)
	var jumps := player.jump_count
	main.tap_at_screen(_prop_screen_pos(main, "Bed"))
	check_eq(player.jump_count, jumps + 1, "napautus sänkyyn on uusi pomppu")
	check_eq(bed.use_count, 1, "sänky reagoi")
	# Napautus hahmoon sängyllä on myös pomppu.
	var camera := main.get_node("Camera3D") as Camera3D
	main.tap_at_screen(camera.unproject_position(player.global_position + Vector3(0, 0.5, 0)))
	check_eq(player.jump_count, jumps + 2, "napautus hahmoon sängyllä on pomppu")
	check_eq(bed.use_count, 2, "sänky reagoi toisen kerran")
	check(bed.use_count % bed.variants.size() != 0 or bed.variants.size() <= 2, "temput vuorottelevat")
	# Napautus lattiaan: alas sängyltä ja kävelemään.
	var goal := Vector3(1.0, 0, 1.4)
	main.tap_at_screen(camera.unproject_position(goal))
	check(main.climbed == null, "hahmo hyppää alas sängyltä")
	check(absf(player.global_position.y) < 0.01, "hahmo on lattialla")
	check(main.grid.is_walkable(player.global_position), "hahmo laskeutuu vapaalle paikalle")
	check(player.is_walking(), "hahmo lähtee kohti napautusta")
	_walk_until_arrived(main)
	check(player.global_position.distance_to(goal) < 0.25, "hahmo pääsee perille alas hypyn jälkeen")
	main.free()


func test_panda_hug_and_hearts() -> void:
	var main := _spawn_main()
	var player := main.get_node("Player") as Player
	var panda := Interactable.of(main.get_node("Room/Panda"))
	main.tap_at_screen(_prop_screen_pos(main, "Panda"))
	_walk_until_arrived(main)
	check_eq(player.hug_count, 1, "hahmo halaa pandaa")
	check_eq(panda.use_count, 1, "panda reagoi")
	check(main.climbed == null, "hahmo ei kiipeä pandan päälle")
	check(main.tried.has("Panda"), "panda on merkitty kokeilluksi")
	check(_effect_count(main) >= 3, "pandan yläpuolelle nousee sydämiä (%d)" % _effect_count(main))
	var symbol := main.get_node("Effects").get_child(0) as FloatingSymbol
	check(symbol != null and symbol.shape == "heart", "tehoste on sydän")
	# Toinen kerta: kuperkeikka.
	main.tap_at_screen(_prop_screen_pos(main, "Panda"))
	_walk_until_arrived(main)
	check_eq(panda.use_count, 2, "panda tekee toisen tempun")
	check(panda.is_playing(), "kuperkeikka on käynnissä")
	main.free()


func test_creature_flies_and_returns() -> void:
	var main := _spawn_main()
	var creature := Interactable.of(main.get_node("Room/WingCreature"))
	var visual := main.get_node("Room/WingCreature/Visual") as Node3D
	var wing := main.get_node("Room/WingCreature/Visual/WingLeft") as Node3D
	var rest := visual.transform
	var wing_rest := wing.transform
	var ctx := ReactionContext.new(creature.prop(), main.get_node("Player"), main.get_node("Effects"))
	check_eq(creature.use(ctx), 0, "ensin otus herää ja lepattaa")
	check_eq(creature.use(ctx), 1, "toisella kerralla otus lentää")
	var flight: FlyPathReaction
	for r in creature.variants[1].reactions:
		if r is FlyPathReaction:
			flight = r
	check(flight != null and flight.points.size() >= 4, "lentoreitti kiertää huoneen")
	var highest := 0.0
	var farthest := 0.0
	var wing_moved := false
	# Ajetaan animaatioita eteenpäin ja seurataan, minne otus lentää.
	for i in 300:
		for t in creature._tweens:
			if t.is_valid():
				t.custom_step(STEP)
		highest = maxf(highest, visual.position.y - rest.origin.y)
		farthest = maxf(farthest, visual.position.distance_to(rest.origin))
		wing_moved = wing_moved or not wing.transform.is_equal_approx(wing_rest)
	check(highest > 0.7, "otus lentää ylös (%.2f m)" % highest)
	check(farthest > 2.0, "otus lentää kauas huoneeseen (%.2f m)" % farthest)
	check(wing_moved, "siivet lepattavat")
	for i in 120:
		for t in creature._tweens:
			if t.is_valid():
				t.custom_step(STEP)
	check(visual.transform.is_equal_approx(rest), "otus palaa sängylle")
	check(wing.transform.is_equal_approx(wing_rest), "siivet palaavat paikoilleen")
	main.free()


func test_new_tap_restarts_trick_cleanly() -> void:
	var main := _spawn_main()
	var panda := Interactable.of(main.get_node("Room/Panda"))
	var visual := main.get_node("Room/Panda/Visual") as Node3D
	var rest := visual.transform
	var ctx := ReactionContext.new(panda.prop(), main.get_node("Player"), main.get_node("Effects"))
	panda.use(ctx)
	panda.use(ctx)
	for i in 20:
		for t in panda._tweens:
			if t.is_valid():
				t.custom_step(STEP)
	check(not visual.transform.is_equal_approx(rest), "kuperkeikka liikuttaa pandaa")
	panda.use(ctx)
	check(visual.transform.is_equal_approx(rest), "uusi napautus palauttaa pandan ensin paikalleen")
	main.free()


func test_forgiving_tap_near_toy() -> void:
	var main := _spawn_main()
	var pos := _prop_screen_pos(main, "Panda")
	# Vähän ohi pandasta, sängyn viereen lattialle.
	var kind: String = main.tap_at_screen(pos + Vector2(45, 30))
	check_eq(kind, "prop", "napautus pandan vieressä kelpaa")
	main.free()


func test_iphone_touch_on_bed() -> void:
	# Sama kuin iPhonessa: iso sormitunniste ja kosketustapahtuma.
	var main := _spawn_main()
	var pos := _prop_screen_pos(main, "Bed")
	main._unhandled_input(_touch(1730593021, pos, true))
	main._unhandled_input(_touch(1730593021, pos, false))
	check_eq(main.last_tap_kind, "prop", "iPhone-kosketus sänkyyn osuu sänkyyn")
	_walk_until_arrived(main)
	check(main.climbed != null, "hahmo kiipeää sängylle")
	main._unhandled_input(_touch(1730593099, pos, true))
	main._unhandled_input(_touch(1730593099, pos, false))
	check_eq(Interactable.of(main.get_node("Room/Bed")).use_count, 1, "seuraava kosketus pomputtaa")
	main.free()


func test_drag_over_toy_does_not_trigger_it() -> void:
	var main := _spawn_main()
	var panda := Interactable.of(main.get_node("Room/Panda"))
	var kind: String = main._walk_towards_screen(_prop_screen_pos(main, "Panda"), false)
	check_eq(kind, "floor", "liu'utus pandan yli vain kävelee")
	_walk_until_arrived(main)
	check_eq(panda.use_count, 0, "panda ei reagoi liu'utukseen")
	main.free()


func test_symbol_shapes() -> void:
	for shape in ["heart", "star", "note"]:
		var mesh := FloatingSymbol.shape_mesh(shape)
		check(mesh.get_surface_count() == 1, "%s-kuvio on olemassa" % shape)
		var aabb := mesh.get_aabb()
		check(aabb.size.x > 0.5 and aabb.size.x < 1.2 and aabb.size.z < 0.01,
				"%s on litteä ja noin metrin kokoinen (%s)" % [shape, aabb.size])


func test_player_hop_onto_and_off() -> void:
	var player: Player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	tree.root.add_child(player)
	player.hop_to(Vector3(1, 0.5, 0))
	check_eq(player.global_position, Vector3(1, 0.5, 0), "hahmo on heti hypyn kohteessa")
	check(player.is_hopping(), "hyppy on kesken")
	player.walk_path(PackedVector3Array([Vector3(1, 0.5, 0), Vector3(2, 0.5, 0)]))
	player.advance(0.1)
	check_eq(player.global_position, Vector3(1, 0.5, 0), "hahmo ei kävele kesken hypyn")
	for i in 120:
		player.advance(STEP)
	check(player.global_position.distance_to(Vector3(2, 0.5, 0)) < 0.01, "hypyn jälkeen hahmo kävelee")
	player.do_action("hug")
	check_eq(player.hug_count, 1, "halaus lasketaan")
	player.free()


func test_tap_toy_next_to_player_on_bed() -> void:
	# Hahmo pomppii sängyllä ja otus on aivan vieressä: napautus otukseen herättää otuksen.
	var main := _spawn_main()
	main.climb_onto(Interactable.of(main.get_node("Room/Bed")))
	var creature := Interactable.of(main.get_node("Room/WingCreature"))
	main.tap_at_screen(_prop_screen_pos(main, "WingCreature"))
	check(main.climbed == null, "hahmo hyppää alas sängyltä")
	_walk_until_arrived(main)
	check_eq(creature.use_count, 1, "otus herää")
	main.free()
