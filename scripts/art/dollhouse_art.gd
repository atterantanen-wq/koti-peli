@tool
extends Node3D
## Nukkekoti: kermanvalkoiset seinät, punainen tiilikatto, savupiippu, ikkunanpuitteet,
## kaari-ovi ja kukkalaatikko. Laitetaan nukkekodin Visual-solmuun.

const WALL := Color(0.99, 0.94, 0.84)
const ROOF := Color(0.8, 0.26, 0.24)
const ROOF_DARK := Color(0.66, 0.2, 0.2)
const TRIM := Color(0.86, 0.7, 0.45)
const GLASS := Color(0.62, 0.78, 0.9)


func _ready() -> void:
	if get_node_or_null("Chimney") != null:
		return
	var wall := ArtKit.material(WALL)
	var trim := ArtKit.material(TRIM)
	var house := get_node_or_null("House") as MeshInstance3D
	if house != null:
		house.material_override = wall
	var roof := get_node_or_null("Roof") as MeshInstance3D
	if roof != null:
		roof.material_override = ArtKit.textured(ArtKit.stripes_image([ROOF, ROOF, ROOF_DARK], 21))
	# Savupiippu katolla.
	ArtKit.part(self, "Chimney", _box(Vector3(0.06, 0.12, 0.06)), Vector3(0.17, 0.6, -0.05), wall)
	ArtKit.part(self, "ChimneyTop", _box(Vector3(0.075, 0.02, 0.075)), Vector3(0.17, 0.665, -0.05),
			ArtKit.material(ROOF_DARK))
	# Nurkkalistat ja ikkunanpuitteet piirretään yhdellä kertaa.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [-0.27, 0.27]:
		ArtKit.add_box(st, Vector3(x, 0.225, 0.195), Vector3(0.025, 0.45, 0.025))
	# Ikkunat: lasi, puitteet ja ristikko. Valot (Light0..2) syttyvät lasin päälle.
	for n in ["Window0", "Window1", "Window2"]:
		var w := get_node_or_null(n) as MeshInstance3D
		if w == null:
			continue
		w.material_override = ArtKit.material(GLASS, 0.3)
		var p := w.position + Vector3(0, 0, 0.012)
		var frame := Vector3(0.14, 0.13, 0.012)
		for dy in [-frame.y / 2.0, frame.y / 2.0]:
			ArtKit.add_box(st, p + Vector3(0, dy, 0), Vector3(frame.x, 0.016, 0.012))
		for dx in [-frame.x / 2.0, frame.x / 2.0]:
			ArtKit.add_box(st, p + Vector3(dx, 0, 0), Vector3(0.016, frame.y, 0.012))
		ArtKit.add_box(st, p, Vector3(0.008, frame.y, 0.01))
		ArtKit.add_box(st, p, Vector3(frame.x, 0.008, 0.01))
	ArtKit.part(self, "Trim", ArtKit.commit(st), Vector3.ZERO, trim)
	# Kaari-ovi, nuppi ja kynnys.
	var door := get_node_or_null("Door") as MeshInstance3D
	if door != null:
		var arch := ArtKit.part(self, "DoorArch", ArtKit.cylinder(0.05, 0.01, 16),
				door.position + Vector3(0, 0.08, 0), door.material_override if door.material_override \
				else door.get_surface_override_material(0))
		arch.rotation.x = PI / 2.0
		ArtKit.part(self, "Knob", ArtKit.sphere(0.008, 8), door.position + Vector3(0.03, 0, 0.01),
				ArtKit.material(Color(1.0, 0.82, 0.35), 0.3))
		ArtKit.part(self, "Step", _box(Vector3(0.14, 0.02, 0.05)), Vector3(0, 0.01, 0.22), trim)
	# Kukkalaatikko vasemman alaikkunan paikalla.
	ArtKit.part(self, "FlowerBox", _box(Vector3(0.13, 0.03, 0.035)), Vector3(-0.15, 0.08, 0.215),
			ArtKit.material(Color(0.5, 0.72, 0.5)))
	for i in 4:
		var c := [Color(1.0, 0.6, 0.75), Color(1.0, 0.85, 0.4)][i % 2] as Color
		ArtKit.part(self, "Flower", ArtKit.sphere(0.013, 8), Vector3(-0.195 + i * 0.03, 0.105, 0.22),
				ArtKit.material(c))


static func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b
