class_name CardPicker
extends Control
## Pelin alun valintaruutu: kaksi isoa keinuvaa kuvakorttia, joista lapsi napauttaa
## toista. Ei tekstiä, joten lukutaitoa ei tarvita. Aliluokka piirtää kuvat
## (_draw_card) ja kertoo vaihtoehdot (kinds) ja korttien värit.

signal chosen(kind: String)

## Uusi valintaruutu ei ota napautuksia heti, koska edellisen ruudun napautus
## (kosketus ja siitä tehty hiiren napsautus) voisi muuten valita samalla kertaa
## myös tämän ruudun kortin.
const INPUT_DELAY := 0.4

var kinds: Array = []
var card_colors: Array = []

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


## Kortin keskikohta ja säde ruudulla (0 = vasen, 1 = oikea).
func card(i: int) -> Array:
	var s := size if size != Vector2.ZERO else get_viewport_rect().size
	var r := minf(s.x * 0.2, s.y * 0.32)
	var center := Vector2(s.x * (0.3 if i == 0 else 0.7), s.y * 0.53)
	return [center, r]


## Mikä vaihtoehto on ruudun kohdassa ("" = ei mikään).
func kind_at(pos: Vector2) -> String:
	for i in kinds.size():
		var c: Array = card(i)
		if pos.distance_to(c[0]) <= c[1] * 1.15:
			return kinds[i]
	return ""


func choose(kind: String) -> void:
	if _picked != "" or kind == "":
		return
	_picked = kind
	chosen.emit(kind)


func is_done() -> bool:
	return _picked != ""


func _gui_input(event: InputEvent) -> void:
	var pos := Vector2.INF
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		pos = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		pos = (event as InputEventMouseButton).position
	if pos != Vector2.INF:
		if _time >= INPUT_DELAY:
			choose(kind_at(pos))
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.97, 0.92, 0.88))
	for i in kinds.size():
		var c: Array = card(i)
		var center: Vector2 = c[0]
		var r: float = c[1]
		var grow := 1.0 + sin(_time * 3.0 + i * PI) * 0.04
		if _picked == kinds[i]:
			grow = 1.0 + _pop * 0.8
		r *= grow
		draw_circle(center + Vector2(0, r * 0.06), r, Color(0.4, 0.3, 0.4, 0.15))
		draw_circle(center, r, card_colors[i])
		draw_arc(center, r, 0.0, TAU, 48, Color.WHITE, r * 0.06, true)
		_draw_card(i, center, r)


## Piirtää kortin kuvan. Aliluokka toteuttaa.
func _draw_card(_i: int, _center: Vector2, _r: float) -> void:
	pass
