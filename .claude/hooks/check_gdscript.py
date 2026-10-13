"""PostToolUse hook: after Claude edits a .gd file, parse-check every script in the project.

The whole project is checked, not just the edited file, because a changed signature breaks its
callers. Exit 2 sends the errors back to Claude; a clean check is silent.
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import godot

payload = json.load(sys.stdin)
path = (payload.get("tool_input") or {}).get("file_path", "")
if not path.endswith(".gd") or "addons" in path.replace("\\", "/").split("/"):
    sys.exit(0)

code, lines = godot.call(["--headless", "--script", "res://tools/check_scripts.gd"], timeout=120)
found = godot.problems(lines)
if code or found:
    print("GDScript check failed after editing " + os.path.basename(path) + ":", file=sys.stderr)
    print("\n".join(found) or "\n".join(lines[-20:]), file=sys.stderr)
    sys.exit(2)
