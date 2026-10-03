# Design vault snapshot

`https://publish.obsidian.md/projectfour` is the source of truth for this game. What is in this
folder is a dated copy of it, fetched by `tools/fetch_design_vault.py`, checked in so that
"what changed in the design since the last pass?" is a `git diff` rather than a re-read of
thirty-odd notes.

Refresh it with:

```bash
python tools/fetch_design_vault.py
```

Then `git diff design/` shows exactly what moved. `DESIGN_ALIGNMENT.md` at the repository root
tracks what has been built against it.
