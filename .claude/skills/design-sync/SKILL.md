---
name: design-sync
description: Re-fetch the design vault (publish.obsidian.md/projectfour) into design/, diff what changed, and update DESIGN_ALIGNMENT.md with what the changes mean for the code. Use when the user says the design changed, asks what is new in the design, or asks to re-sync with the vault.
---

# Sync with the design vault

1. Fetch: `python tools/fetch_design_vault.py`. It overwrites `design/` and `design/MANIFEST.json`.
2. See what moved: `git diff --stat design/` then `git diff design/<note>.md` for each changed
   note. New notes show up as untracked (`git status design/`).
   If nothing changed, say so and stop.
3. For each change, find the code it touches (`TETRIS_INTEGRATION.md` "Structure" maps notes to
   files) and classify it:
   - **already matches** the code
   - **conflicts** with what is built — name the file and the behaviour
   - **new work** not started
   - **inconsistent within the vault** itself
4. Update `DESIGN_ALIGNMENT.md`: add a dated section in the style of "4b. What the vault added
   since the last pass", and append vault inconsistencies to section 6. Don't change game code in
   this pass unless the user asked for it.
5. Reply with a short list: what changed, what conflicts, what it would take. Ask before
   implementing anything.

`design/` is never edited by hand — it is a snapshot.
