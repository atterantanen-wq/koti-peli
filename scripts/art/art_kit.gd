class_name ArtKit
extends RefCounted
## Pehmeän ja satumaisen tyylin työkalut: pyöreäkulmaiset laatikot, putket (esim.
## metallisängyn kiehkurat) ja pienet koodilla piirretyt kuviot (raidat, tähdet).
## Kaikki tehdään koodilla, joten peli pysyy pienenä eikä tarvitse kuvatiedostoja.


## Pyöreäkulmainen "tyyny"-laatikko. roundness 0 = terävä, 1 = melkein pallo.
## UV: u kulkee x-suunnassa, v z-suunnassa (ylhäältä katsottuna), jotta kuviot näkyvät päällä.
static func soft_box(size: Vector3, roundness := 0.35, segments := 14) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var e := clampf(roundness, 0.05, 1.0)
	var half := size * 0.5
	var rows := segments
	var cols := segments * 2
	var verts: Array[Vector3] = []
	for r in rows + 1:
		var phi := lerpf(-PI / 2.0, PI / 2.0, float(r) / rows)
		for c in cols + 1:
			var theta := lerpf(-PI, PI, float(c) / cols)
			var cp := _sp(cos(phi), e)
			verts.append(Vector3(half.x * cp * _sp(cos(theta), e), half.y * _sp(sin(phi), e),
					half.z * cp * _sp(sin(theta), e)))
	for r in rows:
		for c in cols:
			var a := r * (cols + 1) + c
			var b := a + cols + 1
			for i in [a, b, a + 1, a + 1, b, b + 1]:
				var v: Vector3 = verts[i]
				st.set_uv(Vector2(v.x / size.x + 0.5, v.z / size.z + 0.5))
				st.add_vertex(v)
	st.index()
	st.generate_normals()
	return st.commit()


static func _sp(v: float, e: float) -> float:
	return signf(v) * pow(absf(v), e)


## Lisää putken pisteiden läpi (pyöreä poikkileikkaus). Monta putkea voi koota samaan
## SurfaceTooliin, jolloin koko metallikehys piirretään yhdellä kertaa (nopeaa).
static func add_tube(st: SurfaceTool, points: PackedVector3Array, radius: float, sides := 6,
		caps := true) -> void:
	if points.size() < 2:
		return
	var rings: Array = []
	var prev_n := Vector3.ZERO
	for i in points.size():
		var tangent: Vector3
		if i == 0:
			tangent = points[1] - points[0]
		elif i == points.size() - 1:
			tangent = points[i] - points[i - 1]
		else:
			tangent = points[i + 1] - points[i - 1]
		tangent = tangent.normalized()
		var n: Vector3
		if prev_n == Vector3.ZERO:
			n = tangent.cross(Vector3.UP if absf(tangent.y) < 0.9 else Vector3.RIGHT).normalized()
		else:
			n = (prev_n - tangent * prev_n.dot(tangent)).normalized()
		prev_n = n
		var b := tangent.cross(n)
		var ring: Array[Vector3] = []
		for s in sides:
			var a := TAU * s / sides
			ring.append(n * cos(a) + b * sin(a))
		rings.append(ring)
	for i in points.size() - 1:
		for s in sides:
			var s2 := (s + 1) % sides
			var r0: Array[Vector3] = rings[i]
			var r1: Array[Vector3] = rings[i + 1]
			_tri(st, points[i] + r0[s] * radius, r0[s], points[i + 1] + r1[s] * radius, r1[s],
					points[i] + r0[s2] * radius, r0[s2])
			_tri(st, points[i] + r0[s2] * radius, r0[s2], points[i + 1] + r1[s] * radius, r1[s],
					points[i + 1] + r1[s2] * radius, r1[s2])
	if caps:
		add_ball(st, points[0], radius, sides)
		add_ball(st, points[points.size() - 1], radius, sides)


static func _tri(st: SurfaceTool, a: Vector3, na: Vector3, b: Vector3, nb: Vector3, c: Vector3,
		nc: Vector3) -> void:
	# Godot piirtää myötäpäivään kierretyt kolmiot etupuoleksi.
	st.set_normal(na)
	st.add_vertex(a)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_normal(nc)
	st.add_vertex(c)


## Lisää pienen pallon (esim. sängyn pylvään nuppi).
static func add_ball(st: SurfaceTool, center: Vector3, radius: float, sides := 8) -> void:
	var rows := maxi(3, sides / 2)
	for r in rows:
		var p0 := PI * r / rows - PI / 2.0
		var p1 := PI * (r + 1) / rows - PI / 2.0
		for s in sides:
			var t0 := TAU * s / sides
			var t1 := TAU * (s + 1) / sides
			var a := _sphere_dir(p0, t0)
			var b := _sphere_dir(p1, t0)
			var c := _sphere_dir(p0, t1)
			var d := _sphere_dir(p1, t1)
			_tri(st, center + a * radius, a, center + c * radius, c, center + b * radius, b)
			_tri(st, center + c * radius, c, center + d * radius, d, center + b * radius, b)


static func _sphere_dir(phi: float, theta: float) -> Vector3:
	return Vector3(cos(phi) * cos(theta), sin(phi), cos(phi) * sin(theta))


## Kiehkura eli spiraali: alkaa säteeltä radius ja kiertyy turns kierrosta sisäänpäin.
## Taso annetaan kahdella suunnalla (u, v). start_angle radiaaneina.
static func spiral(center: Vector3, u: Vector3, v: Vector3, radius: float, turns := 1.6,
		start_angle := 0.0, inner := 0.25, steps := 28) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in steps + 1:
		var t := float(i) / steps
		var a := start_angle + t * turns * TAU
		var r := radius * lerpf(1.0, inner, t)
		pts.append(center + u * cos(a) * r + v * sin(a) * r)
	return pts


## Kaari (ympyrän osa) kahden kulman välillä.
static func arc(center: Vector3, u: Vector3, v: Vector3, radius: float, from_angle: float,
		to_angle: float, steps := 12) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in steps + 1:
		var a := lerpf(from_angle, to_angle, float(i) / steps)
		pts.append(center + u * cos(a) * radius + v * sin(a) * radius)
	return pts


## Pehmeä, hieman kiiltävä materiaali.
static func material(color: Color, roughness := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


## Materiaali koodilla piirretyllä kuvalla.
static func textured(image: Image, roughness := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	image.generate_mipmaps()
	m.albedo_texture = ImageTexture.create_from_image(image)
	m.roughness = roughness
	return m


## Raitakuva: värit vuorottelevat. Raidat kulkevat poikittain (v-suunnassa vaihtuvat).
static func stripes_image(colors: Array[Color], stripes: int, size := 64) -> Image:
	var img := Image.create(4, size, false, Image.FORMAT_RGB8)
	for y in size:
		var c: Color = colors[int(float(y) / size * stripes) % colors.size()]
		for x in 4:
			img.set_pixel(x, y, c)
	return img


## Kuva, jonka pohjavärin päälle on piirretty tähtiä: [kohta 0..1, koko 0..1, väri].
static func stars_image(base: Color, stars: Array, size := 64) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	img.fill(base)
	for star in stars:
		var c: Vector2 = star[0] * size
		var r: float = star[1] * size
		for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
			for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
				if x < 0 or y < 0 or x >= size or y >= size:
					continue
				if in_star(Vector2(x + 0.5, y + 0.5) - c, r):
					img.set_pixel(x, y, star[2])
	return img


## Onko piste viisisakaraisen tähden sisällä (tähden keskipiste origossa, kärki ylöspäin).
static func in_star(p: Vector2, radius: float) -> bool:
	var d := p.length()
	if d > radius:
		return false
	var a := fposmod(atan2(p.x, -p.y) + TAU / 10.0, TAU / 5.0) - TAU / 10.0
	# Sakaran reuna: säde vaihtelee kärjen (radius) ja loven (0.45 * radius) välillä.
	var edge := lerpf(radius, radius * 0.45, absf(a) / (TAU / 10.0))
	return d <= edge


## Kokoaa SurfaceToolin valmiiksi kappaleeksi.
static func commit(st: SurfaceTool) -> ArrayMesh:
	st.index()
	return st.commit()
