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

func _track_player_area() -> void:
	if exclusive_areas.is_empty():
		return

	Player.gamepiece_changed.connect(_follow_player)
	_follow_player()


func _follow_player() -> void:
	if Player.gamepiece == null:
		return
	if not Player.gamepiece.arrived.is_connected(_update_visible_area):
		Player.gamepiece.arrived.connect(_update_visible_area)
	_update_visible_area()


func _update_visible_area() -> void:
	var cell: = Gameboard.pixel_to_cell(Player.gamepiece.position)

	var occupied: Node2D = null
	for path in exclusive_areas:
		var area: = get_node_or_null(path) as Node2D
		if area and _area_contains(area, cell):
			occupied = area
			break

	# Until the player is standing somewhere known, show everything rather than a blank screen.
	for path in exclusive_areas:
		var area: = get_node_or_null(path) as Node2D
		if area:
			area.visible = occupied == null or area == occupied


func _area_contains(area: Node2D, cell: Vector2i) -> bool:
	for layer: TileMapLayer in area.find_children("*", "TileMapLayer"):
		if cell in layer.get_used_cells():
			return true
	return false
