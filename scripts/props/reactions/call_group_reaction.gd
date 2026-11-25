class_name CallGroupReaction
extends Reaction
## Pyytää jotain koko huoneessa: kutsuu ryhmän solmuille funktiota
## (esim. ryhmä "day_night", funktio "toggle" vaihtaa päivän ja yön).

@export var group := "day_night"
@export var method := "toggle"


func play(ctx: ReactionContext) -> Tween:
	if not ctx.prop.is_inside_tree():
		return null
	if delay > 0.0:
		var tween := ctx.prop.create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func() -> void: ctx.prop.get_tree().call_group(group, method))
		return tween
	ctx.prop.get_tree().call_group(group, method)
	return null
