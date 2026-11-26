class_name ShowReaction
extends Reaction
## Piilossa oleva osa ponnahtaa näkyviin (esim. nukkekodin ikkunavalot, raiteet, lelut).
## Jos kesto on 0, osa jää näkyviin, muuten se piiloutuu taas kuluneen ajan jälkeen.

@export var duration_visible := 3.0
@export var pop_time := 0.25


func _animate(_ctx: ReactionContext, node: Node3D, tween: Tween) -> void:
	var rest := node.scale
	tween.tween_callback(func() -> void:
		node.scale = rest * 0.05
		node.visible = true)
	tween.tween_property(node, "scale", rest, pop_time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if duration_visible > 0.0:
		tween.tween_interval(duration_visible)
		tween.tween_property(node, "scale", rest * 0.05, pop_time * 0.6)
		tween.tween_callback(func() -> void:
			node.visible = false
			node.scale = rest)


func _length() -> float:
	return pop_time + (duration_visible + pop_time * 0.6 if duration_visible > 0.0 else 0.0)
