class_name FlapReaction
extends Reaction
## Siivet, viirit tai korvat heiluvat edestakaisin ja asettuvat lopuksi paikoilleen.
## mirror: joka toinen osa kääntyy peilikuvana (vasen ja oikea siipi liikkuvat yhdessä).
## wave: osat heiluvat vähän eri tahtiin, kuin aalto kulkisi niiden läpi (viirinauha).

@export var parts: Array[NodePath] = []
@export var axis := Vector3.FORWARD
@export var degrees := 40.0
@export var flaps := 6
@export var flap_time := 0.18
@export var mirror := true
## Vaihe-ero peräkkäisten osien välillä (radiaaneina). 0 = kaikki yhtä aikaa.
@export var wave := 0.0


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
	var amp := deg_to_rad(degrees)
	var do_mirror := mirror
	var phase := wave
	tween.tween_method(func(t: float) -> void:
		# Heilahdus vaimenee loppua kohti, jotta osat pysähtyvät pehmeästi.
		var fade := minf(1.0, 4.0 * (1.0 - t))
		for i in nodes.size():
			var sign_ := -1.0 if do_mirror and i % 2 == 1 else 1.0
			var a := sin(t * TAU * count - i * phase) * amp * fade * sign_
			nodes[i].basis = Basis(ax, a) * rests[i],
		0.0, 1.0, flap_time * flaps)
	tween.tween_callback(func() -> void:
		for i in nodes.size():
			nodes[i].basis = rests[i])
	return tween


func _length() -> float:
	return flap_time * flaps
