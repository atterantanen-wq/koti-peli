@tool
class_name RoomPropsArt
extends Node3D
## Lastenhuoneen pienemmät esineet: lipasto, lelulaatikko, kori, lammasyövalo, matot ja
## seinähylly nukkeineen. Laitetaan esineen Visual-solmuun ja valitaan kind.
## Kohtauksen nimetyt osat (Sheep, LidPivot, Toys...) säilyvät, koska temput liikuttavat niitä.

@export_enum("dresser", "toybox", "basket", "sheep_light", "rugs", "shelf") var kind := "dresser"

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
	var wool := ArtKit.material(Color(1.0, 0.98, 0.92), 1.0)
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


func _rugs() -> void:
	var pink := _mesh("PinkRug")
	if pink != null:
		pink.mesh = ArtKit.soft_box(Vector3(1.8, 0.012, 1.2), 0.15, 12)
		var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
		for y in 64:
			for x in 64:
				var weave := 0.5 + 0.5 * sin(x * 1.6) * sin(y * 1.6)
				img.set_pixel(x, y, Color(0.96, 0.8, 0.8).lerp(Color(0.92, 0.7, 0.72), weave * 0.6))
		pink.material_override = ArtKit.textured(img)
		pink.material_override.uv1_scale = Vector3(4, 3, 1)
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
