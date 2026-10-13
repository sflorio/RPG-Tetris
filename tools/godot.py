"""Runs Godot from the command line so a change can be checked without opening the editor.

    python tools/godot.py check                  parse every script, then boot the game headless
    python tools/godot.py shot [scene] [-f N]    play N frames and save the last one as a PNG
    python tools/godot.py run [scene]            play it in a window

Anything after `--` is passed to the game as user arguments (OS.get_cmdline_user_args()), e.g.
    python tools/godot.py shot res://tools/sandbox/combat_sandbox.tscn -- --effect=Blind

`check` exits non-zero on any parse error or any SCRIPT ERROR / ERROR the engine prints while the
game boots. The leak report Godot prints at exit is not counted: it is there on a clean run too.

`shot` uses Movie Maker mode, so frames are rendered at a fixed 30 fps however slow the machine
is, and the result is the same every time. It needs a window, so it cannot run headless.

Godot is found through $GODOT, then the 4.7.2 console build at C:\\, then `godot` on PATH.
"""
import argparse, glob, os, re, shutil, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_GODOT = r"C:\Godot_v4.7.2-stable_win64_console.exe"

# Printed at exit on every run, clean or not.
NOISE = re.compile(r"leaked at exit|still in use at exit|^\s+at: (cleanup|clear) ")
PROBLEM = re.compile(r"^(SCRIPT ERROR|ERROR|USER ERROR):")


def godot():
    for candidate in (os.environ.get("GODOT"), DEFAULT_GODOT, shutil.which("godot")):
        if candidate and os.path.exists(candidate):
            return candidate
    sys.exit("Godot not found: set GODOT to the path of the console executable.")


def call(args, timeout=300):
    proc = subprocess.run([godot(), "--path", ROOT, *args], capture_output=True, text=True,
                          encoding="utf-8", errors="replace", timeout=timeout)
    return proc.returncode, (proc.stdout + proc.stderr).splitlines()


def problems(lines):
    """Each distinct error with the context the engine prints under it, once, with a count.

    An error in _process repeats every frame; printing it 600 times buries everything else.
    """
    blocks, current = [], None
    for line in lines:
        if NOISE.search(line):
            current = None
        elif PROBLEM.match(line):
            current = [line]
            blocks.append(current)
        elif current is not None and line.startswith((" ", "\t")):
            current.append(line)
        else:
            current = None
    counts = {}
    for block in blocks:
        key = "\n".join(block)
        counts[key] = counts.get(key, 0) + 1
    return [key if n == 1 else f"{key}\n   (x{n})" for key, n in counts.items()]


def check(args):
    code, lines = call(["--headless", "--script", "res://tools/check_scripts.gd"])
    for line in lines:
        if line.startswith(("check_scripts:", "  FAILED")):
            print(line)
    found = problems(lines)
    if code or found:
        print("\n".join(found))
        return 1

    print(f"boot: {args.frames} frames headless")
    code, lines = call(["--headless", "--quit-after", str(args.frames)])
    found = problems(lines)
    if found:
        print("\n".join(found))
        return 1
    print("boot: clean")
    return 0


def shot(args):
    out = os.path.abspath(args.out)
    work = tempfile.mkdtemp(prefix="godot_shot_")
    try:
        scene = [args.scene] if args.scene else []
        code, lines = call(["--write-movie", os.path.join(work, "f.png"), "--fixed-fps", "30",
                            "--quit-after", str(args.frames), *scene, *args.user])
        frames = sorted(glob.glob(os.path.join(work, "f*.png")))
        if not frames:
            print("\n".join(problems(lines) or lines[-20:]))
            return 1
        os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
        shutil.copyfile(frames[-1], out)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    found = problems(lines)
    if found:
        print("\n".join(found))
    print(out)
    return 0


def run(args):
    scene = [args.scene] if args.scene else []
    return subprocess.call([godot(), "--path", ROOT, *scene, *args.user])


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("check", help="parse every script, then boot the game headless")
    p.add_argument("-f", "--frames", type=int, default=600, help="frames to boot for (600)")
    p.set_defaults(func=check)

    p = sub.add_parser("shot", help="save the last of N frames as a PNG")
    p.add_argument("scene", nargs="?", help="res:// path of a scene; the main scene if omitted")
    p.add_argument("-f", "--frames", type=int, default=90, help="frames to play first (90)")
    p.add_argument("-o", "--out", default=os.path.join(ROOT, ".godot", "shot.png"))
    p.set_defaults(func=shot)

    p = sub.add_parser("run", help="play in a window")
    p.add_argument("scene", nargs="?")
    p.set_defaults(func=run)

    argv = sys.argv[1:]
    user = argv[argv.index("--"):] if "--" in argv else []
    args = parser.parse_args(argv[:len(argv) - len(user)])
    args.user = user
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
