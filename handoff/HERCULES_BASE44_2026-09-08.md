# CHRONICA HĀRŪN — Hercules → Base44 handoff

Date: 2026-09-08
Branch: `feat/chronica-replit-migration-v1`

## Source of truth

- Repository canon remains `neuralSynapse/societaselectorum`.
- Frater Hārūn is a fictional canonical character.
- Real author credit remains Frater Horus Phosphorus.
- Do not merge this branch into `main` without explicit user approval.

## Hercules terminal state

Hercules app `01M1ZK5HR3R8R7DAHGBBN0F8EE` / slug `mundus-chronica-harun` exhausted the Free-plan budget. Verified remaining credits: **0**. Last agent turn terminated with `out_of_credits`.

Published Hercules URL at exhaustion: `https://mundus-chronica-harun.onhercules.app`.

### QA completed before exhaustion

- ESLint exit code 0.
- Vite TypeScript exit code 0.
- Convex TypeScript exit code 0.
- Hard refresh completed successfully.
- Runtime console had no errors; only Three.js deprecation warnings for `THREE.Clock` and `PCFSoftShadowMap`.
- TITLE screenshot captured successfully: `https://hercules-cdn.com/file_IQ9lKebrEc60Id3JqvF8F5pa`.
- Gameplay screenshot captured successfully: `https://hercules-cdn.com/file_csWkWR3uSpzXH5LcGJiN19vG`.

### Functional work already implemented

- First-person movement, mouse-look, WASD and sprint.
- Primary melee attack and hit feedback.
- HP/damage/death/restart loop.
- 2-second spawn grace period.
- Kill-count double-count guard.
- Enemy respawn/repopulation logic on restart.
- Enemy AI transitions including chase/attack fallback.
- Batched enemy Zustand updates to reduce per-frame render churn.
- Shared mutable player-position ref for AI hot reads.
- Pointer-lock flow with release/resume handling.
- HUD, kill counter, score and damage vignette.
- First-person WeaponView exists in the gameplay scene and is intended to animate on attack.
- Initial game phase restored to `TITLE` after QA test overrides.

## Partial visual correction left by Hercules

The final turn identified major over-saturation in the gameplay screenshot and began correcting it before credits ran out.

Changes known to have been applied:

- Canvas tone mapping changed to `NoToneMapping` (`toneMapping: 0`) with exposure 1.0.
- Enemy palette and eye emissives reduced.
- Enemy HP bars changed to less saturated colors.
- Torch/ambient/directional lighting reduced and warmed.
- Ceiling darkened to `#0C0A06`.
- Altar sigil emissive reduced.

Pending/uncertain because exhaustion happened mid-turn:

- Brazier/fire emissive reduction was not confirmed complete.
- No lint/typecheck was run after the final visual edits.
- No post-correction gameplay screenshot was captured.
- Weapon visibility after the visual corrections was not verified.
- Corrected build was not confirmed published after the final edits.

## Base44 continuation

Base44 app: `Chronica Hārūn: The Peregrinus Quest`
App ID: `6a9f74d6e7dce9ea0995ad09`
Editor: `https://app.base44.com/apps/6a9f74d6e7dce9ea0995ad09/editor/preview`

Direct sandbox/file access is blocked on the current Base44 plan (`PREMIUM_REQUIRED` / Builder plan required). The built-in Base44 builder remains available and has been instructed to continue the project autonomously while preserving this source-of-truth and migration policy.

## Next priority

1. Stabilize and visually validate the existing vertical slice before content expansion.
2. Preserve TITLE as initial phase.
3. Verify repeated attack → kill → victory/death → restart cycles.
4. Verify enemy repopulation and kill count across multiple restarts.
5. Verify pointer lock Esc/reacquire behavior.
6. Verify WeaponView is visible and attack animation is legible.
7. Reduce remaining blown-out brazier/emissive materials.
8. Run lint/typecheck/build after any code-accessible migration.
9. Capture real post-change TITLE and gameplay screenshots before calling visual QA complete.
10. Only then expand rooms, enemy archetypes, bosses, roguelite rewards, progression, codex, audio and cinematics.
