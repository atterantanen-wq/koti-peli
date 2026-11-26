class_name PetArt
extends RefCounted
## Lemmikin ulkonäkö koodilla: kissanpentu (oranssi raitakisu) tai koiranpentu
## (vaalearuskea, lerppakorvat ja punainen panta). Lemmikki katsoo +z-suuntaan.
##
## Osat, joita lemmikki liikuttaa (scripts/pet/pet.gd):
## Body (lantio, kallistuu istuessa), Body/Head, Body/Head/Mouth, Body/Tail,
## jalat LegFL, LegFR, LegBL, LegBR ja korvat Body/Head/EarL, EarR. Varjo: shadow().

const SIZE := 1.45

const CAT_FUR := Color(1.0, 0.64, 0.3)
const CAT_STRIPE := Color(0.85, 0.42, 0.16)
const CAT_NOSE := Color(1.0, 0.55, 0.62)
const DOG_FUR := Color(0.88, 0.69, 0.48)
const DOG_EAR := Color(0.55, 0.35, 0.22)
const DOG_NOSE := Color(0.12, 0.1, 0.11)
const COLLAR := Color(0.9, 0.2, 0.25)
const CREAM := Color(1.0, 0.95, 0.87)
const EYE := Color(0.08, 0.07, 0.09)
const CHEEK := Color(1.0, 0.6, 0.65)
const MOUTH := Color(0.72, 0.25, 0.32)

## Lantion paikka (jalkojen yläpää) ja hartioiden etäisyys siitä.
const HIP := Vector3(0, 0.15, -0.09)
const SHOULDER_Z := 0.21
const LEG_TOP := 0.15


## Rakentaa lemmikin kuvan. kind: "cat" tai "dog".
static func build(kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Art"
	root.scale = Vector3.ONE * SIZE
	var cat := kind == "cat"
	var fur := ArtKit.plush(CAT_FUR if cat else DOG_FUR)
	var cream := ArtKit.plush(CREAM)
	var eye := ArtKit.material(EYE, 0.2)
	var shine := ArtKit.shine_material()

	var body := _pivot(root, "Body", HIP)
	ArtKit.part(body, "Torso", ArtKit.sphere(0.1, 20), Vector3(0, 0.03, 0.1), fur, Vector3(0.9, 0.85, 1.55))
	ArtKit.part(body, "Chest", ArtKit.sphere(0.07, 14), Vector3(0, 0.0, 0.2), cream, Vector3(0.9, 1.0, 0.7))
	if cat:
		# Raidat selässä.
		for i in 3:
			ArtKit.part(body, "Stripe%d" % i, ArtKit.sphere(0.03, 10), Vector3(0, 0.105, 0.02 + i * 0.07),
					ArtKit.material(CAT_STRIPE, 0.95), Vector3(2.6, 0.5, 0.6))
	else:
		var collar := TorusMesh.new()
		collar.inner_radius = 0.05
		collar.outer_radius = 0.064
		var c := ArtKit.part(body, "Collar", collar, Vector3(0, 0.1, 0.21), ArtKit.material(COLLAR, 0.5))
		c.rotation.x = 0.9
		ArtKit.part(body, "Tag", ArtKit.sphere(0.014, 8), Vector3(0, 0.055, 0.26),
				ArtKit.material(Color(1.0, 0.82, 0.25), 0.3))

	var head := _pivot(body, "Head", Vector3(0, 0.13, 0.23))
	var head_r := 0.085 if cat else 0.09
	ArtKit.part(head, "Skull", ArtKit.sphere(head_r, 20), Vector3.ZERO, fur, Vector3(1.08, 0.95, 1.0))
	if cat:
		ArtKit.part(head, "Muzzle", ArtKit.sphere(0.04, 14), Vector3(0, -0.028, 0.068), cream,
				Vector3(1.3, 0.8, 0.8))
		ArtKit.part(head, "Nose", ArtKit.sphere(0.013, 8), Vector3(0, -0.006, 0.1),
				ArtKit.material(CAT_NOSE, 0.5), Vector3(1.3, 0.8, 0.8))
		for i in 3:
			ArtKit.part(head, "Mark%d" % i, ArtKit.sphere(0.012, 8),
					Vector3((i - 1) * 0.022, 0.06, 0.06), ArtKit.material(CAT_STRIPE, 0.95),
					Vector3(0.5, 1.6, 0.5))
		var whisker := ArtKit.material(Color(1, 1, 1), 0.6)
		for side in [-1.0, 1.0]:
			for k in 2:
				var a := Vector3(0.035 * side, -0.025 - k * 0.012, 0.09)
				var b := a + Vector3(0.07 * side, 0.012 - k * 0.02, -0.01)
				ArtKit.tube_part(head, "Whisker", PackedVector3Array([a, b]), 0.0025, whisker)
	else:
		ArtKit.part(head, "Muzzle", ArtKit.sphere(0.045, 14), Vector3(0, -0.025, 0.08), cream,
				Vector3(1.1, 0.85, 1.3))
		ArtKit.part(head, "Nose", ArtKit.sphere(0.02, 10), Vector3(0, -0.005, 0.135),
				ArtKit.material(DOG_NOSE, 0.3), Vector3(1.2, 0.85, 0.9))
		ArtKit.part(head, "Spot", ArtKit.sphere(0.04, 12), Vector3(0.04, 0.035, 0.05),
				ArtKit.material(DOG_EAR, 0.95), Vector3(1.0, 0.9, 0.6))
	var mouth := ArtKit.part(head, "Mouth", ArtKit.sphere(0.02, 10),
			Vector3(0, -0.05, 0.09 if cat else 0.115), ArtKit.material(MOUTH, 0.6), Vector3(1.0, 0.15, 0.5))
	mouth.visible = false
	for side in [-1.0, 1.0]:
		var p := Vector3(0.036 * side, 0.018, head_r * 0.85)
		ArtKit.part(head, "Eye", ArtKit.sphere(0.017, 10), p, eye, Vector3(1.0, 1.15, 0.6))
		ArtKit.part(head, "Shine", ArtKit.sphere(0.006, 6), p + Vector3(0.006, 0.008, 0.01), shine)
		ArtKit.part(head, "Cheek", ArtKit.sphere(0.016, 8), Vector3(0.06 * side, -0.02, 0.06),
				ArtKit.material(CHEEK, 0.9), Vector3(1.2, 0.7, 0.5))
		var ear := _pivot(head, "EarL" if side < 0 else "EarR", Vector3.ZERO)
		if cat:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.034
			cone.height = 0.075
			cone.radial_segments = 10
			cone.rings = 1
			var e := ArtKit.part(ear, "Ear", cone, Vector3(0.05 * side, 0.085, -0.005), fur)
			e.rotation = Vector3(-0.1, 0, -0.35 * side)
			var inner := CylinderMesh.new()
			inner.top_radius = 0.0
			inner.bottom_radius = 0.02
			inner.height = 0.05
			inner.radial_segments = 8
			inner.rings = 1
			var ie := ArtKit.part(ear, "EarInner", inner, Vector3(0.049 * side, 0.08, 0.007),
					ArtKit.material(CAT_NOSE, 0.9))
			ie.rotation = Vector3(-0.1, 0, -0.35 * side)
		else:
			var e := ArtKit.part(ear, "Ear", ArtKit.sphere(0.042, 12), Vector3(0.088 * side, -0.005, -0.01),
					ArtKit.material(DOG_EAR, 0.95), Vector3(0.45, 1.35, 0.85))
			e.rotation.z = 0.25 * side

	var tail := _pivot(body, "Tail", Vector3(0, 0.05, -0.06))
	var tail_pts := PackedVector3Array([Vector3.ZERO, Vector3(0, 0.04, -0.07), Vector3(0, 0.12, -0.12),
			Vector3(0, 0.2, -0.11), Vector3(0, 0.25, -0.07)]) if cat else \
			PackedVector3Array([Vector3.ZERO, Vector3(0, 0.05, -0.05), Vector3(0, 0.11, -0.06)])
	ArtKit.tube_part(tail, "TailTube", tail_pts, 0.017 if cat else 0.02,
			ArtKit.material(CAT_STRIPE if cat else DOG_FUR, 0.95))
	ArtKit.part(tail, "TailTip", ArtKit.sphere(0.02, 8), tail_pts[tail_pts.size() - 1],
			ArtKit.material(CAT_STRIPE, 0.95) if cat else cream)

	for leg_name in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var front: bool = leg_name.begins_with("LegF")
		var side := -1.0 if leg_name.ends_with("L") else 1.0
		var leg := _pivot(root, leg_name, Vector3(0.045 * side, LEG_TOP, HIP.z + SHOULDER_Z if front else -0.06))
		ArtKit.part(leg, "Leg", ArtKit.capsule(0.03, 0.17), Vector3(0, -0.075, 0), fur)
		ArtKit.part(leg, "Paw", ArtKit.sphere(0.033, 10), Vector3(0, -0.135, 0.012), cream,
				Vector3(1.0, 0.7, 1.2))

	return root


## Pehmeä varjo lemmikin alle (erillään kuvasta, jotta se ei kallistu kuvan mukana).
static func shadow() -> MeshInstance3D:
	var m := ArtKit.soft_shadow(Vector2(0.42, 0.62) * SIZE, 0.4)
	m.name = "Shadow"
	m.position = Vector3(0, 0.016, 0.05)
	return m


static func _pivot(parent: Node3D, pivot_name: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = pivot_name
	n.position = pos
	parent.add_child(n)
	return n
