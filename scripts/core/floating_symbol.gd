class_name FloatingSymbol
extends MeshInstance3D
## Sydän, tähti tai nuotti, joka nousee ilmaan, keinuu ja häipyy. Kääntyy aina kameraan päin.

var start := Vector3.ZERO
var rise := 0.6
var lifetime := 1.2
var start_delay := 0.0
var shape := "heart"

static var _meshes := {}


func _init(p_shape: String = "heart", color: Color = Color.WHITE, size: float = 0.12) -> void:
	shape = p_shape
	mesh = shape_mesh(shape)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.albedo_color = color
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scale = Vector3.ONE * size


func _ready() -> void:
	global_position = start
	visible = start_delay <= 0.0
	var base_scale := scale
	scale = base_scale * 0.2
	var tween := create_tween()
	if start_delay > 0.0:
		tween.tween_interval(start_delay)
		tween.tween_callback(show)
	tween.tween_property(self, "scale", base_scale, 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "global_position:y", start.y + rise, lifetime) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "global_position:x", start.x + 0.08, lifetime * 0.5) \
			.set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(material_override, "albedo_color:a", 0.0, lifetime * 0.4) \
			.set_delay(lifetime * 0.6)
	tween.tween_callback(queue_free)


## Kuvion muoto litteänä 3D-kappaleena (koko noin 1 x 1, keskellä origo).
static func shape_mesh(name: String) -> ArrayMesh:
	if _meshes.has(name):
		return _meshes[name]
	var outline := PackedVector2Array()
	match name:
		"star":
			for i in 10:
				var a := TAU * i / 10.0
				var r := 0.5 if i % 2 == 0 else 0.22
				outline.append(Vector2(sin(a), cos(a)) * r)
		"note":
			# Kahdeksasosanuotti: pallo, varsi ja lippu yhtenä ääriviivana.
			outline = PackedVector2Array([
					Vector2(-0.05, -0.30), Vector2(0.05, -0.30), Vector2(0.05, 0.38),
					Vector2(0.35, 0.18), Vector2(0.35, 0.30), Vector2(0.05, 0.50),
					Vector2(-0.05, 0.50), Vector2(-0.05, -0.20)])
			for i in 12:
				var a := TAU * i / 12.0
				outline.append(Vector2(-0.18, -0.30) + Vector2(cos(a) * 0.17, sin(a) * 0.13))
		_:
			# Sydänkäyrä.
			for i in 32:
				var t := TAU * i / 32.0
				var x := 16.0 * pow(sin(t), 3)
				var y := 13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t)
				outline.append(Vector2(x, y + 2.0) / 34.0)
	var built := flat_mesh(outline)
	_meshes[name] = built
	return built


## Tekee ääriviivasta litteän kappaleen XY-tasoon.
static func flat_mesh(outline: PackedVector2Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.BACK)
	var tris := Geometry2D.triangulate_polygon(outline)
	if tris.is_empty():
		# Ääriviiva ei ollut yksinkertainen: viuhka keskipisteestä.
		for i in outline.size():
			tris.append_array([outline.size(), i, (i + 1) % outline.size()])
		outline = outline.duplicate()
		outline.append(Vector2.ZERO)
	for idx in tris:
		st.add_vertex(Vector3(outline[idx].x, outline[idx].y, 0.0))
	return st.commit()
