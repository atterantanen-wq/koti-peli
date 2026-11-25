class_name TapMarker
extends MeshInstance3D
## Pieni tähti lattialla siinä kohdassa, johon lapsi napautti. Ponnahtaa esiin ja häipyy.

const LIFETIME := 0.7
const COLOR := Color(1.0, 0.85, 0.25)


func _init() -> void:
	mesh = make_star_mesh(0.22, 0.1, 5)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = COLOR
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _ready() -> void:
	scale = Vector3.ONE * 0.2
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE, 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation:y", PI * 0.6, LIFETIME)
	tween.tween_property(material_override, "albedo_color:a", 0.0, LIFETIME - 0.15)
	tween.tween_callback(queue_free)


## Litteä tähti lattiatasossa (y = 0), kärjet säteellä outer.
static func make_star_mesh(outer: float, inner: float, points: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var n := points * 2
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var r0 := outer if i % 2 == 0 else inner
		var r1 := outer if (i + 1) % 2 == 0 else inner
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a1) * r1, 0.0, cos(a1) * r1))
		st.add_vertex(Vector3(sin(a0) * r0, 0.0, cos(a0) * r0))
	return st.commit()
