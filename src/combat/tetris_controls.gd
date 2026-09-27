## Combat input bindings, per the Controls note in the design vault.
##
## The design defines two keyboard schemes that cannot coexist: in Keyboard A the letter keys move
## the block and the arrows rotate it, and in Keyboard B it is the other way round. So the combat
## actions are registered at runtime from whichever scheme is active, rather than being baked into
## project.godot.
##
## Field controls are untouched — they keep using the project's `ui_*` actions.
class_name TetrisControls extends RefCounted

enum Scheme {
	## Letters move, arrows rotate.
	KEYBOARD_A,
	## Arrows move, letters rotate.
	KEYBOARD_B,
}

const ACTION_MOVE_LEFT: = "tetris_move_left"
const ACTION_MOVE_RIGHT: = "tetris_move_right"
const ACTION_SOFT_DROP: = "tetris_soft_drop"
const ACTION_HARD_DROP: = "tetris_hard_drop"
const ACTION_ROTATE_LEFT: = "tetris_rotate_left"
const ACTION_ROTATE_RIGHT: = "tetris_rotate_right"
const ACTION_HOLD: = "tetris_hold"
const ACTION_CANCEL: = "tetris_cancel"

## Keyboard bindings per scheme. Letters use physical keycodes so they follow the key's position on
## non-QWERTY layouts.
const KEYBOARD_BINDINGS: = {
	Scheme.KEYBOARD_A: {
		ACTION_MOVE_LEFT: KEY_A,
		ACTION_MOVE_RIGHT: KEY_D,
		ACTION_SOFT_DROP: KEY_S,
		ACTION_HARD_DROP: KEY_W,
		ACTION_ROTATE_LEFT: KEY_LEFT,
		ACTION_ROTATE_RIGHT: KEY_RIGHT,
	},
	Scheme.KEYBOARD_B: {
		ACTION_MOVE_LEFT: KEY_LEFT,
		ACTION_MOVE_RIGHT: KEY_RIGHT,
		ACTION_SOFT_DROP: KEY_DOWN,
		ACTION_HARD_DROP: KEY_UP,
		ACTION_ROTATE_LEFT: KEY_A,
		ACTION_ROTATE_RIGHT: KEY_D,
	},
}

## Bindings that are the same in both schemes.
const SHARED_BINDINGS: = {
	ACTION_HOLD: KEY_SPACE,
	ACTION_CANCEL: KEY_ESCAPE,
}

## Controller bindings. Rotation is deliberately incomplete: the design assigns the A button to
## both Rotate Left and Rotate Right, which cannot work, so only Rotate Right is bound until that
## is resolved.
const GAMEPAD_BINDINGS: = {
	ACTION_MOVE_LEFT: JOY_BUTTON_DPAD_LEFT,
	ACTION_MOVE_RIGHT: JOY_BUTTON_DPAD_RIGHT,
	ACTION_SOFT_DROP: JOY_BUTTON_DPAD_DOWN,
	ACTION_HARD_DROP: JOY_BUTTON_DPAD_UP,
	ACTION_HOLD: JOY_BUTTON_X,
	ACTION_ROTATE_RIGHT: JOY_BUTTON_A,
	ACTION_CANCEL: JOY_BUTTON_B,
}

## The scheme currently in force. Change through [method apply].
static var active_scheme: Scheme = Scheme.KEYBOARD_A


## Registers the combat actions for `scheme`, replacing any previous combat bindings. Safe to call
## repeatedly; call it before a board starts reading input.
static func apply(scheme: Scheme = active_scheme) -> void:
	active_scheme = scheme

	var keyboard: Dictionary = KEYBOARD_BINDINGS[scheme]
	for action in get_actions():
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action)

		if keyboard.has(action):
			InputMap.action_add_event(action, _key_event(keyboard[action]))
		if SHARED_BINDINGS.has(action):
			InputMap.action_add_event(action, _key_event(SHARED_BINDINGS[action]))
		if GAMEPAD_BINDINGS.has(action):
			InputMap.action_add_event(action, _button_event(GAMEPAD_BINDINGS[action]))


## Every action this class owns.
static func get_actions() -> PackedStringArray:
	return PackedStringArray([
		ACTION_MOVE_LEFT, ACTION_MOVE_RIGHT, ACTION_SOFT_DROP, ACTION_HARD_DROP,
		ACTION_ROTATE_LEFT, ACTION_ROTATE_RIGHT, ACTION_HOLD, ACTION_CANCEL,
	])


# Arrows and Space are bound by keycode; letters by physical position.
static func _key_event(key: Key) -> InputEventKey:
	var event: = InputEventKey.new()
	if key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SPACE, KEY_ESCAPE]:
		event.keycode = key
	else:
		event.physical_keycode = key
	return event


static func _button_event(button: JoyButton) -> InputEventJoypadButton:
	var event: = InputEventJoypadButton.new()
	event.button_index = button
	return event
