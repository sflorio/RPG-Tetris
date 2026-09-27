## Restyles an instanced board scene to match the rest of the combat UI.
##
## The original PokeTetris art is a red pixel frame with a Kremlin tucked under the line counter.
## Rather than editing that scene, the skin is applied to each instance at runtime: the heavy frame
## is hidden, the backgrounds go dark slate, and the remaining panel art is tinted to a neutral
## colour. That keeps the change in one place and reversible.
class_name BoardSkin extends RefCounted

## The board scene's own background rect.
const BACKGROUND_COLOR: = Color("0a0e17")

## The playfield behind the blocks.
const PLAYFIELD_COLOR: = Color("111726")

## Tint applied to the remaining frame art, replacing its red.
const PANEL_TINT: = Color("6b7694")


static func apply(grid: Node2D) -> void:
	var board_ui: = grid.get_node_or_null("UI") as Control
	if board_ui == null:
		return

	var background: = board_ui.get_node_or_null("Background") as ColorRect
	if background != null:
		background.color = BACKGROUND_COLOR

	var playfield: = board_ui.get_node_or_null("GridBackground") as ColorRect
	if playfield != null:
		playfield.color = PLAYFIELD_COLOR

	# The heavy red frame is replaced by a thin rounded border drawn by the battle.
	var border: = board_ui.get_node_or_null("Border") as Node2D
	if border != null:
		border.visible = false

	# The Kremlin under the line counter is unrelated to anything in the design.
	var kremlin: = board_ui.get_node_or_null("Lines/Sprite2D") as Control
	if kremlin != null:
		kremlin.visible = false

	# Each label sets the DOS pixel font directly on the node, which a theme cannot override.
	# Clearing the override lets the battle's theme font apply instead.
	for node in board_ui.find_children("*", "Label", true, false):
		(node as Label).remove_theme_font_override("font")

	# The remaining frame art is all red pixel boxes around Hold, Next, Score and Level. Tinting
	# cannot desaturate a red texture — modulate only multiplies — so they are hidden outright and
	# the pieces sit on the dark background with their labels, which is the modern look anyway.
	for node in board_ui.find_children("*", "TextureRect", true, false):
		(node as TextureRect).visible = false


## A thin rounded border to draw around a board's playfield, replacing the pixel frame.
static func make_frame_style() -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color("2b3550")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style
