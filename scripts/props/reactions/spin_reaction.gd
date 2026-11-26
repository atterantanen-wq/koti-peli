class_name SpinReaction
extends Reaction
## Esine pyörähtää akselin ympäri, esim. kuperkeikka (akseli X, 360 astetta).

@export var axis := Vector3.UP
@export var degrees := 360.0
@export var time := 0.7
## Samalla pieni hyppy, jotta kuperkeikka ei mene lattian läpi.
@export var hop_height := 0.0
## Jos 0 tai enemmän: osa jää käännettyyn asentoon näin moneksi sekunniksi ja kääntyy
## sitten pehmeästi takaisin (esim. lelulaatikon kansi). Muuten palaa heti.
@export var hold := -1.0


func _animate(_ctx: ReactionContext, node: Node3D, tween: Tween) -> void:
	# Lähtöasento otetaan vasta pyörähdyksen alkaessa (esine voi olla liikkunut viiveen aikana).
	var start := [node.transform]
	var ax := axis.normalized()
	var rad := deg_to_rad(degrees)
	var hop := hop_height
	var turn := func(t: float) -> void:
		var rest: Transform3D = start[0]
		node.transform = Transform3D(Basis(ax, rad * t) * rest.basis,
				rest.origin + Vector3(0, sin(t * PI) * hop, 0))
	tween.tween_callback(func() -> void: start[0] = node.transform)
	if hold >= 0.0:
		tween.tween_method(turn, 0.0, 1.0, time * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(hold)
		tween.tween_method(turn, 1.0, 0.0, time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tween.tween_method(turn, 0.0, 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: node.transform = start[0])


func _length() -> float:
	return time + maxf(hold, 0.0)
