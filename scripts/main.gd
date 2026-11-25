extends Node3D
## Tyhjä testikohtaus (vaihe 0).
## Kuutio pyörii, ja napautus mihin tahansa vaihtaa sen väriä ja pompauttaa sitä.
## Tällä tarkistetaan, että peli aukeaa ja kosketus toimii iPhonen Safarissa.

const COLORS: Array[Color] = [
	Color(0.4, 0.6, 1.0),   # sininen
	Color(1.0, 0.55, 0.6),  # vaaleanpunainen
	Color(1.0, 0.85, 0.3),  # keltainen
	Color(0.45, 0.85, 0.55), # vihreä
]
const SPIN_SPEED := 0.8  # radiaania sekunnissa

var color_index := 0
var tap_count := 0
var _build_text := ""

@onready var cube: MeshInstance3D = $Cube
@onready var info_label: Label = $UI/InfoLabel
@onready var _material: StandardMaterial3D = cube.get_surface_override_material(0).duplicate()


func _ready() -> void:
	cube.set_surface_override_material(0, _material)
	_material.albedo_color = COLORS[color_index]
	_build_text = _read_build_info()
	_update_label()


func _process(delta: float) -> void:
	cube.rotate_y(SPIN_SPEED * delta)
	_update_label()


func _unhandled_input(event: InputEvent) -> void:
	var pressed_touch: bool = event is InputEventScreenTouch and event.pressed
	var pressed_mouse: bool = event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT
	if pressed_touch or pressed_mouse:
		on_tap()
		get_viewport().set_input_as_handled()


## Kutsutaan jokaisesta napautuksesta.
func on_tap() -> void:
	tap_count += 1
	color_index = (color_index + 1) % COLORS.size()
	_material.albedo_color = COLORS[color_index]
	if is_inside_tree():
		var tween := create_tween()
		tween.tween_property(cube, "position:y", 1.3, 0.15).set_ease(Tween.EASE_OUT)
		tween.tween_property(cube, "position:y", 0.5, 0.25).set_ease(Tween.EASE_IN) \
				.set_trans(Tween.TRANS_BOUNCE)


func _update_label() -> void:
	info_label.text = "Koti-peli %s  ·  %d fps" % [_build_text, Engine.get_frames_per_second()]


## Julkaisu kirjoittaa tiedostoon version tunnisteen, jotta näkee onko uusin versio auki.
func _read_build_info() -> String:
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	if FileAccess.file_exists("res://build_info.txt"):
		var build := FileAccess.get_file_as_string("res://build_info.txt").strip_edges()
		if build != "":
			return "%s (%s)" % [version, build]
	return version
