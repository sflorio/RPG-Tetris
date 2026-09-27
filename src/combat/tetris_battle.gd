## A combat "arena" that resolves a fight by playing Tetris.
##
## Clearing lines makes the player's characters attack, following the design's Boards note: the
## block used to clear decides [i]who[/i] attacks, and the number of lines decides [i]how[/i]:
## 1 line is a Basic Attack, 2 a Special, 3 a Special with +50%, and 4 makes every active ally
## perform their Rally Strike. Lines also fill the Union meter, which fires a Union Assault at ten.
##
## Responsibilities are split like this:
## [br]- [TetrisBattleConfig] decides who fights, the block assignments and how the board starts.
## [br]- [AttackResolver] turns one attack into damage.
## [br]- [UnionMeter] tracks progress toward the Union Assault.
## [br]- [CombatUnit] holds a unit's health; [UITetrisEnemyList] draws the enemy roster.
## [br]- This node wires those together and reports the outcome, which [Combat] turns into
##      [signal CombatEvents.combat_finished].
class_name TetrisBattle extends Control

## Emitted once when the Tetris game ends.
signal finished(won: bool, score: int, lines: int)

const TETRIS_SCENE: PackedScene = preload("res://scn/Main.tscn")

## The area the PokeTetris scene was authored against (its Background rect is 600x821).
const DESIGN_SIZE: = Vector2(600.0, 821.0)

## The board was laid out for Godot's default font size; the project theme uses a much larger one.
const TETRIS_FONT_SIZE: = 16

## Vertical space kept free above the board for the encounter banner.
const BANNER_HEIGHT: = 90.0

## Vertical space kept free below the board for the block legend.
const TALLY_HEIGHT: = 84.0

## Margin around the rosters drawn beside the board.
const ROSTER_MARGIN: = 40.0

## Pause after the final blow so the player sees the last enemy drop before the screen fades.
const VICTORY_PAUSE: = 0.8

## Who is fighting and how the board starts. Assign before adding this node to the tree.
var config: = TetrisBattleConfig.new()

## Progress toward the Union Assault.
var union_meter: = UnionMeter.new()

var _tetris: Node2D = null
var _grid: Node2D = null
var _enemy_list: UITetrisEnemyList = null
var _clear_tally: UIClearTally = null
var _union_ui: UIUnionMeter = null
var _board_rect: = Rect2()
var _active_popup: Control = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Combat actions are registered from the active scheme before the board reads any input.
	TetrisControls.apply()

	var viewport_size: = get_viewport_rect().size

	var backdrop: = ColorRect.new()
	backdrop.color = Color(0.05, 0.05, 0.09)
	backdrop.position = Vector2.ZERO
	backdrop.size = viewport_size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_add_banner(viewport_size)
	_add_board(viewport_size)
	_add_enemy_roster()
	_add_union_meter()
	_add_clear_tally(viewport_size)


func _add_banner(viewport_size: Vector2) -> void:
	var banner: = Label.new()
	banner.text = "VS %s" % config.enemy_description
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.position = Vector2.ZERO
	banner.size = Vector2(viewport_size.x, BANNER_HEIGHT)
	banner.add_theme_font_size_override("font_size", 40)
	add_child(banner)


func _add_board(viewport_size: Vector2) -> void:
	_tetris = TETRIS_SCENE.instantiate() as Node2D
	_grid = _tetris.get_node("Grid") as Node2D
	# Fall speed comes from the party's Gravity stat, not from the enemies present.
	_grid.start_level = maxi(config.party.gravity, 1)
	_grid.junk_rows = config.junk_rows
	_grid.lines_cleared.connect(_on_lines_cleared)
	_grid.battle_finished.connect(_on_grid_battle_finished)

	var tetris_theme: = Theme.new()
	tetris_theme.default_font_size = TETRIS_FONT_SIZE
	tetris_theme.set_font_size("font_size", "Label", TETRIS_FONT_SIZE)
	(_grid.get_node("UI") as Control).theme = tetris_theme

	var board_area: = Vector2(viewport_size.x, viewport_size.y - BANNER_HEIGHT - TALLY_HEIGHT)
	var scale_factor: = minf(board_area.x / DESIGN_SIZE.x, board_area.y / DESIGN_SIZE.y)
	var board_size: = DESIGN_SIZE * scale_factor
	_tetris.scale = Vector2(scale_factor, scale_factor)
	_tetris.position = Vector2(
		(viewport_size.x - board_size.x) * 0.5,
		BANNER_HEIGHT + (board_area.y - board_size.y) * 0.5
	)
	_board_rect = Rect2(_tetris.position, board_size)

	add_child(_tetris)


# The rosters live in the empty margin left of the board, which is free because the board's own
# readouts (next blocks, lines) sit on its right.
func _add_enemy_roster() -> void:
	_enemy_list = UITetrisEnemyList.new()
	_enemy_list.position = Vector2(ROSTER_MARGIN, BANNER_HEIGHT + ROSTER_MARGIN)
	_enemy_list.size = Vector2(_get_roster_width(), _board_rect.size.y * 0.55)
	add_child(_enemy_list)
	# Enemy health is only legible once the HP Sight Psionic Power has been found.
	_enemy_list.setup(config.enemies, config.party.has_power(PartyStats.HP_SIGHT))


func _add_union_meter() -> void:
	_union_ui = UIUnionMeter.new()
	_union_ui.position = Vector2(
		ROSTER_MARGIN, BANNER_HEIGHT + ROSTER_MARGIN + _board_rect.size.y*0.55 + 30.0
	)
	_union_ui.size = Vector2(_get_roster_width(), 60.0)
	add_child(_union_ui)


func _add_clear_tally(viewport_size: Vector2) -> void:
	_clear_tally = UIClearTally.new()
	_clear_tally.position = Vector2(0.0, viewport_size.y - TALLY_HEIGHT)
	_clear_tally.size = Vector2(viewport_size.x, TALLY_HEIGHT)
	add_child(_clear_tally)
	_clear_tally.setup(config.allies)


func _get_roster_width() -> float:
	return maxf(_board_rect.position.x - ROSTER_MARGIN*2.0, 140.0)


# --- Combat ----------------------------------------------------------------------------------

func _on_lines_cleared(count: int, block_type: int) -> void:
	var target: = _get_target_enemy()
	if target == null:
		return

	var results: Array[AttackResult] = []

	if count >= 4:
		# Four lines is only reachable with the Line block, and rallies the whole team.
		for ally in config.get_active_allies():
			results.append(AttackResolver.resolve(ally, target, AttackResolver.Kind.RALLY_STRIKE))
	else:
		# Otherwise only the character holding this block type attacks. A block assigned to nobody
		# still clears the line and fills the Union meter, it just deals no damage.
		var attacker: = config.find_ally_for_block(block_type)
		if attacker != null:
			results.append(
				AttackResolver.resolve(attacker, target, AttackResolver.kind_for_lines(count))
			)

	# Lines always feed the Union meter, whoever cleared them.
	var union_bonus: = union_meter.add_lines(count)
	if union_bonus > 0.0:
		for ally in config.get_active_allies():
			results.append(AttackResolver.resolve(
				ally, target, AttackResolver.Kind.UNION_ASSAULT, union_bonus
			))

	_apply_results(results)

	if union_bonus > 0.0:
		_union_ui.play_assault()
	else:
		_union_ui.refresh(union_meter.lines)

	_clear_tally.record_clear(block_type, count)

	if _get_target_enemy() == null:
		_win_battle()


# Applies every attack in order, letting damage spill onto the next enemy so a Rally Strike can
# drop more than one. Each enemy reached is animated.
func _apply_results(results: Array[AttackResult]) -> void:
	var struck_indices: Array[int] = []
	var total_damage: = 0

	for result in results:
		var remaining: = result.damage
		total_damage += remaining
		while remaining > 0:
			var index: = _enemy_list.get_target_index()
			if index < 0:
				break
			var dealt: = config.enemies[index].take_damage(remaining)
			if dealt <= 0:
				break
			if index not in struck_indices:
				struck_indices.append(index)
			remaining -= dealt

	for index in struck_indices:
		_enemy_list.play_hit(index)

	if not results.is_empty():
		_show_attack_popup(results, total_damage)


func _get_target_enemy() -> CombatUnit:
	for enemy in config.enemies:
		if not enemy.is_downed():
			return enemy
	return null


func _win_battle() -> void:
	_grid.set_physics_process(false)
	await get_tree().create_timer(VICTORY_PAUSE).timeout
	if is_instance_valid(_grid):
		_grid.end_battle(true)


# --- Feedback --------------------------------------------------------------------------------

# Plain Controls with explicit positions are used rather than a VBoxContainer: a container would
# re-layout the labels into its own (zero-height) rect and they would never appear.
func _show_attack_popup(results: Array[AttackResult], total_damage: int) -> void:
	const DAMAGE_HEIGHT: = 70.0
	const LINE_HEIGHT: = 32.0

	if is_instance_valid(_active_popup):
		_active_popup.queue_free()

	var popup: = Control.new()
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The board sets z_index = 1 on its Grid, so the popup must sit above that to be seen at all.
	popup.z_index = 10
	popup.position = Vector2(_board_rect.position.x, _board_rect.get_center().y)
	popup.size = Vector2(_board_rect.size.x, DAMAGE_HEIGHT)

	var damage_label: = Label.new()
	damage_label.text = "-%d" % total_damage
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.position = Vector2.ZERO
	damage_label.size = Vector2(_board_rect.size.x, DAMAGE_HEIGHT)
	damage_label.add_theme_font_size_override("font_size", 64)
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	popup.add_child(damage_label)

	var lines: Array[String] = []
	for result in results:
		lines.append(result.get_label())

	var detail: = Label.new()
	detail.text = "\n".join(lines)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.position = Vector2(0.0, DAMAGE_HEIGHT)
	detail.size = Vector2(_board_rect.size.x, LINE_HEIGHT * lines.size())
	detail.add_theme_font_size_override("font_size", 26)
	detail.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0))
	popup.add_child(detail)

	add_child(popup)
	_active_popup = popup

	var tween: = create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 140.0, 1.1)
	tween.tween_property(popup, "modulate:a", 0.0, 1.1).set_delay(0.35)
	tween.chain().tween_callback(popup.queue_free)


func _on_grid_battle_finished(won: bool, final_score: int, final_lines: int) -> void:
	finished.emit(won, final_score, final_lines)
