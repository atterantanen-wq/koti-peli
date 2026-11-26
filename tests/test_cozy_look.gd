extends "res://tests/test_case.gd"
## Tunnelma ja valaistus: pehmeät varjot, auringonläikkä, tapetti, alusta ja yövalon kajo.
## (Oikeita varjoja ei käytetä: ne ovat puhelimen selaimessa raskaita.)


func _spawn_main() -> Node:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	return main


func test_soft_disc_fades_at_edges() -> void:
	var mesh := ArtKit.soft_disc()
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var center_alpha := 0.0
	var edge_alpha := 1.0
	for i in verts.size():
		var r := Vector2(verts[i].x, verts[i].z).length()
		if r < 0.01:
			center_alpha = maxf(center_alpha, colors[i].a)
		if r > 0.49:
			edge_alpha = minf(edge_alpha, colors[i].a)
	check(center_alpha > 0.9, "varjo on keskeltä tumma")
	check(edge_alpha < 0.01, "varjon reuna häipyy näkymättömiin")
	check(mesh.get_aabb().size.x < 1.01, "levyn halkaisija on 1")


func test_props_have_soft_shadows_on_floor() -> void:
	var main := _spawn_main()
	for prop in ["Bed", "ToyBox", "Basket", "Dresser", "SheepLight", "Panda"]:
		var sh := main.get_node_or_null("Room/%s/SoftShadow" % prop) as MeshInstance3D
		check(sh != null, "esineellä %s on pehmeä varjo" % prop)
		if sh != null:
			check(absf(sh.global_position.y) < 0.02, "varjo %s on lattialla (%.3f)" % [prop, sh.global_position.y])
			check(sh.global_basis.y.normalized().is_equal_approx(Vector3.UP), "varjo %s on vaakatasossa" % prop)
	var sun := main.get_node("Sun") as DirectionalLight3D
	check(not sun.shadow_enabled, "oikeat varjot ovat pois (selaimessa raskaat)")
	main.free()


func test_room_has_cozy_walls_and_base() -> void:
	var main := _spawn_main()
	var room := main.get_node("Room")
	for path in ["Wallpaper", "WallPanel", "ChairRail", "WallCap", "DioramaBase", "FloorShade",
			"PictureFrame", "Rainbow0", "PlantPot", "Rugs/PinkRug/Fringe"]:
		check(room.get_node_or_null(path) != null, "huoneessa on %s" % path)
	var paper := (room.get_node("Wallpaper") as MeshInstance3D).material_override as StandardMaterial3D
	check(paper.albedo_texture != null, "tapetissa on kuvio")
	main.free()


func test_sun_patch_by_day_and_glow_by_night() -> void:
	var main := _spawn_main()
	var day_night := main.get_node("DayNight") as DayNight
	var patch := main.get_node("Room/SunPatch") as Node3D
	var halo := main.get_node("Room/SheepLight/Visual/NightHalo") as Node3D
	check(patch.visible, "päivällä lattialla on auringonläikkä")
	check(not halo.visible, "päivällä lampaan kajo on pois")
	day_night.set_night(true)
	check(not patch.visible, "yöllä auringonläikkä katoaa")
	check(halo.visible, "yöllä lampaan ympärillä on kajo")
	day_night.set_night(false)
	check(patch.visible and not halo.visible, "aamulla aurinko palaa")
	main.free()


func test_plush_toys_look_soft() -> void:
	var main := _spawn_main()
	var panda := main.get_node("Room/Panda/Visual") as Node3D
	var found := false
	for child in panda.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).material_override is StandardMaterial3D:
			if ((child as MeshInstance3D).material_override as StandardMaterial3D).rim_enabled:
				found = true
	check(found, "pandan pinta on samettisen pehmeä")
	main.free()
