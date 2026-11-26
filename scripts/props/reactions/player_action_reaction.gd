class_name PlayerActionReaction
extends Reaction
## Pelihahmo tekee liikkeen esineen kanssa: halaa, hyppää tai pomppii.

@export_enum("hug", "jump", "bounce", "cheer") var action := "hug"


func play(ctx: ReactionContext) -> Tween:
	if ctx.player == null:
		return null
	if delay > 0.0 and ctx.prop.is_inside_tree():
		var tween := ctx.prop.create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(ctx.player.do_action.bind(action))
		return tween
	ctx.player.do_action(action)
	return null


func _length() -> float:
	return 0.5
