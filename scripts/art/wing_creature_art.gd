@tool
extends Node3D
## Sininen siipiotus-pehmo: pyöreä tyynymäinen otus, liilan raidallinen vatsa, pienet
## tuntosarvet, posket ja hohtavat siivet. Laitetaan otuksen Visual-solmuun.

const BLUE := Color(0.55, 0.85, 0.93)
const BELLY := Color(0.72, 0.58, 0.9)
const BELLY_STRIPE := Color(0.62, 0.47, 0.84)
const ANTENNA := Color(0.62, 0.5, 0.88)


func _ready() -> void:
	if get_node_or_null("Cheek0") != null:
		return
	var body := get_node_or_null("Body") as MeshInstance3D
	if body != null:
		body.mesh = ArtKit.soft_box(Vector3(0.3, 0.27, 0.22), 0.75, 16)
		body.material_override = ArtKit.plush(BLUE)
	var belly := get_node_or_null("Belly") as MeshInstance3D
	if belly != null:
		belly.mesh = ArtKit.sphere(0.08, 16)
		belly.position = Vector3(0, -0.035, 0.085)
		belly.scale = Vector3(1.25, 0.95, 0.4)
		var m := ArtKit.textured(ArtKit.stripes_image([BELLY, BELLY_STRIPE], 9))
		belly.material_override = m
	var eye := ArtKit.material(Color(0.12, 0.12, 0.2), 0.3)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var e := get_node_or_null("EyeLeft" if i == 0 else "EyeRight") as MeshInstance3D
		if e != null:
			e.mesh = ArtKit.sphere(0.018, 10)
			e.position = Vector3(0.055 * side, 0.045, 0.105)
			e.material_override = eye
		ArtKit.part(self, "Shine%d" % i, ArtKit.sphere(0.006, 6), Vector3(0.058 * side, 0.052, 0.121),
				ArtKit.shine_material())
		ArtKit.part(self, "Cheek%d" % i, ArtKit.sphere(0.02, 10), Vector3(0.088 * side, 0.02, 0.098),
				ArtKit.material(Color(1.0, 0.62, 0.72)), Vector3(1.2, 0.7, 0.4))
		# Tuntosarvi: kaareva varsi ja pallo päässä.
		var base := Vector3(0.05 * side, 0.12, 0.0)
		var tip := base + Vector3(0.03 * side, 0.07, -0.01)
		var stalk := PackedVector3Array([base, base.lerp(tip, 0.5) + Vector3(0.012 * side, 0, 0), tip])
		ArtKit.tube_part(self, "Antenna%d" % i, stalk, 0.008, ArtKit.material(ANTENNA))
		ArtKit.part(self, "AntennaTip%d" % i, ArtKit.sphere(0.018, 10), tip, ArtKit.material(ANTENNA))
	ArtKit.tube_part(self, "Smile", ArtKit.smile(Vector3(0, 0.022, 0.112), 0.022), 0.003, eye)
	# Siivet: ohuet pyöreät lehdet, jotka hohtavat sinisestä vaaleanpunaiseen.
	var wing_mat := ArtKit.textured(ArtKit.gradient_image([Color(0.7, 0.9, 1.0), Color(0.85, 0.75, 1.0),
			Color(1.0, 0.75, 0.85)]), 0.35)
	for wing_name in ["WingLeft/Mesh", "WingRight/Mesh"]:
		var w := get_node_or_null(wing_name) as MeshInstance3D
		if w != null:
			w.mesh = ArtKit.soft_box(Vector3(0.19, 0.018, 0.13), 0.55, 10)
			w.material_override = wing_mat
