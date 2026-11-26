class_name FlyPathReaction
extends Reaction
## Esine lentää reittiä pitkin ja palaa paikalleen. Reitin pisteet annetaan
## suhteessa esineen lähtöpaikkaan (metreinä), ja esine kääntyy lentosuuntaan.

@export var points := PackedVector3Array()
@export var time := 4.0


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
		var seg := route[i] - route[i - 1]
		var seg_time := time * seg.length() / length
		var flat := Vector2(seg.x, seg.z)
		if flat.length() > 0.01:
			tween.tween_property(node, "rotation:y", atan2(seg.x, seg.z), minf(0.2, seg_time * 0.5))
		tween.tween_property(node, "position", route[i], seg_time) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "rotation:y", rest.basis.get_euler().y, 0.25)
	tween.tween_callback(func() -> void: node.transform = rest)


func _length() -> float:
	return time + 0.25
