## The enemy roster shown beside the Tetris board: one name + health bar per enemy.
##
## Built entirely in code so it needs no scene file. Call [method setup] once with the battle's
## enemies, then [method refresh] whenever their health changes.
class_name UITetrisEnemyList extends VBoxContainer

const ROW_SEPARATION: = 18
const BAR_HEIGHT: = 26

const COLOR_TARGET: = Color(1.0, 0.95, 0.85)
const COLOR_WAITING: = Color(0.72, 0.72, 0.78)
const COLOR_DEFEATED: = Color(0.45, 0.45, 0.5)

const BAR_FILL_TARGET: = Color(0.85, 0.25, 0.30)
const BAR_FILL_WAITING: = Color(0.55, 0.25, 0.32)
const BAR_BACKGROUND: = Color(0.16, 0.16, 0.22)

var _enemies: Array[TetrisEnemy] = []
var _name_labels: Array[Label] = []
var _health_bars: Array[ProgressBar] = []


## Creates one row per enemy. `enemies` is kept by reference, so later damage is picked up by
## [method refresh].
func setup(enemies: Array[TetrisEnemy]) -> void:
	_enemies = enemies
	_name_labels.clear()
	_health_bars.clear()
	for child in get_children():
		child.queue_free()

	add_theme_constant_override("separation", ROW_SEPARATION)

	for enemy in _enemies:
		var row: = VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		add_child(row)

		var name_label: = Label.new()
		name_label.add_theme_font_size_override("font_size", 26)
		row.add_child(name_label)
		_name_labels.append(name_label)

		var health_bar: = ProgressBar.new()
		health_bar.custom_minimum_size = Vector2(0.0, BAR_HEIGHT)
		health_bar.min_value = 0.0
		health_bar.max_value = float(enemy.max_hp)
		health_bar.show_percentage = false
		health_bar.add_theme_stylebox_override("background", _make_bar_style(BAR_BACKGROUND))
		row.add_child(health_bar)
		_health_bars.append(health_bar)

	refresh()


## Repaints every row from the enemies' current health.
func refresh() -> void:
	var target_index: = get_target_index()

	for i in _enemies.size():
		var enemy: = _enemies[i]
		var is_target: = i == target_index

		var text_color: = COLOR_DEFEATED
		if not enemy.is_defeated():
			text_color = COLOR_TARGET if is_target else COLOR_WAITING

		var label: = _name_labels[i]
		label.text = "%s  %d/%d" % [enemy.display_name, maxi(enemy.hp, 0), enemy.max_hp]
		if enemy.is_defeated():
			label.text = "%s  DOWN" % enemy.display_name
		elif is_target:
			label.text = "> " + label.text
		label.add_theme_color_override("font_color", text_color)

		var bar: = _health_bars[i]
		bar.value = float(maxi(enemy.hp, 0))
		bar.add_theme_stylebox_override(
			"fill", _make_bar_style(BAR_FILL_TARGET if is_target else BAR_FILL_WAITING)
		)
		bar.modulate.a = 0.35 if enemy.is_defeated() else 1.0


## Index of the enemy currently taking damage: the first one still standing. Returns -1 when every
## enemy has been defeated.
func get_target_index() -> int:
	for i in _enemies.size():
		if not _enemies[i].is_defeated():
			return i
	return -1


static func _make_bar_style(color: Color) -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style
