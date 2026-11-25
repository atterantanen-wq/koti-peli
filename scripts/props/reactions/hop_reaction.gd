class_name HopReaction
extends Reaction
## Esine pomppaa ylös ja alas (count kertaa).

@export var height := 0.2
@export var count := 1
@export var hop_time := 0.4


func _animate(_ctx: ReactionContext, node: Node3D, tween: Tween) -> void:
	# Suhteellinen liike: toimii myös, jos esine on jo liikkunut (esim. lelu lattialla).
	for i in count:
		tween.tween_property(node, "position:y", height, hop_time * 0.45).as_relative() \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "position:y", -height, hop_time * 0.55).as_relative() \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _length() -> float:
	return hop_time * count
