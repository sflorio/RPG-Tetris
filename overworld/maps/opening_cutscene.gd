extends Cutscene

## The design's Opening begins with the character creator -- name entry only, for the demo -- and
## then Chapter 1, which plays over a black screen until the player wakes up.
const CHARACTER_CREATOR: = preload(
	"res://src/field/ui/character_creator/character_creator.tscn")

## The signal the Chapter 1 timeline raises on the line the player wakes on.
const WAKE_SIGNAL: = "wake_up"

## How long the screen takes to fade in once they are awake.
const WAKE_FADE: = 1.2

@export var timeline: DialogicTimeline

## Where the player is standing when the screen comes up: the inn's storage attic.
@export var start_cell: = Vector2i(64, 4)


func _execute() -> void:
	$Background/ColorRect.show()

	await _name_the_player()
	_place_player()

	Dialogic.signal_event.connect(_on_dialogic_signal_event)
	Dialogic.start_timeline(timeline)
	await Dialogic.timeline_ended
	Dialogic.signal_event.disconnect(_on_dialogic_signal_event)

	Music.play(load("res://assets/music/Apple Cider.mp3"))
	queue_free.call_deferred()


# The one thing the character creator does for the demo is take a name, which every PLAYER in the
# Opening's script is then replaced with.
func _name_the_player() -> void:
	var creator: = CHARACTER_CREATOR.instantiate() as CharacterCreator
	add_child(creator)
	await creator.finished


func _place_player() -> void:
	if Player.gamepiece:
		Player.gamepiece.position = Gameboard.cell_to_pixel(start_cell)
		Camera.reset_position()


# The screen is black until the player is awake, so the fade is driven by the timeline rather than
# by a timer: it lands on the line it is written against.
func _on_dialogic_signal_event(argument: String) -> void:
	if argument == WAKE_SIGNAL:
		var fade: = create_tween()
		fade.tween_property($Background/ColorRect, "modulate:a", 0.0, WAKE_FADE)
		await fade.finished
		$Background/ColorRect.hide()
