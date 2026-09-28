## A always-on strip above the player's board naming the effects currently changing how it plays.
##
## The status call-outs fire once, at the moment an effect lands. This is the other half: while an
## effect is active the player can look straight at the board and see why the preview is hidden, why
## a third is dark, or why rotation is refused — along with how many Rounds are left of it.
class_name UIBoardStatus extends HBoxContainer

## Effects worth showing here: the ones that change how the board behaves, rather than the ones
## that only drain health.
const TRACKED: Array[String] = [
	StatusEffectDefs.BLIND,
	StatusEffectDefs.SHOCKED,
	StatusEffectDefs.CONFUSION,
	StatusEffectDefs.INFECTION,
]

## What each one actually does to the board, in the player's terms.
const EXPLANATIONS: = {
	StatusEffectDefs.BLIND: "board hidden",
	StatusEffectDefs.SHOCKED: "cannot rotate",
	StatusEffectDefs.CONFUSION: "preview hidden",
	StatusEffectDefs.INFECTION: "corrupted blocks",
}

const COLOR_ACTIVE: = Color(1.0, 0.55, 0.55)
const FONT_SIZE: = 19
const EXPLAIN_FONT_SIZE: = 15


## Rebuilds the strip from whichever allies are afflicted. Call whenever effects change.
func refresh(allies: Array[CombatUnit]) -> void:
	for child in get_children():
		child.queue_free()

	add_theme_constant_override("separation", 26)
	alignment = BoxContainer.ALIGNMENT_CENTER

	# One entry per effect, showing the longest remaining duration across the team — that is how
	# long the board stays affected, since any afflicted ally affects the shared board.
	for id in TRACKED:
		var rounds: = -1
		var tier: = StatusEffect.TIER_NORMAL
		for ally in allies:
			if ally.is_downed():
				continue
			var effect: StatusEffect = ally.get_effect(id)
			if effect != null and effect.rounds_remaining > rounds:
				rounds = effect.rounds_remaining
				tier = effect.tier
		if rounds < 0:
			continue

		add_child(_make_entry(id, tier, rounds))

	visible = get_child_count() > 0


func _make_entry(id: String, tier: int, rounds: int) -> Control:
	var entry: = VBoxContainer.new()
	entry.add_theme_constant_override("separation", 0)
	entry.alignment = BoxContainer.ALIGNMENT_CENTER

	var suffix: = ""
	if tier == StatusEffect.TIER_WEAK:
		suffix = "-"
	elif tier == StatusEffect.TIER_STRONG:
		suffix = "+"

	var title: = Label.new()
	title.text = "%s%s  %d" % [id.to_upper(), suffix, rounds]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", FONT_SIZE)
	title.add_theme_color_override("font_color", COLOR_ACTIVE)
	entry.add_child(title)

	var explain: = Label.new()
	explain.text = EXPLANATIONS.get(id, "")
	explain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explain.add_theme_font_size_override("font_size", EXPLAIN_FONT_SIZE)
	explain.add_theme_color_override("font_color", Color(0.72, 0.72, 0.80))
	entry.add_child(explain)

	return entry
