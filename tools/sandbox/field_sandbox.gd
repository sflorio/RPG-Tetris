## Boots the real overworld (src/main.tscn) without the Opening, puts the player anywhere, and can
## walk them, set story flags and print a map as text. Development only: nothing in the game
## references this scene.
##
##     python tools/godot.py shot res://tools/sandbox/field_sandbox.tscn -- --spawn=MainHall
##     python tools/godot.py map MainHall          # wraps --map below, headless
##
## User arguments (after `--`):
##     --spawn=WHERE        an area (Town, StorageAttic, Kitchen, MainHall, House, Forest), a
##                          gamepiece by node name (lands on a free cell next to it, facing it), or
##                          a cell as x,y. Defaults to the attic cell the Opening wakes you on.
##     --walk=STEPS         comma-separated: u d l r (one cell), x (interact), w (wait a second).
##                          Doorways are taken like in play. Prints where each step ended.
##     --set=Var=Value      set a Dialogic variable first, e.g. --set=Chapter1Stage=2. Repeatable.
##     --map=AREA           print AREA as a character grid with a legend, then quit.
##     --quit               quit once spawning and walking are done.
##
## Placement and doorways go through the same calls the game uses (GamepieceRegistry.move_gamepiece,
## the AreaTransition triggers), so what this reports is what a player would get.
extends Node

const MAIN: = "res://src/main.tscn"
## Where the Opening puts the player (opening_cutscene.gd start_cell).
const DEFAULT_SPAWN: = Vector2i(64, 4)
const STEPS: = {"u": Vector2.UP, "d": Vector2.DOWN, "l": Vector2.LEFT, "r": Vector2.RIGHT}
## Longest a single step may take, including a doorway's blackout, before it is reported stuck.
const STEP_TIMEOUT: = 5.0

var _map: Node2D
var _areas: Dictionary = {}  # area name -> {node, cells}


func _ready() -> void:
	var args: = _parse_args()

	var main: = (load(MAIN) as PackedScene).instantiate()
	var field: = main.get_node("Field")
	# The Opening would take over the screen with the name prompt and a timeline.
	if field.opening_cutscene:
		field.opening_cutscene.queue_free()
		field.opening_cutscene = null
	add_child(main)
	_map = main.get_node("Field/Map")
	for path: NodePath in _map.exclusive_areas:
		var area: = _map.get_node(path) as Node2D
		_areas[area.name] = {"node": area, "cells": _cells_of(area)}

	# Gameboard layers and gamepieces register on entering the tree; give them a frame to settle.
	await get_tree().process_frame
	await get_tree().process_frame

	for pair: Array in args.set:
		if not Dialogic.VAR.set_variable(pair[0], _parse_value(pair[1])):
			push_error("field_sandbox: no Dialogic variable '%s'" % pair[0])

	if args.map != "":
		_print_map(args.map)
		get_tree().quit()
		return

	var spawn: = _resolve_spawn(args.spawn)
	if spawn == Gameboard.INVALID_CELL:
		get_tree().quit(1)
		return
	_place_player(spawn)
	# Interactions are found by Area2D overlap, which only updates on a physics step; an `x` on the
	# very next frame would press against where the player used to be.
	for i in 3:
		await get_tree().physics_frame
	_report("spawn")

	await _walk(args.walk)

	if args.quit:
		get_tree().quit()


func _parse_args() -> Dictionary:
	var args: = {"spawn": "", "walk": [], "set": [], "map": "", "quit": false}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--spawn="):
			args.spawn = arg.trim_prefix("--spawn=")
		elif arg.begins_with("--walk="):
			args.walk = Array(arg.trim_prefix("--walk=").to_lower().split(",", false))
		elif arg.begins_with("--set="):
			var pair: = arg.trim_prefix("--set=").split("=", true, 1)
			if pair.size() == 2:
				args.set.append([pair[0], pair[1]])
		elif arg.begins_with("--map="):
			args.map = arg.trim_prefix("--map=")
		elif arg == "--quit":
			args.quit = true
	return args


func _parse_value(text: String) -> Variant:
	if text.is_valid_int():
		return int(text)
	if text.is_valid_float():
		return float(text)
	return text


# --- Placing the player -------------------------------------------------------------------------

func _resolve_spawn(where: String) -> Vector2i:
	if where == "":
		return DEFAULT_SPAWN

	var parts: = where.split(",")
	if parts.size() == 2 and parts[0].strip_edges().is_valid_int():
		return Vector2i(int(parts[0]), int(parts[1]))

	if _areas.has(where):
		return _nearest_free_cell(_areas[where].cells)

	var gp: = GamepieceRegistry.get_gamepiece_by_name(where)
	if gp:
		var at: = GamepieceRegistry.get_cell(gp)
		for cell in Gameboard.get_adjacent_cells(at):
			if Gameboard.pathfinder.can_move_to(cell):
				return cell
		push_error("field_sandbox: every cell next to %s at %s is blocked" % [where, at])
		return Gameboard.INVALID_CELL

	var names: = PackedStringArray(_areas.keys())
	for piece in GamepieceRegistry.get_gamepieces():
		if piece != Player.gamepiece:
			names.append(piece.name)
	push_error("field_sandbox: unknown spawn '%s'. Use x,y or one of: %s"
		% [where, ", ".join(names)])
	return Gameboard.INVALID_CELL


# The walkable cell closest to the middle of an area, so a spawn by area name lands somewhere
# central rather than in a corner.
func _nearest_free_cell(cells: Dictionary) -> Vector2i:
	var centre: = Vector2.ZERO
	for cell: Vector2i in cells:
		centre += Vector2(cell)
	centre /= maxf(cells.size(), 1)

	var best: = Gameboard.INVALID_CELL
	var best_distance: = INF
	for cell: Vector2i in cells:
		var distance: = centre.distance_squared_to(Vector2(cell))
		if distance < best_distance and Gameboard.pathfinder.can_move_to(cell):
			best = cell
			best_distance = distance
	if best == Gameboard.INVALID_CELL:
		push_error("field_sandbox: the area has no free walkable cell")
	return best


func _place_player(cell: Vector2i) -> void:
	var gp: = Player.gamepiece
	gp.stop()
	gp.position = Gameboard.cell_to_pixel(cell)
	if GamepieceRegistry.get_cell(gp) != cell:
		GamepieceRegistry.move_gamepiece(gp, cell)
	Camera.reset_position()

	# Face whatever is next to us, so an immediate `x` talks to the gamepiece spawned beside.
	for neighbour in Gameboard.get_adjacent_cells(cell):
		var other: = GamepieceRegistry.get_gamepiece(neighbour)
		if other and other != gp:
			var facing: = Directions.vector_to_direction(other.position - gp.position)
			# The controller moves its interaction searcher on direction_changed, which only fires
			# on a change; turn away first so facing the way we already face still moves it.
			gp.direction = Directions.Points.NORTH if facing != Directions.Points.NORTH \
				else Directions.Points.SOUTH
			gp.direction = facing
			break


# --- Walking ------------------------------------------------------------------------------------

func _walk(steps: Array) -> void:
	for step: String in steps:
		await _wait_for_control()
		if STEPS.has(step):
			var controller: = _player_controller()
			var before: = GamepieceRegistry.get_cell(Player.gamepiece)
			controller.move_to_pressed_key(STEPS[step])
			if Player.gamepiece.is_moving():
				await _arrived_or_timeout()
			await _wait_for_control()
			if GamepieceRegistry.get_cell(Player.gamepiece) == before:
				_report("%s blocked" % step)
				continue
		elif step == "x":
			_press("interact")
			await get_tree().create_timer(0.5).timeout
		elif step == "w":
			await get_tree().create_timer(1.0).timeout
		else:
			push_error("field_sandbox: unknown step '%s' (use u d l r x w)" % step)
			continue
		_report(step)


# Doorways and conversations pause input while they run; the next step waits them out, the way a
# player would.
func _wait_for_control() -> void:
	var waited: = 0.0
	while Cutscene.is_cutscene_in_progress() or Player.gamepiece.is_moving():
		await get_tree().process_frame
		waited += get_process_delta_time()
		if waited > STEP_TIMEOUT:
			push_error("field_sandbox: still busy after %ss (dialogue open?)" % STEP_TIMEOUT)
			return


func _arrived_or_timeout() -> void:
	var timer: = get_tree().create_timer(STEP_TIMEOUT)
	while Player.gamepiece.is_moving() and timer.time_left > 0.0:
		await get_tree().process_frame


func _player_controller() -> PlayerController:
	for node in get_tree().get_nodes_in_group(PlayerController.GROUP):
		return node as PlayerController
	return null


func _press(action: String) -> void:
	for pressed in [true, false]:
		var event: = InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)


func _report(what: String) -> void:
	var cell: = GamepieceRegistry.get_cell(Player.gamepiece)
	print("field_sandbox: %s -> %s in %s" % [what, cell, _area_name_at(cell)])


func _area_name_at(cell: Vector2i) -> String:
	for area_name: String in _areas:
		if _areas[area_name].cells.has(cell):
			return area_name
	return "no area"


# --- Map as text --------------------------------------------------------------------------------

func _cells_of(area: Node2D) -> Dictionary:
	var cells: = {}
	for layer: TileMapLayer in area.find_children("*", "TileMapLayer"):
		for cell: Vector2i in layer.get_used_cells():
			cells[cell] = true
	return cells


func _print_map(area_name: String) -> void:
	if not _areas.has(area_name):
		push_error("field_sandbox: unknown area '%s'. Areas: %s"
			% [area_name, ", ".join(PackedStringArray(_areas.keys()))])
		return
	var cells: Dictionary = _areas[area_name].cells
	var area_node: Node2D = _areas[area_name].node

	var lo: = Vector2i(1 << 20, 1 << 20)
	var hi: = -lo
	for cell: Vector2i in cells:
		lo = Vector2i(mini(lo.x, cell.x), mini(lo.y, cell.y))
		hi = Vector2i(maxi(hi.x, cell.x), maxi(hi.y, cell.y))

	# Marks drawn over the terrain, keyed by cell, with the legend line for each.
	var marks: = {}
	var legend: PackedStringArray = []
	var letter: = "A".unicode_at(0)
	for gp in GamepieceRegistry.get_gamepieces():
		var at: = GamepieceRegistry.get_cell(gp)
		if not cells.has(at):
			continue
		if gp == Player.gamepiece:
			marks[at] = "@"
			continue
		var symbol: = String.chr(letter)
		letter += 1
		marks[at] = symbol
		legend.append("%s  %s %s" % [symbol, gp.name, at])

	var door: = 1
	for trigger: Trigger in _map.find_children("*", "Trigger", true, false):
		var at: = Gameboard.get_cell_under_node(trigger)
		if not cells.has(at):
			continue
		if trigger is AreaTransition:
			var symbol: = str(door % 10)
			door += 1
			var arrival: = Gameboard.pixel_to_cell(trigger.arrival_coordinates)
			marks[at] = symbol
			legend.append("%s  doorway %s %s -> %s in %s%s" % [symbol, trigger.name, at, arrival,
				_area_name_at(arrival), "" if trigger.is_active else " (inactive)"])
		else:
			marks[at] = "T"
			legend.append("T  trigger %s %s" % [trigger.name, at])

	for interaction: Interaction in _map.find_children("*", "Interaction", true, false):
		var at: = Gameboard.get_cell_under_node(interaction)
		if cells.has(at) and not marks.has(at):
			marks[at] = "?"
			legend.append("?  %s %s" % [interaction.get_parent().name + "/" + interaction.name, at])

	var lines: PackedStringArray = []
	lines.append("%s  x %d..%d  y %d..%d   (# blocked  . walkable  @ player)"
		% [area_name, lo.x, hi.x, lo.y, hi.y])
	var header: = "     "
	for x in range(lo.x, hi.x + 1):
		header += str(posmod(x, 10))
	lines.append(header)
	for y in range(lo.y, hi.y + 1):
		var row: = "%4d " % y
		for x in range(lo.x, hi.x + 1):
			var cell: = Vector2i(x, y)
			if marks.has(cell):
				row += marks[cell]
			elif not cells.has(cell):
				row += " "
			elif Gameboard.pathfinder.has_cell(cell):
				row += "."
			else:
				row += "#"
		lines.append(row)
	lines.append("")
	lines.append_array(legend)
	if area_node.find_children("*", "TileMapLayer").is_empty():
		lines.append("(area has no tile layers)")
	print("\n".join(lines))
