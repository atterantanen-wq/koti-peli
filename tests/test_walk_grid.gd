extends "res://tests/test_case.gd"
## Tarkistaa reitinhaun: hahmo kiertää esteet ja löytää lähimmän vapaan kohdan.


func _grid_with_box() -> WalkGrid:
	var grid := WalkGrid.new(Rect2(-2, -2, 4, 4), 0.2)
	grid.add_obstacle(Rect2(-0.5, -1.5, 1.0, 3.0))  # pitkä laatikko keskellä
	return grid


func test_path_goes_around_obstacle() -> void:
	var grid := _grid_with_box()
	var path := grid.find_path(Vector3(-1.5, 0, 0), Vector3(1.5, 0, 0))
	check(path.size() >= 3, "reitti kiertää esteen (useampi pätkä)")
	check_eq(path[path.size() - 1], Vector3(1.5, 0, 0), "reitti päättyy kohteeseen")
	for i in range(1, path.size()):
		check(grid.is_line_clear(path[i - 1], path[i]), "reitin pätkä %d ei mene esteen läpi" % i)


func test_straight_path_when_clear() -> void:
	var grid := _grid_with_box()
	var path := grid.find_path(Vector3(-1.5, 0, -1.8), Vector3(-1.5, 0, 1.8))
	check_eq(path.size(), 2, "esteetön reitti on yksi suora pätkä")


func test_nearest_walkable_moves_out_of_obstacle() -> void:
	var grid := _grid_with_box()
	var inside := Vector3(0.1, 0, 0)
	check(not grid.is_walkable(inside), "laatikon sisällä ei voi kävellä")
	var p := grid.nearest_walkable(inside)
	check(grid.is_walkable(p), "lähin kohta on vapaa")
	check(p.distance_to(inside) < 0.8, "lähin kohta on lähellä (%s)" % p)


func test_edges_blocked() -> void:
	var grid := WalkGrid.new(Rect2(-2, -2, 4, 4), 0.2)
	grid.block_edges(0.25)
	check(not grid.is_walkable(Vector3(-1.95, 0, 0)), "seinän viereen ei kävellä")
	check(grid.is_walkable(Vector3(0, 0, 0)), "keskellä voi kävellä")
