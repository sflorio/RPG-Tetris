## A team's roster beside its board: portrait, name, health bar and — for enemies — a cast bar.
##
## Used for both sides. What is visible depends on the psionic powers the player has unlocked:
## enemy health reads "???" until [b]HP Sight[/b], and the cast bar only appears with
## [b]Future Sight[/b]. The player's own team always shows everything.
##
## Built in code, so it needs no scene file.
class_name UIUnitRoster extends VBoxContainer

const ROW_SEPARATION: = 16
const BAR_HEIGHT: = 22
const CAST_BAR_HEIGHT: = 8
## 3x the 24px source art, so the pixels stay square.
const ICON_SIZE: = 72

## How long a health bar takes to drain to its new value.
const DRAIN_TIME: = 0.35

const COLOR_TARGET: = Color(1.0, 0.95, 0.85)
const COLOR_WAITING: = Color(0.72, 0.72, 0.78)
const COLOR_DOWNED: = Color(0.45, 0.45, 0.5)
const COLOR_BUFF: = Color(0.55, 0.95, 0.65)
const COLOR_DEBUFF: = Color(1.0, 0.55, 0.55)

const BAR_FILL_TARGET: = Color(0.85, 0.25, 0.30)
const BAR_FILL_WAITING: = Color(0.55, 0.25, 0.32)
const BAR_FILL_ALLY: = Color(0.30, 0.75, 0.45)
const BAR_BACKGROUND: = Color(0.16, 0.16, 0.22)
const CAST_FILL: = Color(0.95, 0.65, 0.25)

var _units: Array[CombatUnit] = []
var _reveal_health: = false
var _show_cast: = false
var _is_ally_roster: = false

var _rows: Array[Control] = []
var _icons: Array[TextureRect] = []
var _name_labels: Array[Label] = []
var _health_bars: Array[ProgressBar] = []
var _cast_bars: Array[ProgressBar] = []
var _effect_labels: Array[Label] = []


## Builds one row per unit. `units` is kept by reference so later damage is picked up by
## [method refresh].
func setup(
	units: Array[CombatUnit],
	reveal_health: bool,
	show_cast: bool = false,
	is_ally_roster: bool = false
) -> void:
	_units = units
	_reveal_health = reveal_health
	_show_cast = show_cast
	_is_ally_roster = is_ally_roster

	for array in [_rows, _icons, _name_labels, _health_bars, _cast_bars, _effect_labels]:
		array.clear()
	for child in get_children():
		child.queue_free()

	add_theme_constant_override("separation", ROW_SEPARATION)

	for unit in _units:
		var row: = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		add_child(row)
		_rows.append(row)

		# The portrait sits in a plain holder: a container would overwrite the shake tween.
		var icon_holder: = Control.new()
		icon_holder.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		row.add_child(icon_holder)

		var icon: = TextureRect.new()
		icon.size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = unit.icon
		icon_holder.add_child(icon)
		_icons.append(icon)

		var details: = VBoxContainer.new()
		details.add_theme_constant_override("separation", 2)
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(details)

		var name_label: = Label.new()
		name_label.add_theme_font_size_override("font_size", 22)
		details.add_child(name_label)
		_name_labels.append(name_label)

		var health_bar: = ProgressBar.new()
		health_bar.custom_minimum_size = Vector2(0.0, BAR_HEIGHT)
		health_bar.min_value = 0.0
		health_bar.max_value = float(unit.stats.max_hp)
		health_bar.value = float(unit.hp)
		health_bar.show_percentage = false
		health_bar.add_theme_stylebox_override("background", _make_style(BAR_BACKGROUND))
		details.add_child(health_bar)
		_health_bars.append(health_bar)

		var effect_label: = Label.new()
		effect_label.add_theme_font_size_override("font_size", 19)
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(effect_label)
		_effect_labels.append(effect_label)

		var cast_bar: = ProgressBar.new()
		cast_bar.custom_minimum_size = Vector2(0.0, CAST_BAR_HEIGHT)
		cast_bar.min_value = 0.0
		cast_bar.max_value = 1.0
		cast_bar.show_percentage = false
		cast_bar.visible = _show_cast
		cast_bar.add_theme_stylebox_override("background", _make_style(BAR_BACKGROUND))
		cast_bar.add_theme_stylebox_override("fill", _make_style(CAST_FILL))
		details.add_child(cast_bar)
		_cast_bars.append(cast_bar)

	refresh()


## Repaints every row from the units' current state, without animating.
func refresh() -> void:
	var target_index: = get_target_index()

	for i in _units.size():
		var unit: = _units[i]
		var is_target: = i == target_index and not _is_ally_roster

		var text_color: = COLOR_DOWNED
		if not unit.is_downed():
			text_color = COLOR_TARGET if (is_target or _is_ally_roster) else COLOR_WAITING

		_name_labels[i].text = _format_row(unit, is_target)
		_name_labels[i].add_theme_color_override("font_color", text_color)

		var bar: = _health_bars[i]
		bar.value = float(maxi(unit.hp, 0)) if _reveal_health else float(unit.stats.max_hp)
		bar.add_theme_stylebox_override("fill", _make_style(_get_fill_color(is_target)))

		_refresh_effects(i)
		_cast_bars[i].value = unit.get_cast_ratio()
		_cast_bars[i].visible = _show_cast and not unit.is_downed()
		_rows[i].modulate.a = 0.4 if unit.is_downed() else 1.0


# Status effects are listed under the health bar, tinted by whether they help or hurt.
func _refresh_effects(index: int) -> void:
	var unit: = _units[index]
	var label: = _effect_labels[index]
	label.text = unit.get_effect_summary()
	label.visible = not label.text.is_empty() and not unit.is_downed()

	var has_debuff: = false
	for effect: StatusEffect in unit.effects.values():
		if not StatusEffectDefs.is_positive(effect.id):
			has_debuff = true
			break
	label.add_theme_color_override("font_color", COLOR_DEBUFF if has_debuff else COLOR_BUFF)


## Floats a health change over a unit, so per-Round damage and healing are seen landing rather than
## inferred from a bar that moved. `delta` is negative for damage, positive for healing.
func play_tick(index: int, delta: int) -> void:
	if index < 0 or index >= _rows.size() or delta == 0:
		return

	var label: = Label.new()
	label.text = ("%d" % delta) if delta < 0 else ("+%d" % delta)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override(
		"font_color", Color(0.55, 0.95, 0.65) if delta > 0 else Color(1.0, 0.45, 0.45)
	)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.05, 0.95))

	var row: = _rows[index]
	label.position = Vector2(row.size.x - 70.0, 0.0)
	label.size = Vector2(64.0, 30.0)
	label.z_index = 10
	row.add_child(label)

	var tween: = create_tween().set_parallel()
	tween.tween_property(label, "position:y", -26.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)


## Updates just the cast bars, after a Round has advanced.
func refresh_casts() -> void:
	for i in _units.size():
		if i < _cast_bars.size():
			_cast_bars[i].value = _units[i].get_cast_ratio()
			_cast_bars[i].visible = _show_cast and not _units[i].is_downed()


## Plays the damage reaction for one unit: the portrait flashes and shakes, and the health bar
## drains. Call after the unit's health has been reduced.
func play_hit(index: int) -> void:
	if index < 0 or index >= _units.size():
		return

	var unit: = _units[index]
	_name_labels[index].text = _format_row(unit, not _is_ally_roster)
	# An attack can inflict a status effect, so the effect line has to update with the hit rather
	# than waiting for the next full refresh.
	_refresh_effects(index)

	var drain: Tween = null
	if _reveal_health:
		var bar: = _health_bars[index]
		drain = create_tween()
		drain.tween_property(bar, "value", float(maxi(unit.hp, 0)), DRAIN_TIME)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var icon: = _icons[index]
	var flash: = create_tween()
	flash.tween_property(icon, "modulate", Color(2.0, 0.5, 0.5), 0.05)
	flash.tween_property(icon, "modulate", Color.WHITE, 0.25)

	var shake: = create_tween()
	for offset in [Vector2(-7, 0), Vector2(6, 0), Vector2(-4, 0), Vector2(2, 0)]:
		shake.tween_property(icon, "position", offset, 0.04)
	shake.tween_property(icon, "position", Vector2.ZERO, 0.04)

	if unit.is_downed():
		if drain != null:
			await drain.finished
		_play_downed(index)


# A downed unit goes out with a flash before dissolving away, rather than just dimming.
func _play_downed(index: int) -> void:
	_name_labels[index].text = "%s  DOWN" % _units[index].display_name
	_name_labels[index].add_theme_color_override("font_color", COLOR_DOWNED)
	_cast_bars[index].visible = false

	var icon: = _icons[index]

	# Blow out to white, hang for a beat, then dissolve.
	var flash: = create_tween()
	flash.tween_property(icon, "modulate", Color(6.0, 6.0, 6.0), 0.07)
	flash.tween_property(icon, "modulate", Color(3.0, 3.0, 3.0), 0.10)
	await flash.finished

	var fade: = create_tween().set_parallel()
	fade.tween_property(_rows[index], "modulate:a", 0.35, 0.45)
	fade.tween_property(icon, "modulate", Color(0.35, 0.35, 0.42), 0.45)
	fade.tween_property(icon, "position", Vector2(0.0, 10.0), 0.45)		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await fade.finished

	icon.position = Vector2.ZERO
	refresh()


## Index of the unit currently taking damage: the first one still standing. -1 when all are down.
func get_target_index() -> int:
	for i in _units.size():
		if not _units[i].is_downed():
			return i
	return -1


func _get_fill_color(is_target: bool) -> Color:
	if _is_ally_roster:
		return BAR_FILL_ALLY
	return BAR_FILL_TARGET if is_target else BAR_FILL_WAITING


# "> Bugcat  12/50" when health is readable, "> Bugcat  ???" when it is not.
func _format_row(unit: CombatUnit, is_target: bool) -> String:
	if unit.is_downed():
		return "%s  DOWN" % unit.display_name

	var health: = "%d/%d" % [maxi(unit.hp, 0), unit.stats.max_hp] if _reveal_health else "???"
	var prefix: = "> " if is_target else ""
	return "%s%s  %s" % [prefix, unit.display_name, health]


static func _make_style(color: Color) -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style
