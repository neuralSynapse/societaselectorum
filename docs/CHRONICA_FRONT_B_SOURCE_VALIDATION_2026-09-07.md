# CHRONICA HARUN · FRENTE B · SOURCE VALIDATION

Date: 2026-09-07
Branch: `feat/chronica-combat-entities`
Base handoff HEAD supplied: `83979a10b5aee037dd513c09f41cc87fba1fc225`

## Result

The requested Godot source is **not reconstructable from the persisted v2 blob currently stored on GitHub**.

`chronica-handoff/FRONT_B_RESTORE_v2.md` declares a verified package SHA-256 of:

`8f7346d4dcf4df25d3ea028f77d8df4cf886cf18d2eb7ea85b9ce1bc03a29154`

The persisted v2 base64 blob was validated in GitHub Actions from the Front B branch. After whitespace removal:

```text
base64_chars=18479
length_mod_4=3
direct_decoded_bytes=13852
direct_sha256=32b8812cfb359030d9028e737602186e10032ff046dda785a9c87799704e7d9b
```

The blob is therefore not valid base64 for the package described by the restore document.

A repair attempt tested all 1,182,720 possible single-character insertions across the compacted base64 string against the published decoded SHA-256. No candidate matched:

```text
approx_corruption_byte=6926
approx_base64_pos=9234
repair_attempts=1182720
Unable to repair v2 package to the published SHA-256
```

This demonstrates that the persisted v2 blob is not merely missing one base64 character. Bytes were elided/truncated or the published SHA belongs to a different local artifact.

## Independent corroboration

Front A (`feat/chronica-foundation-audit`) independently audited the handoff and records that both v1 and v2 persisted blobs contain an ellipsis marker / invalid characters and are truncated. Its sync note explicitly states that the Front A scaffold must not be used as the historical/comprehensive gameplay source.

## Local workspace search

The current runtime was checked for the previously declared recovered workspace:

```text
/mnt/data/chronica-godot-recovered/.worktrees/narrative-integration  MISSING
/mnt/data/chronica-godot-recovered                              MISSING
/mnt/data/chronica-harun-godot                                  MISSING
```

Therefore there is no intact local recovered tree available in this execution environment to repersist.

## What remains valid

The repository and handoff branch exist. `chronica-handoff/source/project.godot` exists directly. The handoff documentation also records the intended recovered local history (`82449af...`, `f464779...`) and the expected 82 enemy / 16 boss generation result, but those local commits are not present as remote Git objects and the complete source tree is not exposed directly on the handoff branch.

## Required unblock

Persist the actual Godot tree as ordinary Git files in a dedicated branch or repository, rather than another giant base64 text blob. Minimum required paths:

- `project.godot`
- `autoload/GameState.gd`
- `autoload/SaveService.gd`
- `autoload/RogueliteContentService.gd`
- `scripts/progression/StageDirector.gd`
- `scripts/generation/StageFloorBuilder.gd`
- `scripts/content/BuildResolver.gd`
- `scripts/content/PowerMutationRuntime.gd`
- `scripts/content/DaimonRuntime.gd`
- `scripts/rooms/SpecialRoomDirector.gd`
- `scripts/vision/VisionDirector.gd`
- `scripts/meta/MetaRunDirector.gd`
- `data/stages/student_journey.json`
- `data/enemies/student_enemies.json`
- `data/bosses/student_bosses.json`
- `data/roguelite/`
- `scenes/player/`
- `scenes/enemies/`
- `scenes/bosses/`
- `scripts/ai/`
- `scripts/combat/`
- source/model generators and tests

Generated GLBs may be regenerated in CI if the generators are present and deterministic.

## Anti-regression decision

No combat implementation was applied on the web project, Front A scaffold, or roguelite partial branch. No merge to `main` occurred.
