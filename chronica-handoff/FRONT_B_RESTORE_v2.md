# FRONT B RESTORE v2 · CHRONICA HARUN Godot

Use this file, not the older v1 handoff.

## Repository / branch

Repository: `neuralSynapse/societaselectorum`

Branch: `handoff/chronica-godot-real-source-2026-09-07`

The recovered Godot source used to build this handoff had local Git HEAD:

`82449af8f83c10b46b4e4d907e2f1aea39bdee48`

Gameplay reconstruction base:

`f4647798046254baff3447d9e224dd4fdb52d548`

## Source package

Fetch from this branch:

`chronica-handoff/CHRONICA_HARUN_FRONT_B_SOURCE_MIN_v2_2026-09-07.tar.gz.b64`

Then restore:

```bash
base64 -d CHRONICA_HARUN_FRONT_B_SOURCE_MIN_v2_2026-09-07.tar.gz.b64 > source.tar.gz
mkdir chronica-harun-godot
cd chronica-harun-godot
tar -xzf ../source.tar.gz
python tools/generate_recovered_content.py
python tools/generate_models.py
pytest -q
```

After restore + generators, `project.godot` is at the repository root:

`./project.godot`

and the requested files/directories are present:

- `./data/enemies/student_enemies.json`
- `./data/bosses/student_bosses.json`
- `./scenes/enemies/`
- `./scenes/bosses/`
- `./scripts/ai/`
- `./scripts/combat/`

The package also includes player/projectile/room/stage runtimes, SpecialRoomDirector, MetaRunDirector, VisionDirector, roguelite combat hooks, and the source/model generators.

Package SHA-256:

`8f7346d4dcf4df25d3ea028f77d8df4cf886cf18d2eb7ea85b9ce1bc03a29154`

## Fresh restore verification performed before publishing v2

```text
generated recovery content
generated 82 enemy GLBs and 16 boss GLBs
.......................                                                  [100%]
23 passed in 0.10s
```

Required-path verification:

```text
YES project.godot
YES data/enemies/student_enemies.json
YES data/bosses/student_bosses.json
YES scenes/enemies
YES scenes/bosses
YES scripts/ai
YES scripts/combat
enemies 82
bosses 16
```

## Original recovered workspace verification

`git status`:

```text
On branch feat/chronica-narrative-integration
nothing to commit, working tree clean
```

`git log --oneline -20`:

```text
82449af feat: add cinematic presentation and story codex runtime
0f2e5c6 feat: integrate canonical CHRONICA narrative runtime
f464779 feat: reconstruct playable Godot runtime and generated models
15bb60f chore: recover CHRONICA HARUN Godot checkpoint
0650de3 chore: initialize Godot recovery workspace
```

Original full recovered-tree `pytest -q`:

```text
.....................................................                    [100%]
53 passed in 0.10s
```

## Historical commit audit

The older checkpoint declared:

`ed9570e`, `62be8b4`, `c229ccd`, `9a418c3`, `e01f1dc`, `94ed311`, `e3b38a9`, `5259c0b`, `52a2295`.

All nine were checked with `git cat-file` and are **ABSENT** from the recovered Git object database. Their intended state was reconstructed in `15bb60f` / `f464779` and then extended by the narrative commits. Do not claim the old objects were recovered.

The historical local `CHRONICA_HARUN_HANDOFF_PACK_2026-09-07.zip` was also found at about 120 MB, but Front B should use the verified v2 source package above because it is smaller, reconstructable and independently test-verified.

Do not modify the browser/Web game as a substitute for this Godot source. Do not merge the handoff branch into `main`.
