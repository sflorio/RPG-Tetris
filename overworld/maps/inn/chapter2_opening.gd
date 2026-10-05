extends Cutscene

## Chapter 2 opens on the line that cuts Quinn off: "A HUGE BOOM IS HEARD AND THE BUILDING SHAKES."
## It runs straight off the end of Chapter 1 rather than off anything the player does.

@export var timeline: DialogicTimeline

## How hard and how long the building shakes.
@export var shake_strength: = 8.0
@export var shake_duration: = 1.1


func _ready() -> void:
	# Cutscene has no _ready of its own; connect straight to the signal.
	FieldEvents.chapter1_finished.connect(run, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


func _execute() -> void:
	await _shake()

	if timeline:
		Dialogic.start_timeline(timeline)
		await Dialogic.timeline_ended


# The camera is an autoload rather than a child of the field, so the shake is applied to its offset
# and put back afterwards.
func _shake() -> void:
	var elapsed: = 0.0
	while elapsed < shake_duration:
		var falloff: = 1.0 - elapsed/shake_duration
		Camera.offset = Vector2(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * falloff
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	Camera.offset = Vector2.ZERO
