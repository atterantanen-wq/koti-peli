class_name HeroPicker
extends CardPicker
## Pelin alussa: lapsi valitsee, onko hahmo tyttö vai poika, napauttamalla kasvokuvaa.

const KINDS := ["girl", "boy"]
const CARD_COLORS := [Color(1.0, 0.82, 0.88), Color(0.8, 0.92, 0.82)]


func _init() -> void:
	kinds = KINDS
	card_colors = CARD_COLORS


func _draw_card(i: int, center: Vector2, r: float) -> void:
	LookIcons.draw_face(self, center + Vector2(0, -r * 0.08), r * 0.6, KINDS[i])
	# Vaatekuva pienenä kortin alareunassa: hahmon oletusasu.
	LookIcons.draw_outfit(self, center + Vector2(0, r * 0.7), r * 0.2,
			PlayerArt.default_outfit(KINDS[i]))
