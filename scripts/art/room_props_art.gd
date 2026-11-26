@tool
class_name RoomPropsArt
extends Node3D
## Lastenhuoneen pienemmät esineet: lipasto, lelulaatikko, kori, lammasyövalo, matot ja
## seinähylly nukkeineen. Laitetaan esineen Visual-solmuun ja valitaan kind.
## Kohtauksen nimetyt osat (Sheep, LidPivot, Toys...) säilyvät, koska temput liikuttavat niitä.

@export_enum("dresser", "toybox", "basket", "sheep_light", "rugs", "shelf", "room") var kind := "dresser"

const PINE := Color(0.93, 0.8, 0.62)
const PINE_DARK := Color(0.85, 0.68, 0.48)


func _ready() -> void:
	if get_node_or_null("ArtDone") != null:
		return
	var marker := Node.new()
	marker.name = "ArtDone"
	add_child(marker)
	match kind:
		"dresser": _dresser()
		"toybox": _toybox()
		"basket": _basket()
		"sheep_light": _sheep_light()
		"rugs": _rugs()
		"shelf": _shelf()
		"room": _room()


## Männynvärinen puu, jossa on syyt ja muutama oksankohta.
static func wood_material(light := PINE, dark := PINE_DARK) -> StandardMaterial3D:
	var w := 64
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var wave := sin(float(y) * 0.45 + sin(float(x) * 0.09 + float(y) * 0.02) * 2.2)
			var t := smoothstep(0.55, 1.0, wave) * 0.8
			img.set_pixel(x, y, light.lerp(dark, t))
	for knot in [Vector2(18, 40), Vector2(46, 96)]:
		for y in range(int(knot.y) - 5, int(knot.y) + 6):
			for x in range(int(knot.x) - 4, int(knot.x) + 5):
				var d := Vector2((x - knot.x) / 4.0, (y - knot.y) / 5.0).length()
				if d < 1.0:
					img.set_pixel(x, y, dark.lerp(light, d * 0.7).darkened(0.08 * (1.0 - d)))
	return ArtKit.textured(img)


func _mesh(node_name: String) -> MeshInstance3D:
	return get_node_or_null(node_name) as MeshInstance3D


func _dresser() -> void:
	var wood := wood_material()
	var body := _mesh("Body")
	if body != null:
		body.mesh = ArtKit.soft_box(Vector3(1.3, 0.8, 0.55), 0.06, 12)
		body.material_override = wood
	for i in 3:
		var d := _mesh("Drawer%d" % i)
		if d == null:
			continue
		d.mesh = ArtKit.soft_box(Vector3(1.2, 0.2, 0.03), 0.1, 8)
		d.material_override = wood_material(PINE.lightened(0.05), PINE_DARK)
		for x in [-0.3, 0.3]:
			ArtKit.part(self, "Knob", ArtKit.sphere(0.025, 10), d.position + Vector3(x, 0, 0.025),
					ArtKit.material(PINE_DARK, 0.6))


func _toybox() -> void:
	var mint := Color(0.55, 0.8, 0.7)
	var box := _mesh("Box")
	if box != null:
		box.mesh = ArtKit.soft_box(Vector3(0.5, 0.3, 0.45), 0.2, 10)
		box.material_override = ArtKit.material(mint)
		# Kyljissä köysikahvat ja edessä iso tähti.
		for x in [-0.255, 0.255]:
			var handle := ArtKit.part(self, "Handle", _torus(0.025, 0.045), box.position + Vector3(x, 0.05, 0),
					ArtKit.material(Color(0.95, 0.9, 0.8)))
			handle.rotation.z = PI / 2.0
		var star_mat := ArtKit.material(Color(1.0, 0.85, 0.4))
		star_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var star := ArtKit.part(self, "Star", _star_mesh(0.08, 0.012), box.position + Vector3(0, 0.0, 0.228),
				star_mat)
		star.rotation.x = PI / 2.0
	var lid := get_node_or_null("LidPivot/Lid") as MeshInstance3D
	if lid != null:
		lid.mesh = ArtKit.soft_box(Vector3(0.54, 0.05, 0.49), 0.3, 10)
		lid.material_override = ArtKit.material(mint.lightened(0.25))


func _basket() -> void:
	var b := _mesh("Basket")
	if b == null:
		return
	b.mesh = ArtKit.cylinder(0.24, 0.35, 24)
	b.material_override = ArtKit.textured(ArtKit.stripes_image(
			[Color(0.96, 0.92, 0.84), Color(0.88, 0.82, 0.7)], 18))
	var rim := ArtKit.part(self, "Rim", _torus(0.22, 0.26), b.position + Vector3(0, 0.175, 0),
			ArtKit.material(Color(0.93, 0.88, 0.78)))
	rim.scale = Vector3(1, 0.6, 1)
	for z in [-0.24, 0.24]:
		var ear := ArtKit.part(self, "Handle", _torus(0.03, 0.055), b.position + Vector3(0, 0.15, z),
				ArtKit.material(Color(0.9, 0.84, 0.72)))
		ear.rotation.x = PI / 2.0
		ear.rotation.y = PI / 2.0
	# Korista kurkistaa lelupallo ja nalle-pehmon korvat.
	ArtKit.part(self, "Ball", ArtKit.sphere(0.08, 14), b.position + Vector3(0.08, 0.16, 0.04),
			ArtKit.material(Color(0.98, 0.6, 0.6)))
	ArtKit.part(self, "Teddy", ArtKit.sphere(0.08, 14), b.position + Vector3(-0.07, 0.17, -0.05),
			ArtKit.material(Color(0.8, 0.62, 0.45)))
	for x in [-0.12, -0.02]:
		ArtKit.part(self, "TeddyEar", ArtKit.sphere(0.03, 10), b.position + Vector3(x, 0.24, -0.06),
				ArtKit.material(Color(0.8, 0.62, 0.45)))


func _sheep_light() -> void:
	var wood := wood_material()
	var stool := _mesh("Stool")
	if stool != null:
		stool.mesh = ArtKit.soft_box(Vector3(0.45, 0.08, 0.45), 0.25, 10)
		stool.position.y = 0.21
		stool.material_override = wood
		for x in [-0.17, 0.17]:
			for z in [-0.17, 0.17]:
				ArtKit.part(self, "Leg", ArtKit.cylinder(0.025, 0.18, 10), Vector3(x, 0.09, z), wood)
	var wool := ArtKit.plush(Color(1.0, 0.98, 0.92), 1.0)
	var face := ArtKit.material(Color(0.42, 0.37, 0.38), 0.9)
	var sheep := _mesh("Sheep")
	if sheep != null:
		sheep.mesh = ArtKit.sphere(0.12, 16)
		sheep.scale = Vector3(1.0, 0.8, 0.85)
		sheep.material_override = wool
		# Pörröinen villa: pieniä palloja rungon ympärillä (lammas-osan lapsina, jotta
		# ne litistyvät lampaan mukana).
		for i in 10:
			var a := TAU * i / 10.0
			var y := 0.04 if i % 2 == 0 else -0.01
			ArtKit.part(sheep, "Wool", ArtKit.sphere(0.06, 10), Vector3(cos(a) * 0.1, y, sin(a) * 0.09), wool)
		ArtKit.part(sheep, "Wool", ArtKit.sphere(0.07, 10), Vector3(0, 0.09, 0), wool)
		for x in [-0.07, 0.07]:
			for z in [-0.05, 0.05]:
				ArtKit.part(sheep, "Leg", ArtKit.capsule(0.018, 0.08), Vector3(x, -0.12, z), face)
	var head := _mesh("SheepHead")
	if head != null:
		head.mesh = ArtKit.sphere(0.05, 14)
		head.scale = Vector3(1.0, 1.1, 0.9)
		head.position = Vector3(0.15, 0.4, 0)
		head.material_override = face
		for z in [-1.0, 1.0]:
			var ear := ArtKit.part(head, "Ear", ArtKit.sphere(0.022, 8), Vector3(-0.005, 0.02, 0.055 * z), face,
					Vector3(0.6, 0.6, 1.5))
			ear.rotation.x = 0.5 * z
			ArtKit.part(head, "Eye", ArtKit.sphere(0.01, 8), Vector3(0.04, 0.012, 0.022 * z),
					ArtKit.shine_material())
		ArtKit.part(head, "Tuft", ArtKit.sphere(0.03, 10), Vector3(-0.01, 0.05, 0), wool)
	_sheep_halo()


## Yöllä lampaan ympärillä lämmin kajo (halpa: läpinäkyviä levyjä, ei oikeaa valoa lisää).
func _sheep_halo() -> void:
	# Kameraan päin kääntyvä levy lampaan ympärillä.
	var mat := ArtKit.glow_material(Color(1.0, 0.82, 0.55, 0.5))
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var halo := ArtKit.part(self, "NightHalo", _upright_disc(), Vector3(0, 0.36, 0), mat, Vector3.ONE * 0.85)
	# Lattialle valoläikkä.
	var pool := ArtKit.part(self, "NightPool", ArtKit.soft_disc(), Vector3(0, 0.007, 0),
			ArtKit.glow_material(Color(1.0, 0.78, 0.5, 0.4)), Vector3(1.8, 1, 1.8))
	for n in [halo, pool]:
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.visible = false
		n.add_to_group(DayNight.NIGHT_LIGHT_GROUP)


## soft_disc pystyyn käännettynä (xy-tasoon), esim. kameraan päin kääntyvää kajoa varten.
static func _upright_disc() -> ArrayMesh:
	var flat := ArtKit.soft_disc()
	var st := SurfaceTool.new()
	st.create_from(flat, 0)
	var arrays := st.commit_to_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] = Vector3(verts[i].x, -verts[i].z, 0)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in normals.size():
		normals[i] = Vector3.BACK
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _rugs() -> void:
	var pink := _mesh("PinkRug")
	if pink != null:
		pink.mesh = ArtKit.soft_box(Vector3(1.8, 0.012, 1.2), 0.3, 12)
		var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
		for y in 64:
			for x in 64:
				var weave := 0.5 + 0.5 * sin(x * 1.6) * sin(y * 1.6)
				img.set_pixel(x, y, Color(0.96, 0.8, 0.8).lerp(Color(0.92, 0.7, 0.72), weave * 0.6))
		pink.material_override = ArtKit.textured(img)
		pink.material_override.uv1_scale = Vector3(4, 3, 1)
		# Pörröiset tupsut maton lyhyissä päissä.
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for side in [-1.0, 1.0]:
			for i in 15:
				var z := lerpf(-0.5, 0.5, i / 14.0)
				ArtKit.add_ball(st, Vector3(side * 0.93, 0.006, z), 0.028, 6)
		ArtKit.part(pink, "Fringe", ArtKit.commit(st), Vector3.ZERO,
				ArtKit.plush(Color(0.98, 0.86, 0.86)), Vector3(1.0, 0.5, 1.0))
	var animal := _mesh("AnimalRug")
	if animal != null:
		animal.mesh = ArtKit.soft_box(Vector3(1.1, 0.014, 1.0), 1.0, 20)
		animal.material_override = ArtKit.textured(animal_face_image())
		var ear_mat := ArtKit.material(Color(0.85, 0.8, 0.74))
		for x in [-0.36, 0.36]:
			ArtKit.part(animal, "Ear", ArtKit.cylinder(0.13, 0.012, 20), Vector3(x, -0.001, -0.38), ear_mat)


## Eläinmaton kasvot: vaalea pohja, silmät, poskipunat, nenä ja hymy (ylhäältä katsottuna).
static func animal_face_image() -> Image:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var base := Color(0.88, 0.84, 0.78)
	img.fill(base)
	var dark := Color(0.3, 0.27, 0.27)
	var paint := func(c: Vector2, r: Vector2, col: Color) -> void:
		for y in range(int(c.y - r.y), int(c.y + r.y) + 1):
			for x in range(int(c.x - r.x), int(c.x + r.x) + 1):
				if x >= 0 and y >= 0 and x < s and y < s \
						and Vector2((x - c.x) / r.x, (y - c.y) / r.y).length() <= 1.0:
					img.set_pixel(x, y, col)
	paint.call(Vector2(44, 56), Vector2(6, 8), dark)
	paint.call(Vector2(84, 56), Vector2(6, 8), dark)
	paint.call(Vector2(30, 74), Vector2(9, 6), Color(0.96, 0.72, 0.72))
	paint.call(Vector2(98, 74), Vector2(9, 6), Color(0.96, 0.72, 0.72))
	paint.call(Vector2(64, 70), Vector2(7, 5), Color(0.85, 0.55, 0.58))
	for i in 15:
		var a := lerpf(0.2, PI - 0.2, i / 14.0)
		paint.call(Vector2(64 + cos(a) * 14, 78 + sin(a) * 8), Vector2(1.5, 1.5), dark)
	return img


func _shelf() -> void:
	var shelf := _mesh("Shelf")
	if shelf != null:
		shelf.mesh = ArtKit.soft_box(Vector3(0.25, 0.035, 0.6), 0.2, 8)
		shelf.material_override = wood_material()
		# Hylly roikkuu köysistä.
		var rope := ArtKit.material(Color(0.95, 0.92, 0.86))
		for z in [-0.27, 0.27]:
			var p := shelf.position + Vector3(0.1, 0.0, z)
			ArtKit.tube_part(self, "Rope", PackedVector3Array([p, Vector3(-0.04, p.y + 0.45, shelf.position.z)]),
					0.006, rope)
	var doll := _mesh("Doll")
	if doll == null:
		return
	# Nukke istuu hyllyn reunalla tyllimekossa, jalat roikkuvat.
	doll.mesh = null
	var base := doll.position
	var skin := ArtKit.material(Color(1.0, 0.88, 0.8))
	var dress := ArtKit.material(Color(0.98, 0.84, 0.86))
	var hair := ArtKit.material(Color(0.88, 0.7, 0.62))
	var skirt := CylinderMesh.new()
	skirt.top_radius = 0.03
	skirt.bottom_radius = 0.085
	skirt.height = 0.13
	skirt.radial_segments = 16
	ArtKit.part(doll, "Dress", skirt, Vector3(0, -0.06, 0), dress)
	ArtKit.part(doll, "Head", ArtKit.sphere(0.045, 14), Vector3(0, 0.05, 0), skin)
	ArtKit.part(doll, "Hair", ArtKit.sphere(0.048, 14), Vector3(-0.008, 0.062, 0), hair, Vector3(1, 0.9, 1))
	ArtKit.part(doll, "Bun", ArtKit.sphere(0.022, 10), Vector3(-0.01, 0.11, 0), hair)
	for z in [-0.018, 0.018]:
		ArtKit.part(doll, "Eye", ArtKit.sphere(0.005, 6), Vector3(0.043, 0.048, z), ArtKit.material(Color(0.2, 0.15, 0.15)))
		ArtKit.part(doll, "Arm", ArtKit.capsule(0.012, 0.09), Vector3(0.01, -0.02, z * 3.0), skin)
		var leg := ArtKit.part(doll, "Leg", ArtKit.capsule(0.013, 0.16), Vector3(0.09, -0.18, z), skin)
		leg.rotation.z = 0.25
		ArtKit.part(doll, "Shoe", ArtKit.sphere(0.018, 8), Vector3(0.11, -0.26, z), dress)
	doll.position = base + Vector3(0.02, 0.02, 0)


## Huone: lautalattia, seinät jalkalistoineen ja iso ikkuna sälekaihtimineen.
## (Laitetaan huoneen juureen.)
func _room() -> void:
	var floor_mesh := get_node_or_null("Floor/Mesh") as MeshInstance3D
	if floor_mesh != null:
		var m := ArtKit.textured(floor_image())
		m.uv1_scale = Vector3(4.3, 6.9, 1)
		floor_mesh.material_override = m
	var wall := ArtKit.material(Color(0.96, 0.94, 0.9), 0.95)
	var white := ArtKit.material(Color(0.99, 0.99, 0.98), 0.6)
	for path in ["BackWall/Visual/Wall", "LeftWall/Visual/Wall"]:
		var w := get_node_or_null(path) as MeshInstance3D
		if w != null:
			w.material_override = wall
	# Jalkalistat seinien alareunassa.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	ArtKit.add_box(st, Vector3(0, 0.04, -2.49), Vector3(6.0, 0.08, 0.02))
	ArtKit.add_box(st, Vector3(-2.99, 0.04, 0), Vector3(0.02, 0.08, 5.0))
	ArtKit.part(self, "Baseboards", ArtKit.commit(st), Vector3.ZERO, white)
	_window()
	_wall_decor()
	_diorama_base()
	_corner_shade()
	_prop_shadows()
	_sunbeam()
	_wall_art()


## Seinät kaksivärisiksi: alhaalla pehmeä minttupaneeli, ylhäällä pilkullinen tapetti,
## välissä valkoinen lista. Paneelit ovat ohuita tasoja seinän edessä.
func _wall_decor() -> void:
	const PANEL_H := 0.85
	const WALL_H := 2.6
	var paper := ArtKit.textured(wallpaper_image(), 0.95)
	paper.uv1_scale = Vector3(6, 2, 1)
	var panel := ArtKit.textured(panel_image(), 0.9)
	panel.uv1_scale = Vector3(24, 1, 1)
	var trim := ArtKit.material(Color(0.99, 0.98, 0.96), 0.6)
	# [seinän keskikohta lattiatasolla, suunta seinää pitkin, leveys, kääntö]
	var walls := [[Vector3(0, 0, -2.495), 6.0, 0.0, 6.0], [Vector3(-2.995, 0, 0), 5.0, PI / 2.0, 5.0]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for w in walls:
		var base: Vector3 = w[0]
		var width: float = w[1]
		var yaw: float = w[2]
		var upper := QuadMesh.new()
		upper.size = Vector2(width, WALL_H - PANEL_H)
		var u := ArtKit.part(self, "Wallpaper", upper, base + Vector3(0, (WALL_H + PANEL_H) / 2.0, 0), paper)
		u.rotation.y = yaw
		var lower := QuadMesh.new()
		lower.size = Vector2(width, PANEL_H)
		var l := ArtKit.part(self, "WallPanel", lower, base + Vector3(0, PANEL_H / 2.0, 0), panel)
		l.rotation.y = yaw
		var along := Vector3.RIGHT if yaw == 0.0 else Vector3.BACK
		var out := Vector3.BACK if yaw == 0.0 else Vector3.RIGHT
		var size := along * width + Vector3(0, 0.04, 0) + out * 0.03
		ArtKit.add_box(st, base + Vector3(0, PANEL_H, 0) + out * 0.01, size.abs())
	ArtKit.part(self, "ChairRail", ArtKit.commit(st), Vector3.ZERO, trim)
	# Seinien yläreunaan pyöreä valkoinen "kermakakun reuna".
	var cap_mat := ArtKit.material(Color(0.99, 0.97, 0.95), 0.7)
	var back_cap := ArtKit.part(self, "WallCap", ArtKit.soft_box(Vector3(6.3, 0.07, 0.16), 0.5, 8),
			Vector3(0.0, WALL_H, -2.55), cap_mat)
	back_cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var left_cap := ArtKit.part(self, "WallCap", ArtKit.soft_box(Vector3(0.16, 0.07, 5.25), 0.5, 8),
			Vector3(-3.05, WALL_H, 0.025), cap_mat)
	left_cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Tapetti: lämmin kermanvalkoinen, jossa pieniä vaaleanpunaisia ja keltaisia pilkkuja.
static func wallpaper_image() -> Image:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var base := Color(0.98, 0.95, 0.9)
	img.fill(base)
	var dots := [[Vector2(16, 16), Color(0.97, 0.84, 0.84)], [Vector2(48, 48), Color(0.98, 0.9, 0.72)],
			[Vector2(48, 16), Color(0.86, 0.91, 0.96)], [Vector2(16, 48), Color(0.97, 0.84, 0.84)]]
	for d in dots:
		var c: Vector2 = d[0]
		for y in range(int(c.y) - 4, int(c.y) + 5):
			for x in range(int(c.x) - 4, int(c.x) + 5):
				var t := Vector2(x + 0.5, y + 0.5).distance_to(c + Vector2(0.5, 0.5))
				if t < 3.6:
					img.set_pixel(x, y, base.lerp(d[1], clampf(3.6 - t, 0.0, 1.0)))
	return img


## Paneeli: pystysuuntaiset helmiponttilaudat vaalean mintun sävyssä.
static func panel_image() -> Image:
	var w := 16
	var h := 8
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var mint := Color(0.85, 0.93, 0.89)
	for y in h:
		for x in w:
			var c := mint
			if x == 0:
				c = mint.darkened(0.12)
			elif x == 1:
				c = mint.lightened(0.25)
			img.set_pixel(x, y, c)
	return img


## Huone seisoo pyöreäreunaisella "leikkialustalla", joten se näyttää nukkekodilta
## eikä leiju tyhjässä.
func _diorama_base() -> void:
	var base := ArtKit.part(self, "DioramaBase", ArtKit.soft_box(Vector3(6.35, 0.32, 5.35), 0.15, 12),
			Vector3(-0.05, -0.165, -0.05), ArtKit.material(Color(0.95, 0.8, 0.74), 0.8))
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Varjoisa raita lattian ja seinän rajaan sekä nurkkaan: huone näyttää syvemmältä.
func _corner_shade() -> void:
	var shade := ArtKit.material(Color(0.4, 0.28, 0.3), 1.0)
	shade.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shade.albedo_texture = _fade_texture()
	shade.albedo_color.a = 0.22
	shade.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	# Lattialla seinän vieressä (tummin seinän kohdalla).
	for w in [[Vector3(0, 0.003, -2.5 + 0.25), Vector2(6.0, 0.5), 0.0],
			[Vector3(-3.0 + 0.25, 0.0031, 0), Vector2(5.0, 0.5), -PI / 2.0]]:
		var q := PlaneMesh.new()
		q.size = w[1]
		var m := ArtKit.part(self, "FloorShade", q, w[0], shade)
		m.rotation.y = w[2]
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Liukuväri, joka on yläreunasta (v = 0) tumma ja häipyy alas.
static func _fade_texture() -> ImageTexture:
	var img := Image.create(4, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		var a := pow(1.0 - y / 31.0, 2.2)
		for x in 4:
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


## Pehmeät varjot esineiden alle: esineet seisovat lattialla eivätkä leiju.
func _prop_shadows() -> void:
	# [solmu, varjon koko (leveys x, syvyys z), keskikohdan siirto, tummuus]
	var shadows := [
		["Bed", Vector2(1.7, 2.75), Vector3.ZERO, 0.4],
		["ToyBox", Vector2(0.95, 0.88), Vector3.ZERO, 0.45],
		["Basket", Vector2(0.85, 0.85), Vector3.ZERO, 0.45],
		["Dresser", Vector2(1.9, 1.05), Vector3(0, 0, 0.1), 0.42],
		["SheepLight", Vector2(0.8, 0.8), Vector3.ZERO, 0.4],
		["Panda", Vector2(0.75, 0.7), Vector3(0, 0, 0.05), 0.45],
		["Dollhouse", Vector2(0.75, 0.5), Vector3.ZERO, 0.3],
	]
	for s in shadows:
		var prop := get_node_or_null(s[0]) as Node3D
		if prop == null:
			continue
		var sh := ArtKit.soft_shadow(s[1], s[3])
		var size: Vector2 = s[1]
		prop.add_child(sh)
		# Varjo pysyy suorassa ja lattian tasolla, vaikka esine olisi skaalattu tai käännetty.
		sh.global_basis = Basis.IDENTITY.scaled(Vector3(size.x, 1.0, size.y))
		sh.global_position = prop.global_position + s[2] + Vector3(0, 0.004, 0)


## Ikkunasta lattialle lankeava auringonläikkä. Näkyy vain päivällä.
func _sunbeam() -> void:
	var patch_mat := ArtKit.material(Color(1.0, 0.92, 0.7), 1.0)
	patch_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	patch_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	patch_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	patch_mat.albedo_texture = ImageTexture.create_from_image(window_patch_image())
	patch_mat.albedo_color.a = 0.3
	patch_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var patch := PlaneMesh.new()
	patch.size = Vector2(1.7, 1.3)
	var p := ArtKit.part(self, "SunPatch", patch, Vector3(0.55, 0.006, -1.35), patch_mat)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.add_to_group(DayNight.DAY_ONLY_GROUP)


## Seinälle sateenkaaritaulu ja ikkunalaudalle pieni kukkaruukku.
func _wall_art() -> void:
	# Taulu takaseinällä sängyn ja ikkunan välissä.
	var center := Vector3(-1.05, 1.55, -2.47)
	ArtKit.part(self, "PictureFrame", ArtKit.soft_box(Vector3(0.62, 0.5, 0.04), 0.25, 8), center,
			wood_material())
	ArtKit.part(self, "PictureCanvas", ArtKit.soft_box(Vector3(0.52, 0.4, 0.03), 0.15, 6),
			center + Vector3(0, 0, 0.008), ArtKit.material(Color(0.99, 0.97, 0.93)))
	var colors := [Color(0.98, 0.62, 0.6), Color(1.0, 0.8, 0.5), Color(0.98, 0.93, 0.6),
			Color(0.62, 0.85, 0.7), Color(0.62, 0.75, 0.95)]
	var arc_center := center + Vector3(0, -0.12, 0.03)
	for i in colors.size():
		var r := 0.19 - i * 0.03
		ArtKit.tube_part(self, "Rainbow%d" % i, ArtKit.arc(arc_center, Vector3.RIGHT, Vector3.UP, r, 0.0, PI, 16),
				0.014, ArtKit.material(colors[i]))
	for x in [-0.19, 0.19]:
		ArtKit.part(self, "Cloud", ArtKit.sphere(0.04, 10), arc_center + Vector3(x, 0.0, 0.01),
				ArtKit.material(Color.WHITE), Vector3(1.5, 0.9, 0.6))
	# Kukkaruukku ikkunalaudalla.
	var pot := Vector3(-0.15, 0.84, -2.4)
	var pot_mesh := CylinderMesh.new()
	pot_mesh.top_radius = 0.07
	pot_mesh.bottom_radius = 0.05
	pot_mesh.height = 0.11
	pot_mesh.radial_segments = 14
	pot_mesh.rings = 1
	ArtKit.part(self, "PlantPot", pot_mesh, pot + Vector3(0, 0.055, 0), ArtKit.material(Color(0.95, 0.72, 0.62)))
	var leaf := ArtKit.plush(Color(0.5, 0.75, 0.5), 0.8)
	for i in 5:
		var a := TAU * i / 5.0
		var l := ArtKit.part(self, "Leaf", ArtKit.sphere(0.045, 10), pot + Vector3(cos(a) * 0.05, 0.16 + (i % 2) * 0.03, sin(a) * 0.035),
				leaf, Vector3(0.6, 1.3, 0.6))
		l.rotation = Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5)
	ArtKit.part(self, "Flower", ArtKit.sphere(0.03, 10), pot + Vector3(0, 0.24, 0),
			ArtKit.material(Color(1.0, 0.75, 0.8)))


## Ikkunan muotoinen valoläikkä: neljä ruutua, pehmeät reunat (alfa).
static func window_patch_image() -> Image:
	var w := 64
	var h := 48
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var u := (x + 0.5) / w
			var v := (y + 0.5) / h
			var edge := smoothstep(0.0, 0.18, minf(u, 1.0 - u)) * smoothstep(0.0, 0.2, minf(v, 1.0 - v))
			var bar := 1.0 - 0.6 * (1.0 - smoothstep(0.0, 0.025, absf(u - 0.5))) \
					- 0.6 * (1.0 - smoothstep(0.0, 0.03, absf(v - 0.5)))
			img.set_pixel(x, y, Color(1, 1, 1, clampf(edge * bar, 0.0, 1.0)))
	return img


func _window() -> void:
	var visual := get_node_or_null("BackWall/Visual") as Node3D
	if visual == null:
		return
	var glass := visual.get_node_or_null("WindowGlass") as MeshInstance3D
	var frame := visual.get_node_or_null("WindowFrame") as MeshInstance3D
	if glass == null or frame == null:
		return
	var c := glass.position
	var size := Vector2(1.6, 1.1)
	frame.visible = false
	var quad := QuadMesh.new()
	quad.size = size
	glass.mesh = quad
	glass.position.z += 0.021
	var view := ArtKit.textured(window_view_image())
	view.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.material_override = view
	# Yöllä ikkunasta näkyy tähtitaivas ja kuu (päivä/yö vaihtaa näkyvyyden).
	var night_mat := ArtKit.textured(window_view_image(true))
	night_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var night := ArtKit.part(visual, "NightView", quad, glass.position + Vector3(0, 0, 0.002), night_mat)
	night.visible = false
	night.add_to_group(DayNight.NIGHT_LIGHT_GROUP)
	var white := ArtKit.material(Color(0.99, 0.99, 0.98), 0.55)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Paksut valkoiset karmit ja leveä ikkunalauta.
	var t := 0.09
	ArtKit.add_box(st, c + Vector3(0, size.y / 2 + t / 2, 0.03), Vector3(size.x + t * 2, t, 0.08))
	ArtKit.add_box(st, c + Vector3(0, -size.y / 2 - t / 2, 0.03), Vector3(size.x + t * 2, t, 0.08))
	for sx in [-1.0, 1.0]:
		ArtKit.add_box(st, c + Vector3(sx * (size.x / 2 + t / 2), 0, 0.03), Vector3(t, size.y, 0.08))
	ArtKit.add_box(st, c + Vector3(0, -size.y / 2 - t - 0.01, 0.08), Vector3(size.x + t * 2 + 0.1, 0.03, 0.16))
	# Sälekaihdin: ylimmät säleet tiheässä, alhaalla näkyy maisema.
	for i in 18:
		var y := c.y + size.y / 2 - 0.03 - i * 0.034
		ArtKit.add_box(st, Vector3(c.x, y, c.z + 0.035), Vector3(size.x - 0.04, 0.022, 0.006))
	ArtKit.add_box(st, Vector3(c.x, c.y + size.y / 2 - 0.03 - 18 * 0.034, c.z + 0.04), Vector3(size.x - 0.02, 0.03, 0.02))
	# Rullaverho karmin yläpuolella.
	ArtKit.add_box(st, c + Vector3(0, size.y / 2 + t + 0.07, 0.08), Vector3(size.x + t * 2 + 0.1, 0.14, 0.1))
	ArtKit.part(visual, "WindowTrim", ArtKit.commit(st), Vector3.ZERO, white)
	# Kaihtimen narut.
	var cord := ArtKit.material(Color(0.92, 0.92, 0.9))
	for dx in [-0.05, -0.02]:
		var top := c + Vector3(-size.x / 2 + 0.08 + dx, size.y / 2 - 0.02, 0.05)
		ArtKit.tube_part(visual, "Cord", PackedVector3Array([top, top + Vector3(0, -0.9, 0)]), 0.004, cord)
	for i in 5:
		var blind := visual.get_node_or_null("Blind%d" % i) as Node3D
		if blind != null:
			blind.visible = false


## Lautalattia: vaaleat tammilaudat, saumat ja limitetyt päät.
static func floor_image() -> Image:
	var w := 128
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var tones := [Color(0.86, 0.75, 0.61), Color(0.83, 0.72, 0.58), Color(0.88, 0.78, 0.64), Color(0.84, 0.74, 0.6)]
	for y in h:
		var plank := y / 32
		var offset: int = [0, 70, 30, 100][plank]
		for x in w:
			var c: Color = tones[plank]
			var grain := sin(float(x) * 0.15 + sin(float(y) * 0.7 + plank) * 1.5)
			c = c.darkened(0.04 * smoothstep(0.6, 1.0, grain))
			if y % 32 == 0 or (x + offset) % w == 0:
				c = c.darkened(0.2)
			img.set_pixel(x, y, c)
	return img


## Ikkunasta näkyvä maisema: taivas, pilvi ja naapuritalojen pehmeät katot.
## night = true: tummansininen yötaivas, kuu, tähdet ja valaistut ikkunat.
static func window_view_image(night := false) -> Image:
	var w := 128
	var h := 96
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		var sky := Color(0.62, 0.8, 0.97).lerp(Color(0.86, 0.93, 1.0), float(y) / h)
		if night:
			sky = Color(0.1, 0.12, 0.3).lerp(Color(0.22, 0.24, 0.45), float(y) / h)
		for x in w:
			img.set_pixel(x, y, sky)
	var paint := func(cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
		for y in range(int(cy - ry), int(cy + ry) + 1):
			for x in range(int(cx - rx), int(cx + rx) + 1):
				if x >= 0 and y >= 0 and x < w and y < h \
						and Vector2((x - cx) / rx, (y - cy) / ry).length() <= 1.0:
					img.set_pixel(x, y, col)
	if night:
		paint.call(98, 18, 9, 9, Color(1.0, 0.95, 0.75))
		paint.call(103, 15, 8, 8, Color(0.1, 0.12, 0.3))
		for p in [[12, 8], [30, 20], [52, 10], [70, 26], [84, 6], [118, 30], [40, 32], [20, 30]]:
			paint.call(p[0], p[1], 1.2, 1.2, Color(1.0, 0.95, 0.7))
	else:
		for p in [[30, 18, 12, 6], [40, 15, 10, 7], [50, 19, 10, 5], [96, 26, 9, 5], [104, 24, 8, 6]]:
			paint.call(p[0], p[1], p[2], p[3], Color(1, 1, 1))
	# Katot: kaksi kerrosta, kauempi vaaleampi.
	for y in range(40, h):
		for x in w:
			var roof_far := 40 + absf(fmod(x + 10.0, 64.0) - 32.0) * 0.35
			var roof_near := 60 + absf(fmod(x, 80.0) - 40.0) * 0.3
			var near := Color(0.6, 0.66, 0.78)
			var far := Color(0.75, 0.8, 0.88)
			if night:
				near = Color(0.16, 0.17, 0.3)
				far = Color(0.22, 0.23, 0.38)
			if y > roof_near:
				var stripe := 0.04 if int(y) % 6 < 1 else 0.0
				img.set_pixel(x, y, near.darkened(stripe))
			elif y > roof_far:
				img.set_pixel(x, y, far)
	if night:
		for p in [[20, 80], [56, 84], [92, 78], [110, 86], [36, 62]]:
			for yy in range(p[1], p[1] + 5):
				for xx in range(p[0], p[0] + 4):
					img.set_pixel(xx, yy, Color(1.0, 0.85, 0.45))
	return img


static func _torus(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 16
	t.ring_segments = 8
	return t


## Paksu viisisakarainen tähti (kärki ylöspäin, paksuus y-suunnassa).
static func _star_mesh(radius: float, depth: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector3] = []
	for i in 10:
		var a := TAU * i / 10.0
		var r := radius if i % 2 == 0 else radius * 0.45
		pts.append(Vector3(sin(a) * r, 0, -cos(a) * r))
	for side in [1.0, -1.0]:
		var y: float = depth * 0.5 * side
		for i in 10:
			var a := pts[i] + Vector3(0, y, 0)
			var b := pts[(i + 1) % 10] + Vector3(0, y, 0)
			var c := Vector3(0, y, 0)
			st.set_normal(Vector3(0, side, 0))
			if side > 0:
				st.add_vertex(c); st.add_vertex(b); st.add_vertex(a)
			else:
				st.add_vertex(c); st.add_vertex(a); st.add_vertex(b)
	for i in 10:
		var a := pts[i]
		var b := pts[(i + 1) % 10]
		var n := (a + b).normalized()
		var top := Vector3(0, depth * 0.5, 0)
		st.set_normal(n)
		st.add_vertex(a + top); st.add_vertex(b + top); st.add_vertex(b - top)
		st.add_vertex(a + top); st.add_vertex(b - top); st.add_vertex(a - top)
	return st.commit()
