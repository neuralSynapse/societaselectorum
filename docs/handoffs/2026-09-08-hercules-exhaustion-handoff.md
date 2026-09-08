# CHRONICA HĀRŪN — Hercules Exhaustion Handoff

Date: 2026-09-08
Source of truth: `neuralSynapse/societaselectorum`
Handoff branch: `feat/chronica-replit-migration-v1`
Hercules app: `MUNDUS · CHRONICA HĀRŪN`
Hercules app id: `01M1ZK5HR3R8R7DAHGBBN0F8EE`
Thread id: `01M1ZK5J0WTF6HWCTWFV3D23SV`
Published URL: `https://mundus-chronica-harun.onhercules.app`

## Platform state

Hercules free credits reached exactly `0`. The final agent turn terminated with `out_of_credits`. Do not spend future migration effort trying to continue Hercules unless credits become available again.

## Verified QA state before exhaustion

The Hercules environment reported a clean lint/typecheck pass immediately before the final visual pass:

- ESLint exit code: 0
- Vite TypeScript exit code: 0
- Convex TypeScript exit code: 0
- Browser runtime errors: none observed
- Browser warnings only: Three.js `Clock` deprecation and `PCFSoftShadowMap` deprecation
- Real TITLE screenshot was captured successfully
- Real gameplay screenshot was captured successfully

Do not interpret this as final visual QA. The gameplay screenshot exposed severe visual issues that were being corrected when credits ended.

## Gameplay/runtime work already implemented in Hercules

The vertical slice evolved beyond a blank prototype and includes or was actively wired for:

- first-person runtime
- WASD movement
- mouse look / pointer lock flow
- primary melee attack
- attack cooldown
- player HP / damage / death
- restart loop
- enemy spawning
- multiple enemy archetype types already represented (`GUARDIAN`, `SHADE`, `WARDEN`)
- enemy chase/attack state behavior
- victory condition after all enemies die
- kill counter and score
- hit feedback and player damage vignette
- HUD
- first-person weapon component (`WeaponView`) added before final QA turn
- grace period on run start
- batched enemy state updates to reduce Zustand writes
- protection against repeated kill-count increment on already-dead enemies
- shared mutable player-position ref for hot AI reads
- enemy HP bars with camera-facing billboard logic

## Important fixes already attempted

### Store/game loop

- `damageEnemy` changed so an enemy only increments kill count when transitioning from alive to dead.
- Enemy updates were moved toward a single batched update per frame instead of N Zustand writes per enemy.
- Initial/restart grace period was introduced.
- `restartGame()` resets combat state and timestamps run start.
- Initial phase was restored to `TITLE` after temporary screenshot testing.

### Player

- restart resets the local first-person position/camera refs.
- `performAttack` was moved before use and wrapped for stable invocation.
- attack targeting uses camera direction and range.
- store position writes were reduced relative to the original implementation.

### Enemy AI

- `ATTACK` can transition back to `CHASE` when distance increases.
- restart spawning was hardened.
- AI reads `playerPosRef` for current player location.

### QA

A later lint run returned all-zero exit codes before the final visual edits. Re-run all checks after migration because subsequent visual changes happened after that pass.

## Final unfinished visual pass

The real gameplay screenshot revealed:

- over-saturated emissive colors
- bright/incorrect ceiling hue
- braziers/flames appearing as strongly saturated spheres
- HP-bar colors visually overwhelming in scene
- first-person weapon visibility needed further verification
- `CLICK TO RESUME` pointer-lock hint visible in the gameplay screenshot

The final Hercules turn began correcting these before credits ran out:

- Canvas tone mapping changed from ACES Filmic, then Linear, finally to `NoToneMapping` (`toneMapping: 0`) with exposure 1.0.
- Enemy body/emissive palette was reduced in saturation.
- Enemy eye emissive intensity was reduced from 1.2 to 0.6.
- Enemy HP-bar colors were changed to less saturated values.
- Lighting intensity/range was reduced and made warmer/dimmer.
- Ceiling material was darkened.
- Altar sigil emissive intensity was reduced.

The final agent turn stopped before completing the remaining brazier material edit and before a fresh lint/runtime/screenshot verification after all visual edits.

## Canonical constraints

- Preserve existing narrative/canon from the main CHRONICA project.
- Frater Hārūn is a fictional canonical character, not the real author.
- Real author credit: `Frater Horus Phosphorus`.
- Do not merge to `main` without explicit user approval.
- Do not replace historical/canonical content merely to fit a plugin limitation.
- Do not treat coarse geometric proxies as final production art.

## Next-tool priority

1. Import/reconstruct this verified vertical-slice behavior without restarting from a blank concept.
2. Finish the incomplete visual pass first.
3. Re-run lint/typecheck/build.
4. Perform real runtime QA and capture both TITLE and gameplay states.
5. Confirm weapon visibility, enemies, grace period, restart, kill count and pointer-lock flow.
6. Only after the vertical slice is stable, expand rooms, roguelite flow, enemies, bosses, progression, VFX/audio and cinematics.
