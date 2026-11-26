@tool
extends Node3D
## Puinen leikkijuna: pastellinpunainen veturi valkoisella katolla, pyöreä höyrypannu,
## kultainen savupiippu, pyörät napoineen ja vaunu palikkalastissa. Laitetaan junan
## Visual-solmuun. Kohtauksen osat (Train, Engine, Chimney...) säilyvät tempuille.

const PINK := Color(0.97, 0.7, 0.76)
const CREAM := Color(0.99, 0.96, 0.9)
const WOOD := Color(0.9, 0.75, 0.55)
const GOLD := Color(1.0, 0.82, 0.4)
const MINT := Color(0.62, 0.84, 0.76)


func _ready() -> void:
	if get_node_or_null("Train/Engine/CabRoof") != null:
		return
	var pink := ArtKit.material(PINK)
	var cream := ArtKit.material(CREAM)
	var wood := ArtKit.material(WOOD)
	_dress("Train/Engine/Base", ArtKit.soft_box(Vector3(0.11, 0.045, 0.2), 0.3, 8), wood)
	_dress("Train/Engine/Cab", ArtKit.soft_box(Vector3(0.1, 0.09, 0.08), 0.3, 8), pink)
	var cab := get_node_or_null("Train/Engine/Cab") as Node3D
	var engine := get_node_or_null("Train/Engine") as Node3D
	if engine != null and cab != null:
		ArtKit.part(engine, "CabRoof", ArtKit.soft_box(Vector3(0.12, 0.02, 0.1), 0.4, 8),
				cab.position + Vector3(0, 0.055, 0), cream)
		ArtKit.part(engine, "CabWindow", ArtKit.soft_box(Vector3(0.102, 0.03, 0.03), 0.4, 6),
				cab.position + Vector3(0, 0.015, 0), ArtKit.material(Color(0.6, 0.75, 0.9), 0.3))
	_dress("Train/Engine/Boiler", ArtKit.cylinder(0.04, 0.11, 16), cream)
	var boiler := get_node_or_null("Train/Engine/Boiler") as Node3D
	if engine != null and boiler != null:
		for dz in [-0.03, 0.03]:
			var band := ArtKit.part(engine, "Band", ArtKit.cylinder(0.043, 0.012, 16),
					boiler.position + Vector3(0, 0, dz), pink)
			band.rotation.x = PI / 2.0
		var front := ArtKit.part(engine, "BoilerFront", ArtKit.sphere(0.04, 12),
				boiler.position + Vector3(0, 0, 0.055), cream, Vector3(1, 1, 0.3))
		front.name = "BoilerFront"
	var chimney_mesh := CylinderMesh.new()
	chimney_mesh.top_radius = 0.026
	chimney_mesh.bottom_radius = 0.015
	chimney_mesh.height = 0.06
	chimney_mesh.radial_segments = 12
	_dress("Train/Engine/Chimney", chimney_mesh, ArtKit.material(GOLD, 0.4))
	_dress("Train/Wagon/Box", ArtKit.soft_box(Vector3(0.1, 0.06, 0.14), 0.3, 8), ArtKit.material(MINT))
	var wagon := get_node_or_null("Train/Wagon") as Node3D
	if wagon != null:
		var colors := [Color(1.0, 0.85, 0.4), Color(0.97, 0.6, 0.6), Color(0.6, 0.75, 1.0)]
		for i in 3:
			ArtKit.part(wagon, "Cargo%d" % i, ArtKit.soft_box(Vector3(0.035, 0.035, 0.035), 0.3, 6),
					Vector3(-0.025 + (i % 2) * 0.05, 0.12 + (i / 2) * 0.035, -0.03 + i * 0.03),
					ArtKit.material(colors[i]))
	# Pyörät: pinkit renkaat ja valkoinen napa.
	var wheel := ArtKit.cylinder(0.03, 0.016, 16)
	for w in find_children("Wheel*", "MeshInstance3D", true, false):
		(w as MeshInstance3D).mesh = wheel
		(w as MeshInstance3D).material_override = pink
		ArtKit.part(w, "Hub", ArtKit.cylinder(0.012, 0.02, 10), Vector3.ZERO, cream)


func _dress(path: String, mesh: Mesh, mat: Material) -> void:
	var m := get_node_or_null(path) as MeshInstance3D
	if m == null:
		return
	m.mesh = mesh
	m.material_override = mat
