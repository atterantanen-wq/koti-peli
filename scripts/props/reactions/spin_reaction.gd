class_name SpinReaction
extends Reaction
## Esine pyörähtää akselin ympäri, esim. kuperkeikka (akseli X, 360 astetta).

@export var axis := Vector3.UP
@export var degrees := 360.0
@export var time := 0.7
## Samalla pieni hyppy, jotta kuperkeikka ei mene lattian läpi.
@export var hop_height := 0.0


func _animate(_ctx: ReactionContext, node: Node3D, tween: Tween) -> void:
	var rest := node.transform
	var ax := axis.normalized()
	tween.tween_method(func(t: float) -> void:
		var spin := Basis(ax, deg_to_rad(degrees) * t)
		node.transform = Transform3D(spin * rest.basis,
				rest.origin + Vector3(0, sin(t * PI) * hop_height, 0)),
			0.0, 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: node.transform = rest)


func _length() -> float:
	return time
