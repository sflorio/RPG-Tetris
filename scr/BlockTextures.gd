## Supplies the block sprite for each cell on the Tetris board.
##
## Replaces the original PokeTetris pokeballs with classic bevelled Tetris blocks. The textures are
## drawn in code at startup, so there are no image files to maintain: change [constant PIECE_COLORS]
## and every block, preview and ghost piece updates.
##
## Colour indices match [Constants]: 1 = I, 2 = J, 3 = L, 4 = O, 5 = T, 6 = Z, 7 = S. Index 0 is an
## empty cell.
extends Node

## Pixel size of one block texture. The board draws these at 2x, filling its 32px cells.
const BLOCK_SIZE: = 16

## The standard Tetris colour per piece, keyed by colour index.
const PIECE_COLORS: = {
	1: Color("00f0f0"),  # I - cyan
	2: Color("2040f0"),  # J - blue
	3: Color("f0a000"),  # L - orange
	4: Color("f0f000"),  # O - yellow
	5: Color("a000f0"),  # T - purple
	6: Color("f02020"),  # Z - red
	7: Color("00d020"),  # S - green
}

## Colour of the faint grid square drawn in empty cells.
const EMPTY_CELL_COLOR: = Color(1.0, 1.0, 1.0, 0.05)

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


# A solid block with a dark outline, a lit top-left edge and a shaded bottom-right edge. That bevel
# is what makes a stack of blocks readable as individual cells.
func _build_block_texture(color: Color) -> Texture2D:
	var image: = Image.create(BLOCK_SIZE, BLOCK_SIZE, false, Image.FORMAT_RGBA8)

	var outline: = color.darkened(0.65)
	var highlight: = color.lightened(0.45)
	var shadow: = color.darkened(0.35)
	var last: = BLOCK_SIZE - 1

	for y in BLOCK_SIZE:
		for x in BLOCK_SIZE:
			if x == 0 or y == 0 or x == last or y == last:
				image.set_pixel(x, y, outline)
			elif x == 1 or y == 1:
				image.set_pixel(x, y, highlight)
			elif x == last - 1 or y == last - 1:
				image.set_pixel(x, y, shadow)
			else:
				image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)


# Empty cells get a faint outline so the playfield still reads as a grid.
func _build_empty_texture() -> Texture2D:
	var image: = Image.create(BLOCK_SIZE, BLOCK_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var last: = BLOCK_SIZE - 1
	for i in BLOCK_SIZE:
		image.set_pixel(i, 0, EMPTY_CELL_COLOR)
		image.set_pixel(i, last, EMPTY_CELL_COLOR)
		image.set_pixel(0, i, EMPTY_CELL_COLOR)
		image.set_pixel(last, i, EMPTY_CELL_COLOR)

	return ImageTexture.create_from_image(image)
