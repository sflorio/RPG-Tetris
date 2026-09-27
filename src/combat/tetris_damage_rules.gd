## Turns a line clear into damage dealt to the enemy.
##
## The base rule is [b]one damage per line cleared[/b]. Everything else is a bonus that either adds
## flat damage or multiplies the total:
## [codeblock]
## damage = ceil((lines + sum_of_flat_bonuses) * product_of_multipliers)
## [/codeblock]
##
## [b]How to add a rule[/b]:
## [br]1. Write a method that returns a [Contribution] (set [code]flat[/code], [code]multiplier[/code]
##      and a [code]label[/code] the player will see).
## [br]2. Add a call to it in the list inside [method resolve_clear].
## [br][br]Streak state (combos, repeated pieces) lives on this object and persists for the whole
## battle, so a rule can react to what happened on earlier clears.
class_name TetrisDamageRules extends RefCounted

## Piece identity. These values are the colour indices used by the board in [Constants], so
## [code]O[/code] really is the square piece.
enum Piece {NONE = 0, I = 1, J = 2, L = 3, O = 4, T = 5, Z = 6, S = 7}

## Player-facing names for each piece.
const PIECE_NAMES: = {
	Piece.I: "LINE", Piece.J: "J", Piece.L: "L", Piece.O: "SQUARE",
	Piece.T: "T", Piece.Z: "Z", Piece.S: "S",
}

## Damage multiplier for clearing 1, 2, 3 or 4 lines with a single piece.
const LINE_COUNT_MULTIPLIERS: = {1: 1.0, 2: 1.5, 3: 2.0, 4: 3.0}

## Label shown for each line count. Empty means "no bonus worth announcing".
const LINE_COUNT_LABELS: = {1: "", 2: "DOUBLE", 3: "TRIPLE", 4: "TETRIS"}

## How many clears in a row with the same piece trigger the streak bonus.
const SAME_PIECE_STREAK_LENGTH: = 3

## Damage multiplier for clearing [constant SAME_PIECE_STREAK_LENGTH] times in a row with the same
## piece. Applies to every piece, so three square clears in a row triple the damage, and so do
## three line-piece clears.
const SAME_PIECE_STREAK_MULTIPLIER: = 3.0

## Multiplier for clearing every block off the board.
const PERFECT_CLEAR_MULTIPLIER: = 5.0

## Multiplier for two Tetrises (4-line clears) in a row.
const BACK_TO_BACK_MULTIPLIER: = 1.5

## Clears made back-to-back without a wasted piece. 1 on the first clear of a chain.
var combo_count: int = 0

## How many clears in a row have been made with the same piece.
var same_piece_streak: int = 0

# The piece used for the previous clear, and whether that clear was a Tetris.
var _last_clear_piece: int = Piece.NONE
var _last_clear_was_tetris: bool = false


## One rule's contribution to the damage total.
class Contribution extends RefCounted:
	## Damage added before multipliers are applied.
	var flat: int = 0
	## Damage multiplier. 1.0 means "this rule did nothing".
	var multiplier: float = 1.0
	## Shown to the player when this rule fires. Leave empty for a silent rule.
	var label: String = ""


## Resolves a single line clear into damage. `piece` is the colour index of the piece that was
## locked to cause the clear (see [enum Piece]).
func resolve_clear(lines_cleared: int, piece: int, is_perfect_clear: bool) -> TetrisDamageBreakdown:
	var result: = TetrisDamageBreakdown.new()
	if lines_cleared <= 0:
		return result

	_advance_streaks(piece)
	result.base_damage = lines_cleared

	# --- The rule list. Add new rules here. ---
	var contributions: Array[Contribution] = [
		_rule_line_count(lines_cleared),
		_rule_combo(),
		_rule_same_piece_streak(piece),
		_rule_back_to_back(lines_cleared),
		_rule_perfect_clear(is_perfect_clear),
	]

	var flat_bonus: = 0
	var multiplier: = 1.0
	for contribution in contributions:
		flat_bonus += contribution.flat
		multiplier *= contribution.multiplier
		if not contribution.label.is_empty():
			result.bonus_labels.append(contribution.label)

	result.total_damage = maxi(1, ceili((result.base_damage + flat_bonus) * multiplier))

	_last_clear_was_tetris = lines_cleared >= 4
	return result


## Must be called whenever a piece locks without clearing a line. This breaks the combo chain.
## The same-piece streak deliberately survives, so "three clears with the square" does not require
## three clears on three consecutive pieces.
func on_clearless_lock() -> void:
	combo_count = 0


# --- Rules -----------------------------------------------------------------------------------

# Clearing several lines with one piece is worth more than clearing them one at a time.
func _rule_line_count(lines_cleared: int) -> Contribution:
	var contribution: = Contribution.new()
	var line_key: = clampi(lines_cleared, 1, 4)
	contribution.multiplier = LINE_COUNT_MULTIPLIERS[line_key]

	var name: String = LINE_COUNT_LABELS[line_key]
	if not name.is_empty():
		contribution.label = "%s x%s" % [name, _format_multiplier(contribution.multiplier)]
	return contribution


# Clearing on consecutive pieces adds one flat damage per extra link in the chain.
func _rule_combo() -> Contribution:
	var contribution: = Contribution.new()
	if combo_count < 2:
		return contribution

	contribution.flat = combo_count - 1
	contribution.label = "COMBO x%d" % combo_count
	return contribution


# Three clears in a row with the same piece triple the damage. The streak then restarts, so it pays
# out again on the sixth, ninth, and so on.
func _rule_same_piece_streak(piece: int) -> Contribution:
	var contribution: = Contribution.new()
	if piece == Piece.NONE or same_piece_streak < SAME_PIECE_STREAK_LENGTH:
		return contribution

	contribution.multiplier = SAME_PIECE_STREAK_MULTIPLIER
	contribution.label = "%s STREAK x%s" % [
		PIECE_NAMES.get(piece, "?"), _format_multiplier(contribution.multiplier)
	]
	same_piece_streak = 0
	return contribution


# Two Tetrises in a row.
func _rule_back_to_back(lines_cleared: int) -> Contribution:
	var contribution: = Contribution.new()
	if lines_cleared < 4 or not _last_clear_was_tetris:
		return contribution

	contribution.multiplier = BACK_TO_BACK_MULTIPLIER
	contribution.label = "BACK-TO-BACK x%s" % _format_multiplier(contribution.multiplier)
	return contribution


# Wiping every block off the board.
func _rule_perfect_clear(is_perfect_clear: bool) -> Contribution:
	var contribution: = Contribution.new()
	if not is_perfect_clear:
		return contribution

	contribution.multiplier = PERFECT_CLEAR_MULTIPLIER
	contribution.label = "PERFECT CLEAR x%s" % _format_multiplier(contribution.multiplier)
	return contribution


# --- Internals -------------------------------------------------------------------------------

func _advance_streaks(piece: int) -> void:
	combo_count += 1
	same_piece_streak = same_piece_streak + 1 if piece == _last_clear_piece else 1
	_last_clear_piece = piece


# 2.0 -> "2", 1.5 -> "1.5".
static func _format_multiplier(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return str(snappedf(value, 0.1))
