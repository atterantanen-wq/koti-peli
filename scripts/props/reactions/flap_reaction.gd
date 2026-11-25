class_name FlapReaction
extends Reaction
## Siivet (tai korvat, kädet...) heiluvat edestakaisin.
## Parittomat osat kääntyvät peilikuvana, joten vasen ja oikea siipi liikkuvat yhdessä.

@export var parts: Array[NodePath] = []
@export var axis := Vector3.FORWARD
@export var degrees := 40.0
@export var flaps := 6
@export var flap_time := 0.18


func play(ctx: ReactionContext) -> Tween:
	if not ctx.prop.is_inside_tree():
		return null
	var tween := ctx.prop.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	var nodes: Array[Node3D] = []
	var rests: Array[Basis] = []
	for path in parts:
		var n := ctx.prop.get_node_or_null(path) as Node3D
		if n != null:
			nodes.append(n)
			rests.append(n.basis)
	if nodes.is_empty():
		return tween
	var ax := axis.normalized()
	var count := flaps
	tween.tween_method(func(t: float) -> void:
		var a := sin(t * TAU * count) * deg_to_rad(degrees)
		for i in nodes.size():
			var sign_ := 1.0 if i % 2 == 0 else -1.0
			nodes[i].basis = Basis(ax, a * sign_) * rests[i],
		0.0, 1.0, flap_time * flaps)
	tween.tween_callback(func() -> void:
		for i in nodes.size():
			nodes[i].basis = rests[i])
	return tween


func _length() -> float:
	return flap_time * flaps
