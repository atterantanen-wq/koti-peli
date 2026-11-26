class_name SquashReaction
extends Reaction
## Esine litistyy ja joustaa takaisin kuin hyytelö.

@export var amount := 0.15
@export var time := 0.45


func _animate(_ctx: ReactionContext, node: Node3D, tween: Tween) -> void:
	var rest := node.scale
	var squashed := rest * Vector3(1.0 + amount * 0.6, 1.0 - amount, 1.0 + amount * 0.6)
	tween.tween_property(node, "scale", squashed, time * 0.25)
	tween.tween_property(node, "scale", rest, time * 0.75) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _length() -> float:
	return time
