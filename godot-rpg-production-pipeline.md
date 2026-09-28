# Godot RPG — Standard Production Pipeline, Tooling & Steam Deployment

**Scope:** end-to-end reference for building and shipping a commercial RPG with Godot 4 on Steam.
**Last verified:** 2026-09-11. Version numbers move fast — re-check the links in §12 before locking anything in.

---

## 1. The production pipeline (what "standard" actually means)

Game production is not a linear software pipeline; it's a loop that tightens over four phases. Every studio, from solo to AAA, uses some version of this.

| Phase | Goal | Exit gate ("don't move on until…") | Share of calendar |
|---|---|---|---|
| **0. Concept / Pre-production** | Prove the idea is worth building | 1-page pitch + Game Design Document + paper/grey-box prototype of the *core loop* (combat, exploration, progression) | 10–15% |
| **1. Vertical slice** | Prove you can build it at shipping quality | ~15–30 min of the game at final art/audio/UX quality, on the real tech stack. This is what you show publishers and what feeds the Steam page. | 15–20% |
| **2. Production** | Build content at volume | Content pipeline is boring and repeatable: a designer can add a quest/area/enemy without a programmer. Feature-complete = all systems in, content still landing. | 45–55% |
| **3. Alpha → Beta → Gold** | Make it finishable and stable | Alpha = feature complete. Beta = **content complete**, bug-fix only. Gold = release candidate passes a full playthrough on min-spec and Steam Deck. | 20–25% |
| **4. Live / post-launch** | Patches, DLC, ports | Hotfix path from bug report → patch live on Steam in under 48h | ongoing |

**RPG-specific warning:** RPGs are *content-bound*, not *feature-bound*. The schedule risk is almost never "can we build a dialogue system" — it's "can we write, record, balance and QA 40 hours of content." Design your tooling in Phase 1 so that content authoring never requires touching engine code. That single decision is the difference between shipping in 2 years and never shipping.

### The recurring content loop (the thing you repeat 500 times)

```
Design (spreadsheet / JSON / Dialogic timeline)
  → Author asset (Aseprite / Blender / Reaper)
    → Import to Godot (automated .import settings, never hand-tuned per file)
      → Wire into scene (designer, not programmer)
        → Playtest build (nightly CI → itch.io private page)
          → Feedback → back to Design
```

Cadence that works: 2-week sprints, a **playable build every single week** (even if broken), a playtester-facing build every month.

---

## 2. Team & roles (map to whoever you actually have)

| Role | Owns | Solo-dev substitute |
|---|---|---|
| Game / systems designer | Combat math, progression curves, quest structure | You + spreadsheets |
| Narrative designer / writer | Dialogue, lore, quest text, localization source | You + Dialogic / Ink / articy |
| Programmer (gameplay) | Systems, tools, save/load, performance | You |
| Tech artist | Shaders, import pipeline, VFX, batching | Asset store + tutorials |
| 2D/3D artist, animator | Characters, tiles, environments, UI | Asset packs + commissioned work |
| Audio | SFX, music, implementation | Licensed music (Epidemic/Artlist) + freesound + own SFX |
| QA | Test passes, regression, platform checks | Friends + a Steam playtest branch |
| Producer | Scope, schedule, cutting | You, ruthlessly |

Realistic solo/duo RPG scope: **4–8 hours of content, tight systems, strong art direction**. "60-hour JRPG, solo" is the number one cause of abandoned projects.

---

## 3. Repository & version control

### 3.1 Hosting

| Option | Why pick it | Large-file reality |
|---|---|---|
| **GitHub** (recommended) | Best CI (Actions), free private repos; everything below assumes it | Git LFS: 1 GB free, then ~$5/mo per 50 GB data pack — that quota covers **storage *and* bandwidth** |
| GitLab | Free self-hosting, built-in CI | ~10 GB LFS on the free tier |
| Azure DevOps | Free unlimited Git LFS, 5 free users | Weaker gamedev ecosystem |
| Perforce Helix Core (free ≤5 users) | Industry standard for big binary assets, **file locking** | Overkill unless you have a real art team or >50 GB of assets |
| Diversion / Anchorpoint / Unity VCS | Artist-friendly GUI, binary-first | Paid; nice when non-technical artists are on the team |

**Recommendation:** GitHub + Git LFS for a team of ≤5. Move to Perforce only if you pass ~100 GB or genuinely need file locking on uncompressed art source.

### 3.2 Repo layout

Keep the **game** and the **art source** in separate repos. Art source (`.psd`, `.blend`, `.aseprite`, `.wav` masters) bloats LFS and is never needed by a build.

```
my-rpg/                      # the Godot project IS the repo root (project.godot at root)
├── .github/workflows/       # CI
├── addons/                  # plugins — committed and pinned; avoid submodules for these
├── assets/                  # EXPORTED, game-ready assets only (.png, .ogg, .glb)
│   ├── characters/
│   ├── environments/
│   ├── ui/
│   └── audio/
├── data/                    # content as data: .json/.csv/.tres — items, enemies, quests, loot
├── scenes/
│   ├── actors/              # player, npc, enemy scenes
│   ├── levels/              # maps / areas
│   ├── ui/                  # hud, menus, inventory
│   └── systems/             # managers, autoload-backed scenes
├── scripts/
│   ├── core/                # save system, event bus, state machines
│   ├── gameplay/
│   └── resources/           # custom Resource classes (ItemData, SkillData, QuestData…)
├── localization/            # .csv / .po
├── tests/                   # gdUnit4 / GUT suites
├── tools/                   # editor plugins, importers, build scripts
├── export_presets.cfg       # COMMIT THIS — CI reads it
├── project.godot
├── .gitattributes
└── .gitignore

my-rpg-artsource/            # SEPARATE repo or cloud drive: .blend, .psd, .aseprite, .rpp
```

> `export_presets.cfg` can hold encryption keys and signing paths. Commit the file, keep secrets out of it, and inject them in CI through environment variables.

### 3.3 `.gitignore` (Godot 4)

Generate the baseline from the editor — **Project → Version Control → Generate Version Control Metadata** — then extend:

```gitignore
# Godot 4
.godot/
/android/
export_presets.cfg.local
*.translation

# Builds
/build/
/exports/
*.pck
*.zip

# OS / IDE
.DS_Store
Thumbs.db
.vscode/
.idea/
.mono/
/.vs/

# C# only
bin/
obj/
```

Never commit `.godot/` (the import cache). **Do** commit every `*.import` file, or CI re-imports from scratch and asset UIDs drift.

### 3.4 `.gitattributes` + Git LFS

**Order matters:** `git lfs install` → commit `.gitattributes` → *then* add binaries. Retrofitting LFS onto existing history means `git lfs migrate import --everything`, which rewrites history and forces everyone to re-clone.

```gitattributes
# Normalize line endings
* text=auto eol=lf
*.gd    text eol=lf
*.cs    text eol=lf diff=csharp
*.tscn  text eol=lf
*.tres  text eol=lf
*.cfg   text eol=lf
*.godot text eol=lf

# Binaries via LFS
*.png      filter=lfs diff=lfs merge=lfs -text
*.jpg      filter=lfs diff=lfs merge=lfs -text
*.psd      filter=lfs diff=lfs merge=lfs -text
*.aseprite filter=lfs diff=lfs merge=lfs -text
*.ogg      filter=lfs diff=lfs merge=lfs -text
*.wav      filter=lfs diff=lfs merge=lfs -text
*.mp3      filter=lfs diff=lfs merge=lfs -text
*.glb      filter=lfs diff=lfs merge=lfs -text
*.gltf     filter=lfs diff=lfs merge=lfs -text
*.blend    filter=lfs diff=lfs merge=lfs -text
*.fbx      filter=lfs diff=lfs merge=lfs -text
*.ttf      filter=lfs diff=lfs merge=lfs -text
*.otf      filter=lfs diff=lfs merge=lfs -text
*.ogv      filter=lfs diff=lfs merge=lfs -text
```

### 3.5 Branching & merge discipline

- `main` = always shippable. `develop` = integration. `feature/*` short-lived (≤3 days).
- Godot `.tscn`/`.tres` are text and *technically* mergeable, but scene merges are painful in practice. The working rule: **one person owns a scene at a time**. Split large scenes into sub-scenes so ownership falls out naturally.
- Tag every build: `v0.4.2-alpha`, `v1.0.0`. CI uses the tag as the Steam build description.
- Conventional Commits (`feat:`, `fix:`, `content:`) so you can auto-generate Steam patch notes.

---

## 4. Engine version & language choice

**Godot 4.7.x** is the current stable line (4.7.2, Aug 2026; 4.6 landed Jan 2026). Pin the *exact* patch version across the team and CI — mismatched editor versions silently rewrite `.tscn` files.

| | GDScript | C# (.NET) | GDExtension (C++/Rust) |
|---|---|---|---|
| Iteration speed | Best | Good | Poor |
| Performance | Fine for ~99% of RPG logic | ~2–5× faster in hot loops | Fastest |
| Plugin ecosystem | All of it | Most | N/A |
| Export friction | None | .NET runtime, some targets need care | Must compile per platform |

**Recommendation for an RPG:** GDScript everywhere; drop to C# or GDExtension only for a *measured* bottleneck (large pathfinding grids, procedural generation, heavy save serialization). Mixing is supported but doubles your CI matrix — decide in pre-production, not in year two.

---

## 5. Tooling landscape

### 5.1 Core

| Need | Tool | Notes |
|---|---|---|
| Engine | **Godot 4.7.x** | Free, MIT. Export templates must match the editor version exactly. |
| Code editor | Built-in / **VS Code** + godot-tools / **Rider** | Rider is the best C# experience |
| Version control | Git + Git LFS; GitHub Desktop, Fork, GitKraken | |
| Issue tracking | GitHub Projects, Linear, Notion, Jira | Solo: GitHub Projects is plenty |
| Design docs | Notion / Obsidian / Google Docs | The GDD is a living doc, not a 200-page artifact |

### 5.2 Art

| Need | Tool | Cost |
|---|---|---|
| Pixel art + animation | **Aseprite** | ~$20 (free if built from source) |
| 2D painting / textures | **Krita** (free), Photoshop, Affinity Photo | |
| Vector / UI | Inkscape (free), Affinity Designer, **Figma** | Figma for UI mockups |
| 3D modeling / animation | **Blender** (free) | Godot imports `.blend` directly |
| Tilemaps / level design | Godot `TileMapLayer` (built-in), **Tiled**, **LDtk** (+ importer plugins) | Godot's own tooling is usually enough now |
| VFX | Godot GPUParticles + shaders; godotshaders.com for reference | |
| Sprite import automation | **Aseprite Wizard** plugin | Auto-imports `.aseprite` → `SpriteFrames` |

### 5.3 Audio

| Need | Tool |
|---|---|
| DAW / music | Reaper (~$60), LMMS (free), FL Studio, Ableton |
| SFX editing | Audacity (free), ocenaudio |
| SFX synthesis | sfxr / jsfxr, ChipTone |
| Middleware (optional) | **FMOD for Godot** (GDExtension) or **Wwise Godot Integration** — both free under indie revenue thresholds |
| Licensed music | Epidemic Sound, Artlist, or commission a composer |

Verdict for an RPG: Godot's built-in `AudioStreamPlayer` + audio buses + `AudioStreamInteractive`/`AudioStreamPlaylist` covers most needs. Add FMOD only if you want layered adaptive combat music *and* have someone who knows the tool.

### 5.4 RPG-specific systems & plugins

| System | Option | Notes |
|---|---|---|
| Dialogue & branching | **Dialogic 2** (free) | Timeline editor, characters, portraits, conditions, save integration. The default choice. |
| Dialogue (script-like) | **Dialogue Manager** (Nathan Hoad) | Plain-text driven — great for writers and for clean git diffs |
| Narrative authoring (external) | **articy:draft**, **Ink** (+ godot-ink), **Twine** | articy is the pro option for large branching RPGs; Ink is excellent and diffable |
| AI / behavior | **LimboAI** | Behavior trees + hierarchical state machines with an editor dock |
| Inventory / items | Custom `Resource` classes, or an inventory plugin from the Asset Store | Custom `Resource` (e.g. `ItemData`) is the idiomatic Godot approach |
| Quests | Custom `Resource`-based quest graph, or a quest-manager addon | Quest state lives in the save system, never scattered across scenes |
| Save / load | Custom: serialize one `GameState` dictionary → JSON, or `ResourceSaver` binary | Plan versioning + migration from day one |
| Balancing data | Google Sheets → CSV → `.tres`/JSON importer in `tools/` | Designers edit sheets; an editor button or CI regenerates resources |
| Camera | **Phantom Camera** | Cinemachine-like; big quality-of-life win |
| Localization | Godot CSV/PO translations + **Crowdin** / **POEditor** / Lokalise | Budget this *before* writing 100k words |
| Debug tools | In-game console addon, debug draw, Godot profiler | A cheat/warp console saves hundreds of QA hours in an RPG |
| Steam API | **GodotSteam** (GDExtension build) | Achievements, cloud, stats, rich presence, Workshop |
| Testing | **gdUnit4** (v6.x — GDScript + C#, CLI, JUnit XML) or **GUT** | gdUnit4 ships an official GitHub Action |
| Analytics (optional) | GameAnalytics, self-hosted, or Steam's built-in stats | Must be disclosed in your privacy policy |
| Crash/error reporting | Rotating log file + upload, or Sentry community SDKs | At minimum, write a log the player can attach to a report |

### 5.5 Asset sources

Godot Asset Store (store.godotengine.org), itch.io asset packs, **Kenney** (CC0), OpenGameArt, Humble gamedev bundles. Unity Asset Store art is often usable if the license is engine-agnostic — **read the license before you ship it**.

---

## 6. CI/CD pipeline

### 6.1 What the pipeline must do

1. **On every PR:** headless import + run gdUnit4 tests + lint (`gdlint`) → block merge on failure.
2. **On every push to `develop`:** export Windows/Linux/macOS → upload as workflow artifacts → push to **itch.io** (via `butler`) on a private/password-protected page for playtesters.
3. **On a `v*` tag:** export all platforms → smoke test → upload to **Steam** on a *non-default* branch (`internal` / `beta`) → notify Discord/Slack.
4. **Never auto-publish to Steam's `default` branch.** Valve requires the final "Set Build Live" click in the Steamworks web UI — and you want that human gate anyway.

### 6.2 The moving parts

- **Headless export:** `godot --headless --export-release "Windows Desktop" build/game.exe`. Needs the editor binary **and** matching export templates in the container.
- **Docker image:** `barichello/godot-ci:<version>` is the community standard (editor + templates preinstalled). Pin the tag to your exact Godot version.
- **Ready-made actions:**
  - `firebelley/godot-export` — reads `export_presets.cfg` and exports every preset
  - `godot-gdunit-labs/gdUnit4-action` — runs tests, emits JUnit XML
  - `game-ci/steam-deploy` — wraps `steamcmd` for uploads
  - `yeslayla/butler-publish-itchio-action` — itch.io uploads
- **GitHub secrets you'll need:** `STEAM_USERNAME`, `STEAM_CONFIG_VDF`, `BUTLER_API_KEY`, optionally `GODOT_ENCRYPTION_KEY`.

> **Steam Guard in CI:** log in once on a machine with `steamcmd +login <user> +quit`, complete 2FA, then base64-encode the resulting `config.vdf` into the `STEAM_CONFIG_VDF` secret. Use a **dedicated Steamworks build account** with limited permissions, never your personal one. The session expires — expect to refresh it every few months.

### 6.3 Example workflow (trimmed, but the right shape)

```yaml
# .github/workflows/release.yml
name: Build & Ship
on:
  push:
    tags: ['v*']
  workflow_dispatch:

env:
  GODOT_VERSION: 4.7.2

jobs:
  test:
    runs-on: ubuntu-latest
    container: barichello/godot-ci:4.7.2
    steps:
      - uses: actions/checkout@v4
        with: { lfs: true }
      - name: Import project (twice - first pass populates the cache)
        run: |
          godot --headless --import || true
          godot --headless --import
      - uses: godot-gdunit-labs/gdUnit4-action@v1
        with:
          godot-version: 4.7.2
          paths: 'res://tests/'
          report-name: test-report.xml

  export:
    needs: test
    runs-on: ubuntu-latest
    container: barichello/godot-ci:4.7.2
    strategy:
      matrix:
        include:
          - preset: "Windows Desktop"
            name: windows
            out: build/windows/MyRPG.exe
          - preset: "Linux"
            name: linux
            out: build/linux/MyRPG.x86_64
          - preset: "macOS"
            name: macos
            out: build/macos/MyRPG.zip
    steps:
      - uses: actions/checkout@v4
        with: { lfs: true }
      - name: Set up export templates
        run: |
          mkdir -p ~/.local/share/godot/export_templates
          mv /root/.local/share/godot/export_templates/* ~/.local/share/godot/export_templates/ || true
      - run: godot --headless --import || true
      - name: Export
        run: |
          mkdir -p "$(dirname '${{ matrix.out }}')"
          godot --headless --export-release "${{ matrix.preset }}" "${{ matrix.out }}"
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.name }}
          path: build/${{ matrix.name }}

  steam:
    needs: export
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4
        with: { path: build }
      - uses: game-ci/steam-deploy@v3
        with:
          username: ${{ secrets.STEAM_USERNAME }}
          configVdf: ${{ secrets.STEAM_CONFIG_VDF }}
          appId: 1234560
          buildDescription: ${{ github.ref_name }}
          rootPath: build
          depot1Path: windows
          depot2Path: linux
          depot3Path: macos
          releaseBranch: internal      # NEVER 'default'
```

**macOS caveat:** signed + notarized macOS builds need an Apple Developer account ($99/yr) and signing on a macOS runner. Plenty of indies ship Windows + Linux only; the Windows build under Proton is also the most common path to Steam Deck.

---

## 7. Steam: account, structure, deployment

### 7.1 One-time setup — start this ~4 months before launch

1. **Steamworks account** — company or individual, identity verification, bank details, tax forms (W-8BEN or local equivalent). Allow 1–2 weeks.
2. **Pay Steam Direct: $100 USD per app**, recoupable once the game earns $1,000 in adjusted gross revenue.
3. **30-day waiting period** after the fee before you're allowed to release. Non-negotiable.
4. You get an **AppID** (e.g. `1234560`); Steam creates **depots** (e.g. `1234561` Windows, `1234562` Linux, `1234563` macOS).
5. Download the **Steamworks SDK** → `sdk/tools/ContentBuilder/`.
6. Build the **store page** → submit for review → then make it **public at least 2 weeks before launch** (Valve enforces this).

### 7.2 Revenue split

30% to Valve, dropping to 25% above $10M and 20% above $50M lifetime revenue *per app*. Payments are monthly, roughly 30 days after month end, subject to a minimum payout threshold.

### 7.3 Build upload — SteamPipe / ContentBuilder

Layout from the SDK:

```
ContentBuilder/
├── builder/steamcmd.exe          (builder_linux/, builder_osx/ elsewhere)
├── content/
│   ├── windows/   ← exported Windows build
│   ├── linux/
│   └── macos/
├── output/                       (logs + chunk cache — KEEP between builds, uploads stay incremental)
└── scripts/
    ├── app_build_1234560.vdf
    └── depot_build_1234561.vdf …
```

`app_build_1234560.vdf`:

```
"appbuild"
{
    "appid"       "1234560"
    "desc"        "v1.0.0 - launch build"
    "buildoutput" "..\output\"
    "contentroot" "..\content\"
    "setlive"     ""            // "" = do NOT set live. Use "internal"/"beta" for test branches.
    "preview"     "0"
    "local"       ""

    "depots"
    {
        "1234561" "depot_build_1234561.vdf"
        "1234562" "depot_build_1234562.vdf"
        "1234563" "depot_build_1234563.vdf"
    }
}
```

`depot_build_1234561.vdf`:

```
"DepotBuild"
{
    "DepotID"     "1234561"
    "ContentRoot" "..\content\windows\"
    "FileMapping"
    {
        "LocalPath" "*"
        "DepotPath" "."
        "recursive" "1"
    }
    "FileExclusion" "*.pdb"
    "FileExclusion" "steam_appid.txt"
}
```

Upload:

```bash
steamcmd +login <builder_account> +run_app_build ../scripts/app_build_1234560.vdf +quit
```

Then, in the Steamworks web UI: **Builds → pick the build → choose a branch → Set Build Live**. Publishing to `default` always requires this manual step (and a second confirmation from another account if you've enabled publisher security).

### 7.4 Godot-specific export & packaging notes

- Export with **release** templates for shipping — debug templates leak stack traces and run slower.
- Per platform, ship: the executable, the `.pck` (or embed it via "Embed PCK"), the **Steamworks API shared library** (`steam_api64.dll` / `libsteam_api.so` / `libsteam_api.dylib`), and the **GodotSteam GDExtension** binaries plus its `.gdextension` file.
- With the **GDExtension** flavour of GodotSteam you use **stock Godot export templates** — custom GodotSteam templates are only for the older engine-module build.
- `steam_appid.txt` (containing just the AppID) is needed **only for local testing outside the Steam client**. **Exclude it from the depot** — shipping it lets players spoof the app.
- Verify `Steam.steamInitEx()` succeeds before any other Steam call, and degrade gracefully when it fails so the game still runs offline / DRM-free.
- Current GodotSteam line: **4.2x** for Godot 4.4+, tracking **Steamworks SDK 1.65**, with Windows / Linux / macOS / Android / Linux-ARM64 binaries. Separate branches exist for Godot 4.0 and 4.1–4.3.

### 7.5 Steam features worth wiring into an RPG

| Feature | Effort | Payoff |
|---|---|---|
| **Achievements** | Low (`set_achievement` + `store_stats`) | High — players expect them; helps visibility |
| **Steam Cloud** | Low (auto-cloud by file path, zero code) | High — configure UFS rules in Steamworks |
| **Trading cards / points** | Low, post-launch | Extra marketing surface |
| **Rich presence / stats** | Low | Nice to have |
| **Steam Input** | Medium | Controller support without hand-mapping every pad |
| **Steam Deck Verified** | Medium | Big for RPGs specifically — Deck players buy long games. Needs controller glyphs, readable text at 1280×800, no external launcher, a default controller config |
| **Demo + Playtest** | Medium | Separate AppIDs, granted free; the main wishlist engine |
| **Next Fest** | Planning | One shot per game, usually right before launch — plan the demo around it |
| **Workshop / mods** | High | Only if modding is a design pillar (huge for RPGs, but a real commitment) |

### 7.6 Branches

Use Steam betas with branch passwords: `internal` (team), `qa` (testers), `beta` (public opt-in patches). Player-visible branches need a description. Push CI builds to `internal` continuously; promote to `default` by hand.

---

## 8. Launch checklist & timeline

**T-4 months**
- [ ] Steamworks account created, $100 paid, 30-day clock started
- [ ] Store page drafted: capsule art (all sizes), 5+ screenshots, trailer, tags, short/long description
- [ ] Store page submitted for review, then made **public** (wishlists start accumulating)

**T-3 months**
- [ ] First build uploaded to a private Steam branch and confirmed downloadable through the Steam client
- [ ] Achievements + Cloud configured and tested end to end
- [ ] Content complete → Beta
- [ ] Demo build branched off; Next Fest slot chosen

**T-2 months**
- [ ] Localization strings frozen and sent for translation
- [ ] External QA / playtest round; crash telemetry in place
- [ ] Steam Deck pass; min-spec machine pass
- [ ] Press kit (presskit() or an itch page), key distribution via Keymailer/Woovit, streamer outreach list

**T-1 month**
- [ ] Release candidate on the `beta` branch for a week with real players
- [ ] Pricing + regional pricing set; launch discount configured (keep it ≤10% if you want normal discounting later)
- [ ] Full playthrough by someone who has never played it
- [ ] Hotfix pipeline rehearsed end to end (tag → CI → Steam branch → set live); time it, target under 2 hours

**Launch day**
- [ ] Build set live on `default` hours ahead of the release time, not minutes
- [ ] Someone watching the discussion boards and the refund rate
- [ ] Day-1 hotfix branch ready to go

**Cost floor (solo, own art):** $100 Steam + ~$20 Aseprite + ~$60 Reaper + $0 for Godot/Blender/Krita ≈ **under $200**, plus optional $99/yr Apple Developer for macOS and ~$5/mo GitHub LFS.

---

## 9. Common failure modes (RPG-flavoured)

1. **Scope.** Cut the world map in half in pre-production, and again at alpha. RPG content cost is superlinear — every new system multiplies against every item, enemy and quest.
2. **No content tooling.** If adding a quest needs a programmer, you'll ship about a fifth of the content you planned.
3. **Save system as an afterthought.** Retrofitting saves onto a half-built RPG is the most expensive refactor in the genre. Build it during the vertical slice, with a version field and a migration path.
4. **Godot version drift across the team.** Pin the patch version; let CI enforce it.
5. **LFS added late.** History rewrite plus everyone re-clones. Do it on day one.
6. **Scene merge conflicts.** Decompose scenes; one owner per scene.
7. **Steam schedule surprises.** The 30-day wait, the 2-week public store page rule, and build review latency (1–5 business days) all block your launch date and are all easy to forget.
8. **Late localization.** Hardcoded strings and fixed-width UI. Wrap every player-facing string in `tr()` from the first line of UI code, and test with a language ~40% longer (German) and one needing CJK fonts.
9. **Shipping `steam_appid.txt`** or debug export templates.
10. **Testing only on your dev machine.** Test on min-spec, on a fresh OS profile (no cached fonts or dev drivers), and on a Steam Deck.

---

## 10. Recommended stack (concrete and opinionated)

For a solo dev or small team shipping a 2D RPG on Steam:

- **Engine:** Godot 4.7.x, GDScript
- **Repo:** private GitHub + Git LFS; `main` / `develop` / `feature/*`; Conventional Commits
- **Dialogue:** Dialogic 2 (or Ink if you prefer text-file authoring and clean diffs)
- **AI:** LimboAI
- **Camera:** Phantom Camera
- **Data:** Google Sheets → CSV → `.tres` importer in `tools/`
- **Tests:** gdUnit4 + its official GitHub Action
- **Art:** Aseprite + Krita (+ Blender for any 3D)
- **Audio:** Reaper + Audacity, Godot's built-in buses (skip middleware)
- **Steam:** GodotSteam GDExtension for achievements + cloud
- **CI:** GitHub Actions on `barichello/godot-ci`; nightly → itch.io via butler; tags → Steam `internal` via `game-ci/steam-deploy`; manual promotion to `default`
- **Localization:** Godot CSV translations, Crowdin once there's budget
- **Tracking:** GitHub Projects, 2-week sprints, weekly playable build

---

## 11. First 10 concrete steps

1. Install Godot 4.7.x + matching export templates. Pin the version in the README.
2. `git init`, `git lfs install`, commit `.gitattributes` and `.gitignore` **before** any asset.
3. Create the folder skeleton from §3.2; add a README and a one-page GDD.
4. Build the core loop grey-boxed: move → encounter → resolve combat → gain progression → save → load. No art.
5. Write the **save system** and a `GameState` resource now, with a `version` field.
6. Add gdUnit4 and a CI workflow that imports and tests on every PR. Make it green on day one.
7. Add Dialogic and one data-driven definition (`ItemData` as a `Resource`) plus a CSV→`.tres` importer.
8. Build the vertical slice: 20 minutes at final quality. Stop and evaluate honestly.
9. Create the Steamworks account and pay the $100 as soon as the slice looks real — the 30-day clock and store page review run in parallel with development for free.
10. Wire GodotSteam and ship a build to a private Steam branch, then install it through the Steam client. Do this *early*; it always breaks the first time.

---

## 12. Sources & links to re-verify

- Godot downloads & releases — https://godotengine.org/download/archive/ · https://github.com/godotengine/godot-builds/releases
- Godot version-control best practices — https://github.com/godotengine/godot-docs/blob/master/tutorials/best_practices/version_control_systems.rst
- Awesome Godot (plugin index) — https://github.com/godotengine/awesome-godot
- Godot Asset Store — https://store.godotengine.org/
- GodotSteam docs, "Exporting and Shipping" — https://godotsteam.com/tutorials/exporting_shipping/ · https://codeberg.org/godotsteam/godotsteam
- GodotSteam GDExtension asset — https://store.godotengine.org/asset/godotsteam/godotsteam-gdextension/
- Dialogic — https://github.com/dialogic-godot/dialogic
- gdUnit4 + official action — https://github.com/godot-gdunit-labs/gdUnit4 · https://github.com/godot-gdunit-labs/gdUnit4-action
- godot-export action — https://github.com/firebelley/godot-export
- steam-deploy action — https://github.com/marketplace/actions/steam-deploy
- godot-ci Docker & templates — https://github.com/marketplace/actions/godot-ci · https://github.com/HeyImKyu/godot-steam-ci
- Auto-export + upload to Steam/itch walkthrough — http://mreliptik.dev/godot-auto-export/
- Steamworks partner documentation (SteamPipe, app admin) — https://partner.steamgames.com/doc/home
- FMOD for Godot — https://github.com/alessandrofama/fmod-for-godot · Wwise for Godot — https://github.com/alessandrofama/wwise-godot-integration
