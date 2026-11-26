class_name Reaction
extends Resource
## Yksi uudelleenkäytettävä reaktion palikka (pomppaa, pyöri, lennä, sydämiä...).
## Esineen reaktiot kootaan näistä kohtauksessa ilman uutta koodia.
## Uusi palikka: peri tämä ja kirjoita _animate().

## Mitä esineen osaa liikutetaan (polku esineestä). Tyhjä = koko esineen Visual.
@export var target: NodePath = ^"Visual"
## Odotus ennen reaktion alkua sekunteina.
@export var delay := 0.0


## Käynnistää reaktion. Palauttaa animaation (Tween) tai null.
func play(ctx: ReactionContext) -> Tween:
	var node := target_node(ctx)
	if node == null or not ctx.prop.is_inside_tree():
		return null
	var tween := ctx.prop.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	_animate(ctx, node, tween)
	return tween


func target_node(ctx: ReactionContext) -> Node3D:
	if target.is_empty():
		return ctx.prop.get_node_or_null("Visual") as Node3D
	return ctx.prop.get_node_or_null(target) as Node3D


## Kuinka kauan reaktio kestää kaikkiaan (sekunteina).
func duration() -> float:
	return delay + _length()


func _animate(_ctx: ReactionContext, _node: Node3D, tween: Tween) -> void:
	tween.tween_interval(0.0)


func _length() -> float:
	return 0.0
