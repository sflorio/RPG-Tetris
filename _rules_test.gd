extends Node

const O := TetrisDamageRules.Piece.O
const I := TetrisDamageRules.Piece.I

func show(tag: String, r: TetrisDamageBreakdown) -> void:
	print("  %-22s %s" % [tag, r])

func _ready() -> void:
	print("== base rule: 1 line = 1 damage ==")
	var r := TetrisDamageRules.new()
	show("1 line (I)", r.resolve_clear(1, I, false))

	print("== the square rule: 3 clears with the square doubles damage ==")
	r = TetrisDamageRules.new()
	for i in 4:
		r.on_clearless_lock()   # isolate the streak rule from the combo rule
		show("square clear %d" % (i + 1), r.resolve_clear(1, O, false))

	print("== a non-square clear breaks the streak ==")
	r = TetrisDamageRules.new()
	r.on_clearless_lock(); show("square 1", r.resolve_clear(1, O, false))
	r.on_clearless_lock(); show("square 2", r.resolve_clear(1, O, false))
	r.on_clearless_lock(); show("line piece", r.resolve_clear(1, I, false))
	r.on_clearless_lock(); show("square 3", r.resolve_clear(1, O, false))

	print("== multi-line clears and back-to-back ==")
	r = TetrisDamageRules.new()
	show("tetris", r.resolve_clear(4, I, false))
	show("tetris again", r.resolve_clear(4, I, false))

	print("== combo chain (clears on consecutive pieces) ==")
	r = TetrisDamageRules.new()
	for i in 3:
		show("combo clear %d" % (i + 1), r.resolve_clear(1, I, false))

	print("== perfect clear ==")
	r = TetrisDamageRules.new()
	show("perfect", r.resolve_clear(2, I, true))
	get_tree().quit()
