class_name PetPicker
extends Control
## Pelin alussa: lapsi valitsee lemmikin napauttamalla kissan tai koiran kuvaa.
## Ei tekstiä, joten lukutaitoa ei tarvita. Kuvat keinuvat kutsuvasti.

signal chosen(kind: String)

const KINDS := ["cat", "dog"]
const CARD_COLORS := [Color(1.0, 0.86, 0.72), Color(0.78, 0.89, 1.0)]

var _time := 0.0
var _picked := ""
var _pop := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_time += delta
	if _picked != "":
		_pop += delta
		modulate.a = clampf(1.0 - _pop / 0.35, 0.0, 1.0)
		if _pop >= 0.35:
			queue_free()
	queue_redraw()


## Kortin keskikohta ja säde ruudulla (0 = kissa, 1 = koira).
func card(i: int) -> Array:
	var s := size if size != Vector2.ZERO else get_viewport_rect().size
	var r := minf(s.x * 0.2, s.y * 0.32)
	var center := Vector2(s.x * (0.3 if i == 0 else 0.7), s.y * 0.53)
	return [center, r]


## Mikä lemmikki on ruudun kohdassa ("" = ei kumpikaan).
func kind_at(pos: Vector2) -> String:
	for i in 2:
		var c: Array = card(i)
		if pos.distance_to(c[0]) <= c[1] * 1.15:
			return KINDS[i]
	return ""


func choose(kind: String) -> void:
	if _picked != "" or kind == "":
		return
	_picked = kind
	chosen.emit(kind)


func _gui_input(event: InputEvent) -> void:
	var pos := Vector2.INF
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		pos = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		pos = (event as InputEventMouseButton).position
	if pos != Vector2.INF:
		choose(kind_at(pos))
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.97, 0.92, 0.88))
	for i in 2:
		var c: Array = card(i)
		var center: Vector2 = c[0]
		var r: float = c[1]
		var grow := 1.0 + sin(_time * 3.0 + i * PI) * 0.04
		if _picked == KINDS[i]:
			grow = 1.0 + _pop * 0.8
		r *= grow
		draw_circle(center + Vector2(0, r * 0.06), r, Color(0.4, 0.3, 0.4, 0.15))
		draw_circle(center, r, CARD_COLORS[i])
		draw_arc(center, r, 0.0, TAU, 48, Color.WHITE, r * 0.06, true)
		if i == 0:
			_draw_cat(center, r * 0.62)
		else:
			_draw_dog(center, r * 0.62)
		# Pieni tassunjälki kortin alareunassa vihjeeksi: "napauta tästä".
		_draw_paw(center + Vector2(0, r * 0.78), r * 0.1, Color(1, 1, 1, 0.9))


func _ellipse(center: Vector2, radius: Vector2, rot := 0.0, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n:
		var a := TAU * k / n
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y).rotated(rot))
	return pts


func _eyes(c: Vector2, s: float) -> void:
	for side in [-1.0, 1.0]:
		var e := c + Vector2(0.33 * s * side, -0.08 * s)
		draw_colored_polygon(_ellipse(e, Vector2(0.1, 0.13) * s), PetArt.EYE)
		draw_circle(e + Vector2(0.035, -0.045) * s, 0.035 * s, Color.WHITE)
		draw_colored_polygon(_ellipse(c + Vector2(0.55 * s * side, 0.18 * s), Vector2(0.12, 0.07) * s),
				Color(PetArt.CHEEK, 0.8))


func _draw_cat(c: Vector2, s: float) -> void:
	for side in [-1.0, 1.0]:
		var ear := PackedVector2Array([c + Vector2(0.25 * side, -0.65) * s, c + Vector2(0.85 * side, -0.95) * s,
				c + Vector2(0.78 * side, -0.25) * s])
		draw_colored_polygon(ear, PetArt.CAT_FUR)
		var inner := PackedVector2Array([c + Vector2(0.38 * side, -0.6) * s, c + Vector2(0.76 * side, -0.8) * s,
				c + Vector2(0.72 * side, -0.38) * s])
		draw_colored_polygon(inner, PetArt.CAT_NOSE)
	draw_colored_polygon(_ellipse(c, Vector2(0.95, 0.82) * s), PetArt.CAT_FUR)
	for k in 3:
		draw_colored_polygon(_ellipse(c + Vector2((k - 1) * 0.18, -0.62) * s, Vector2(0.05, 0.16) * s),
				PetArt.CAT_STRIPE)
	draw_colored_polygon(_ellipse(c + Vector2(0, 0.32) * s, Vector2(0.42, 0.28) * s), PetArt.CREAM)
	_eyes(c, s)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-0.09, 0.14) * s, c + Vector2(0.09, 0.14) * s,
			c + Vector2(0, 0.25) * s]), PetArt.CAT_NOSE)
	draw_arc(c + Vector2(-0.08, 0.27) * s, 0.08 * s, 0.2, PI - 0.2, 10, PetArt.MOUTH, 0.03 * s, true)
	draw_arc(c + Vector2(0.08, 0.27) * s, 0.08 * s, 0.2, PI - 0.2, 10, PetArt.MOUTH, 0.03 * s, true)
	for side in [-1.0, 1.0]:
		for k in 2:
			var a := c + Vector2(0.4 * side, (0.26 + k * 0.1)) * s
			draw_line(a, a + Vector2(0.5 * side, (-0.05 + k * 0.12)) * s, Color(0.45, 0.35, 0.3), 0.025 * s, true)


func _draw_dog(c: Vector2, s: float) -> void:
	draw_colored_polygon(_ellipse(c, Vector2(0.88, 0.85) * s), PetArt.DOG_FUR)
	draw_colored_polygon(_ellipse(c + Vector2(0.32, -0.3) * s, Vector2(0.3, 0.28) * s), PetArt.DOG_EAR)
	for side in [-1.0, 1.0]:
		draw_colored_polygon(_ellipse(c + Vector2(0.86 * side, -0.05) * s, Vector2(0.24, 0.55) * s, -0.35 * side),
				PetArt.DOG_EAR)
	draw_colored_polygon(_ellipse(c + Vector2(0, 0.35) * s, Vector2(0.45, 0.32) * s), PetArt.CREAM)
	_eyes(c, s)
	draw_colored_polygon(_ellipse(c + Vector2(0, 0.42) * s, Vector2(0.1, 0.12) * s), Color(1.0, 0.5, 0.6))
	draw_colored_polygon(_ellipse(c + Vector2(0, 0.18) * s, Vector2(0.17, 0.11) * s), PetArt.DOG_NOSE)
	draw_circle(c + Vector2(-0.05, 0.15) * s, 0.035 * s, Color(1, 1, 1, 0.7))


func _draw_paw(c: Vector2, s: float, color: Color) -> void:
	draw_colored_polygon(_ellipse(c + Vector2(0, 0.3) * s, Vector2(0.75, 0.6) * s), color)
	for k in 4:
		var x := (k - 1.5) * 0.55
		draw_circle(c + Vector2(x, -0.5 - (0.25 if k in [1, 2] else 0.0)) * s, 0.3 * s, color)
