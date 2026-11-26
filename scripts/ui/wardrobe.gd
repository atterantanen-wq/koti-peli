class_name Wardrobe
extends Control
## Vaatekaappi: ruudun oikeassa yläkulmassa on paitanappi. Napautus avaa ruudun
## alareunaan rivin kuvia: tyttö, poika ja neljä asua. Kuvan napautus pukee hahmon
## heti, ja valikko jää auki, jotta voi kokeilla lisää. Napautus muualle (tai
## paitanappiin) sulkee valikon. Ei tekstiä.

signal changed(hero: String, outfit: String)

const ITEMS := [["hero", "girl"], ["hero", "boy"], ["outfit", "hoodie"], ["outfit", "dress"],
		["outfit", "stripes"], ["outfit", "pajamas"]]
const BUTTON_COLOR := Color(1.0, 0.8, 0.4)
const CARD_COLOR := Color(1.0, 0.97, 0.92)
const SELECTED_COLOR := Color(1.0, 0.72, 0.2)

var is_open := false
var hero := "boy"
var outfit := "hoodie"

var _time := 0.0
var _pop := {}  # kortin indeksi -> pomppuaika
var _last_press_class := ""
var _last_press_time := -1.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	_time += delta
	for k in _pop.keys():
		_pop[k] -= delta
		if _pop[k] <= 0.0:
			_pop.erase(k)
	queue_redraw()


func _screen() -> Vector2:
	return size if size != Vector2.ZERO else get_viewport_rect().size


## Paitanapin keskikohta ja säde.
func button() -> Array:
	var s := _screen()
	var r := minf(s.x, s.y) * 0.075
	return [Vector2(s.x - r * 1.35, r * 1.35), r]


## Valikon kortin keskikohta ja säde (0, 1 = tyttö, poika; 2..5 = asut).
func card(i: int) -> Array:
	var s := _screen()
	var slot := s.x * 0.92 / 6.5
	var r := minf(slot * 0.42, s.y * 0.11)
	var x := s.x * 0.04 + slot * (i + 0.5) + (slot * 0.5 if i >= 2 else 0.0)
	return [Vector2(x, s.y - r * 1.45), r]


## Valikon taustan alue.
func panel_rect() -> Rect2:
	var s := _screen()
	var r: float = card(0)[1]
	return Rect2(Vector2(0, s.y - r * 2.9), Vector2(s.x, r * 2.9))


func open() -> void:
	is_open = true


func close() -> void:
	is_open = false


## Näyttää valituksi hahmon nykyiset valinnat.
func show_current(new_hero: String, new_outfit: String) -> void:
	hero = new_hero
	outfit = new_outfit


## Mikä on ruudun kohdassa: "button", kortin indeksi merkkijonona ("0".."5"), "panel" tai "".
func thing_at(pos: Vector2) -> String:
	var b: Array = button()
	if pos.distance_to(b[0]) <= b[1] * 1.25:
		return "button"
	if not is_open:
		return ""
	for i in ITEMS.size():
		var c: Array = card(i)
		if pos.distance_to(c[0]) <= c[1] * 1.15:
			return str(i)
	if panel_rect().has_point(pos):
		return "panel"
	return ""


## Napautus kohtaan. Palauttaa true, jos vaatekaappi otti napautuksen.
func press(pos: Vector2) -> bool:
	var thing := thing_at(pos)
	if thing == "button":
		is_open = not is_open
		return true
	if not is_open:
		return false
	if thing == "" :
		close()
		return true
	if thing == "panel":
		return true
	pick(int(thing))
	return true


## Valitsee kortin: pukee hahmon.
func pick(i: int) -> void:
	var item: Array = ITEMS[i]
	if item[0] == "hero":
		hero = item[1]
	else:
		outfit = item[1]
	_pop[i] = 0.3
	changed.emit(hero, outfit)


func is_selected(i: int) -> bool:
	var item: Array = ITEMS[i]
	return (hero if item[0] == "hero" else outfit) == item[1]


## Suljettuna vain paitanappi ottaa napautuksia, muu ruutu menee peliin.
func _has_point(point: Vector2) -> bool:
	return is_open or thing_at(point) == "button"


func _gui_input(event: InputEvent) -> void:
	var pos := Vector2.INF
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		pos = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		pos = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventScreenDrag:
		accept_event()
	if pos == Vector2.INF:
		return
	accept_event()
	# Sama napautus voi tulla sekä kosketuksena että hiirenä: käsitellään vain kerran.
	var now := Time.get_ticks_msec() / 1000.0
	var cls := event.get_class()
	if cls != _last_press_class and now - _last_press_time < 0.25:
		return
	_last_press_class = cls
	_last_press_time = now
	press(pos)


func _draw() -> void:
	var b: Array = button()
	var bc: Vector2 = b[0]
	var br: float = b[1] * (1.0 + sin(_time * 2.5) * 0.03)
	draw_circle(bc + Vector2(0, br * 0.08), br, Color(0.4, 0.3, 0.4, 0.2))
	draw_circle(bc, br, BUTTON_COLOR if not is_open else SELECTED_COLOR)
	draw_arc(bc, br, 0.0, TAU, 40, Color.WHITE, br * 0.1, true)
	var shirt_color: Color = PlayerArt.COLORS[outfit]["top"]
	LookIcons.draw_shirt_icon(self, bc, br * 0.55, shirt_color)
	if not is_open:
		return
	var panel := panel_rect()
	draw_rect(panel, Color(1.0, 0.95, 0.88, 0.85))
	for i in ITEMS.size():
		var c: Array = card(i)
		var center: Vector2 = c[0]
		var r: float = c[1]
		if _pop.has(i):
			r *= 1.0 + sin(_pop[i] / 0.3 * PI) * 0.18
		draw_circle(center + Vector2(0, r * 0.06), r, Color(0.4, 0.3, 0.4, 0.15))
		draw_circle(center, r, CARD_COLOR)
		var ring := SELECTED_COLOR if is_selected(i) else Color.WHITE
		draw_arc(center, r, 0.0, TAU, 40, ring, r * (0.14 if is_selected(i) else 0.07), true)
		var item: Array = ITEMS[i]
		if item[0] == "hero":
			LookIcons.draw_face(self, center + Vector2(0, r * 0.05), r * 0.62, item[1])
		else:
			LookIcons.draw_outfit(self, center + Vector2(0, r * 0.05), r * 0.62, item[1])
