## The strip under the board showing which character each block type attacks for.
##
## This is combat information, not decoration: clearing with a block assigned to a character makes
## that character attack, so the player needs to see the mapping at a glance. The Line block is
## shown apart because it belongs to no one — it is the Rally Strike trigger.
class_name UIClearTally extends HBoxContainer

const SWATCH_SIZE: = 28
const NAME_FONT_SIZE: = 17
const COUNT_FONT_SIZE: = 20

const COLOR_OWNER: = Color(0.78, 0.82, 0.95)
const COLOR_RALLY: = Color(0.55, 1.0, 0.75)
const COLOR_IDLE: = Color(0.55, 0.55, 0.62)
const COLOR_ACTIVE: = Color(1.0, 0.95, 0.8)

var _count_labels: Dictionary = {}   # block type -> Label
var _swatches: Dictionary = {}       # block type -> TextureRect
var _clears: Dictionary = {}         # block type -> lines cleared with it

var _lines_label: Label = null


## Draws one entry per block type, labelled with the ally it attacks for.
func setup(allies: Array[CombatUnit]) -> void:
	for child in get_children():
		child.queue_free()
	_count_labels.clear()
	_swatches.clear()
	_clears.clear()

	add_theme_constant_override("separation", 18)
	alignment = BoxContainer.ALIGNMENT_CENTER

	_lines_label = _make_label("LINES 0", COUNT_FONT_SIZE, COLOR_ACTIVE)
	add_child(_lines_label)

	for block_type in BlockTypes.ALL:
		_clears[block_type] = 0
		add_child(_make_entry(block_type, _find_owner_name(allies, block_type)))

	refresh()


## Records a clear made with `block_type`.
func record_clear(block_type: int, lines: int) -> void:
	if _clears.has(block_type):
		_clears[block_type] = _clears[block_type] + lines
	refresh()
	_pop(_swatches.get(block_type))


func refresh() -> void:
	var total: = 0
	for block_type in _clears:
		total += _clears[block_type]
	_lines_label.text = "LINES %d" % total

	for block_type in _clears:
		var cleared: int = _clears[block_type]
		_count_labels[block_type].text = str(cleared)
		_count_labels[block_type].add_theme_color_override(
			"font_color", COLOR_ACTIVE if cleared > 0 else COLOR_IDLE
		)
		_swatches[block_type].modulate.a = 1.0 if cleared > 0 else 0.45


# A swatch with the owning character's name beneath it.
func _make_entry(block_type: int, owner_name: String) -> Control:
	var entry: = VBoxContainer.new()
	entry.add_theme_constant_override("separation", 1)
	entry.alignment = BoxContainer.ALIGNMENT_CENTER

	var top: = HBoxContainer.new()
	top.add_theme_constant_override("separation", 5)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	entry.add_child(top)

	var swatch: = TextureRect.new()
	swatch.custom_minimum_size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
	swatch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	swatch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	swatch.texture = BlockTextures.getTextureForColorIndex(block_type)
	top.add_child(swatch)
	_swatches[block_type] = swatch

	var count_label: = _make_label("0", COUNT_FONT_SIZE, COLOR_IDLE)
	top.add_child(count_label)
	_count_labels[block_type] = count_label

	var is_rally: = block_type == BlockTypes.I
	var owner_label: = _make_label(
		owner_name, NAME_FONT_SIZE, COLOR_RALLY if is_rally else COLOR_OWNER
	)
	owner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entry.add_child(owner_label)

	return entry


# The Line block triggers everyone's Rally Strike rather than belonging to one character.
static func _find_owner_name(allies: Array[CombatUnit], block_type: int) -> String:
	if block_type == BlockTypes.I:
		return "RALLY"
	for ally in allies:
		if ally.handles_block(block_type):
			return ally.display_name
	return "-"


func _pop(node: Control) -> void:
	if node == null:
		return
	node.pivot_offset = node.size * 0.5
	var tween: = create_tween()
	tween.tween_property(node, "scale", Vector2(1.4, 1.4), 0.08)
	tween.tween_property(node, "scale", Vector2.ONE, 0.18)


static func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
