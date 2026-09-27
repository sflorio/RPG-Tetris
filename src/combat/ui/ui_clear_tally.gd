## The strip under the board showing how many lines have been cleared with each piece.
##
## This is combo information, not decoration: the same-piece streak rule in [TetrisDamageRules] pays
## out on three clears in a row with one piece, so the player needs to see which piece they have
## been clearing with and how far along the current streak is.
class_name UIClearTally extends HBoxContainer

## Colour indices in the order they are displayed, matching [Constants].
const PIECE_ORDER: Array[int] = [1, 2, 3, 4, 5, 6, 7]

const SWATCH_SIZE: = 30
const FONT_SIZE: = 24

const COLOR_IDLE: = Color(0.6, 0.6, 0.68)
const COLOR_ACTIVE: = Color(1.0, 0.95, 0.8)
const COLOR_STREAK_READY: = Color(0.55, 1.0, 0.65)

var _count_labels: Dictionary = {}     # colour index -> Label
var _swatches: Dictionary = {}         # colour index -> TextureRect
var _clears_by_piece: Dictionary = {}  # colour index -> how many clears
var _total_lines: = 0

var _lines_label: Label = null
var _streak_label: Label = null


func _ready() -> void:
	add_theme_constant_override("separation", 22)
	alignment = BoxContainer.ALIGNMENT_CENTER

	_lines_label = _make_label("LINES 0", COLOR_ACTIVE)
	add_child(_lines_label)

	for index in PIECE_ORDER:
		_clears_by_piece[index] = 0

		var entry: = HBoxContainer.new()
		entry.add_theme_constant_override("separation", 6)
		add_child(entry)

		var swatch: = TextureRect.new()
		swatch.custom_minimum_size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
		swatch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		swatch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		swatch.texture = BlockTextures.getTextureForColorIndex(index)
		swatch.modulate.a = 0.4
		entry.add_child(swatch)
		_swatches[index] = swatch

		var count_label: = _make_label("0", COLOR_IDLE)
		entry.add_child(count_label)
		_count_labels[index] = count_label

	_streak_label = _make_label("", COLOR_STREAK_READY)
	add_child(_streak_label)


## Records a clear and refreshes the strip. `streak_length` is how many clears in a row have now
## been made with `piece`, and `streak_target` how many are needed for the bonus.
func record_clear(piece: int, lines: int, streak_length: int, streak_target: int) -> void:
	_total_lines += lines
	if _clears_by_piece.has(piece):
		_clears_by_piece[piece] = _clears_by_piece[piece] + lines

	_lines_label.text = "LINES %d" % _total_lines

	for index in PIECE_ORDER:
		var is_active: int = _clears_by_piece[index] > 0
		_count_labels[index].text = str(_clears_by_piece[index])
		_count_labels[index].add_theme_color_override(
			"font_color", COLOR_ACTIVE if index == piece else COLOR_IDLE
		)
		_swatches[index].modulate.a = 1.0 if is_active else 0.4

	# A streak of 0 means the bonus just paid out and the count restarted.
	if streak_length >= 1 and streak_length < streak_target:
		_streak_label.text = "%s STREAK %d/%d" % [
			TetrisDamageRules.PIECE_NAMES.get(piece, "?"), streak_length, streak_target
		]
	else:
		_streak_label.text = ""

	_pop(_swatches.get(piece))


# A small scale pop so the piece that just scored draws the eye.
func _pop(node: Control) -> void:
	if node == null:
		return
	node.pivot_offset = node.size * 0.5
	var tween: = create_tween()
	tween.tween_property(node, "scale", Vector2(1.45, 1.45), 0.08)
	tween.tween_property(node, "scale", Vector2.ONE, 0.18)


static func _make_label(text: String, color: Color) -> Label:
	var label: = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
