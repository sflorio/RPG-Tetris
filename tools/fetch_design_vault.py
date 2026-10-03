"""Snapshots the published design vault into design/, so changes to it can be diffed.

https://publish.obsidian.md/projectfour is the source of truth. What lands in design/ is a dated
copy of it and nothing more -- it is checked in so that "what changed in the design since the last
pass?" is a `git diff` rather than a re-read of thirty-odd notes.

Obsidian Publish serves the notes from a separate host that wants a publish.obsidian.md referer;
without one every request comes back 403.
"""
import hashlib, json, os, sys, urllib.parse, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "design")

SITE = "https://publish.obsidian.md/projectfour"
UID = "6ae904d3a19cd5cab1cac54f952cfc5e"
HOST = "https://publish-01.obsidian.md"
HEADERS = {"Referer": "https://publish.obsidian.md/", "User-Agent": "Mozilla/5.0"}


def fetch(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=30).read()


def main():
    os.makedirs(OUT, exist_ok=True)
    listing = json.loads(fetch("%s/cache/%s" % (HOST, UID)))
    notes = sorted(k for k in listing if k.lower().endswith(".md"))

    manifest = {}
    for name in notes:
        body = fetch("%s/access/%s/%s" % (HOST, UID, urllib.parse.quote(name)))
        path = os.path.join(OUT, name.replace("/", "__"))
        with open(path, "wb") as f:
            f.write(body.replace(b"\r\n", b"\n"))
        manifest[name] = hashlib.sha256(body).hexdigest()[:16]

    with open(os.path.join(OUT, "MANIFEST.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump({"site": SITE, "notes": manifest}, f, indent=1, sort_keys=True)
        f.write("\n")
    print("%d notes -> %s" % (len(notes), OUT))


if __name__ == "__main__":
    sys.exit(main())
