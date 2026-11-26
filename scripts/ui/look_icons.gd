class_name LookIcons
extends RefCounted
## Hahmon ja vaatteiden kuvat 2D-valikoihin (hahmon valinta ja vaatekaappi).
## Värit tulevat PlayerArtista, joten kuva näyttää samalta kuin hahmo pelissä.
## c = kuvan keskikohta, s = kuvan koko (noin puolet leveydestä).


static func ellipse(center: Vector2, radius: Vector2, rot := 0.0, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n:
		var a := TAU * k / n
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y).rotated(rot))
	return pts


static func _poly(points: Array, c: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(c + (p as Vector2) * s)
	return out


static func star(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2.0 + TAU * k / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.45))
	return pts


## Tytön tai pojan kasvot.
static func draw_face(ci: CanvasItem, c: Vector2, s: float, hero: String) -> void:
	var hair := PlayerArt.HAIR
	if hero == "girl":
		for side in [-1.0, 1.0]:
			ci.draw_colored_polygon(ellipse(c + Vector2(0.95 * side, 0.15) * s, Vector2(0.26, 0.5) * s,
					-0.5 * side), hair)
			ci.draw_circle(c + Vector2(0.78 * side, -0.2) * s, 0.13 * s, PlayerArt.HAIR_TIE)
		ci.draw_colored_polygon(ellipse(c + Vector2(0, 0.1) * s, Vector2(0.86, 0.8) * s), hair)
	else:
		ci.draw_colored_polygon(ellipse(c + Vector2(0, -0.12) * s, Vector2(0.8, 0.66) * s), hair)
	ci.draw_colored_polygon(ellipse(c + Vector2(0, 0.08) * s, Vector2(0.72, 0.7) * s), PlayerArt.SKIN)
	# Tukka päälaella.
	if hero == "girl":
		ci.draw_colored_polygon(ellipse(c + Vector2(0, -0.45) * s, Vector2(0.78, 0.33) * s), hair)
		ci.draw_colored_polygon(star(c + Vector2(0.38, -0.42) * s, 0.15 * s), PlayerArt.HAIR_TIE)
	else:
		ci.draw_colored_polygon(ellipse(c + Vector2(0, -0.42) * s, Vector2(0.76, 0.34) * s), hair)
		ci.draw_colored_polygon(ellipse(c + Vector2(-0.3, -0.25) * s, Vector2(0.3, 0.14) * s, 0.3), hair)
		ci.draw_colored_polygon(ellipse(c + Vector2(0.28, -0.25) * s, Vector2(0.28, 0.13) * s, -0.3), hair)
		ci.draw_arc(c + Vector2(0.05, -0.85) * s, 0.12 * s, PI * 0.6, PI * 2.2, 14, hair, 0.08 * s, true)
	# Silmät, posket ja hymy.
	for side in [-1.0, 1.0]:
		var e := c + Vector2(0.26 * side, 0.05) * s
		ci.draw_colored_polygon(ellipse(e, Vector2(0.08, 0.11) * s), PlayerArt.EYE)
		ci.draw_circle(e + Vector2(0.03, -0.04) * s, 0.03 * s, Color.WHITE)
		if hero == "girl":
			ci.draw_line(e + Vector2(0.06 * side, -0.08) * s, e + Vector2(0.15 * side, -0.16) * s,
					PlayerArt.EYE, 0.035 * s, true)
		ci.draw_colored_polygon(ellipse(c + Vector2(0.45 * side, 0.3) * s, Vector2(0.11, 0.07) * s),
				Color(PlayerArt.CHEEK, 0.8))
	ci.draw_arc(c + Vector2(0, 0.28) * s, 0.16 * s, 0.25, PI - 0.25, 12, PlayerArt.MOUTH, 0.05 * s, true)


const SHIRT := [Vector2(-0.18, -0.55), Vector2(-0.55, -0.45), Vector2(-0.85, -0.1), Vector2(-0.62, 0.06),
		Vector2(-0.42, -0.08), Vector2(-0.42, 0.5), Vector2(0.42, 0.5), Vector2(0.42, -0.08),
		Vector2(0.62, 0.06), Vector2(0.85, -0.1), Vector2(0.55, -0.45), Vector2(0.18, -0.55),
		Vector2(0, -0.42)]
const PANTS := [Vector2(-0.4, 0.0), Vector2(0.4, 0.0), Vector2(0.44, 0.8), Vector2(0.07, 0.8),
		Vector2(0, 0.25), Vector2(-0.07, 0.8), Vector2(-0.44, 0.8)]
const SHORTS := [Vector2(-0.4, 0.0), Vector2(0.4, 0.0), Vector2(0.46, 0.38), Vector2(0.06, 0.38),
		Vector2(0, 0.2), Vector2(-0.06, 0.38), Vector2(-0.46, 0.38)]
const DRESS := [Vector2(-0.2, -0.75), Vector2(-0.45, -0.65), Vector2(-0.62, -0.4), Vector2(-0.42, -0.3),
		Vector2(-0.3, -0.4), Vector2(-0.3, -0.05), Vector2(-0.72, 0.8), Vector2(0.72, 0.8), Vector2(0.3, -0.05),
		Vector2(0.3, -0.4), Vector2(0.42, -0.3), Vector2(0.62, -0.4), Vector2(0.45, -0.65), Vector2(0.2, -0.75),
		Vector2(0, -0.62)]


## Vaatekuva: paita ja housut (tai mekko) asun väreissä.
static func draw_outfit(ci: CanvasItem, c: Vector2, s: float, outfit: String) -> void:
	var col: Dictionary = PlayerArt.COLORS.get(outfit, PlayerArt.COLORS["hoodie"])
	var top: Color = col["top"]
	var bottom: Color = col["bottom"]
	var shirt_c := c + Vector2(0, -0.35) * s
	var shirt_s := s * 0.75
	var pants_c := c + Vector2(0, 0.05) * s
	match outfit:
		"dress":
			var dress := _poly(DRESS, c + Vector2(0, -0.05) * s, s)
			ci.draw_colored_polygon(dress, top)
			for p in [Vector2(-0.3, 0.35), Vector2(0.25, 0.25), Vector2(0.0, 0.6), Vector2(-0.45, 0.68),
					Vector2(0.45, 0.62), Vector2(0.05, 0.05)]:
				ci.draw_circle(c + (p + Vector2(0, -0.05)) * s, 0.07 * s, col["dots"])
			ci.draw_colored_polygon(ellipse(c + Vector2(0, -0.67) * s, Vector2(0.2, 0.07) * s), col["dots"])
		"stripes":
			ci.draw_colored_polygon(_poly(SHORTS, pants_c, s), bottom)
			var shirt := _poly(SHIRT, shirt_c, shirt_s)
			ci.draw_colored_polygon(shirt, top)
			for k in 4:
				var y := shirt_c.y + (-0.3 + k * 0.22) * shirt_s
				var band := PackedVector2Array([Vector2(c.x - s, y), Vector2(c.x + s, y),
						Vector2(c.x + s, y + 0.1 * shirt_s), Vector2(c.x - s, y + 0.1 * shirt_s)])
				for piece in Geometry2D.intersect_polygons(shirt, band):
					ci.draw_colored_polygon(piece, col["stripe"])
		"pajamas":
			ci.draw_colored_polygon(_poly(PANTS, pants_c, s), bottom)
			ci.draw_colored_polygon(_poly(SHIRT, shirt_c, shirt_s), top)
			for p in [Vector2(-0.18, -0.45), Vector2(0.2, -0.25), Vector2(-0.22, 0.35), Vector2(0.25, 0.6)]:
				ci.draw_colored_polygon(star(c + p * s, 0.12 * s), col["star"])
		_:
			ci.draw_colored_polygon(_poly(PANTS, pants_c, s), bottom)
			ci.draw_colored_polygon(_poly(SHIRT, shirt_c, shirt_s), top)
			# Hupun reuna ja tasku.
			ci.draw_arc(shirt_c + Vector2(0, -0.5) * shirt_s, 0.22 * shirt_s, 0.0, PI, 12, top.darkened(0.15),
					0.08 * shirt_s, true)
			ci.draw_colored_polygon(ellipse(shirt_c + Vector2(0, 0.25) * shirt_s, Vector2(0.25, 0.12) * shirt_s),
					top.darkened(0.1))


## Vaatekaappinapin kuva: T-paita.
static func draw_shirt_icon(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	ci.draw_colored_polygon(_poly(SHIRT, c + Vector2(0, 0.03) * s, s), color)
	ci.draw_colored_polygon(star(c + Vector2(0, 0.12) * s, 0.2 * s), Color(1, 1, 1, 0.9))
