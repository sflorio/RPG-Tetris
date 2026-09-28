## Supplies the block sprite for each cell on a board.
##
## Draws flat, rounded, slightly glossy blocks — the modern puzzle-game look — generated in code at
## startup, so there are no image files to maintain: change [constant PIECE_COLORS] and every block,
## preview and ghost piece updates.
##
## Colour indices match [Constants]: 1 = I, 2 = J, 3 = L, 4 = O, 5 = T, 6 = Z, 7 = S. Index 0 is an
## empty cell, and 8 is a Xenoblock (see [XenoBlocks]).
extends Node

## Pixel size of one block texture. The board draws these at 2x, filling its 32px cells.
const BLOCK_SIZE: = 16

## Corner rounding, in pixels.
const CORNER_RADIUS: = 3

## Thickness of the darker edge around each block.
const BORDER_WIDTH: = 2

## How far down the block the gloss highlight reaches, as a fraction of its height.
const GLOSS_HEIGHT: = 0.4

## Strength of the gloss highlight.
const GLOSS_STRENGTH: = 0.22

## The standard Tetris colour per piece, keyed by colour index.
const PIECE_COLORS: = {
	1: Color("22d3ee"),  # I - cyan
	2: Color("3b6ef6"),  # J - blue
	3: Color("f59f0b"),  # L - orange
	4: Color("facc15"),  # O - yellow
	5: Color("a855f7"),  # T - purple
	6: Color("ef4444"),  # Z - red
	7: Color("22c55e"),  # S - green
	8: Color("8b1f6b"),  # Xenoblock - corrupted magenta, deliberately unlike any normal block
}

## Colour of the faint grid square drawn in empty cells.
const EMPTY_CELL_COLOR: = Color(1.0, 1.0, 1.0, 0.055)

var _textures: Dictionary = {}


func _ready() -> void:
	_textures[0] = _build_empty_texture()
	for index: int in PIECE_COLORS:
		_textures[index] = _build_block_texture(PIECE_COLORS[index])


## Returns the texture for a cell's colour index. Unknown indices fall back to the empty cell, so a
## stray value can never crash the board.
func getTextureForColorIndex(index) -> Texture2D:
	return _textures.get(int(index), _textures[0])


## The colour used for a piece, for UI that wants to match the board (tallies, effects).
func get_color_for_index(index: int) -> Color:
	return PIECE_COLORS.get(index, Color.WHITE)


# A flat rounded block: solid fill, a darker edge to separate it from its neighbours, and a soft
# highlight across the top so a dense stack still reads as individual cells.
func _build_block_texture(color: Color) -> Texture2D:
	var image: = Image.create(BLOCK_SIZE, BLOCK_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var border_color: = color.darkened(0.45)
	var gloss_color: = color.lerp(Color.WHITE, GLOSS_STRENGTH)
	var gloss_limit: = int(BLOCK_SIZE * GLOSS_HEIGHT)

	for y in BLOCK_SIZE:
		for x in BLOCK_SIZE:
			if not _is_inside_rounded(x, y, BLOCK_SIZE, CORNER_RADIUS):
				continue

			var inner: = _is_inside_rounded_inset(x, y, BLOCK_SIZE, CORNER_RADIUS, BORDER_WIDTH)
			if not inner:
				image.set_pixel(x, y, border_color)
			elif y < gloss_limit:
				image.set_pixel(x, y, gloss_color)
			else:
				image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)


# Empty cells get a faint outline so the playfield still reads as a grid.
func _build_empty_texture() -> Texture2D:
	var image: = Image.create(BLOCK_SIZE, BLOCK_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var last: = BLOCK_SIZE - 1
	for i in range(1, last):
		image.set_pixel(i, 0, EMPTY_CELL_COLOR)
		image.set_pixel(i, last, EMPTY_CELL_COLOR)
		image.set_pixel(0, i, EMPTY_CELL_COLOR)
		image.set_pixel(last, i, EMPTY_CELL_COLOR)

	return ImageTexture.create_from_image(image)


# Whether a pixel falls inside a rounded square, so the corners can be left transparent.
static func _is_inside_rounded(x: int, y: int, size: int, radius: int) -> bool:
	var last: = size - 1
	var corner_x: = -1
	var corner_y: = -1

	if x < radius:
		corner_x = radius
	elif x > last - radius:
		corner_x = last - radius
	if y < radius:
		corner_y = radius
	elif y > last - radius:
		corner_y = last - radius

	# Not in a corner region, so it is inside by definition.
	if corner_x < 0 or corner_y < 0:
		return true

	var dx: = float(x - corner_x)
	var dy: = float(y - corner_y)
	return dx*dx + dy*dy <= float(radius*radius) + 0.5


# The same test against a shape shrunk by `inset`, used to carve the border ring.
static func _is_inside_rounded_inset(x: int, y: int, size: int, radius: int, inset: int) -> bool:
	if x < inset or y < inset or x >= size - inset or y >= size - inset:
		return false
	return _is_inside_rounded(x - inset, y - inset, size - inset*2, maxi(radius - inset, 1))
