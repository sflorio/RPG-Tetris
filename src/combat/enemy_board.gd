## The enemy team's board, on the right of the screen.
##
## Unlike the player's board this one is not simulated: nobody is placing pieces on it. It is a
## readable picture of enemy pressure — the stack rises as the enemy team charges and drops back
## when they strike, so how full their board looks tells you how close the next attack is.
##
## That is a deliberate scope choice. A genuine Tetris AI stacking pieces is a far larger job than
## the fight needs, and the player never sees the difference. The seam is narrow — [method
## set_charge] is the only way the board changes — so a real AI could drive the same board later
## without touching anything else.
class_name EnemyBoard extends RefCounted

## The board scene, shared with the player's side.
const BOARD_SCENE: PackedScene = preload("res://scn/Main.tscn")

## Panels that only make sense on the board you actually play.
const HIDDEN_PANELS: Array[String] = ["Hold", "Score", "Level", "Lines"]

## Rows the charge stack reaches at a full cast.
const MAX_CHARGE_ROWS: = 12

## The instanced board scene root, to be added to the tree by the caller.
var root: Node2D = null

## The board's Grid node.
var grid: Node2D = null

# The board as it looked once the opening junk was placed, restored before each redraw so the
# charge stack never permanently alters it.
var _base_grid: Array = []

# Pre-rolled colours for the charge rows, so the stack does not flicker between redraws.
var _charge_pattern: Array = []


func _init(junk_rows: int, show_next_blocks: bool) -> void:
	root = BOARD_SCENE.instantiate() as Node2D
	grid = root.get_node("Grid") as Node2D
	grid.junk_rows = junk_rows
	# Gravity is irrelevant here; nothing falls on this board.
	grid.start_level = 1

	var board_ui: = grid.get_node("UI") as Control
	for panel_name in HIDDEN_PANELS:
		var panel: = board_ui.get_node_or_null(panel_name) as Control
		if panel != null:
			panel.visible = false

	# The enemy's upcoming blocks are only legible with the Third Eye psionic power.
	var next_panel: = board_ui.get_node_or_null("NextPieces") as Control
	if next_panel != null:
		next_panel.visible = show_next_blocks


## Must be called once the board is inside the tree, after its own _ready has run. Stops the board
## simulating itself, removes the piece it spawned, and snapshots the starting layout.
func take_control() -> void:
	grid.set_physics_process(false)
	var lock_timer: = grid.get_node_or_null("LockTimer") as Timer
	if lock_timer != null:
		lock_timer.stop()

	# Grid._ready spawns a falling piece. Nothing drives it here, so take it off the board.
	grid.deletePieceFromGrid()

	var width: int = grid.gridWidth
	var height: int = grid.gridHeight

	_base_grid = []
	for x in width:
		var column: Array = []
		for y in height:
			column.append(grid.grid[x][y])
		_base_grid.append(column)

	_charge_pattern = []
	for i in MAX_CHARGE_ROWS:
		var row: Array = []
		var gaps: = [randi() % width, randi() % width]
		for x in width:
			row.append(0 if x in gaps else randi_range(1, 7))
		_charge_pattern.append(row)

	grid.drawGrid()


## Sets how charged the enemy team looks, 0..1. Called once per Round with the most advanced
## enemy's cast progress, so the stack rises toward their strike and falls back after it.
func set_charge(ratio: float) -> void:
	if _base_grid.is_empty():
		return

	var width: int = grid.gridWidth
	var height: int = grid.gridHeight

	# Start from the opening layout so charge rows never accumulate.
	for x in width:
		for y in height:
			grid.grid[x][y] = _base_grid[x][y]

	var rows: = roundi(clampf(ratio, 0.0, 1.0) * MAX_CHARGE_ROWS)
	var top_of_base: = _find_top_filled_row()
	for i in rows:
		var y: = top_of_base - 1 - i
		if y <= grid.vanishZone:
			break
		for x in width:
			grid.grid[x][y] = _charge_pattern[i][x]

	grid.drawGrid()


## How full the board is, 0..1.
func get_fill_ratio() -> float:
	var visible_rows: int = grid.gridHeight - grid.vanishZone
	var filled: int = grid.gridHeight - _find_top_filled_row()
	return clampf(float(filled) / float(visible_rows), 0.0, 1.0)


# The highest row containing any block, or gridHeight when the board is empty.
func _find_top_filled_row() -> int:
	for y in range(grid.gridHeight):
		for x in grid.gridWidth:
			if grid.grid[x][y] != 0:
				return y
	return int(grid.gridHeight)
