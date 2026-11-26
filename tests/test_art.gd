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


func test_soft_box_faces_outwards() -> void:
	# Pinnan normaalit osoittavat ulospäin, muuten kappale näkyy nurinpäin.
	var mesh := ArtKit.soft_box(Vector3(1, 1, 1), 0.3)
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var outward := 0
	for i in verts.size():
		if verts[i].dot(normals[i]) > 0.0:
			outward += 1
	check(outward > verts.size() * 0.95, "pehmeän laatikon pinnat osoittavat ulospäin (%d/%d)" % [outward, verts.size()])


func test_room_items_have_details() -> void:
	var main: Node = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	tree.root.add_child(main)
	var room := main.get_node("Room")
	for path in ["Panda/Visual/Muzzle", "Panda/Visual/Smile", "WingCreature/Visual/Antenna0",
			"WingCreature/Visual/Cheek1", "Dollhouse/Visual/Chimney", "Dollhouse/Visual/DoorArch",
			"Train/Visual/Train/Engine/CabRoof", "Train/Visual/Train/Wagon/Cargo0",
			"ToyBox/Visual/Star", "Basket/Visual/Teddy", "SheepLight/Visual/Sheep/Wool",
			"SheepLight/Visual/SheepHead/Ear", "Rugs/AnimalRug/Ear", "LeftWall/Visual/Doll/Head",
			"LeftWall/Visual/Rope"]:
		check(room.get_node_or_null(path) != null, "huoneessa on yksityiskohta %s" % path)
	var rug := room.get_node("Rugs/AnimalRug") as MeshInstance3D
	check((rug.material_override as StandardMaterial3D).albedo_texture != null, "eläinmatossa on kasvot")
	main.free()


func test_animal_face_has_eyes() -> void:
	var img := RoomPropsArt.animal_face_image()
	check(img.get_pixel(44, 56).v < 0.4, "eläinmatolla on silmä")
	check(img.get_pixel(5, 5).v > 0.7, "maton pohja on vaalea")
