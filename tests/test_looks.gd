extends "res://tests/test_case.gd"
## Hahmon valinta (tyttö tai poika) pelin alussa ja vaatekaappi kesken pelin.


func _spawn_main() -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func _tap(control: Control, pos: Vector2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	ev.position = pos
	control._gui_input(ev)


func _top_color(art: Node) -> Color:
	var torso := art.get_node("Torso") as MeshInstance3D
	var mat := torso.material_override as StandardMaterial3D
	return mat.albedo_color


func test_game_starts_with_girl_or_boy_choice() -> void:
	var main := _spawn_main()
	var picker := main.picker as HeroPicker
	check(picker != null and picker.is_inside_tree(), "pelin alussa valitaan tyttö tai poika")
	check(main.pet == null, "lemmikkiä ei valita ennen hahmoa")
	check_eq(picker.kind_at(picker.card(0)[0]), "girl", "vasemmalla on tyttö")
	check_eq(picker.kind_at(picker.card(1)[0]), "boy", "oikealla on poika")
	picker._time = CardPicker.INPUT_DELAY
	check(not main.wardrobe.visible, "vaatekaappi ei näy alun valintojen aikana")
	_tap(picker, picker.card(0)[0])
	var player := main.get_node("Player") as Player
	check_eq(player.hero(), "girl", "napautus tytön kuvaan tekee hahmosta tytön")
	check_eq(player.outfit(), "dress", "tytöllä on aluksi mekko")
	check(main.picker is PetPicker, "seuraavaksi valitaan lemmikki")
	# Sama napautus (iPhonella myös hiirenä) ei saa heti valita lemmikkiä.
	_tap(main.picker, main.picker.card(0)[0])
	check(main.pet == null, "hahmon valinnan napautus ei valitse samalla lemmikkiä")
	main.picker._time = CardPicker.INPUT_DELAY
	_tap(main.picker, main.picker.card(1)[0])
	check(main.pet != null and main.pet.kind == "dog", "lemmikin valinta toimii hahmon jälkeen")
	check(main.wardrobe.visible, "vaatekaappinappi näkyy, kun valinnat on tehty")
	main.free()


func test_girl_and_boy_look_different() -> void:
	var girl := PlayerArt.new()
	girl.hero = "girl"
	tree.root.add_child(girl)
	var boy := PlayerArt.new()
	tree.root.add_child(boy)
	check(girl.get_node_or_null("Head/Pigtail") != null, "tytöllä on saparot")
	check(girl.get_node_or_null("Head/Curl") == null, "tytöllä ei ole pojan kiharaa")
	check(boy.get_node_or_null("Head/Curl") != null, "pojalla on kihara")
	check(boy.get_node_or_null("Head/Pigtail") == null, "pojalla ei ole saparoita")
	girl.free()
	boy.free()


func test_every_outfit_has_limbs_and_own_colors() -> void:
	var art := PlayerArt.new()
	tree.root.add_child(art)
	var colors := []
	for outfit in PlayerArt.OUTFITS:
		art.dress_up("boy", outfit)
		for part in ["Torso", "Head/Face", "ArmLeft/Hand", "ArmRight/Hand", "LegLeft/Shoe", "LegRight/Shoe"]:
			check(art.get_node_or_null(part) != null, "%s: osa %s löytyy" % [outfit, part])
		var mat := (art.get_node("Torso") as MeshInstance3D).material_override as StandardMaterial3D
		var tex := mat.albedo_texture
		colors.append(mat.albedo_color if tex == null else tex.get_image().get_pixel(0, 0))
	check(art.get_node_or_null("Skirt") == null, "pyjamassa ei ole hametta")
	art.dress_up("boy", "dress")
	check(art.get_node_or_null("Skirt") != null, "mekossa on helma")
	for i in colors.size():
		for j in range(i + 1, colors.size()):
			check(colors[i] != colors[j], "asut %s ja %s näyttävät erilaisilta" % [PlayerArt.OUTFITS[i],
					PlayerArt.OUTFITS[j]])
	art.dress_up("boy", "nonsense")
	check_eq(art.outfit, "dress", "tuntematon asu ei muuta vaatteita")
	art.free()


func test_wardrobe_changes_clothes_mid_game() -> void:
	var main := _spawn_main()
	main.choose_hero("boy")
	main.choose_pet("cat")
	var player := main.get_node("Player") as Player
	var w := main.wardrobe as Wardrobe
	check(w.visible and not w.is_open, "vaatekaappi on aluksi kiinni")
	check(not w._has_point(Vector2(640, 360)), "suljettu vaatekaappi ei vie napautuksia pelistä")
	check(w._has_point(w.button()[0]), "paitanappi ottaa napautuksen")
	_tap(w, w.button()[0])
	check(w.is_open, "paitanappi avaa vaatekaapin")
	check_eq(main.tap_count, 0, "napin napautus ei liikuta hahmoa")
	# Raitapaita (kortti 4).
	var arm_before := player.body.get_node("ArmLeft")
	_tap(w, w.card(4)[0])
	check_eq(player.outfit(), "stripes", "kortin napautus vaihtaa asun")
	check(w.is_open, "vaatekaappi jää auki, jotta voi kokeilla lisää")
	check(w.is_selected(4) and not w.is_selected(2), "valittu asu näkyy valittuna")
	check(player.body.get_node_or_null("LegLeft/Shorts") != null, "raitapaidan kanssa on shortsit")
	check(player.body.get_node_or_null("ArmLeft") != arm_before, "hahmo puettiin uudelleen")
	# Tyttö (kortti 0): asu pysyy samana.
	_tap(w, w.card(0)[0])
	check_eq(player.hero(), "girl", "kesken pelin voi vaihtaa tytöksi")
	check_eq(player.outfit(), "stripes", "asu säilyy, kun vaihtaa tytöksi")
	# Napautus valikon ulkopuolelle sulkee sen.
	_tap(w, Vector2(640, 200))
	check(not w.is_open, "napautus muualle sulkee vaatekaapin")
	check_eq(main.tap_count, 0, "sulkeva napautus ei liikuta hahmoa")
	main.free()


func test_dressing_up_keeps_animation_working() -> void:
	var player: Player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	tree.root.add_child(player)
	player.dress_up("girl", "pajamas")
	check_eq(player.body.get_children().filter(func(n): return n.name == "ArmLeft").size(), 1,
			"vanhat kädet poistettiin")
	player.bounce()
	for i in 10:
		player.advance(1.0 / 30.0)
	check(player.arm_raise() > 0.5, "kädet nousevat pompussa myös uusissa vaatteissa")
	player.free()


func test_wardrobe_pictures_are_on_screen() -> void:
	var main := _spawn_main()
	var w := main.wardrobe as Wardrobe
	var screen := Rect2(Vector2.ZERO, Vector2(1280, 720))
	w.size = screen.size
	check(screen.has_point(w.button()[0]), "paitanappi on ruudulla")
	for i in Wardrobe.ITEMS.size():
		var c: Array = w.card(i)
		check(screen.has_point(c[0] - Vector2(c[1], c[1])) and screen.has_point(c[0] + Vector2(c[1], c[1])),
				"kortti %d mahtuu ruudulle" % i)
		if i > 0:
			var prev: Array = w.card(i - 1)
			check((c[0] as Vector2).distance_to(prev[0]) > c[1] + prev[1], "kortit %d ja %d eivät mene päällekkäin" % [i - 1, i])
	main.free()
