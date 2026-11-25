class_name Interactable
extends Node
## Tekee esineestä käytettävän. Lisää tämä esineen (ryhmä "prop") lapseksi ja valitse
## reaktiot kohtauksessa: uusi esine syntyy ilman uutta koodia.
##
## Jokainen napautus käynnistää seuraavan reaktiosarjan (variants), joten sama esine
## tekee vuorotellen eri temppuja. Uusi napautus kesken tempun aloittaa uuden heti.

signal used(variant: int)

## Reaktiosarjat, jotka vuorottelevat napautus kerrallaan.
@export var variants: Array[ReactionSet] = []
## Voiko hahmo kiivetä esineen päälle (esim. sänky). Päällä napautus käyttää esinettä uudelleen.
@export var climbable := false
## Kohta esineen päällä, johon hahmo kiipeää (suhteessa esineeseen).
@export var climb_point := Vector3(0, 0.5, 0)
## Esineen keskikohdan korkeus, jota käytetään anteeksiantavaan napautukseen.
@export var focus_height := 0.3

var use_count := 0
var _tweens: Array[Tween] = []
var _rest := {}


func _ready() -> void:
	_remember_rest()


func prop() -> Node3D:
	return get_parent() as Node3D


## Esineen Interactable-osa, tai null jos esine ei ole käytettävä.
static func of(node: Node) -> Interactable:
	if node == null:
		return null
	for child in node.get_children():
		if child is Interactable:
			return child
	return null


## Kohta, jota kohti napautuksen anteeksianto mitataan.
func focus_position() -> Vector3:
	return prop().global_position + Vector3(0, focus_height, 0)


func climb_position() -> Vector3:
	return prop().to_global(climb_point)


## Käyttää esinettä: käynnistää seuraavan reaktiosarjan. Palauttaa sarjan numeron (-1 = ei sarjoja).
func use(ctx: ReactionContext) -> int:
	stop()
	if variants.is_empty():
		use_count += 1
		used.emit(-1)
		return -1
	var index := use_count % variants.size()
	use_count += 1
	var chosen := variants[index]
	if chosen != null:
		for reaction in chosen.reactions:
			if reaction == null:
				continue
			var tween := reaction.play(ctx)
			if tween != null:
				_tweens.append(tween)
	used.emit(index)
	return index


## Pysäyttää käynnissä olevat temput ja palauttaa esineen osat paikoilleen.
func stop() -> void:
	for tween in _tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_tweens.clear()
	for node in _rest:
		if is_instance_valid(node):
			(node as Node3D).transform = _rest[node][0]
			(node as Node3D).visible = _rest[node][1]


func is_playing() -> bool:
	for tween in _tweens:
		if tween != null and tween.is_valid() and tween.is_running():
			return true
	return false


func _remember_rest() -> void:
	_rest.clear()
	var p := prop()
	if p == null:
		return
	var visual := p.get_node_or_null("Visual")
	if visual == null:
		return
	for node in [visual] + visual.find_children("*", "Node3D", true, false):
		_rest[node] = [(node as Node3D).transform, (node as Node3D).visible]
