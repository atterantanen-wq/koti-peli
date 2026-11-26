class_name HopReaction
extends Reaction
## Esine pomppaa ylös ja alas (count kertaa).

@export var height := 0.2
@export var count := 1
@export var hop_time := 0.4


func _animate(_ctx: ReactionContext, node: Node3D, tween: Tween) -> void:
	var rest := node.position
	for i in count:
		tween.tween_property(node, "position:y", rest.y + height, hop_time * 0.45) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "position:y", rest.y, hop_time * 0.55) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _length() -> float:
	return hop_time * count
