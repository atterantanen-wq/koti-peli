class_name ReactionSet
extends Resource
## Yhdellä napautuksella yhtä aikaa käynnistyvät reaktiot (esim. halaus + sydämet).
## Esineellä voi olla monta tällaista, ja ne vuorottelevat napautus kerrallaan.

@export var reactions: Array[Reaction] = []


func duration() -> float:
	var longest := 0.0
	for r in reactions:
		if r != null:
			longest = maxf(longest, r.duration())
	return longest
