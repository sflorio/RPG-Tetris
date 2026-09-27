## The enemy roster shown beside the Tetris board: a portrait, a name and a health bar per enemy.
##
## Health values are hidden until the player unlocks the [b]HP Sight[/b] Psionic Power. Without it
## the bar is drawn as an unreadable block and the numbers read "???", which is the design's intent:
## seeing enemy health is something the player earns.
##
## Built entirely in code so it needs no scene file. Call [method setup] once with the battle's
## enemies, then [method play_hit] when one takes damage.
class_name UITetrisEnemyList extends VBoxContainer

const ROW_SEPARATION: = 18
const BAR_HEIGHT: = 26
const ICON_SIZE: = 72

## How long a health bar takes to drain to its new value.
const DRAIN_TIME: = 0.35

const COLOR_TARGET: = Color(1.0, 0.95, 0.85)
const COLOR_WAITING: = Color(0.72, 0.72, 0.78)
const COLOR_DEFEATED: = Color(0.45, 0.45, 0.5)

const BAR_FILL_TARGET: = Color(0.85, 0.25, 0.30)
const BAR_FILL_WAITING: = Color(0.55, 0.25, 0.32)
const BAR_BACKGROUND: = Color(0.16, 0.16, 0.22)

var _enemies: Array[CombatUnit] = []

## Whether exact health is shown, i.e. whether HP Sight has been unlocked.
var _reveal_health: = false
var _rows: Array[Control] = []
var _icons: Array[TextureRect] = []
var _name_labels: Array[Label] = []
var _health_bars: Array[ProgressBar] = []


## Creates one row per enemy. `enemies` is kept by reference, so later damage is picked up by
## [method refresh]. `reveal_health` comes from the HP Sight Psionic Power.
func setup(enemies: Array[CombatUnit], reveal_health: bool) -> void:
	_enemies = enemies
	_reveal_health = reveal_health
	_rows.clear()
	_icons.clear()
	_name_labels.clear()
	_health_bars.clear()
	for child in get_children():
		child.queue_free()

	add_theme_constant_override("separation", ROW_SEPARATION)

	for enemy in _enemies:
		# Portrait on the left, name + health bar stacked on the right.
		var row: = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		add_child(row)
		_rows.append(row)

		# The portrait sits inside a plain holder rather than directly in the HBoxContainer: a
		# container would overwrite the position the shake tween sets.
		var icon_holder: = Control.new()
		icon_holder.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon_holder.clip_contents = false
		row.add_child(icon_holder)

		var icon: = TextureRect.new()
		icon.size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.position = Vector2.ZERO
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = enemy.icon
		icon_holder.add_child(icon)
		_icons.append(icon)

		var details: = VBoxContainer.new()
		details.add_theme_constant_override("separation", 2)
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(details)

		var name_label: = Label.new()
		name_label.add_theme_font_size_override("font_size", 26)
		details.add_child(name_label)
		_name_labels.append(name_label)

		var health_bar: = ProgressBar.new()
		health_bar.custom_minimum_size = Vector2(0.0, BAR_HEIGHT)
		health_bar.min_value = 0.0
		health_bar.max_value = float(enemy.stats.max_hp)
		health_bar.value = float(enemy.hp)
		health_bar.show_percentage = false
		health_bar.add_theme_stylebox_override("background", _make_bar_style(BAR_BACKGROUND))
		details.add_child(health_bar)
		_health_bars.append(health_bar)

	refresh()


## Repaints every row from the enemies' current health, without animating.
func refresh() -> void:
	var target_index: = get_target_index()

	for i in _enemies.size():
		var enemy: = _enemies[i]
		var is_target: = i == target_index

		var text_color: = COLOR_DEFEATED
		if not enemy.is_downed():
			text_color = COLOR_TARGET if is_target else COLOR_WAITING

		var label: = _name_labels[i]
		label.text = _format_row(enemy, is_target)
		label.add_theme_color_override("font_color", text_color)

		var bar: = _health_bars[i]
		# Without HP Sight the bar stays full, so it reveals nothing about remaining health.
		bar.value = float(maxi(enemy.hp, 0)) if _reveal_health else float(enemy.stats.max_hp)
		bar.add_theme_stylebox_override(
			"fill", _make_bar_style(BAR_FILL_TARGET if is_target else BAR_FILL_WAITING)
		)
		_rows[i].modulate.a = 0.4 if enemy.is_downed() else 1.0


## Plays the damage reaction for one enemy: the portrait flashes red and shakes, and the health bar
## drains to its new value rather than jumping. Call after the enemy's health has been reduced.
func play_hit(index: int) -> void:
	if index < 0 or index >= _enemies.size():
		return

	var enemy: = _enemies[index]
	_name_labels[index].text = _format_row(enemy, true)

	# Drain the bar smoothly toward the new health, but only when HP Sight makes it readable.
	# Without the power the bar stays full, so it gives no information away.
	var drain: Tween = null
	if _reveal_health:
		var bar: = _health_bars[index]
		drain = create_tween()
		drain.tween_property(bar, "value", float(maxi(enemy.hp, 0)), DRAIN_TIME)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Flash the portrait red and shake it.
	var icon: = _icons[index]
	var flash: = create_tween()
	flash.tween_property(icon, "modulate", Color(2.0, 0.5, 0.5), 0.05)
	flash.tween_property(icon, "modulate", Color.WHITE, 0.25)

	var home: = Vector2.ZERO
	var shake: = create_tween()
	for offset in [Vector2(-7, 0), Vector2(6, 0), Vector2(-4, 0), Vector2(2, 0)]:
		shake.tween_property(icon, "position", home + offset, 0.04)
	shake.tween_property(icon, "position", home, 0.04)

	if enemy.is_downed():
		if drain != null:
			await drain.finished
		_play_defeat(index)


# A defeated enemy slumps: the whole row fades back and the portrait desaturates.
func _play_defeat(index: int) -> void:
	var enemy: = _enemies[index]
	_name_labels[index].text = "%s  DOWN" % enemy.display_name
	_name_labels[index].add_theme_color_override("font_color", COLOR_DEFEATED)

	var fade: = create_tween().set_parallel()
	fade.tween_property(_rows[index], "modulate:a", 0.4, 0.4)
	fade.tween_property(_icons[index], "modulate", Color(0.4, 0.4, 0.45), 0.4)
	await fade.finished
	refresh()


## Index of the enemy currently taking damage: the first one still standing. Returns -1 when every
## enemy has been defeated.
func get_target_index() -> int:
	for i in _enemies.size():
		if not _enemies[i].is_downed():
			return i
	return -1


# "> Bugcat  12/50" with HP Sight, "> Bugcat  ???" without it.
func _format_row(enemy: CombatUnit, is_target: bool) -> String:
	if enemy.is_downed():
		return "%s  DOWN" % enemy.display_name

	var health: = "%d/%d" % [maxi(enemy.hp, 0), enemy.stats.max_hp] if _reveal_health else "???"
	var prefix: = "> " if is_target else ""
	return "%s%s  %s" % [prefix, enemy.display_name, health]


static func _make_bar_style(color: Color) -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style
