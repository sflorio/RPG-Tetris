## Parse-checks every GDScript in the project (Dialogic excluded) by loading it.
## Run headless: godot --headless --path . --script res://tools/check_scripts.gd
## Errors are printed by the engine as they are found; exits 1 if any script fails.
extends SceneTree

const ROOTS: Array[String] = [
	"res://src", "res://scr", "res://overworld", "res://combat", "res://tools",
]


func _initialize() -> void:
	var paths: Array[String] = []
	for root in ROOTS:
		_collect(root, paths)
	var failed: Array[String] = []
	for path in paths:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if script == null or not script.can_instantiate():
			failed.append(path)
	print("check_scripts: %d scripts, %d failed" % [paths.size(), failed.size()])
	for path in failed:
		print("  FAILED ", path)
	quit(1 if failed else 0)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_collect(dir_path.path_join(sub), out)
	for file in dir.get_files():
		# Loading this script again from inside itself hangs the engine.
		if file.ends_with(".gd") and dir_path.path_join(file) != get_script().resource_path:
			out.append(dir_path.path_join(file))
