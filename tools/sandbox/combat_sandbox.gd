## Opens a Tetris battle directly, skipping the overworld, so combat can be run, screenshotted and
## debugged on its own. Development only: nothing in the game references this scene.
##
##     python tools/godot.py shot res://tools/sandbox/combat_sandbox.tscn -f 120
##     python tools/godot.py run res://tools/sandbox/combat_sandbox.tscn -- --effect=Blind
##
## User arguments (after `--`):
##     --arena=res://path/to/arena.tscn   the encounter; defaults to the town's first test arena
##     --effect=Name[:tier]                status effect on the first ally, e.g. Blind or Poison:1.
##                                         Repeatable. Tier is -1, 0 (default) or 1.
##
## Built the same way Combat builds one ([method Combat._setup_tetris_combat]), minus the
## transition, music and results dialog.
extends CanvasLayer

const DEFAULT_ARENA: = "res://overworld/maps/town/battles/test_combat_arena.tscn"


func _ready() -> void:
	var arena_path: = DEFAULT_ARENA
	var effects: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--arena="):
			arena_path = arg.trim_prefix("--arena=")
		elif arg.begins_with("--effect="):
			effects.append(arg.trim_prefix("--effect="))

	var battle: = TetrisBattle.new()
	battle.config = TetrisBattleConfig.from_arena(load(arena_path) as PackedScene, Party.stats)

	# Before add_child: the battle reads board effects once when it enters the tree.
	for spec in effects:
		var parts: = spec.split(":")
		if not StatusEffectDefs.exists(parts[0]):
			push_error("combat_sandbox: no status effect named '%s'" % parts[0])
			continue
		var tier: = int(parts[1]) if parts.size() > 1 else 0
		battle.config.allies[0].apply_effect(parts[0], tier)

	add_child(battle)

	var results: Array = await battle.finished
	print("combat_sandbox: finished, player victory = ", results[0])
