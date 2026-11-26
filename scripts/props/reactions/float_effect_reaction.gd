class_name FloatEffectReaction
extends Reaction
## Esineen yläpuolelle nousee sydämiä, tähtiä tai muita kuvioita, jotka häipyvät.

@export_enum("heart", "star", "note") var shape := "heart"
@export var color := Color(1.0, 0.45, 0.6)
@export var count := 3
## Mistä kohdasta kuviot lähtevät (suhteessa esineeseen).
@export var offset := Vector3(0, 0.5, 0)
@export var spread := 0.25
@export var rise := 0.6
@export var time := 1.2
@export var size := 0.12


func play(ctx: ReactionContext) -> Tween:
	if ctx.effects == null or not ctx.prop.is_inside_tree():
		return null
	var origin := ctx.prop.to_global(offset)
	for i in count:
		var symbol := FloatingSymbol.new(shape, color, size)
		# Kuviot asettuvat viuhkaksi, jotta ne eivät mene päällekkäin.
		var f := 0.0 if count == 1 else float(i) / (count - 1) - 0.5
		symbol.start = origin + Vector3(f * spread * 2.0, 0.0, 0.05 * i)
		symbol.rise = rise * (0.8 + 0.4 * ((i * 7) % 5) / 4.0)
		symbol.lifetime = time
		symbol.start_delay = delay + 0.08 * i
		ctx.effects.add_child(symbol)
	return null


func _length() -> float:
	return time + 0.08 * count
