## The hit announcement that punches over a board when an attack lands.
##
## Reads like a fighting game rather than a spreadsheet: a named call-out ("RALLY STRIKE!!"), a big
## outlined damage number, and a hit counter when several attacks land at once. Escalates with the
## weight of the attack, so a Union Assault does not look like a poke.
class_name UIAttackPopup extends Control

const FONT_BOLD: = "res://addons/dialogic/Example Assets/Fonts/Roboto-Bold.ttf"

const NAME_FONT_SIZE: = 46
const DAMAGE_FONT_SIZE: = 104
const DETAIL_FONT_SIZE: = 26

## Outline thickness, which is what makes the numbers read over a busy stack.
const NAME_OUTLINE: = 10
const DAMAGE_OUTLINE: = 16
const DETAIL_OUTLINE: = 6

## Call-outs per attack kind. More punctuation means a heavier hit.
const KIND_CALLOUTS: = {
	AttackResolver.Kind.BASIC: "HIT",
	AttackResolver.Kind.SPECIAL: "SPECIAL!",
	AttackResolver.Kind.SPECIAL_BOOSTED: "SUPER SPECIAL!!",
	AttackResolver.Kind.RALLY_STRIKE: "RALLY STRIKE!!",
	AttackResolver.Kind.UNION_ASSAULT: "UNION ASSAULT!!!",
}

## Colour per attack kind, warming up as the attack gets heavier.
const KIND_COLORS: = {
	AttackResolver.Kind.BASIC: Color("e2e8f0"),
	AttackResolver.Kind.SPECIAL: Color("5fd4ff"),
	AttackResolver.Kind.SPECIAL_BOOSTED: Color("8b7bff"),
	AttackResolver.Kind.RALLY_STRIKE: Color("ffc94d"),
	AttackResolver.Kind.UNION_ASSAULT: Color("ff5e7a"),
}

const DAMAGE_COLOR: = Color("ffe066")
const CRIT_COLOR: = Color("ff4d6d")
const MISS_COLOR: = Color("94a3b8")
const OUTLINE_COLOR: = Color(0.02, 0.02, 0.05, 0.95)

var _font: Font = null


## Builds and plays the announcement. `results` are the attacks that just landed, `total_damage`
## their combined damage, and `rect` the board they landed on.
func play(results: Array[AttackResult], total_damage: int, rect: Rect2) -> void:
	_font = load(FONT_BOLD)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The board sets z_index = 1 on its Grid, so this has to sit above it to be seen at all.
	z_index = 20
	position = Vector2(rect.position.x, rect.get_center().y - 90.0)
	size = Vector2(rect.size.x, 240.0)

	var heaviest: = _get_heaviest(results)
	var all_missed: = _all_missed(results)
	var any_crit: = _any_crit(results)

	var callout: = _build_label(
		_get_callout(heaviest, all_missed), NAME_FONT_SIZE, NAME_OUTLINE,
		MISS_COLOR if all_missed else KIND_COLORS.get(heaviest, Color.WHITE), 0.0
	)
	add_child(callout)

	var damage_text: = "MISS" if all_missed else "-%d" % total_damage
	var damage_label: = _build_label(
		damage_text, DAMAGE_FONT_SIZE, DAMAGE_OUTLINE,
		MISS_COLOR if all_missed else (CRIT_COLOR if any_crit else DAMAGE_COLOR),
		NAME_FONT_SIZE + 6.0
	)
	add_child(damage_label)

	var detail: = _build_detail(results, any_crit)
	if not detail.is_empty():
		add_child(_build_label(
			detail, DETAIL_FONT_SIZE, DETAIL_OUTLINE, Color("cbd5e1"),
			NAME_FONT_SIZE + DAMAGE_FONT_SIZE + 16.0
		))

	_animate(heaviest, all_missed)


# A hard scale punch, a settle, then a drift upward as it fades. The heavier the attack, the more
# it overshoots and the longer it lingers.
func _animate(kind: int, missed: bool) -> void:
	var weight: = 0.0 if missed else float(kind) / float(AttackResolver.Kind.UNION_ASSAULT)
	var overshoot: = 1.25 + weight*0.45
	var hold: = 0.45 + weight*0.35

	pivot_offset = Vector2(size.x * 0.5, size.y * 0.35)
	scale = Vector2(overshoot, overshoot)
	modulate.a = 0.0

	var punch: = create_tween()
	punch.tween_property(self, "modulate:a", 1.0, 0.06)
	punch.parallel().tween_property(self, "scale", Vector2.ONE, 0.20)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# A heavy hit shakes on impact.
	if weight >= 0.5:
		var shake: = create_tween()
		var home: = position
		for offset in [Vector2(-9, 0), Vector2(8, 0), Vector2(-5, 0), Vector2(3, 0)]:
			shake.tween_property(self, "position", home + offset, 0.035)
		shake.tween_property(self, "position", home, 0.035)

	var exit: = create_tween().set_parallel()
	exit.tween_property(self, "position:y", position.y - 110.0, 0.9).set_delay(hold)
	exit.tween_property(self, "modulate:a", 0.0, 0.9).set_delay(hold)
	exit.chain().tween_callback(queue_free)


func _build_label(
	text: String, font_size: int, outline: int, color: Color, y_offset: float
) -> Label:
	var label: = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0.0, y_offset)
	label.size = Vector2(size.x, font_size + 10.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _font != null:
		label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	return label


# "3 HITS - PERFECT STRIKE - Bear, Squirrel"
func _build_detail(results: Array[AttackResult], any_crit: bool) -> String:
	var parts: Array[String] = []

	var landed: = 0
	for result in results:
		if not result.was_dodged:
			landed += 1
	if landed > 1:
		parts.append("%d HITS" % landed)
	if any_crit:
		parts.append("PERFECT STRIKE")

	var names: Array[String] = []
	for result in results:
		if result.attacker_name not in names:
			names.append(result.attacker_name)
	if not names.is_empty():
		parts.append(", ".join(names))

	return "  -  ".join(parts)


static func _get_callout(kind: int, missed: bool) -> String:
	if missed:
		return "MISS"
	return KIND_CALLOUTS.get(kind, "HIT")


# The heaviest attack in the batch decides the call-out, so a Rally Strike is not announced as a
# plain hit just because a Basic Attack came along with it.
static func _get_heaviest(results: Array[AttackResult]) -> int:
	var heaviest: = AttackResolver.Kind.BASIC
	for result in results:
		if result.kind > heaviest:
			heaviest = result.kind
	return heaviest


static func _all_missed(results: Array[AttackResult]) -> bool:
	for result in results:
		if not result.was_dodged:
			return false
	return true


static func _any_crit(results: Array[AttackResult]) -> bool:
	for result in results:
		if result.was_perfect_strike:
			return true
	return false
