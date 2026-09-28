## Xenoblock shapes — the malformed blocks from the design's Boards note.
##
## [b]Space and rotation follow SRS, unchanged.[/b] Under the Super Rotation System a piece is
## defined by a square bounding box, rotation is a 90° rotation of that box's contents, and the wall
## kicks are a property of [i]the box and its rotation centre[/i] — not of which cells are filled.
## The offset formulation makes that explicit: kick(A→B) = offset[A] − offset[B], and the cells never
## enter the calculation.
##
## The consequence is that Xenoblocks need no rotation code of their own:
## [br]1. A shape is a square matrix, column-major, exactly like [Constants].
## [br]2. [code]Grid.getPosibleRotation[/code] already picks the kick table by [code]shape.size()[/code],
##       so a 3x3 Xenoblock kicks like J/L/S/T/Z and a 4x4 one kicks like I.
## [br]3. So the only thing a Xenoblock has to declare is which cells of its box are filled.
##
## [b]Box size follows the shape's extent[/b]: 3x3 if it fits, otherwise 4x4. Odd boxes rotate about
## a cell centre and even boxes about a gridline intersection, which is the same distinction SRS
## draws between J/L/S/T/Z and I/O.
class_name XenoBlocks extends RefCounted

## The three corruption forms. The design gives every block a `+` and a `-`, and gives T/J/L/S/Z a
## `#` as well.
enum Form {PLUS, HASH, MINUS}

## Colour index for corrupted blocks, painted by [BlockTextures].
const XENO: = 8

# --- MINUS: the block with a cell taken away ---------------------------------------------------
#
# Confirmed against the design's shape table: every `-` form is a tromino, and the vault reuses the
# same artwork across them (O-=L-, T-=Z-, J-=S-). Only two trominoes exist, so all the bent ones are
# the same piece at a different spawn orientation.

## L-tromino. The `-` form of O, T, J, L, S and Z.
const TROMINO_CORNER: = [
	[XENO, XENO, 0],
	[XENO, 0, 0],
	[0, 0, 0],
]

## Straight tromino. The `-` form of I.
const TROMINO_LINE: = [
	[0, XENO, 0],
	[0, XENO, 0],
	[0, XENO, 0],
]

# --- PLUS: the block with an extra cell ---------------------------------------------------------

## I with a cell budding off its side. 4x4 box, so it keeps I-family kicks.
const I_PLUS: = [
	[XENO, XENO, XENO, XENO],
	[0, XENO, 0, 0],
	[0, 0, 0, 0],
	[0, 0, 0, 0],
]

## The square with a cell stacked on one corner. 4x4 box.
const O_PLUS: = [
	[0, 0, 0, 0],
	[XENO, XENO, XENO, 0],
	[0, XENO, XENO, 0],
	[0, 0, 0, 0],
]

## T with the fourth arm filled in: the plus-pentomino.
const T_PLUS: = [
	[0, XENO, 0],
	[XENO, XENO, XENO],
	[0, XENO, 0],
]

## U-pentomino.
const J_PLUS: = [
	[XENO, 0, XENO],
	[XENO, XENO, XENO],
	[0, 0, 0],
]

## P-pentomino.
const L_PLUS: = [
	[XENO, XENO, XENO],
	[0, XENO, XENO],
	[0, 0, 0],
]

## S stretched by one cell.
const S_PLUS: = [
	[0, XENO, XENO],
	[XENO, XENO, 0],
	[XENO, 0, 0],
]

## Z stretched by one cell.
const Z_PLUS: = [
	[XENO, 0, 0],
	[XENO, XENO, 0],
	[0, XENO, XENO],
]

# --- HASH: the block warped rather than grown or shrunk -----------------------------------------
#
# Only T, J, L, S and Z have a `#`; the design lists I# and O# as "None."

## T with a longer stem.
const T_HASH: = [
	[XENO, 0, 0],
	[XENO, XENO, XENO],
	[XENO, 0, 0],
]

## J bent the other way.
const J_HASH: = [
	[0, XENO, XENO],
	[XENO, XENO, 0],
	[XENO, 0, 0],
]

## L bent the other way.
const L_HASH: = [
	[XENO, 0, 0],
	[XENO, XENO, 0],
	[0, XENO, XENO],
]

## S with its step extended.
const S_HASH: = [
	[0, 0, XENO],
	[XENO, XENO, XENO],
	[XENO, 0, 0],
]

## Z with its step extended.
const Z_HASH: = [
	[XENO, 0, 0],
	[XENO, XENO, XENO],
	[0, 0, XENO],
]

## Shapes per block type and form. The design lists no `#` for I or O.
const SHAPES: = {
	BlockTypes.I: {Form.PLUS: I_PLUS, Form.MINUS: TROMINO_LINE},
	BlockTypes.O: {Form.PLUS: O_PLUS, Form.MINUS: TROMINO_CORNER},
	BlockTypes.T: {Form.PLUS: T_PLUS, Form.HASH: T_HASH, Form.MINUS: TROMINO_CORNER},
	BlockTypes.J: {Form.PLUS: J_PLUS, Form.HASH: J_HASH, Form.MINUS: TROMINO_CORNER},
	BlockTypes.L: {Form.PLUS: L_PLUS, Form.HASH: L_HASH, Form.MINUS: TROMINO_CORNER},
	BlockTypes.S: {Form.PLUS: S_PLUS, Form.HASH: S_HASH, Form.MINUS: TROMINO_CORNER},
	BlockTypes.Z: {Form.PLUS: Z_PLUS, Form.HASH: Z_HASH, Form.MINUS: TROMINO_CORNER},
}

## Suffix per form, matching how the design writes them.
const FORM_SUFFIX: = {Form.PLUS: "+", Form.HASH: "#", Form.MINUS: "-"}


## The shape for one corrupted block, or an empty array when that form does not exist — the design
## lists no `#` for I or O.
static func get_shape(block_type: int, form: Form) -> Array:
	return SHAPES.get(block_type, {}).get(form, [])


static func has_form(block_type: int, form: Form) -> bool:
	return not get_shape(block_type, form).is_empty()


## Every corrupted block that currently has a layout, as {block_type, form} pairs.
static func get_available() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for block_type: int in SHAPES:
		for form: Form in SHAPES[block_type]:
			available.append({"block_type": block_type, "form": form})
	return available


## "T+", "I-", and so on.
static func get_display_name(block_type: int, form: Form) -> String:
	var base: = BlockTypes.get_block_name(block_type)
	# The design writes these by letter, not by the board's full colour names.
	var letter: = base.substr(0, 1) if base != "SQUARE" else "O"
	if base == "LINE":
		letter = "I"
	return "%s%s" % [letter, FORM_SUFFIX.get(form, "")]


## The bounding box a shape occupies, which is what decides its kick table.
static func get_box_size(shape: Array) -> int:
	return shape.size()


## How many cells a shape fills, i.e. how corrupted it is.
static func get_cell_count(shape: Array) -> int:
	var count: = 0
	for column in shape:
		for cell in column:
			if cell != 0:
				count += 1
	return count
