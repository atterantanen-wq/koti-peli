class_name ColorCycleReaction
extends Reaction
## Osan väri vaihtuu vuorotellen annettuihin väreihin ja palaa lopuksi omaksi väriksi.
## Useampi osa: parts (jokainen aloittaa hieman myöhemmin, kuin tuuli kulkisi).

@export var parts: Array[NodePath] = []
@export var colors: Array[Color] = [Color(1, 0.75, 0.8), Color(0.7, 0.92, 0.8), Color(1, 0.92, 0.6)]
@export var step_time := 0.3
@export var stagger := 0.08


func play(ctx: ReactionContext) -> Tween:
	if not ctx.prop.is_inside_tree() or colors.is_empty():
		return null
	var mats: Array[StandardMaterial3D] = []
	var originals: Array[Color] = []
	for path in parts:
		var mesh := ctx.prop.get_node_or_null(path) as MeshInstance3D
		var mat := _own_material(mesh) if mesh != null else null
		if mat == null:
			continue
		var original: Color = mesh.get_meta("original_color", mat.albedo_color)
		mesh.set_meta("original_color", original)
		mat.albedo_color = original
		mats.append(mat)
		originals.append(original)
	if mats.is_empty():
		return null
	var palette := colors.duplicate()
	var step := step_time
	var lag := stagger
	var total := _length() - delay
	var tween := ctx.prop.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_method(func(t: float) -> void:
		for i in mats.size():
			# Värijono: oma väri -> värit (eri kohdasta aloittaen) -> oma väri.
			var local := (t - lag * i) / step
			var seq: Array[Color] = [originals[i]]
			for k in palette.size():
				seq.append(palette[(k + i + 1) % palette.size()])
			seq.append(originals[i])
			if local <= 0.0:
				mats[i].albedo_color = originals[i]
			elif local >= seq.size() - 1:
				mats[i].albedo_color = originals[i]
			else:
				var k0 := int(local)
				mats[i].albedo_color = seq[k0].lerp(seq[k0 + 1], local - k0),
		0.0, total, total)
	tween.tween_callback(func() -> void:
		for i in mats.size():
			mats[i].albedo_color = originals[i])
	return tween


## Osalle oma kopio materiaalista, jotta värinvaihto ei muuta muita samanvärisiä osia.
static func _own_material(mesh: MeshInstance3D) -> StandardMaterial3D:
	if mesh.has_meta("own_material"):
		return mesh.get_meta("own_material")
	var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		return null
	var copy := mat.duplicate() as StandardMaterial3D
	mesh.set_surface_override_material(0, copy)
	mesh.set_meta("own_material", copy)
	return copy


func _length() -> float:
	return delay + stagger * parts.size() + step_time * (colors.size() + 1)
