## The seven block shapes, and which of them can be assigned to a character.
##
## Values match the colour indices the board stores in its grid and that [BlockTextures] paints, so
## a cell value is directly a block type.
class_name BlockTypes extends RefCounted

const NONE: = 0
const I: = 1
const J: = 2
const L: = 3
const O: = 4
const T: = 5
const Z: = 6
const S: = 7

const NAMES: = {
	I: "LINE", J: "J", L: "L", O: "SQUARE", T: "T", Z: "Z", S: "S",
}

## The blocks that can be assigned to a character. The Line block is deliberately absent: the design
## reserves it for triggering Rally Strikes, and Anima are not assigned to it.
const ASSIGNABLE: Array[int] = [O, T, J, L, S, Z]

## Every block, in display order.
const ALL: Array[int] = [I, J, L, O, T, Z, S]


static func get_block_name(block_type: int) -> String:
	return NAMES.get(block_type, "?")
