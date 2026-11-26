@tool
class_name PlayerArt
extends Node3D
## Pelihahmon ulkonäkö: pyöreä satuhahmo, jolla on kasvot (silmät, posket, hymy),
## tukka, vaatteet, kädet ja jalat. Laitetaan hahmon Body-solmuun. Kädet ja jalat ovat
## omien nivelsolmujensa (ArmLeft, ArmRight, LegLeft, LegRight) alla, jotta ne voivat heilua.
##
## Hahmo voi olla tyttö tai poika (tukka) ja sillä on neljä vaihtoehtoista asua.
## dress_up() rakentaa hahmon uudelleen, joten asun voi vaihtaa kesken pelin.

const HEROES := ["girl", "boy"]
const OUTFITS := ["hoodie", "dress", "stripes", "pajamas"]

const SKIN := Color(1.0, 0.84, 0.72)
const HAIR := Color(0.47, 0.3, 0.2)
const EYE := Color(0.13, 0.1, 0.14)
const CHEEK := Color(1.0, 0.55, 0.6)
const MOUTH := Color(0.7, 0.25, 0.3)
const HAIR_TIE := Color(1.0, 0.85, 0.3)

## Asujen värit. Samoja värejä käyttää vaatekaapin kuvat (scripts/ui/wardrobe.gd).
const COLORS := {
	"hoodie": {"top": Color(1.0, 0.62, 0.38), "bottom": Color(0.36, 0.6, 0.72),
			"shoes": Color(0.98, 0.96, 0.92)},
	"dress": {"top": Color(0.98, 0.5, 0.66), "bottom": Color(0.98, 0.5, 0.66),
			"shoes": Color(0.85, 0.2, 0.3), "dots": Color(1.0, 0.97, 0.9)},
	"stripes": {"top": Color(0.25, 0.4, 0.72), "stripe": Color(0.98, 0.97, 0.94),
			"bottom": Color(0.9, 0.3, 0.28), "shoes": Color(0.98, 0.96, 0.92)},
	"pajamas": {"top": Color(0.62, 0.78, 0.98), "bottom": Color(0.62, 0.78, 0.98),
			"star": Color(1.0, 0.92, 0.45), "shoes": Color(1.0, 0.72, 0.8)},
}

const HEAD_Y := 0.86
const HEAD_R := 0.22

@export_enum("girl", "boy") var hero := "boy"
@export_enum("hoodie", "dress", "stripes", "pajamas") var outfit := "hoodie"


func _ready() -> void:
	if get_node_or_null("Head") == null:
		_build()


## Pukee hahmon: tyttö tai poika ja asu. Vanhat osat poistetaan heti, jotta uudet
## saavat samat nimet (ArmLeft jne.) ja hahmon liikkeet jatkuvat sujuvasti.
func dress_up(new_hero: String, new_outfit: String) -> void:
	if new_hero in HEROES:
		hero = new_hero
	if new_outfit in OUTFITS:
		outfit = new_outfit
	# Säilytetään raajojen asento, ettei kävely nytkähdä.
	var poses := {}
	for limb in ["ArmLeft", "ArmRight", "LegLeft", "LegRight", "Head"]:
		var n := get_node_or_null(limb) as Node3D
		if n != null:
			poses[limb] = n.rotation
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build()
	for limb in poses:
		(get_node(limb) as Node3D).rotation = poses[limb]


## Oletusasu, kun lapsi valitsee hahmon pelin alussa.
static func default_outfit(for_hero: String) -> String:
	return "dress" if for_hero == "girl" else "hoodie"


func _build() -> void:
	var c: Dictionary = COLORS.get(outfit, COLORS["hoodie"])
	var skin := ArtKit.material(SKIN, 0.8)
	var top := _top_material(c)
	var bottom := _bottom_material(c)
	var shoes := ArtKit.material(c["shoes"], 0.7)

	# Jalat: lantiosta lähtevät nivelet, joiden alla housut (tai paljaat sääret) ja kengät.
	for side in [-1.0, 1.0]:
		var leg := _pivot("LegLeft" if side < 0 else "LegRight", Vector3(0.085 * side, 0.27, 0))
		match outfit:
			"dress":
				_part(leg, "Leg", _capsule(0.052, 0.27), Vector3(0, -0.12, 0), skin)
			"stripes":
				_part(leg, "Shorts", _capsule(0.074, 0.16), Vector3(0, -0.02, 0), bottom)
				_part(leg, "Leg", _capsule(0.052, 0.22), Vector3(0, -0.14, 0), skin)
			_:
				_part(leg, "Leg", _capsule(0.065, 0.28), Vector3(0, -0.12, 0), bottom)
		var shoe_scale := Vector3(1.1, 0.7, 1.4) if outfit == "pajamas" else Vector3(0.95, 0.6, 1.3)
		_part(leg, "Shoe", _sphere(0.08), Vector3(0, -0.235, 0.03), shoes, shoe_scale)
		if outfit == "pajamas":
			# Tossujen tupsut.
			_part(leg, "Pompom", _sphere(0.03), Vector3(0, -0.2, 0.12), ArtKit.material(Color.WHITE, 0.95))

	_build_body(c, top)

	# Kädet: olkapäistä lähtevät nivelet, joiden alla hiha ja kämmen.
	for side in [-1.0, 1.0]:
		var arm := _pivot("ArmLeft" if side < 0 else "ArmRight", Vector3(0.2 * side, 0.6, 0))
		arm.rotation.z = 0.18 * side
		if outfit in ["dress", "stripes"]:
			# Lyhyet hihat, paljas käsivarsi.
			_part(arm, "Sleeve", _capsule(0.066, 0.14), Vector3(0, -0.03, 0), top)
			_part(arm, "Forearm", _capsule(0.048, 0.2), Vector3(0, -0.15, 0), skin)
		else:
			_part(arm, "Sleeve", _capsule(0.06, 0.28), Vector3(0, -0.12, 0), top)
		_part(arm, "Hand", _sphere(0.06), Vector3(0, -0.27, 0.0), skin)

	var head := _pivot("Head", Vector3(0, HEAD_Y, 0))
	_part(head, "Face", _sphere(HEAD_R), Vector3.ZERO, skin)
	_part(head, "Ears", _sphere(0.05), Vector3(0, -0.01, 0), skin, Vector3(4.6, 1.0, 0.7))
	if hero == "girl":
		_build_girl_hair(head)
	else:
		_build_boy_hair(head)
	_build_face(head)


## Vartalo asun mukaan: huppari, mekko, raitapaita tai pyjama.
func _build_body(c: Dictionary, top: Material) -> void:
	match outfit:
		"dress":
			_part(self, "Torso", _capsule(0.18, 0.36), Vector3(0, 0.52, 0), top, Vector3(1.0, 1.0, 0.9))
			var skirt := CylinderMesh.new()
			skirt.top_radius = 0.17
			skirt.bottom_radius = 0.3
			skirt.height = 0.26
			skirt.radial_segments = 20
			skirt.rings = 1
			_part(self, "Skirt", skirt, Vector3(0, 0.3, 0), top, Vector3(1.0, 1.0, 0.9))
			# Valkoiset pilkut helmassa.
			var dots := ArtKit.material(c["dots"], 0.9)
			for k in 8:
				var a := TAU * k / 8.0 + 0.2
				var r := 0.255 if k % 2 == 0 else 0.215
				var y := 0.24 if k % 2 == 0 else 0.33
				_part(self, "Dot", _sphere(0.024), Vector3(sin(a) * r, y, cos(a) * r * 0.9), dots,
						Vector3(1.0, 1.0, 0.5))
			_part(self, "Collar", _torus(0.08, 0.13), Vector3(0, 0.66, 0), dots, Vector3(1.0, 0.7, 1.0))
		"pajamas":
			_part(self, "Torso", _capsule(0.2, 0.46), Vector3(0, 0.46, 0), top, Vector3(1.0, 1.0, 0.9))
			_part(self, "Collar", _torus(0.09, 0.13), Vector3(0, 0.66, 0), ArtKit.material(c["star"], 0.8),
					Vector3(1.0, 0.7, 1.0))
			for k in 3:
				_part(self, "Button", _sphere(0.018), Vector3(0, 0.58 - k * 0.1, 0.19),
						ArtKit.material(c["star"], 0.6))
		"stripes":
			_part(self, "Torso", _capsule(0.2, 0.46), Vector3(0, 0.46, 0), top, Vector3(1.0, 1.0, 0.9))
			_part(self, "Collar", _torus(0.09, 0.13), Vector3(0, 0.66, 0), ArtKit.material(c["top"], 0.9),
					Vector3(1.0, 0.7, 1.0))
		_:
			var hoodie := top
			_part(self, "Torso", _capsule(0.2, 0.46), Vector3(0, 0.46, 0), hoodie, Vector3(1.0, 1.0, 0.9))
			# Hupparin tasku ja kaulus.
			_part(self, "Pocket", _sphere(0.1), Vector3(0, 0.39, 0.15),
					ArtKit.material((c["top"] as Color).darkened(0.08)), Vector3(1.2, 0.6, 0.35))
			_part(self, "Collar", _torus(0.09, 0.13), Vector3(0, 0.66, 0), hoodie, Vector3(1.0, 0.8, 1.0))


func _top_material(c: Dictionary) -> Material:
	match outfit:
		"stripes":
			return ArtKit.textured(ArtKit.stripes_image([c["top"], c["stripe"]], 8))
		"pajamas":
			return ArtKit.textured(_pajama_image(c))
	return ArtKit.material(c["top"], 0.9)


func _bottom_material(c: Dictionary) -> Material:
	if outfit == "pajamas":
		return ArtKit.textured(_pajama_image(c))
	return ArtKit.material(c["bottom"], 0.9)


static func _pajama_image(c: Dictionary) -> Image:
	var star: Color = c["star"]
	return ArtKit.stars_image(c["top"], [
		[Vector2(0.2, 0.2), 0.12, star], [Vector2(0.7, 0.35), 0.1, star],
		[Vector2(0.35, 0.7), 0.11, star], [Vector2(0.85, 0.85), 0.09, star],
	])


## Pojan tukka: päälakea peittävä kupu, otsatukka ja pieni kihara päälaella.
func _build_boy_hair(head: Node3D) -> void:
	var hair := ArtKit.material(HAIR, 0.95)
	_part(head, "Hair", _sphere(HEAD_R + 0.018), Vector3(0, 0.05, -0.045), hair, Vector3(1.0, 0.92, 1.0))
	_part(head, "Fringe", _sphere(0.09), Vector3(-0.07, 0.15, 0.12), hair, Vector3(1.4, 0.55, 0.8))
	_part(head, "Fringe2", _sphere(0.08), Vector3(0.08, 0.16, 0.11), hair, Vector3(1.3, 0.5, 0.8))
	var curl := ArtKit.spiral(Vector3(0.01, HEAD_R + 0.05, 0.0), Vector3.RIGHT, Vector3.UP, 0.045, 1.3,
			-PI / 2.0, 0.3, 20)
	_tube(head, "Curl", curl, 0.018, hair)


## Tytön tukka: pidempi tukka takana, otsatukka, kaksi saparoa kumilenkkeineen ja
## tähtipinni.
func _build_girl_hair(head: Node3D) -> void:
	var hair := ArtKit.material(HAIR, 0.95)
	_part(head, "Hair", _sphere(HEAD_R + 0.022), Vector3(0, 0.03, -0.05), hair, Vector3(1.04, 1.0, 1.0))
	_part(head, "HairBack", _sphere(0.18), Vector3(0, -0.12, -0.1), hair, Vector3(1.15, 0.8, 0.7))
	_part(head, "Fringe", _sphere(0.1), Vector3(0, 0.15, 0.12), hair, Vector3(1.9, 0.55, 0.8))
	var tie := ArtKit.material(HAIR_TIE, 0.6)
	for side in [-1.0, 1.0]:
		var base := Vector3(0.2 * side, 0.06, -0.04)
		_part(head, "HairTie", _sphere(0.035), base, tie)
		var tail := _part(head, "Pigtail", _capsule(0.06, 0.24), base + Vector3(0.04 * side, -0.13, -0.01), hair)
		tail.rotation.z = 0.28 * side
	# Tähtipinni otsatukassa.
	var clip := ArtKit.material(HAIR_TIE, 0.5)
	_part(head, "Clip", _sphere(0.032), Vector3(0.11, 0.17, 0.15), clip, Vector3(1.0, 1.0, 0.5))


## Kasvot: isot silmät kiiltopisteineen, posket, nenä ja hymy.
func _build_face(head: Node3D) -> void:
	var eye := ArtKit.material(EYE, 0.3)
	var shine := ArtKit.shine_material()
	for side in [-1.0, 1.0]:
		var p := Vector3(0.075 * side, 0.01, HEAD_R - 0.025)
		_part(head, "Eye", _sphere(0.034), p, eye, Vector3(0.9, 1.25, 0.6))
		_part(head, "Shine", _sphere(0.011), p + Vector3(0.012, 0.016, 0.02), shine)
		_part(head, "Cheek", _sphere(0.035), Vector3(0.12 * side, -0.06, HEAD_R - 0.045),
				ArtKit.material(CHEEK, 0.9), Vector3(1.2, 0.75, 0.5))
		if hero == "girl":
			# Pienet ripset silmän ulkoreunassa.
			var lash := _part(head, "Lash", _capsule(0.006, 0.04), p + Vector3(0.03 * side, 0.035, 0.0),
					eye)
			lash.rotation.z = -0.8 * side
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
