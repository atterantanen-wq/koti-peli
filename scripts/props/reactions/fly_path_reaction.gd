class_name FlyPathReaction
extends Reaction
## Esine lentää reittiä pitkin ja palaa paikalleen. Reitin pisteet annetaan
## suhteessa esineen lähtöpaikkaan (metreinä), ja esine kääntyy lentosuuntaan.

@export var points := PackedVector3Array()
@export var time := 4.0
## Odotus reitin viimeisessä pisteessä ennen paluuta (esim. lelu jää hetkeksi lattialle).
@export var pause_at_end := 0.0


func _animate(_ctx: ReactionContext, node: Node3D, tween: Tween) -> void:
	var rest := node.transform
	var route := PackedVector3Array([rest.origin])
	for p in points:
		route.append(rest.origin + p)
	route.append(rest.origin)
	var length := Player.path_length(route)
	if length <= 0.0:
		return
	for i in range(1, route.size()):
		if i == route.size() - 1 and pause_at_end > 0.0:
			tween.tween_interval(pause_at_end)
		var seg := route[i] - route[i - 1]
		var seg_time := time * seg.length() / length
		tween.tween_property(node, "position", route[i], seg_time) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if Vector2(seg.x, seg.z).length() > 0.01:
			# Käännös lentosuuntaan samaan aikaan liikkeen kanssa (lyhintä reittiä).
			var goal := atan2(seg.x, seg.z)
			tween.parallel().tween_method(_turn.bind(node, goal), 0.0, 1.0, minf(0.25, seg_time * 0.5))
	tween.tween_method(_turn.bind(node, rest.basis.get_euler().y), 0.0, 1.0, 0.25)
	tween.tween_callback(func() -> void: node.transform = rest)


## Kääntää osaa pehmeästi kohti kulmaa (lyhintä reittiä, ei koskaan "ympäri").
func _turn(t: float, node: Node3D, goal: float) -> void:
	node.rotation.y = lerp_angle(node.rotation.y, goal, t)


func _length() -> float:
	return time + pause_at_end + 0.25
