@tool
extends Node3D
## Lastenhuoneen sänky: valkoinen metallisänky kiehkuroineen, patja, raidallinen peitto
## ja tähtityyny. Laitetaan sängyn Visual-solmuun. Peitto (Duvet) ja tyyny (Pillow) ovat
## kohtauksessa omina solmuinaan, koska sängyn temput liikuttavat niitä.

const WIDTH := 1.0
const LENGTH := 2.0
const HEAD_HEIGHT := 0.98
const FOOT_HEIGHT := 0.82
const RAIL_Y := 0.24

const METAL := Color(0.97, 0.96, 0.93)
const MINT := Color(0.62, 0.82, 0.78)
const CREAM := Color(0.99, 0.96, 0.88)


func _ready() -> void:
	if get_node_or_null("MetalFrame") != null:
		return
	var frame := MeshInstance3D.new()
	frame.name = "MetalFrame"
	frame.mesh = build_frame()
	frame.material_override = ArtKit.material(METAL, 0.45)
	add_child(frame)

	var mattress := MeshInstance3D.new()
	mattress.name = "Mattress"
	mattress.mesh = ArtKit.soft_box(Vector3(WIDTH - 0.06, 0.16, LENGTH - 0.08), 0.3)
	mattress.position = Vector3(0, RAIL_Y + 0.1, 0)
	mattress.material_override = ArtKit.material(Color(0.98, 0.98, 0.97))
	add_child(mattress)

	var duvet := get_node_or_null("Duvet") as MeshInstance3D
	if duvet != null:
		duvet.mesh = ArtKit.soft_box(Vector3(WIDTH + 0.02, 0.11, 1.45), 0.28)
		duvet.material_override = ArtKit.textured(ArtKit.stripes_image([MINT, CREAM], 14))

	var pillow := get_node_or_null("Pillow") as MeshInstance3D
	if pillow != null:
		pillow.mesh = ArtKit.soft_box(Vector3(0.72, 0.14, 0.38), 0.45)
		pillow.material_override = ArtKit.textured(ArtKit.stars_image(CREAM, [
			[Vector2(0.25, 0.35), 0.16, Color(0.38, 0.4, 0.75)],
			[Vector2(0.72, 0.6), 0.13, Color(0.6, 0.42, 0.72)],
			[Vector2(0.5, 0.2), 0.07, Color(1.0, 0.8, 0.35)],
		]))


## Koko metallikehys yhtenä kappaleena (yksi piirtokerta).
static func build_frame() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := WIDTH * 0.5 - 0.02
	var hz := LENGTH * 0.5 - 0.03
	_end_panel(st, -hz, hx, HEAD_HEIGHT)
	_end_panel(st, hz, hx, FOOT_HEIGHT)
	# Sivupuut patjan alla.
	for x in [-hx, hx]:
		ArtKit.add_tube(st, PackedVector3Array([Vector3(x, RAIL_Y, -hz), Vector3(x, RAIL_Y, hz)]), 0.02)
	# Kiehkurareunat molemmille sivuille: pitkä pääpuolella, lyhyt jalkopäässä.
	for x in [-hx - 0.005, hx + 0.005]:
		_side_guard(st, x, -hz, -0.2, 0.62)
		_side_guard(st, x, hz, 0.45, 0.5)
	return ArtKit.commit(st)


## Pääty: kulmapylväät nuppeineen, kaareva yläpuu ja pystypinnat.
static func _end_panel(st: SurfaceTool, z: float, hx: float, height: float) -> void:
	for x in [-hx, hx]:
		ArtKit.add_tube(st, PackedVector3Array([Vector3(x, 0.0, z), Vector3(x, height, z)]), 0.024)
		ArtKit.add_ball(st, Vector3(x, height + 0.03, z), 0.042, 10)
		# Pylvään yläpään kierteinen koriste.
		ArtKit.add_tube(st, ArtKit.spiral(Vector3(x, height - 0.12, z), Vector3.RIGHT, Vector3.BACK,
				0.03, 3.0, 0.0, 1.0, 36).duplicate(), 0.008, 5)
	var top := PackedVector3Array()
	for i in 17:
		var t := float(i) / 16.0
		var x := lerpf(-hx, hx, t)
		# Yläpuu kaartuu keskeltä hieman ylös ja reunoilta alas pylväisiin.
		top.append(Vector3(x, height - 0.1 + sin(t * PI) * 0.05, z))
	ArtKit.add_tube(st, top, 0.016)
	ArtKit.add_tube(st, PackedVector3Array([Vector3(-hx, RAIL_Y + 0.02, z), Vector3(hx, RAIL_Y + 0.02, z)]), 0.016)
	var bars := 8
	for i in range(1, bars):
		var t := float(i) / bars
		var x := lerpf(-hx, hx, t)
		var y_top := height - 0.1 + sin(t * PI) * 0.05
		ArtKit.add_tube(st, PackedVector3Array([Vector3(x, RAIL_Y + 0.02, z), Vector3(x, y_top, z)]), 0.01, 5, false)


## Sivulaita: yläpuu, joka kaartuu alas, ja sen alla kiehkuroita.
static func _side_guard(st: SurfaceTool, x: float, z_end: float, z_inner: float, top: float) -> void:
	var dir := signf(z_inner - z_end)
	var rail := PackedVector3Array()
	for i in 13:
		var t := float(i) / 12.0
		var z := lerpf(z_end, z_inner, t)
		# Suora alku, sitten pehmeä kaari alas patjan reunaan.
		var drop := smoothstep(0.55, 1.0, t)
		rail.append(Vector3(x, lerpf(top, RAIL_Y + 0.17, drop), z))
	ArtKit.add_tube(st, rail, 0.014)
	var length := absf(z_inner - z_end)
	var curls := maxi(1, int(length / 0.26))
	for i in curls:
		var t := (i + 0.5) / curls * 0.75
		var cz := lerpf(z_end, z_inner, t)
		var cy := lerpf(RAIL_Y + 0.18, top - 0.02, 0.5)
		var r := minf(0.11, (top - RAIL_Y - 0.18) * 0.55)
		var flip := 1.0 if i % 2 == 0 else -1.0
		var curl := ArtKit.spiral(Vector3(x, cy, cz), Vector3.UP * flip, Vector3.BACK * dir, r, 1.5,
				0.0, 0.25, 30)
		ArtKit.add_tube(st, curl, 0.009, 5)
