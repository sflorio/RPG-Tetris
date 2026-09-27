## A combat "arena" that resolves a fight by playing Tetris.
##
## Clearing lines damages the enemies, one at a time, in the order they appear in the roster. The
## battle is won when every enemy is defeated and lost if the player tops out or forfeits.
##
## Responsibilities are split like this:
## [br]- [TetrisBattleConfig] decides who you fight and how the board starts.
## [br]- [TetrisDamageRules] decides how much a clear hurts (combos, streaks, Tetrises).
## [br]- [TetrisEnemy] holds one enemy's health; [UITetrisEnemyList] draws the health bars.
## [br]- This node wires those together around the PokeTetris board and reports the outcome, which
##      [Combat] turns into [signal CombatEvents.combat_finished].
class_name TetrisBattle extends Control

## Emitted once when the Tetris game ends.
signal finished(won: bool, score: int, lines: int)

const TETRIS_SCENE: PackedScene = preload("res://scn/Main.tscn")

## The area the PokeTetris scene was authored against (its Background rect is 600x821).
const DESIGN_SIZE: = Vector2(600.0, 821.0)

## PokeTetris was laid out for Godot's default font size. OpenRPG's project theme uses a much larger
## default, which makes the board's labels overflow and overlap, so the board gets its own theme.
const TETRIS_FONT_SIZE: = 16

## Vertical space kept free above the board for the encounter banner.
const BANNER_HEIGHT: = 90.0

## Margin around the enemy roster drawn beside the board.
const ROSTER_MARGIN: = 40.0

## Pause after the final blow so the player sees the last enemy drop before the screen fades.
const VICTORY_PAUSE: = 0.8

## The encounter's enemies and starting difficulty. Assign before adding this node to the tree.
var config: = TetrisBattleConfig.new()

## The damage rules used for this battle. Swap in a subclass to change how clears score.
var rules: = TetrisDamageRules.new()

var _tetris: Node2D = null
var _grid: Node2D = null
var _enemy_list: UITetrisEnemyList = null
var _board_rect: = Rect2()
var _active_popup: Control = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var viewport_size: = get_viewport_rect().size

	# A dark backdrop so the field map doesn't show through behind the board.
	var backdrop: = ColorRect.new()
	backdrop.color = Color(0.05, 0.05, 0.09)
	backdrop.position = Vector2.ZERO
	backdrop.size = viewport_size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_add_banner(viewport_size)
	_add_board(viewport_size)
	_add_enemy_roster()


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
	_grid.start_level = config.start_level
	_grid.garbage_rows = config.garbage_rows
	_grid.lines_cleared.connect(_on_lines_cleared)
	_grid.clearless_lock.connect(rules.on_clearless_lock)
	_grid.battle_finished.connect(_on_grid_battle_finished)

	var tetris_theme: = Theme.new()
	tetris_theme.default_font_size = TETRIS_FONT_SIZE
	tetris_theme.set_font_size("font_size", "Label", TETRIS_FONT_SIZE)
	(_grid.get_node("UI") as Control).theme = tetris_theme

	# Scale the board to fill the space under the banner without distortion.
	var board_area: = Vector2(viewport_size.x, viewport_size.y - BANNER_HEIGHT)
	var scale_factor: = minf(board_area.x / DESIGN_SIZE.x, board_area.y / DESIGN_SIZE.y)
	var board_size: = DESIGN_SIZE * scale_factor
	_tetris.scale = Vector2(scale_factor, scale_factor)
	_tetris.position = Vector2(
		(viewport_size.x - board_size.x) * 0.5,
		BANNER_HEIGHT + (board_area.y - board_size.y) * 0.5
	)
	_board_rect = Rect2(_tetris.position, board_size)

	add_child(_tetris)


# The roster lives in the empty margin to the left of the board, which is free because the board's
# own readouts (next pieces, lines) sit on its right.
func _add_enemy_roster() -> void:
	_enemy_list = UITetrisEnemyList.new()
	_enemy_list.position = Vector2(ROSTER_MARGIN, BANNER_HEIGHT + ROSTER_MARGIN)
	_enemy_list.size = Vector2(
		maxf(_board_rect.position.x - ROSTER_MARGIN*2.0, 120.0),
		_board_rect.size.y - ROSTER_MARGIN*2.0
	)
	add_child(_enemy_list)
	_enemy_list.setup(config.enemies)


# --- Combat ----------------------------------------------------------------------------------

func _on_lines_cleared(count: int, piece: int, is_perfect_clear: bool) -> void:
	var breakdown: = rules.resolve_clear(count, piece, is_perfect_clear)
	var target: = _get_target_enemy()
	if target == null:
		return

	# Damage spills onto the next enemy so a big hit can take down two weak ones at once.
	var remaining: = breakdown.total_damage
	while remaining > 0:
		var enemy: = _get_target_enemy()
		if enemy == null:
			break
		remaining -= enemy.take_damage(remaining)

	_enemy_list.refresh()
	_show_damage_popup(breakdown)

	if _get_target_enemy() == null:
		_win_battle()


func _get_target_enemy() -> TetrisEnemy:
	for enemy in config.enemies:
		if not enemy.is_defeated():
			return enemy
	return null


func _win_battle() -> void:
	# Freeze the board immediately so the player can't top out during the victory pause.
	_grid.set_physics_process(false)
	await get_tree().create_timer(VICTORY_PAUSE).timeout
	if is_instance_valid(_grid):
		_grid.end_battle(true)


# --- Feedback --------------------------------------------------------------------------------

# Plain Controls with explicit positions are used rather than a VBoxContainer: a container would
# re-layout the labels into its own (zero-height) rect and they would never appear.
func _show_damage_popup(breakdown: TetrisDamageBreakdown) -> void:
	const DAMAGE_HEIGHT: = 70.0
	const BONUS_HEIGHT: = 34.0

	# Only the newest hit is shown: during a fast combo the popups would otherwise pile up on top of
	# each other and none of them could be read.
	if is_instance_valid(_active_popup):
		_active_popup.queue_free()

	var popup: = Control.new()
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The PokeTetris board sets z_index = 1 on its Grid, so the popup must sit above that or it is
	# drawn behind the board and never seen.
	popup.z_index = 10
	popup.position = Vector2(_board_rect.position.x, _board_rect.get_center().y)
	popup.size = Vector2(_board_rect.size.x, DAMAGE_HEIGHT)

	var damage_label: = Label.new()
	damage_label.text = "-%d" % breakdown.total_damage
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.position = Vector2.ZERO
	damage_label.size = Vector2(_board_rect.size.x, DAMAGE_HEIGHT)
	damage_label.add_theme_font_size_override("font_size", 64)
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	popup.add_child(damage_label)

	if breakdown.has_bonus():
		var bonus_label: = Label.new()
		bonus_label.text = "\n".join(breakdown.bonus_labels)
		bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus_label.position = Vector2(0.0, DAMAGE_HEIGHT)
		bonus_label.size = Vector2(
			_board_rect.size.x, BONUS_HEIGHT * breakdown.bonus_labels.size()
		)
		bonus_label.add_theme_font_size_override("font_size", 28)
		bonus_label.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0))
		popup.add_child(bonus_label)

	add_child(popup)
	_active_popup = popup

	var tween: = create_tween().set_parallel()
	tween.tween_property(popup, "position:y", popup.position.y - 140.0, 1.1)
	tween.tween_property(popup, "modulate:a", 0.0, 1.1).set_delay(0.35)
	tween.chain().tween_callback(popup.queue_free)


func _on_grid_battle_finished(won: bool, final_score: int, final_lines: int) -> void:
	finished.emit(won, final_score, final_lines)
