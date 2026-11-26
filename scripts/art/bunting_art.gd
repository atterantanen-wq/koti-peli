@tool
extends Node3D
## Viirinauha: pastelliset kangasviirit pilkku- ja raitakuvioin, roikkuvalla narulla.
## Laitetaan viirinauhan Visual-solmuun. Viirit (Flag0..6) säilyvät, koska ne heiluvat.

const COLORS := [Color(1.0, 0.82, 0.85), Color(0.78, 0.97, 0.88), Color(1.0, 0.93, 0.68),
		Color(0.9, 0.84, 1.0), Color(1.0, 0.78, 0.66)]


func _ready() -> void:
	if get_node_or_null("Cord") != null:
		return
	var flags: Array[Node3D] = []
	for child in get_children():
		if child.name.begins_with("Flag"):
			flags.append(child as Node3D)
	if flags.is_empty():
		return
	# Naru kulkee viirien yläkulmien kautta ja roikkuu niiden välissä.
	var pts := PackedVector3Array()
	var first := flags[0].position
	var last := flags[flags.size() - 1].position
	pts.append(first + Vector3(-0.2, 0.06, 0))
	for i in flags.size():
		var p := flags[i].position
		pts.append(p)
		if i < flags.size() - 1:
			pts.append(p.lerp(flags[i + 1].position, 0.5) + Vector3(0, -0.02, 0))
	pts.append(last + Vector3(0.2, 0.06, 0))
	ArtKit.tube_part(self, "Cord", pts, 0.005, ArtKit.material(Color(0.95, 0.92, 0.85)))
	var string := get_node_or_null("String") as Node3D
	if string != null:
		string.visible = false
	for i in flags.size():
		var mesh := flags[i].get_node_or_null("Mesh") as MeshInstance3D
		if mesh == null:
			continue
		# Kuvio on vaalea harmaa/valkoinen ja väri tulee materiaalista, jotta viirien
		# värileikki (ColorCycleReaction) vaihtaa väriä kuvion alta.
		var mat := ArtKit.textured(flag_image(i % 3))
		mat.albedo_color = COLORS[i % COLORS.size()]
		mesh.set_surface_override_material(0, mat)


## Viirin kuvio: 0 = pilkut, 1 = raidat, 2 = pienet tähdet.
static func flag_image(pattern: int) -> Image:
	var s := 32
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var base := Color(0.88, 0.88, 0.88)
	var accent := Color.WHITE
	for y in s:
		for x in s:
			var c := base
			match pattern:
				0:
					var cell := Vector2(fposmod(x + (y / 8) * 4, 8) - 4, fposmod(y, 8) - 4)
					if cell.length() < 1.6:
						c = accent
				1:
					if (x + y) % 8 < 2:
						c = accent
			img.set_pixel(x, y, c)
	if pattern == 2:
		for p in [Vector2(10, 10), Vector2(22, 18), Vector2(12, 24)]:
			for y in range(-4, 5):
				for x in range(-4, 5):
					if ArtKit.in_star(Vector2(x, y), 4.0):
						img.set_pixel(int(p.x) + x, int(p.y) + y, accent)
	return img
