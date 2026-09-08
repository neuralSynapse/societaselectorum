# CHRONICA HARUN · FRENTE G — AUDIO + VFX + COMBAT FEEDBACK

Status: ready for integration review
Branch: `feat/chronica-audio-vfx-v1`
Exact base: `feat/chronica-combat-v2` @ `4342dcdaf154de952620208ca36f1ab0e76b228e`
Verified implementation HEAD before this publication commit: `921836fc561545c11ce8cac97e398d277d4e62a5`
Verified CI run: `34176938146` — success

## Scope preserved

This front changes only audio, VFX and combat audiovisual feedback plus tests/runtime QA/documentation required to verify that work. No merge was performed. AI, narrative, progression, roguelite catalog semantics and institutional backend were not redesigned.

## AudioDirector

`AudioDirector` now resolves gameplay SFX IDs through an installed asset when present or a safe original procedural `AudioStreamWAV` fallback when absent. Missing final audio therefore does not block boot or gameplay.

Covered gameplay IDs include:

- `player_primary`
- `player_power`
- `kinesis`
- `instrumenta`
- `tarot_activate`
- `player_hit`
- `enemy_windup`
- `enemy_shot`
- `projectile_impact`
- `enemy_hit`
- `enemy_death`
- `boss_windup`
- `boss_attack`
- `boss_phase`
- `boss_death`
- `pickup`
- `secret_break`
- `special_room_activate`
- existing footsteps/dodge/power reveal contracts

The known missing-event warnings for `enemy_windup`, `enemy_shot`, `player_hit` and `boss_phase` are covered by the resolver/fallback contract.

## VFXDirector

A world-space `VFXDirector` was added as an autoload. It supplies compact feedback for:

- player primary attack
- RMB power
- Kinesis
- Instrumenta
- Tarot activation
- player hit
- enemy windup
- enemy telegraph
- enemy projectile
- projectile travel
- projectile impact
- enemy hit
- enemy death
- boss windup
- boss attack
- boss phase transition
- boss death
- pickup
- secret room rupture
- special room activation

Visual limits remain deliberately conservative:

- `MAX_EMISSION = 0.55`
- `TELEGRAPH_MAX_EMISSION = 0.08`
- deep-black compatible silhouettes
- burnt gold + ritual red accents
- short world-space pulses
- no screen-filling glow dependency

## Projectile contract

The ranged projectile contract remains:

`windup -> telegraph -> emission -> travel -> impact`

Damage is not moved to cast time. `ReadableProjectile` remains physically travelling and camera-independent. Projectile feedback was strengthened for readability, including an explicit particle draw pass/trail that remains world-space (`local_coords = false`).

## Runtime QA and TDD

Added/extended tests cover:

- every required SFX ID resolves or has fallback
- missing audio events do not break runtime
- telegraph emission remains under the approved cap
- projectile remains visible/readable
- projectile physically travels
- boss phase feedback fires
- runtime probe rejects missing-event warnings and Godot error diagnostics

TDD exposed a real headless dummy-renderer error around procedural mesh materialization. The probe was strengthened to fail on any `ERROR:` diagnostic and the VFX runtime was made headless-safe without weakening normal rendered gameplay.

## Fresh verification on implementation HEAD `921836fc561545c11ce8cac97e398d277d4e62a5`

GitHub Actions run `34176938146` completed successfully with:

- `98 passed` pytest
- `COMPLETE GAME VALIDATION: PASS`
- `CHRONICA STORY CANON VALIDATION: PASS`
- Godot `4.3.stable.official.77dcf97d8`
- strict Godot import: PASS
- Main boot smoke: PASS
- `AUDIO_VFX_RUNTIME_PROBE=PASS`
- `AUDIO_VFX_RUNTIME=PASS`
- `CHRONICA_AUDIO_VFX_GREEN=PASS`
- no `Audio event not installed` in runtime probe
- no Godot `ERROR:` diagnostic in runtime probe

## Asset classification

See `docs/AUDIO_VFX_ASSET_STATUS.md`.

- final audio assets added by this branch: none
- procedural synthesized sounds: placeholder
- authored audio found at configured paths, if later installed: candidate until production approval
- procedural world-space VFX: candidate runtime VFX
- projectile readability VFX: candidate
- protected third-party media introduced: none

## Remaining warnings

No known in-game missing-audio warning remains in the verified runtime probe.

The CI runner still prints external toolchain deprecation warnings for Node.js 20 compatibility in `actions/checkout@v4` / `actions/setup-python@v5` and the runner-side `punycode` module. These are not Godot/gameplay audio-VFX failures.

## Commit chain from exact base

- `ee58a207b1b4a556de328828146bedd8d9c92753` — chore: establish audio vfx v1 execution gate
- `0953173f0c45b602917b6e2431b5c297b286b289` — test: define audio vfx feedback contracts
- `d12a6cf9f06d6e96ca18bc0883d7eef66335e85e` — feat: add safe audio fallbacks and combat feedback vfx
- `3f4073283ac389cfe443a4b4741108c90940f2fa` — fix: make audio vfx runtime probe headless-safe
- `a22a5b5f3654bd1484973191be42ec048644feb7` — test: reject runtime error diagnostics in audio vfx probe
- `9a3fed1c468eff404a57a2b6dcb66041737036d0` — test: fail audio vfx runtime on any Godot error diagnostic
- `c524c0feb73a6c3a9c1f656201d0b37d97d01f81` — fix: keep procedural vfx silent on headless dummy renderer
- `921836fc561545c11ce8cac97e398d277d4e62a5` — docs: close audio vfx v1 implementation plan

## Integration instruction

The coordinator/main integration agent should integrate the latest GREEN tip of `feat/chronica-audio-vfx-v1`, not selectively reimplement this work. Before integration it should compare against the exact base, inspect overlaps with other parallel fronts, preserve the ranged sequence contract, resolve conflicts minimally, then rerun the full game validators, Godot 4.3 strict import, boot smoke and Audio/VFX runtime probe. It must not replace procedural placeholders with unlicensed third-party material and must retain asset classification as final/candidate/placeholder.

Do not merge this branch automatically from this handoff document. Integration remains the coordinator's responsibility.
