class_name WalkGrid
extends RefCounted
## Huoneen lattia ruudukkona: mihin hahmo voi kävellä ja mitä reittiä.
##
## Huonekalut ja seinät (ryhmä "obstacle", törmäysmuoto BoxShape3D) merkitään
## esteiksi. Esteitä levennetään hahmon säteen verran, jotta hahmo ei hipaise niitä.
## Reitti haetaan A*-haulla ja oiotaan suoriksi pätkiksi, jotta kävely näyttää luontevalta.

const OBSTACLE_GROUP := "obstacle"

var cell_size: float
var bounds: Rect2  # lattia ylhäältä katsottuna: x = maailman x, y = maailman z
var size: Vector2i
var _astar := AStarGrid2D.new()


func _init(floor_bounds: Rect2, cell: float = 0.2) -> void:
	cell_size = cell
	bounds = floor_bounds
	size = Vector2i(ceili(bounds.size.x / cell), ceili(bounds.size.y / cell))
	_astar.region = Rect2i(Vector2i.ZERO, size)
	_astar.cell_size = Vector2(cell, cell)
	_astar.offset = bounds.position + Vector2(cell, cell) * 0.5
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()


## Rakentaa ruudukon kohtauksen esteistä.
static func from_scene(tree: SceneTree, floor_bounds: Rect2, radius: float,
		cell: float = 0.2) -> WalkGrid:
	var grid := WalkGrid.new(floor_bounds, cell)
	for node in tree.get_nodes_in_group(OBSTACLE_GROUP):
		for rect in obstacle_rects(node):
			grid.add_obstacle(rect.grow(radius))
	grid.block_edges(radius)
	return grid


## Esteen jalanjälki lattialla (yksi suorakulmio jokaista laatikkomuotoa kohden).
static func obstacle_rects(node: Node) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for child in node.find_children("*", "CollisionShape3D", true, false):
		var shape := child as CollisionShape3D
		var box := shape.shape as BoxShape3D
		if box == null or shape.disabled:
			continue
		var half := box.size * 0.5
		var xf := shape.global_transform
		var rect := Rect2()
		for i in 8:
			var corner := Vector3(
					half.x if i & 1 else -half.x,
					half.y if i & 2 else -half.y,
					half.z if i & 4 else -half.z)
			var p := xf * corner
			var p2 := Vector2(p.x, p.z)
			rect = Rect2(p2, Vector2.ZERO) if i == 0 else rect.expand(p2)
		rects.append(rect)
	return rects


func add_obstacle(rect: Rect2) -> void:
	for x in size.x:
		for y in size.y:
			if rect.has_point(cell_center(Vector2i(x, y))):
				_astar.set_point_solid(Vector2i(x, y), true)


## Estää reunimmaiset ruudut, jotta hahmo ei kävele seinän sisään.
func block_edges(radius: float) -> void:
	var inner := bounds.grow(-radius)
	for x in size.x:
		for y in size.y:
			if not inner.has_point(cell_center(Vector2i(x, y))):
				_astar.set_point_solid(Vector2i(x, y), true)


func cell_center(cell: Vector2i) -> Vector2:
	return bounds.position + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size


func cell_of(p: Vector3) -> Vector2i:
	var local := (Vector2(p.x, p.z) - bounds.position) / cell_size
	return Vector2i(floori(local.x), floori(local.y))


func is_walkable(p: Vector3) -> bool:
	var c := cell_of(p)
	return _astar.is_in_boundsv(c) and not _astar.is_point_solid(c)


func is_cell_walkable(c: Vector2i) -> bool:
	return _astar.is_in_boundsv(c) and not _astar.is_point_solid(c)


## Lähin kohta, johon hahmo pääsee. Jos kohta on jo vapaa, palautetaan se sellaisenaan.
func nearest_walkable(p: Vector3) -> Vector3:
	if is_walkable(p):
		return Vector3(p.x, 0.0, p.z)
	var target := Vector2(p.x, p.z)
	var best := Vector2.INF
	var best_dist := INF
	for x in size.x:
		for y in size.y:
			var c := Vector2i(x, y)
			if _astar.is_point_solid(c):
				continue
			var center := cell_center(c)
			var d := center.distance_squared_to(target)
			if d < best_dist:
				best_dist = d
				best = center
	if best == Vector2.INF:
		return Vector3(p.x, 0.0, p.z)
	return Vector3(best.x, 0.0, best.y)


## Lähin vapaa kohta esineen viereltä. Samanetäisistä valitaan se, joka on lähimpänä
## kohtaa near (yleensä hahmon nykyinen paikka), jotta hahmo ei kierrä turhaan.
func nearest_walkable_to_rect(rect: Rect2, near: Vector3) -> Vector3:
	var near2 := Vector2(near.x, near.z)
	var best := Vector2.INF
	var best_score := INF
	for x in size.x:
		for y in size.y:
			var c := Vector2i(x, y)
			if _astar.is_point_solid(c):
				continue
			var center := cell_center(c)
			var closest := center.clamp(rect.position, rect.end)
			# Etäisyys esineeseen ratkaisee, pyöristettynä ruudun tarkkuuteen.
			var score := snappedf(center.distance_to(closest), cell_size) * 1000.0 \
					+ center.distance_to(near2)
			if score < best_score:
				best_score = score
				best = center
	if best == Vector2.INF:
		return nearest_walkable(Vector3(rect.get_center().x, 0, rect.get_center().y))
	return Vector3(best.x, 0.0, best.y)


## Paikka esineen sivulla, josta kamera näkee sekä hahmon että esineen.
## toward_camera: vaakasuunta esineestä kameraa kohti (x, z).
## Hahmo ei mene esineen eteen (peittäisi tempun) eikä taakse (esine peittäisi hahmon),
## jos sivulla on tilaa. Paikka on silti aina esineen vieressä.
func side_stand_point(rect: Rect2, near: Vector3, toward_camera: Vector2) -> Vector3:
	var near2 := Vector2(near.x, near.z)
	var cam := toward_camera.normalized()
	var candidates := []
	var min_gap := INF
	for x in size.x:
		for y in size.y:
			var c := Vector2i(x, y)
			if _astar.is_point_solid(c):
				continue
			var center := cell_center(c)
			var gap := center.distance_to(center.clamp(rect.position, rect.end))
			min_gap = minf(min_gap, gap)
			candidates.append([center, gap])
	if candidates.is_empty():
		return nearest_walkable(Vector3(rect.get_center().x, 0, rect.get_center().y))
	var best := Vector2.INF
	var best_score := INF
	for item in candidates:
		var center: Vector2 = item[0]
		var gap: float = item[1]
		# Vain esineen vierestä (enintään puoli ruutua kauempaa kuin lähin vapaa kohta).
		if gap > min_gap + cell_size * 0.6:
			continue
		var side := (center - rect.get_center()).normalized()
		var front := side.dot(cam)
		var penalty := 0.0
		if front > 0.55:
			penalty = 3.0 + front  # edessä: peittäisi esineen
		elif front < -0.6:
			penalty = 1.5  # takana: esine peittäisi hahmon
		var score := penalty + gap * 2.0 + center.distance_to(near2) * 0.25
		if score < best_score:
			best_score = score
			best = center
	return Vector3(best.x, 0.0, best.y)


## Reitti kohdasta toiseen lattiatasossa (y = 0). Tyhjä, jos perille ei pääse.
func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start := nearest_walkable(from)
	var goal := nearest_walkable(to)
	var cells := _astar.get_id_path(cell_of(start), cell_of(goal))
	var result := PackedVector3Array()
	if cells.is_empty():
		return result
	var points: Array[Vector3] = [Vector3(from.x, 0.0, from.z)]
	for i in range(1, cells.size() - 1):
		var c := cell_center(cells[i])
		points.append(Vector3(c.x, 0.0, c.y))
	points.append(goal)
	# Oiotaan: hypätään välipisteiden yli aina kun suora matka on vapaa.
	result.append(points[0])
	var i := 0
	while i < points.size() - 1:
		var j := points.size() - 1
		while j > i + 1 and not is_line_clear(points[i], points[j]):
			j -= 1
		result.append(points[j])
		i = j
	return result


## Onko suora viiva vapaa esteistä.
func is_line_clear(a: Vector3, b: Vector3) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) / (cell_size * 0.25)))
	for s in steps + 1:
		var p := a.lerp(b, float(s) / steps)
		if not is_walkable(p) and cell_of(p) != cell_of(a):
			return false
	return true


## Kaikki vapaat ruudut, joihin pääsee annetusta kohdasta (testejä varten).
func reachable_cells(from: Vector3) -> Array[Vector2i]:
	var start := cell_of(nearest_walkable(from))
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = c + d
			if is_cell_walkable(n) and not seen.has(n):
				seen[n] = true
				queue.append(n)
	var out: Array[Vector2i] = []
	out.assign(seen.keys())
	return out


func walkable_cell_count() -> int:
	var count := 0
	for x in size.x:
		for y in size.y:
			if not _astar.is_point_solid(Vector2i(x, y)):
				count += 1
	return count
