@tool
extends Node3D
## Pelihahmon ulkonäkö: pyöreä satuhahmo, jolla on kasvot (silmät, posket, hymy),
## tukka, huppari, kädet ja jalat. Laitetaan hahmon Body-solmuun. Kädet ja jalat ovat
## omien nivelsolmujensa (ArmLeft, ArmRight, LegLeft, LegRight) alla, jotta ne voivat heilua.

const SKIN := Color(1.0, 0.84, 0.72)
const HAIR := Color(0.47, 0.3, 0.2)
const HOODIE := Color(1.0, 0.62, 0.38)
const PANTS := Color(0.36, 0.6, 0.72)
const SHOES := Color(0.98, 0.96, 0.92)
const EYE := Color(0.13, 0.1, 0.14)
const CHEEK := Color(1.0, 0.55, 0.6)
const MOUTH := Color(0.7, 0.25, 0.3)

const HEAD_Y := 0.86
const HEAD_R := 0.22


func _ready() -> void:
	if get_node_or_null("Head") != null:
		return
	var skin := ArtKit.material(SKIN, 0.8)
	var hoodie := ArtKit.material(HOODIE, 0.9)
	var pants := ArtKit.material(PANTS, 0.9)

	# Jalat: lantiosta lähtevät nivelet, joiden alla housut ja kengät.
	for side in [-1.0, 1.0]:
		var leg := _pivot("LegLeft" if side < 0 else "LegRight", Vector3(0.085 * side, 0.27, 0))
		_part(leg, "Leg", _capsule(0.065, 0.28), Vector3(0, -0.12, 0), pants)
		_part(leg, "Shoe", _sphere(0.08), Vector3(0, -0.235, 0.03), ArtKit.material(SHOES, 0.7),
				Vector3(0.95, 0.6, 1.3))

	_part(self, "Torso", _capsule(0.2, 0.46), Vector3(0, 0.46, 0), hoodie, Vector3(1.0, 1.0, 0.9))
	# Hupparin tasku ja kaulus.
	_part(self, "Pocket", _sphere(0.1), Vector3(0, 0.39, 0.15), ArtKit.material(HOODIE.darkened(0.08)),
			Vector3(1.2, 0.6, 0.35))
	_part(self, "Collar", _torus(0.09, 0.13), Vector3(0, 0.66, 0), hoodie, Vector3(1.0, 0.8, 1.0))

	# Kädet: olkapäistä lähtevät nivelet, joiden alla hiha ja kämmen.
	for side in [-1.0, 1.0]:
		var arm := _pivot("ArmLeft" if side < 0 else "ArmRight", Vector3(0.2 * side, 0.6, 0))
		arm.rotation.z = 0.18 * side
		_part(arm, "Sleeve", _capsule(0.06, 0.28), Vector3(0, -0.12, 0), hoodie)
		_part(arm, "Hand", _sphere(0.06), Vector3(0, -0.27, 0.0), skin)

	var head := _pivot("Head", Vector3(0, HEAD_Y, 0))
	_part(head, "Face", _sphere(HEAD_R), Vector3.ZERO, skin)
	_part(head, "Ears", _sphere(0.05), Vector3(0, -0.01, 0), skin, Vector3(4.6, 1.0, 0.7))
	# Tukka: pään takaosaa ja päälakea peittävä kupu ja pieni kihara päälaella.
	var hair := ArtKit.material(HAIR, 0.95)
	_part(head, "Hair", _sphere(HEAD_R + 0.018), Vector3(0, 0.05, -0.045), hair, Vector3(1.0, 0.92, 1.0))
	_part(head, "Fringe", _sphere(0.09), Vector3(-0.07, 0.15, 0.12), hair, Vector3(1.4, 0.55, 0.8))
	_part(head, "Fringe2", _sphere(0.08), Vector3(0.08, 0.16, 0.11), hair, Vector3(1.3, 0.5, 0.8))
	var curl := ArtKit.spiral(Vector3(0.01, HEAD_R + 0.05, 0.0), Vector3.RIGHT, Vector3.UP, 0.045, 1.3,
			-PI / 2.0, 0.3, 20)
	_tube(head, "Curl", curl, 0.018, hair)

	# Kasvot: isot silmät kiiltopisteineen, posket, nenä ja hymy.
	var eye := ArtKit.material(EYE, 0.3)
	var shine := ArtKit.shine_material()
	for side in [-1.0, 1.0]:
		var p := Vector3(0.075 * side, 0.01, HEAD_R - 0.025)
		_part(head, "Eye", _sphere(0.034), p, eye, Vector3(0.9, 1.25, 0.6))
		_part(head, "Shine", _sphere(0.011), p + Vector3(0.012, 0.016, 0.02), shine)
		_part(head, "Cheek", _sphere(0.035), Vector3(0.12 * side, -0.06, HEAD_R - 0.045),
				ArtKit.material(CHEEK, 0.9), Vector3(1.2, 0.75, 0.5))
	_part(head, "Nose", _sphere(0.022), Vector3(0, -0.035, HEAD_R), ArtKit.material(SKIN.darkened(0.06)))
	var smile := ArtKit.arc(Vector3(0, -0.055, HEAD_R - 0.012), Vector3.RIGHT, Vector3.UP, 0.045,
			PI * 1.18, PI * 1.82, 10)
	_tube(head, "Smile", smile, 0.009, ArtKit.material(MOUTH, 0.6))


func _pivot(pivot_name: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = pivot_name
	n.position = pos
	add_child(n)
	return n


func _part(parent: Node3D, part_name: String, mesh: Mesh, pos: Vector3, mat: Material,
		scl := Vector3.ONE) -> MeshInstance3D:
	return ArtKit.part(parent, part_name, mesh, pos, mat, scl)


func _tube(parent: Node3D, part_name: String, points: PackedVector3Array, radius: float,
		mat: Material) -> void:
	ArtKit.tube_part(parent, part_name, points, radius, mat)


static func _sphere(r: float) -> SphereMesh:
	return ArtKit.sphere(r)


static func _capsule(r: float, h: float) -> CapsuleMesh:
	return ArtKit.capsule(r, h)


static func _torus(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 16
	t.ring_segments = 8
	return t
