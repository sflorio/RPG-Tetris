@tool
extends Node2D

## The map defines the properties of the playable grid, which will be applied on _ready to the
## [Gameboard]. These properties usually correspond to one or multiple tilesets.
@export var gameboard_properties: GameboardProperties:
	set(value):
		gameboard_properties = value
		
		if not is_inside_tree():
			await ready
		
		_debug_boundaries.gameboard_properties = gameboard_properties 

## Areas that are only drawn when the player is standing in them. Every map lives in one scene at
## once, laid out side by side across the gameboard, so without this the player sees the inside of
## the inn next door to the inside of a house, and the forest through the town's back wall. Hiding
## does not touch the pathfinder: [GameboardLayer] registers its cells on entering the tree, not on
## becoming visible.
@export var exclusive_areas: Array[NodePath] = []

@onready var _debug_boundaries: DebugGameboardBoundaries = $Overlay/DebugBoundaries

func _ready() -> void:
	if not Engine.is_editor_hint():
		Camera.gameboard_properties = gameboard_properties
		Gameboard.properties = gameboard_properties
		_track_player_area()
		
		# Gamepieces need to be registered according to which cells they currently occupy.
		# Gamepieces may not overlap, and only the first gamepiece registered to a given cell will
		# be kept.
		#for gamepiece: Gamepiece in find_children("*", "Gamepiece"):
			#var cell: = Gameboard.get_cell_under_node(gamepiece)
			#gamepiece.position = Gameboard.cell_to_pixel(cell)
			#
			#if GamepieceRegistry.register(gamepiece, cell) == false:
				#gamepiece.queue_free()


# --- Showing one area at a time -----------------------------------------------------------------

# Which area was showing last, and the cell that chose it. Cached so the check only runs when the
# player actually moves between cells.
var _visible_area: Node2D = null
var _last_cell: = Vector2i(-9999, -9999)

# Which cells belong to which area, built once. The player crosses a cell every few frames and
# TileMapLayer.get_used_cells() allocates an array each call, so looking it up fresh every time is
# an allocation per layer per step.
var _area_cells: Dictionary = {}


func _track_player_area() -> void:
	if exclusive_areas.is_empty():
		set_process(false)
		return
	_update_visible_area()


# The player's cell is polled rather than taken from a signal. An [AreaTransition] sets the
# gamepiece's position directly and never emits `arrived`, so hooking that signal left the
# destination room hidden and the player standing in an empty grey field; and a cutscene can move
# them too. Polling catches every case for the cost of one cell comparison a frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or Player.gamepiece == null:
		return

	var cell: = Gameboard.pixel_to_cell(Player.gamepiece.position)
	if cell != _last_cell:
		_last_cell = cell
		_update_visible_area()


func _update_visible_area() -> void:
	if Player.gamepiece == null:
		return

	var cell: = Gameboard.pixel_to_cell(Player.gamepiece.position)
	var occupied: Node2D = null
	for path in exclusive_areas:
		var area: = get_node_or_null(path) as Node2D
		if area and _area_contains(area, cell):
			occupied = area
			break

	# A cell that belongs to no area is a gap between rooms, or a frame mid-transition. Keep showing
	# whatever was showing rather than blinking the whole map on.
	if occupied == null:
		occupied = _visible_area
	_visible_area = occupied

	for path in exclusive_areas:
		var area: = get_node_or_null(path) as Node2D
		if area:
			area.visible = occupied == null or area == occupied


func _area_contains(area: Node2D, cell: Vector2i) -> bool:
	if not _area_cells.has(area):
		var cells: = {}
		for layer: TileMapLayer in area.find_children("*", "TileMapLayer"):
			for used: Vector2i in layer.get_used_cells():
				cells[used] = true
		_area_cells[area] = cells
	return _area_cells[area].has(cell)
