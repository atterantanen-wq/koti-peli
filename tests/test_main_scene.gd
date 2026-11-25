extends "res://tests/test_case.gd"
## Tarkistaa, että testikohtaus käynnistyy ja reagoi napautukseen.


func _spawn_main() -> Node:
	var scene: PackedScene = load("res://scenes/main/main.tscn")
	var main := scene.instantiate()
	tree.root.add_child(main)
	check(main.is_node_ready(), "kohtaus käynnistyy (_ready ajettu)")
	return main


func test_scene_has_camera_and_cube() -> void:
	var main := _spawn_main()
	var camera := main.get_node_or_null("Camera3D") as Camera3D
	check(camera != null, "kamera löytyy")
	check(main.get_node_or_null("Cube") != null, "kuutio löytyy")
	check(main.get_node_or_null("UI/InfoLabel") != null, "tekstikenttä löytyy")
	main.free()


func test_tap_changes_color() -> void:
	var main := _spawn_main()
	var cube := main.get_node("Cube") as MeshInstance3D
	var before: Color = cube.get_surface_override_material(0).albedo_color
	main.on_tap()
	var after: Color = cube.get_surface_override_material(0).albedo_color
	check(before != after, "väri vaihtuu napautuksesta")
	check_eq(main.tap_count, 1, "napautuksia laskettu")
	main.free()


func test_colors_cycle_back_to_start() -> void:
	var main := _spawn_main()
	var colors: Array = (main.get_script() as GDScript).get_script_constant_map()["COLORS"]
	for i in colors.size():
		main.on_tap()
	check_eq(main.color_index, 0, "värit kiertävät alkuun")
	main.free()
