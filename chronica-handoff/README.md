# CHRONICA HARUN · Godot Real Source Handoff · 2026-09-07

This branch exists only to persist the recovered REAL Godot source in an accessible location for the parallel development fronts. It must not be merged into `main` as-is.

## Canonical recovered runtime

Local source branch at handoff time:

- `feat/chronica-narrative-integration`
- HEAD: `82449af8f83c10b46b4e4d907e2f1aea39bdee48`
- recovered gameplay base commit: `f4647798046254baff3447d9e224dd4fdb52d548`
- local `project.godot`: `/mnt/data/chronica-godot-recovered/.worktrees/narrative-integration/project.godot`

The source contains:

- `project.godot`
- `data/enemies/student_enemies.json`
- `data/bosses/student_bosses.json`
- `scenes/enemies/`
- `scenes/bosses/`
- `scripts/ai/`
- `scripts/combat/`
- Student Journey runtimes
- roguelite catalogs/runtime
- narrative integration runtime
- generated enemy/boss GLBs
- tests and validators

## Portable Git bundle

The complete Git history available in the recovered workspace is stored in:

`chronica-handoff/CHRONICA_HARUN_GODOT_REAL_SOURCE_2026-09-07.bundle.b64`

It is base64 text because this connector can create UTF-8 GitHub files but cannot upload arbitrary binary blobs directly.

### Restore

```bash
base64 -d CHRONICA_HARUN_GODOT_REAL_SOURCE_2026-09-07.bundle.b64 > CHRONICA_HARUN_GODOT_REAL_SOURCE_2026-09-07.bundle
git clone CHRONICA_HARUN_GODOT_REAL_SOURCE_2026-09-07.bundle chronica-harun-godot
cd chronica-harun-godot
git branch -a
git switch feat/chronica-narrative-integration
```

Bundle SHA-256:

`b798ab799688202426b9c584db21f5d6d373aa8912638dd5d26dce1e903fc226`

## Verification at handoff time

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

`pytest -q`:

```text
.....................................................                    [100%]
53 passed in 0.10s
```

## Historical declared commits

The older checkpoint had declared these SHAs:

`ed9570e`, `62be8b4`, `c229ccd`, `9a418c3`, `e01f1dc`, `94ed311`, `e3b38a9`, `5259c0b`, `52a2295`.

They are **not present in the recovered local Git object database**. Their intended state was reconstructed into the recovery commits above; do not pretend the original objects were recovered.

The historical file `CHRONICA_HARUN_HANDOFF_PACK_2026-09-07.zip` was also found locally at `/mnt/data/CHRONICA_HARUN_HANDOFF_PACK_2026-09-07.zip` (about 120 MB), but this Git bundle is the smaller verified source handoff used for parallel development.

## Front B rule

Front B should restore the bundle, create its own branch from `feat/chronica-narrative-integration` (or from `f464779` if it wants the gameplay base without narrative-only commits), then work only on combat/entities. Do not edit the browser/Web version to substitute for the Godot source.
