@tool
extends Node3D
## Pandapehmo: sileät muodot, silmälaikut kiiltävine silmineen, kuono, nenä ja hymy.
## Laitetaan pandan Visual-solmuun. Kohtauksen osat (Body, Head, EyeLeft...) säilyvät,
## tämä vain pehmentää ne ja lisää yksityiskohdat.

const WHITE := Color(0.98, 0.97, 0.95)
const BLACK := Color(0.17, 0.16, 0.19)


func _ready() -> void:
	if get_node_or_null("Muzzle") != null:
		return
	var white := ArtKit.material(WHITE, 0.95)
	var black := ArtKit.material(BLACK, 0.95)
	_soft("Body", ArtKit.sphere(0.13, 24), Vector3(1.0, 1.05, 0.92))
	_soft("Head", ArtKit.sphere(0.105, 24), Vector3(1.12, 0.95, 1.0))
	for n in ["EarLeft", "EarRight"]:
		_soft(n, ArtKit.sphere(0.04, 12), Vector3(1.0, 1.0, 0.7))
	# Silmälaikut ovat vinot pisarat, kuten oikeilla pandoilla.
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var patch := get_node_or_null("EyeLeft" if i == 0 else "EyeRight") as MeshInstance3D
		if patch != null:
			patch.mesh = ArtKit.sphere(0.04, 12)
			patch.position = Vector3(0.045 * side, 0.172, 0.088)
			patch.rotation = Vector3(0, 0.35 * side, 0.55 * side)
			patch.scale = Vector3(0.65, 0.95, 0.5)
		ArtKit.part(self, "EyeBead%d" % i, ArtKit.sphere(0.012, 10), Vector3(0.044 * side, 0.18, 0.104),
				ArtKit.material(Color(0.06, 0.05, 0.07), 0.15))
		ArtKit.part(self, "EyeShine%d" % i, ArtKit.sphere(0.006, 6), Vector3(0.047 * side, 0.185, 0.114),
				ArtKit.shine_material())
	ArtKit.part(self, "Muzzle", ArtKit.sphere(0.045, 16), Vector3(0, 0.135, 0.09), white,
			Vector3(1.25, 0.8, 0.8))
	var nose := get_node_or_null("Nose") as MeshInstance3D
	if nose != null:
		nose.mesh = ArtKit.sphere(0.04, 12)
		nose.position = Vector3(0, 0.148, 0.124)
		nose.scale = Vector3(0.38, 0.26, 0.25)
	ArtKit.tube_part(self, "Smile", ArtKit.smile(Vector3(0, 0.122, 0.124), 0.03), 0.004, black)
	# Kädet ja jalat ovat soikeita pehmotassuja.
	_soft("ArmLeft", ArtKit.sphere(0.05, 12), Vector3(0.9, 1.35, 0.9))
	_soft("ArmRight", ArtKit.sphere(0.05, 12), Vector3(0.9, 1.35, 0.9))
	_soft("LegLeft", ArtKit.sphere(0.05, 12), Vector3(1.05, 0.85, 1.3))
	_soft("LegRight", ArtKit.sphere(0.05, 12), Vector3(1.05, 0.85, 1.3))
	# Tassujen pohjissa vaaleat anturat.
	for side in [-1.0, 1.0]:
		ArtKit.part(self, "Pad", ArtKit.sphere(0.025, 10), Vector3(0.07 * side, -0.11, 0.135), white,
				Vector3(1.0, 1.0, 0.4))


func _soft(node_name: String, mesh: Mesh, scl: Vector3) -> void:
	var m := get_node_or_null(node_name) as MeshInstance3D
	if m == null:
		return
	m.mesh = mesh
	m.scale = scl
