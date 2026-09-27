## A combat "arena" that resolves a fight across two Tetris boards.
##
## The player's active team plays the left board. Clearing lines makes characters attack, following
## the design's Boards note: the block used decides [i]who[/i] attacks, the number of lines decides
## [i]how[/i] (1 Basic, 2 Special, 3 Special +50%, 4 rallies the whole team). Lines also fill the
## Union meter, which fires a Union Assault at ten.
##
## The enemy team holds the right board. That board is scripted rather than simulated — see
## [EnemyBoard]. Enemies charge over Rounds and strike when their cast completes.
##
## The battle is won when every enemy is down, and lost when the whole active team is down or the
## player tops out.
class_name TetrisBattle extends Control

## Emitted once when the battle ends.
signal finished(won: bool, score: int, lines: int)

const PLAYER_BOARD_SCENE: PackedScene = preload("res://scn/Main.tscn")

## The area a board scene was authored against (its Background rect is 600x821).
const DESIGN_SIZE: = Vector2(600.0, 821.0)

## The playfield's rect inside that scene, i.e. the grid itself without the Hold/Score panels.
## Blind fogs a third of the playfield, not a third of the whole board scene.
const PLAYFIELD_RECT: = Rect2(139.0, 74.0, 322.0, 662.0)

## The board was laid out for Godot's default font size; the project theme uses a much larger one.
const TETRIS_FONT_SIZE: = 18

## Clean font for the board's readouts, replacing the DOS pixel font.
const BOARD_FONT: = "res://addons/dialogic/Example Assets/Fonts/Roboto-Bold.ttf"

## Shared by both boards, so they are styled identically.

const BANNER_HEIGHT: = 90.0
const TALLY_HEIGHT: = 84.0
const ROSTER_WIDTH: = 260.0
const MARGIN: = 24.0

## Pause after the final blow so the player sees the last unit drop before the screen fades.
const END_PAUSE: = 0.8

## Chance an enemy attack also inflicts a status effect. Placeholder: the design gives enemies
## attack tables, which are not modelled yet.
const ENEMY_STATUS_CHANCE: = 0.35

## Who is fighting and how the boards start. Assign before adding this node to the tree.
var config: = TetrisBattleConfig.new()

## Progress toward the Union Assault.
var union_meter: = UnionMeter.new()

var _tetris: Node2D = null
var _grid: Node2D = null
var _enemy_board: EnemyBoard = null

var _ally_roster: UIUnitRoster = null
var _enemy_roster: UIUnitRoster = null
var _clear_tally: UIClearTally = null
var _union_ui: UIUnionMeter = null

var _player_board_rect: = Rect2()
var _enemy_board_rect: = Rect2()
var _active_popup: UIAttackPopup = null
var _is_over: = false

## Fog panels covering thirds of the player's board, shown by the Blind effect.
var _fog_panels: Array[ColorRect] = []

## Scale applied to both board scenes, needed to place overlays on the playfield.
var _board_scale: = 1.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	TetrisControls.apply()

	var viewport_size: = get_viewport_rect().size

	var backdrop: = ColorRect.new()
	backdrop.color = Color(0.05, 0.05, 0.09)
	backdrop.size = viewport_size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	_add_banner(viewport_size)
	_add_boards(viewport_size)
	_add_rosters()
	_add_union_meter()
	_add_clear_tally(viewport_size)
	_add_fog()

	_enemy_board.take_control()
	_refresh_board_effects()


func _add_banner(viewport_size: Vector2) -> void:
	var banner: = Label.new()
	banner.text = "VS %s" % config.enemy_description
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.size = Vector2(viewport_size.x, BANNER_HEIGHT)
	banner.add_theme_font_size_override("font_size", 38)
	add_child(banner)


# Left to right: ally roster, player board, enemy board, enemy roster.
func _add_boards(viewport_size: Vector2) -> void:
	var board_area_height: = viewport_size.y - BANNER_HEIGHT - TALLY_HEIGHT
	var board_area_width: = (viewport_size.x - (ROSTER_WIDTH + MARGIN*2.0)*2.0) * 0.5
	var scale_factor: = minf(board_area_width / DESIGN_SIZE.x, board_area_height / DESIGN_SIZE.y)
	_board_scale = scale_factor
	var board_size: = DESIGN_SIZE * scale_factor
	var board_y: = BANNER_HEIGHT + (board_area_height - board_size.y) * 0.5

	var player_x: = ROSTER_WIDTH + MARGIN*2.0
	var enemy_x: = player_x + board_size.x
	_player_board_rect = Rect2(Vector2(player_x, board_y), board_size)
	_enemy_board_rect = Rect2(Vector2(enemy_x, board_y), board_size)

	# The player's board: the one that is actually played.
	_tetris = PLAYER_BOARD_SCENE.instantiate() as Node2D
	_grid = _tetris.get_node("Grid") as Node2D
	# Fall speed comes from the party's Gravity stat, not from the enemies present.
	_grid.start_level = maxi(config.party.gravity, 1)
	_grid.junk_rows = config.junk_rows
	_grid.lines_cleared.connect(_on_lines_cleared)
	_grid.round_finished.connect(_on_round_finished)
	_grid.piece_rotated.connect(_on_piece_rotated)
	_grid.battle_finished.connect(_on_grid_battle_finished)
	_apply_board_theme(_grid)
	BoardSkin.apply(_grid)
	_tetris.scale = Vector2(scale_factor, scale_factor)
	_tetris.position = _player_board_rect.position
	add_child(_tetris)

	# The enemy's board: a picture of what the enemy team is doing.
	_enemy_board = EnemyBoard.new(
		config.junk_rows, config.party.has_power(PartyStats.THIRD_EYE)
	)
	_apply_board_theme(_enemy_board.grid)
	BoardSkin.apply(_enemy_board.grid)
	_enemy_board.root.scale = Vector2(scale_factor, scale_factor)
	_enemy_board.root.position = _enemy_board_rect.position
	add_child(_enemy_board.root)

	_add_playfield_frame(_player_board_rect)
	_add_playfield_frame(_enemy_board_rect)


# A thin rounded border around a playfield, standing in for the pixel frame the skin hides.
func _add_playfield_frame(board_rect: Rect2) -> void:
	var frame: = Panel.new()
	frame.add_theme_stylebox_override("panel", BoardSkin.make_frame_style())
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.position = board_rect.position + (PLAYFIELD_RECT.position - Vector2(4, 4))*_board_scale
	frame.size = (PLAYFIELD_RECT.size + Vector2(8, 8)) * _board_scale
	# Above the board (whose Grid sits at z_index 1) so the border is not covered by blocks.
	frame.z_index = 2
	add_child(frame)


func _apply_board_theme(grid: Node2D) -> void:
	var board_theme: = Theme.new()
	board_theme.default_font_size = TETRIS_FONT_SIZE
	board_theme.set_font_size("font_size", "Label", TETRIS_FONT_SIZE)
	var font: = load(BOARD_FONT) as Font
	if font != null:
		board_theme.default_font = font
		board_theme.set_font("font", "Label", font)
	(grid.get_node("UI") as Control).theme = board_theme


func _add_rosters() -> void:
	var roster_y: = BANNER_HEIGHT + MARGIN

	_ally_roster = UIUnitRoster.new()
	_ally_roster.position = Vector2(MARGIN, roster_y)
	_ally_roster.size = Vector2(ROSTER_WIDTH, _player_board_rect.size.y * 0.5)
	add_child(_ally_roster)
	# The player always sees their own team in full.
	_ally_roster.setup(config.allies, true, false, true)

	_enemy_roster = UIUnitRoster.new()
	_enemy_roster.position = Vector2(_enemy_board_rect.end.x + MARGIN, roster_y)
	_enemy_roster.size = Vector2(ROSTER_WIDTH, _player_board_rect.size.y * 0.5)
	add_child(_enemy_roster)
	# Enemy health needs HP Sight; their cast bars need Future Sight.
	_enemy_roster.setup(
		config.enemies,
		config.party.has_power(PartyStats.HP_SIGHT),
		config.party.has_power(PartyStats.FUTURE_SIGHT)
	)


# Blind hides a third of the board. Which third depends on the blinded unit's position in the
# team, so one panel is created per third and shown as needed.
func _add_fog() -> void:
	var playfield_origin: = _player_board_rect.position + PLAYFIELD_RECT.position*_board_scale
	var playfield_size: = PLAYFIELD_RECT.size * _board_scale

	for i in 3:
		var fog: = ColorRect.new()
		fog.color = Color(0.03, 0.03, 0.07, 0.94)
		fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fog.position = Vector2(
			playfield_origin.x + playfield_size.x * (i/3.0), playfield_origin.y
		)
		fog.size = Vector2(playfield_size.x / 3.0, playfield_size.y)
		fog.z_index = 5
		fog.visible = false
		add_child(fog)
		_fog_panels.append(fog)


func _add_union_meter() -> void:
	_union_ui = UIUnionMeter.new()
	_union_ui.position = Vector2(
		MARGIN, BANNER_HEIGHT + MARGIN + _player_board_rect.size.y*0.5 + 24.0
	)
	_union_ui.size = Vector2(ROSTER_WIDTH, 60.0)
	add_child(_union_ui)


func _add_clear_tally(viewport_size: Vector2) -> void:
	_clear_tally = UIClearTally.new()
	_clear_tally.position = Vector2(0.0, viewport_size.y - TALLY_HEIGHT)
	_clear_tally.size = Vector2(viewport_size.x, TALLY_HEIGHT)
	add_child(_clear_tally)
	_clear_tally.setup(config.allies)


# --- The player's turn -------------------------------------------------------------------------

func _on_lines_cleared(count: int, block_type: int) -> void:
	var target: = _get_front_unit(config.enemies)
	if target == null:
		return

	var results: Array[AttackResult] = []

	if count >= 4:
		# Four lines is only reachable with the Line block, and rallies the whole team.
		for ally in config.get_active_allies():
			results.append(AttackResolver.resolve(ally, target, AttackResolver.Kind.RALLY_STRIKE))
			# Stands in for an equipped Rally Strike. The only one the design spells out is
			# Doublestep ("all allies gain two stacks of Shield"), so that is what rallying does
			# until Rally Strikes are modelled per character.
			ally.apply_effect(StatusEffectDefs.SHIELD, StatusEffect.TIER_STRONG)
		_ally_roster.refresh()
	else:
		# Otherwise only the character holding this block attacks. A block assigned to nobody still
		# clears the line and fills the Union meter, it just deals no damage.
		var attacker: = config.find_ally_for_block(block_type)
		if attacker != null:
			results.append(
				AttackResolver.resolve(attacker, target, AttackResolver.kind_for_lines(count))
			)

	var union_bonus: = union_meter.add_lines(count)
	if union_bonus > 0.0:
		for ally in config.get_active_allies():
			results.append(AttackResolver.resolve(
				ally, target, AttackResolver.Kind.UNION_ASSAULT, union_bonus
			))

	_apply_results(results, config.enemies, _enemy_roster, _enemy_board_rect)

	if union_bonus > 0.0:
		_union_ui.play_assault()
	else:
		_union_ui.refresh(union_meter.lines)

	_clear_tally.record_clear(block_type, count)

	if _get_front_unit(config.enemies) == null:
		_end_battle(true)


# --- The enemy team's turn ---------------------------------------------------------------------

# One completed drop is one Round. Enemies charge on Rounds and strike when their cast completes.
func _on_round_finished(_round_number: int) -> void:
	if _is_over:
		return

	# Status effects tick once per Round, before anyone acts.
	for unit in config.allies + config.enemies:
		unit.tick_effects()

	# Haste guarantees the hasted ally's block comes next.
	for ally in config.get_active_allies():
		if ally.has_effect(StatusEffectDefs.HASTE) and not ally.block_types.is_empty():
			_grid.force_next_block(ally.block_types.pick_random())
			ally.consume_generation(StatusEffectDefs.HASTE)
			break

	_ally_roster.refresh()
	_enemy_roster.refresh()
	_refresh_board_effects()

	if _get_front_unit(config.allies) == null:
		_end_battle(false)
		return

	var attackers: Array[CombatUnit] = []
	for enemy in config.enemies:
		if enemy.advance_cast():
			attackers.append(enemy)

	_enemy_roster.refresh_casts()
	_refresh_enemy_board()

	if not attackers.is_empty():
		_resolve_enemy_attacks(attackers)


# Bleed costs health every time the team rotates a block.
func _on_piece_rotated() -> void:
	var bled: = false
	for ally in config.get_active_allies():
		if ally.apply_bleed_on_rotate() > 0:
			bled = true
	if bled:
		_ally_roster.refresh()
		if _get_front_unit(config.allies) == null:
			_end_battle(false)


# Blind, Shocked and Confusion are carried by units but act on the board. Any afflicted ally
# affects the whole team's board, which is the simplest reading of "some Unit Effects will affect
# the Board".
func _refresh_board_effects() -> void:
	var shocked: = false
	var confused: = false
	var blinded_positions: Array[int] = []

	for i in config.allies.size():
		var ally: = config.allies[i]
		if ally.is_downed():
			continue
		shocked = shocked or ally.has_effect(StatusEffectDefs.SHOCKED)
		confused = confused or ally.has_effect(StatusEffectDefs.CONFUSION)
		if ally.has_effect(StatusEffectDefs.BLIND):
			blinded_positions.append(i % _fog_panels.size())

	_grid.rotation_locked = shocked
	_grid.set_preview_visible(not confused)
	for i in _fog_panels.size():
		_fog_panels[i].visible = i in blinded_positions


# The enemy board shows how close the most advanced enemy is to striking, so it rises as they
# charge and drops back the Round they act.
func _refresh_enemy_board() -> void:
	var highest: = 0.0
	for enemy in config.enemies:
		if not enemy.is_downed():
			highest = maxf(highest, enemy.get_cast_ratio())
	_enemy_board.set_charge(highest)


func _resolve_enemy_attacks(attackers: Array[CombatUnit]) -> void:
	var target: = _get_front_unit(config.allies)
	if target == null:
		return

	var results: Array[AttackResult] = []
	for enemy in attackers:
		var result: = AttackResolver.resolve(enemy, target, AttackResolver.Kind.BASIC)
		results.append(result)
		if not result.was_dodged and randf() < ENEMY_STATUS_CHANCE:
			var inflicted: String = StatusEffectDefs.ENEMY_INFLICTABLE.pick_random()
			target.apply_effect(inflicted)

	_apply_results(results, config.allies, _ally_roster, _player_board_rect)
	_refresh_board_effects()

	if _get_front_unit(config.allies) == null:
		_end_battle(false)


# --- Shared ------------------------------------------------------------------------------------

# Applies every attack in order, letting damage spill onto the next unit so one blow can drop more
# than one. Each unit reached is animated.
func _apply_results(
	results: Array[AttackResult],
	units: Array[CombatUnit],
	roster: UIUnitRoster,
	popup_rect: Rect2
) -> void:
	var struck_indices: Array[int] = []
	var total_damage: = 0

	for result in results:
		var remaining: = result.damage
		total_damage += remaining
		while remaining > 0:
			var index: = roster.get_target_index()
			if index < 0:
				break
			var dealt: = units[index].take_damage(remaining)
			if dealt <= 0:
				break
			if index not in struck_indices:
				struck_indices.append(index)
			remaining -= dealt

	for index in struck_indices:
		roster.play_hit(index)

	if not results.is_empty():
		_show_attack_popup(results, total_damage, popup_rect)


static func _get_front_unit(units: Array[CombatUnit]) -> CombatUnit:
	for unit in units:
		if not unit.is_downed():
			return unit
	return null


func _end_battle(won: bool) -> void:
	if _is_over:
		return
	_is_over = true

	_grid.set_physics_process(false)
	await get_tree().create_timer(END_PAUSE).timeout
	if is_instance_valid(_grid):
		_grid.end_battle(won)


# --- Feedback ----------------------------------------------------------------------------------

func _show_attack_popup(
	results: Array[AttackResult], total_damage: int, rect: Rect2
) -> void:
	if is_instance_valid(_active_popup):
		_active_popup.queue_free()

	var popup: = UIAttackPopup.new()
	add_child(popup)
	popup.play(results, total_damage, rect)
	_active_popup = popup


func _on_grid_battle_finished(won: bool, final_score: int, final_lines: int) -> void:
	finished.emit(won, final_score, final_lines)
