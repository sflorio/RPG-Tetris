## The character creator the design opens the game with.
##
## "GAME BEGINS WITH CHARACTER CREATOR. For demo, this is only name entry. All instances of PLAYER
## to be replaced with entered name." So that is all this is: a name, handed to [Party], which
## mirrors it into the Dialogic variable the Opening's timelines read as {PlayerName}.
class_name CharacterCreator extends CanvasLayer

## Emitted once the player has confirmed a name, after this has faded itself out.
signal finished(player_name: String)

const MAX_NAME_LENGTH: = 16

@onready var _field: = %NameField as LineEdit
@onready var _confirm: = %Confirm as Button
@onready var _fade: = %Fade as ColorRect


func _ready() -> void:
	_field.max_length = MAX_NAME_LENGTH
	_field.text_submitted.connect(func(_text: String) -> void: _accept())
	_confirm.pressed.connect(_accept)

	_fade.modulate.a = 1.0
	create_tween().tween_property(_fade, "modulate:a", 0.0, 0.4)
	_field.grab_focus.call_deferred()


func _accept() -> void:
	if not _confirm.disabled:
		_confirm.disabled = true
		Party.player_name = _field.text
		var tween: = create_tween()
		tween.tween_property(_fade, "modulate:a", 1.0, 0.3)
		await tween.finished
		finished.emit(Party.player_name)
		queue_free()
