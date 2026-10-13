"""Checks the game's content for references that only break deep into a playthrough.

    python tools/check_content.py          errors and warnings; exits 1 on any error
    python tools/check_content.py -v       also lists unused timelines and variables

Godot's parser sees scripts, not what is inside a dialogue timeline, and a missing file named in a
string only fails when that line runs. So this reads the content directly:

  paths       every res:// path in a script, scene, resource or timeline exists
  timelines   every .dtl is registered with Dialogic, and every registered one exists
  speakers    every `name:` / `join name` in a timeline is a registered character; a short name
              that resolves to a character in another folder while the timeline's own folder has
              one of the same name is an error (the inn's warrior speaking as the town's "Smog")
  variables   every {Var} a timeline uses is defined in project.godot; every one read is set
              somewhere (a timeline or a script)
  signals     every [signal arg="..."] is handled by some script

Dialogic's own files (addons/) are not checked.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {".git", ".godot", "addons", "resoursces", "__pycache__", ".claude"}
TEXT_EXT = (".gd", ".tscn", ".tres", ".dtl", ".dch", ".godot", ".cfg")

# Quoted paths may contain spaces ("Apple Cider.mp3"); a .dch escapes its quotes as \".
RES_PATH = re.compile(r"res://[^\"'\\\n]+")
VAR_USE = re.compile(r"\{([A-Za-z_][\w.]*)\}")
VAR_SET = re.compile(r"^\s*set\s+\{([A-Za-z_][\w.]*)\}")
SPEAKER = re.compile(r"^\s*([^\s:\[{\-#\"][^:\"\[]*?)(?:\s*\([^)]*\))?:\s")
JOIN = re.compile(r"^\s*(?:join|leave|update)\s+(\S+)")
SIGNAL = re.compile(r'\[signal\s+arg="([^"]*)"')
KEYWORDS = {"if", "elif", "else", "set", "jump", "label", "return", "join", "leave", "update"}
GD_VAR_CALL = re.compile(r'(set|get)_variable\(\s*"([A-Za-z_]\w*)"')
GD_STRING_CONST = re.compile(r'const\s+(\w+)\s*:?\s*=\s*"([A-Za-z_]\w*)"')
EXT_RESOURCE = re.compile(r'\[ext_resource[^\]]*path="res://([^"]+)"[^\]]*id="([^"]+)"')
IGNORES_ARGUMENT = re.compile(r"_on_dialogic_signal_event\(\s*_")


def rel(path):
    return os.path.relpath(path, ROOT).replace("\\", "/")


def walk_files():
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            if name.endswith(TEXT_EXT):
                yield os.path.join(dirpath, name)


def read(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read()


def godot_block(project, key):
    """The body of a `key={ ... }` block in project.godot."""
    m = re.search(r"^%s=\{(.*?)^\}" % re.escape(key), project, re.S | re.M)
    return m.group(1) if m else ""


def registry(project, key):
    """A Dialogic directory from project.godot: identifier -> repository-relative path."""
    return {k: v.replace("res://", "")
            for k, v in re.findall(r'"([^"]+)":\s*"([^"]*)"', godot_block(project, key))}


def timeline_scripts(files):
    """Timeline path -> scripts on the scene nodes that hold it, read from every .tscn."""
    owners = {}
    for path, text in files.items():
        if not path.endswith(".tscn"):
            continue
        ext = {res_id: res_path for res_path, res_id in EXT_RESOURCE.findall(text)}
        root_script = None
        for section in re.split(r"\n(?=\[node )", text):
            ids = re.findall(r'ExtResource\("([^"]+)"\)', section)
            dtls = [ext[i] for i in ids if ext.get(i, "").endswith(".dtl")]
            gds = [ext[i] for i in ids if ext.get(i, "").endswith(".gd")]
            header = section.split("\n", 1)[0]
            if header.startswith("[node") and "parent=" not in header:
                root_script = gds[0] if gds else None
            for dtl in dtls:
                owners.setdefault(dtl, set()).update(gds or ([root_script] if root_script else []))
    return owners


class Report:
    def __init__(self):
        self.errors, self.warnings, self.notes = [], [], []

    def error(self, where, msg):
        self.errors.append(f"{where}: {msg}")

    def warn(self, where, msg):
        self.warnings.append(f"{where}: {msg}")

    def note(self, msg):
        self.notes.append(msg)


def check_paths(r, files):
    for path, text in files.items():
        for n, line in enumerate(text.splitlines(), 1):
            if line.lstrip().startswith(("#", ";")):
                continue
            for ref in RES_PATH.findall(line):
                target = ref[len("res://"):].rstrip(".:,) ")
                # A directory (a constant ending in "/", or a settings folder such as Dialogic's
                # optional extensions_folder), or a path built at runtime ("%s.tscn").
                if not target or "%" in target or "{" in target or target.endswith("/") \
                        or "." not in os.path.basename(target):
                    continue
                if not os.path.exists(os.path.join(ROOT, target)):
                    r.error(f"{path}:{n}", f"missing file {ref.rstrip()}")


def check_timelines(r, files, timelines, dtl_dir):
    registered = set(dtl_dir.values())
    for path in timelines:
        if path not in registered:
            r.warn(path, "timeline is not registered with Dialogic (open it once in the editor)")
    everything = "\n".join(t for p, t in files.items() if not p.endswith(".dtl"))
    for name, path in sorted(dtl_dir.items()):
        if path not in timelines:
            r.error("project.godot", f"timeline '{name}' points at missing {path}")
        elif path not in everything and f'"{name}"' not in everything \
                and not any(f"jump {name}" in t for t in timelines.values()):
            r.note(f"timeline '{name}' ({path}) is not used by any scene or script")


def check_speakers(r, timelines, dch_dir):
    for path, text in timelines.items():
        folder = os.path.dirname(path)
        local = {os.path.splitext(os.path.basename(p))[0]: k
                 for k, p in dch_dir.items() if os.path.dirname(p) == folder}
        for n, line in enumerate(text.splitlines(), 1):
            m = SPEAKER.match(line) or JOIN.match(line)
            if not m:
                continue
            name = m.group(1).strip()
            # `PS\: ...` is an escaped colon, not a speaker.
            if name.split()[0] in KEYWORDS or name.startswith("{") or name.endswith("\\"):
                continue
            where = f"{path}:{n}"
            if name not in dch_dir:
                r.warn(where, f"speaker '{name}' is not a registered character")
                continue
            short = os.path.splitext(os.path.basename(dch_dir[name]))[0]
            mine = local.get(short, name)
            if os.path.dirname(dch_dir[name]) != folder and mine != name:
                r.error(where, f"'{name}' is {dch_dir[name]}, not this folder's {dch_dir[mine]} "
                               f"-- the line speaks as the wrong character")


def check_variables(r, project, scripts, timelines):
    defined = set(re.findall(r'^"([^"]+)":', godot_block(project, "variables"), re.M))
    used, set_by = {}, {}
    for path, text in timelines.items():
        for n, line in enumerate(text.splitlines(), 1):
            for var in VAR_USE.findall(line):
                used.setdefault(var, f"{path}:{n}")
            s = VAR_SET.match(line)
            if s:
                set_by.setdefault(s.group(1), f"{path}:{n}")
    gd_reads = set()
    for path, text in scripts.items():
        for kind, var in GD_VAR_CALL.findall(text):
            if kind == "set":
                set_by.setdefault(var, path)
            else:
                gd_reads.add(var)
        for const, var in GD_STRING_CONST.findall(text):
            if re.search(r"set_variable\(\s*%s\b" % const, text):
                set_by.setdefault(var, path)
        for var in re.findall(r"Dialogic\.VAR\.(\w+)\s*=[^=]", text):
            set_by.setdefault(var, path)
    for var, where in sorted(used.items()):
        if var.split(".")[0] not in defined:
            r.error(where, f"variable {{{var}}} is not defined in project.godot")
        elif var not in set_by:
            r.warn(where, f"variable {{{var}}} is read but nothing sets it; it keeps its default")
    for var in sorted(gd_reads - defined):
        r.error("scripts", f'get_variable("{var}") names a variable not in project.godot')
    for var in sorted(defined - set(used) - gd_reads - set(set_by)):
        r.note(f"variable {{{var}}} is defined but never used")


# A signal is heard when a script names it -- as a string, or as the enum key a handler looks up by
# name (Inventory.ItemTypes.RED_WAND) -- or when the script on the node that plays the timeline
# takes every signal (`func _on_dialogic_signal_event(_argument...)`).
def check_signals(r, files, scripts, timelines):
    code = "\n".join(scripts.values())
    owners = timeline_scripts(files)
    for path, text in timelines.items():
        for n, line in enumerate(text.splitlines(), 1):
            for arg in SIGNAL.findall(line):
                if not arg or f'"{arg}"' in code \
                        or re.search(r"\b%s\b" % re.escape(arg.upper()), code):
                    continue
                handlers = owners.get(path, set())
                if any(IGNORES_ARGUMENT.search(scripts.get(h, "")) for h in handlers):
                    continue
                listening = ", ".join(sorted(handlers)) or "no scene plays this timeline"
                r.warn(f"{path}:{n}", f'[signal arg="{arg}"] is not handled ({listening})')


def main(verbose):
    r = Report()
    files = {rel(p): read(p) for p in walk_files()}
    project = files.get("project.godot", "")
    scripts = {p: t for p, t in files.items() if p.endswith(".gd")}
    timelines = {p: t for p, t in files.items() if p.endswith(".dtl")}

    check_paths(r, files)
    check_timelines(r, files, timelines, registry(project, "directories/dtl_directory"))
    check_speakers(r, timelines, registry(project, "directories/dch_directory"))
    check_variables(r, project, scripts, timelines)
    check_signals(r, files, scripts, timelines)

    for item in r.errors:
        print(f"ERROR    {item}")
    for item in r.warnings:
        print(f"WARNING  {item}")
    if verbose:
        for item in r.notes:
            print(f"note     {item}")
    print(f"check_content: {len(r.errors)} errors, {len(r.warnings)} warnings, "
          f"{len(r.notes)} notes" + ("" if verbose else " (-v to list)"))
    return 1 if r.errors else 0


if __name__ == "__main__":
    sys.exit(main("-v" in sys.argv[1:]))
