@tool
## Quinn, who owns the Emberlight Inn.
##
## Quinn has three things to say across Chapter 1 and which one depends on how far the player has
## got: send them to the patrons, wait while they work, and then the conversation the invasion
## interrupts. Dialogic's {Chapter1Stage} is the record of that, so a save resumes correctly.
extends InteractionTemplateConversation

## Stages of Chapter 1, as counted by the {Chapter1Stage} Dialogic variable.
const STAGE_WOKEN: = 1
const STAGE_SERVING: = 2
const STAGE_DONE: = 3

@export var intro_timeline: DialogicTimeline
@export var waiting_timeline: DialogicTimeline
@export var end_timeline: DialogicTimeline

## How many patrons must be served before Quinn has anything new to say.
@export var patrons_required: = 3


func _execute() -> void:
	timeline = _pick_timeline()
	await super()


func _pick_timeline() -> DialogicTimeline:
	var stage: int = Dialogic.VAR.get_variable("Chapter1Stage", 0)
	if stage >= STAGE_SERVING:
		var served: int = Dialogic.VAR.get_variable("PatronsTalked", 0)
		if served >= patrons_required:
			return end_timeline
		return waiting_timeline
	return intro_timeline


func _on_dialogic_signal_event(argument: String) -> void:
	if argument == "chapter1_end":
		# Chapter 2 opens on the explosion that cuts Quinn off mid-sentence.
		FieldEvents.chapter1_finished.emit()
