class_name ReactionContext
extends RefCounted
## Tiedot, joita reaktio tarvitsee: mikä esine, kuka pelaaja ja minne tehosteet lisätään.

var prop: Node3D
var player: Player
## Solmu, johon sydämet, tähdet ym. tehosteet lisätään (ei esineen alle,
## jotta ne eivät liiku esineen mukana).
var effects: Node3D


func _init(p_prop: Node3D, p_player: Player, p_effects: Node3D) -> void:
	prop = p_prop
	player = p_player
	effects = p_effects
