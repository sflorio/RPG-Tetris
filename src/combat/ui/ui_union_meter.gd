## The team's Union meter, shown beside the board.
##
## Fills with every line cleared. At [constant UnionMeter.THRESHOLD] the Union Assault fires and the
## meter resets, which the bar shows with a flash.
class_name UIUnionMeter extends VBoxContainer

const BAR_HEIGHT: = 22

const COLOR_LABEL: = Color(0.85, 0.88, 1.0)
const COLOR_FILL: = Color(0.35, 0.65, 1.0)
const COLOR_READY: = Color(1.0, 0.95, 0.45)
const COLOR_BACKGROUND: = Color(0.16, 0.16, 0.22)

var _label: Label = null
var _bar: ProgressBar = null


func _ready() -> void:
	add_theme_constant_override("separation", 2)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", COLOR_LABEL)
	add_child(_label)

	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(0.0, BAR_HEIGHT)
	_bar.min_value = 0.0
	_bar.max_value = float(UnionMeter.THRESHOLD)
	_bar.show_percentage = false
	_bar.add_theme_stylebox_override("background", _make_style(COLOR_BACKGROUND))
	_bar.add_theme_stylebox_override("fill", _make_style(COLOR_FILL))
	add_child(_bar)

	refresh(0)


## Updates the meter to `lines` banked toward the Assault.
func refresh(lines: int) -> void:
	_label.text = "UNION  %d/%d" % [lines, UnionMeter.THRESHOLD]
	var tween: = create_tween()
	tween.tween_property(_bar, "value", float(lines), 0.25)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Flashes the bar as the Union Assault fires, then empties it.
func play_assault() -> void:
	_label.text = "UNION ASSAULT!"
	_bar.value = float(UnionMeter.THRESHOLD)
	_bar.add_theme_stylebox_override("fill", _make_style(COLOR_READY))

	var tween: = create_tween()
	tween.tween_property(_bar, "modulate:a", 0.25, 0.10)
	tween.tween_property(_bar, "modulate:a", 1.0, 0.10)
	tween.tween_property(_bar, "modulate:a", 0.25, 0.10)
	tween.tween_property(_bar, "modulate:a", 1.0, 0.10)
	await tween.finished

	_bar.add_theme_stylebox_override("fill", _make_style(COLOR_FILL))
	refresh(0)


static func _make_style(color: Color) -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style
