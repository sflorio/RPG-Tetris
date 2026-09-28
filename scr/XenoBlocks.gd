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
# Removing one cell from a tetromino leaves a tromino, and there are only two of those. That is
# borne out by the vault, where the `-` artwork is reused across pieces: O- and L- share an image,
# T- and Z- share one, J- and S- share one. So every `-` form except I- is the same L-tromino,
# differing only in the orientation it spawns at — and orientation is not a distinct piece once it
# can rotate.

## L-tromino. The `-` form of O, T, J, L, S and Z.
const TROMINO_CORNER: = [
	[XENO, XENO, 0],
	[0, XENO, 0],
	[0, 0, 0],
]

## Straight tromino. The `-` form of I, which cannot lose a cell and stay bent.
const TROMINO_LINE: = [
	[0, XENO, 0],
	[0, XENO, 0],
	[0, XENO, 0],
]

# --- PLUS: the block with an extra cell ---------------------------------------------------------
#
# Adding a cell makes a pentomino. Each one is distinct in the vault, so each gets its own shape.
# These are placeholders until the cell layouts are read off the design's images.

const T_PLUS: = [
	[0, XENO, 0],
	[XENO, XENO, XENO],
	[0, XENO, 0],
]

const J_PLUS: = [
	[XENO, XENO, 0],
	[0, XENO, 0],
	[0, XENO, XENO],
]

const L_PLUS: = [
	[0, XENO, XENO],
	[0, XENO, 0],
	[XENO, XENO, 0],
]

const S_PLUS: = [
	[0, XENO, XENO],
	[XENO, XENO, 0],
	[XENO, 0, 0],
]

const Z_PLUS: = [
	[XENO, 0, 0],
	[XENO, XENO, 0],
	[0, XENO, XENO],
]

## O and I are 4x4 pieces, so their corrupted forms stay in a 4x4 box and keep I-family kicks.
const O_PLUS: = [
	[0, 0, 0, 0],
	[0, XENO, XENO, XENO],
	[0, XENO, XENO, 0],
	[0, 0, 0, 0],
]

const I_PLUS: = [
	[0, XENO, 0, 0],
	[0, XENO, XENO, 0],
	[0, XENO, 0, 0],
	[0, XENO, 0, 0],
]

## Shapes per block type and form. A missing entry means that form does not exist for that block —
## the design gives no `#` for I or O — or that its layout has not been specified yet.
const SHAPES: = {
	BlockTypes.I: {Form.PLUS: I_PLUS, Form.MINUS: TROMINO_LINE},
	BlockTypes.O: {Form.PLUS: O_PLUS, Form.MINUS: TROMINO_CORNER},
	BlockTypes.T: {Form.PLUS: T_PLUS, Form.MINUS: TROMINO_CORNER},
	BlockTypes.J: {Form.PLUS: J_PLUS, Form.MINUS: TROMINO_CORNER},
	BlockTypes.L: {Form.PLUS: L_PLUS, Form.MINUS: TROMINO_CORNER},
	BlockTypes.S: {Form.PLUS: S_PLUS, Form.MINUS: TROMINO_CORNER},
	BlockTypes.Z: {Form.PLUS: Z_PLUS, Form.MINUS: TROMINO_CORNER},
}

## Suffix per form, matching how the design writes them.
const FORM_SUFFIX: = {Form.PLUS: "+", Form.HASH: "#", Form.MINUS: "-"}


## The shape for one corrupted block, or an empty array when that form has no layout yet.
## [b]The `#` forms are deliberately absent[/b]: the design shows them only as images, and their
## cell layouts have to be written down before they can be built.
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
