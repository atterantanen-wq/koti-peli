class_name DayNight
extends Node
## Päivä ja yö. Yö on lempeä eikä pimeä: valo himmenee sinertäväksi ja
## yövalot (ryhmä "night_light") syttyvät. Vaihto: kutsu toggle() (ryhmä "day_night").

const NIGHT_LIGHT_GROUP := "night_light"
const FADE_TIME := 1.2

@export var sun_path: NodePath
@export var environment_path: NodePath
@export var night_sun_energy := 0.15
@export var night_ambient_energy := 0.35
@export var night_ambient_color := Color(0.62, 0.68, 1.0)
@export var night_sky_color := Color(0.3, 0.34, 0.58)
@export var star_count := 16

var is_night := false
var _day := {}
var _tween: Tween


func _ready() -> void:
	add_to_group("day_night")
	var stars := Node3D.new()
	stars.name = "NightStars"
	add_child(stars)
	_make_night_stars(stars)
	var sun := _sun()
	var env := _env()
	if sun != null:
		_day["sun"] = sun.light_energy
	if env != null:
		_day["ambient"] = env.ambient_light_energy
		_day["ambient_color"] = env.ambient_light_color
		_day["sky"] = env.background_color
	_apply_night_lights(false)


func toggle() -> void:
	set_night(not is_night)


func set_night(night: bool) -> void:
	is_night = night
	var sun := _sun()
	var env := _env()
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true) if is_inside_tree() else null
	_fade(sun, "light_energy", night_sun_energy if night else _day.get("sun", 1.0))
	_fade(env, "ambient_light_energy", night_ambient_energy if night else _day.get("ambient", 1.0))
	_fade(env, "ambient_light_color", night_ambient_color if night else _day.get("ambient_color", Color.WHITE))
	_fade(env, "background_color", night_sky_color if night else _day.get("sky", Color.WHITE))
	_apply_night_lights(night)


func _fade(obj: Object, prop: String, value: Variant) -> void:
	if obj == null:
		return
	if _tween != null:
		_tween.tween_property(obj, prop, value, FADE_TIME)
	else:
		obj.set(prop, value)


func _apply_night_lights(night: bool) -> void:
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group(NIGHT_LIGHT_GROUP):
		if node is Node3D:
			(node as Node3D).visible = night


func _sun() -> DirectionalLight3D:
	return get_node_or_null(sun_path) as DirectionalLight3D


func _env() -> Environment:
	var we := get_node_or_null(environment_path) as WorldEnvironment
	return we.environment if we != null else null


## Yötaivaan tähdet seinien yläosaan (näkyvät vain yöllä).
func _make_night_stars(parent: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.93, 0.6)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := FloatingSymbol.shape_mesh("star")
	for i in star_count:
		var star := MeshInstance3D.new()
		star.name = "NightStar%d" % i
		star.mesh = mesh
		star.material_override = mat
		star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var s := rng.randf_range(0.07, 0.13)
		if i % 2 == 0:
			# Takaseinä (katsoo huoneeseen päin).
			star.position = Vector3(rng.randf_range(-2.7, 2.7), rng.randf_range(1.75, 2.5), -2.48)
		else:
			# Vasen seinä.
			star.position = Vector3(-2.98, rng.randf_range(1.75, 2.5), rng.randf_range(-2.3, 2.2))
			star.rotation.y = PI * 0.5
		star.rotation.z = rng.randf_range(0.0, TAU)
		star.scale = Vector3.ONE * s
		star.visible = false
		star.add_to_group(NIGHT_LIGHT_GROUP)
		parent.add_child(star)
