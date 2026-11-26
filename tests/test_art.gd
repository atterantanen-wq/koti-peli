extends "res://tests/test_case.gd"
## Tarkistaa koodilla tehdyn grafiikan: pehmeät muodot, kiehkurat ja kuviot.


func test_soft_box_has_requested_size() -> void:
	var mesh := ArtKit.soft_box(Vector3(1.0, 0.2, 2.0), 0.3)
	var aabb := mesh.get_aabb()
	check(aabb.size.distance_to(Vector3(1.0, 0.2, 2.0)) < 0.01, "pehmeä laatikko on oikean kokoinen (%s)" % aabb.size)


func test_spiral_curls_inwards() -> void:
	var pts := ArtKit.spiral(Vector3.ZERO, Vector3.RIGHT, Vector3.UP, 0.1, 1.5)
	check(pts[0].length() > 0.09, "kiehkura alkaa ulkoreunalta")
	check(pts[pts.size() - 1].length() < 0.04, "kiehkura kiertyy sisäänpäin")


func test_star_shape() -> void:
	check(ArtKit.in_star(Vector2.ZERO, 10.0), "tähden keskikohta on tähteä")
	check(ArtKit.in_star(Vector2(0, -9.5), 10.0), "tähden kärki osoittaa ylös")
	check(not ArtKit.in_star(Vector2(10, 10), 10.0), "tähden ulkopuolella ei ole tähteä")


func test_stripes_alternate() -> void:
	var img := ArtKit.stripes_image([Color.RED, Color.WHITE], 4, 64)
	check(img.get_pixel(0, 2).is_equal_approx(Color.RED), "ensimmäinen raita on ensimmäistä väriä")
	check(img.get_pixel(0, 20).is_equal_approx(Color.WHITE), "toinen raita on toista väriä")


func test_bed_looks_like_metal_bed() -> void:
	var bed: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(bed)
	var visual := bed.get_node("Room/Bed/Visual")
	var frame := visual.get_node_or_null("MetalFrame") as MeshInstance3D
	check(frame != null, "sängyllä on metallikehys")
	if frame != null:
		var aabb := frame.mesh.get_aabb()
		check(aabb.size.y > 0.9, "sängyn päädyt ovat korkeat (%.2f m)" % aabb.size.y)
		check(frame.mesh.get_surface_count() == 1, "kehys piirretään yhdellä kertaa")
	var duvet := visual.get_node("Duvet") as MeshInstance3D
	check(duvet.material_override is StandardMaterial3D \
			and (duvet.material_override as StandardMaterial3D).albedo_texture != null, "peitossa on raidat")
	check(visual.get_node_or_null("Mattress") != null, "sängyssä on patja")
	bed.free()
