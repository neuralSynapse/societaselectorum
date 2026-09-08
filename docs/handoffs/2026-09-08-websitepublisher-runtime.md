# CHRONICA HĀRŪN — WebsitePublisher Runtime Handoff

Date: 2026-09-08
Source repo: `neuralSynapse/societaselectorum`
Handoff branch: `feat/chronica-replit-migration-v1`

## Why this runtime exists

Hercules exhausted its free credits, Lovable exhausted its workspace credits, and AppDeploy hit a lifetime Free deploy ceiling (125/125). WebsitePublisher could not create an 11th project because the account is at 10/10 projects, so the completely empty project `x` (project 27912, previously 0 pages / 0 assets / 0 entities) was used as the runtime shell. No existing production project was overwritten.

## Live runtime

Project id: `27912`
Domain: `https://project27912.websitepublisher.ai/`
Landing page: `index.html`
Page version after first runtime fix: 2
Page version hash: `a0bdb38d`
Search indexing intentionally disabled while the build remains a development vertical slice.

## Implemented in the WebsitePublisher runtime

Single-page Three.js first-person vertical slice with:

- WebGL Three.js runtime loaded as an ES module from jsDelivr (`three@0.180.0`)
- title / playing / dead / victory phases
- mouse pointer lock and mouse-look
- WASD movement
- Shift sprint
- outer arena collision/bounds
- first-person sword mesh and swing animation
- melee hit targeting by distance + forward cone
- player HP and visual damage vignette
- death/restart
- six enemy shadows
- direct deterministic enemy AI state machine: chase -> windup -> recover -> chase
- enemy strafing variation
- run-start grace period
- per-enemy HP, death, duplicate-kill prevention via `alive` transition
- 6/6 victory condition
- kill notices and HUD
- measured 30m x 36m spatial rhythm based on the WalkMyPlan citadel blockout
- 4.6m-high outer walls and court separators
- stone court / pillars / central basin / teal sigil / four brazier lights
- restrained low-saturation historical-occultist palette
- correct fictional/author distinction in the visible credit line
- responsive HUD/title treatment for narrow displays
- prefers-reduced-motion handling

## Runtime fix already applied

The first published page referenced a `clamp()` helper in player/enemy bounds without defining it. The page was immediately patched to define:

`const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));`

This produced page version 2 / hash `a0bdb38d`.

## Design context persisted on WebsitePublisher

Frontend design context was saved for continuity:

- primary/background `#080806`
- secondary `#40362B`
- accent `#C5A36B`
- text `#E8DEC8`
- heading: Cormorant Garamond
- body: Manrope
- style: cinematic historical-occultist, Ottoman Aleppo stone architecture, restrained bronze/gold, teal sigils, low saturation, atmospheric lighting, no dashboard/card aesthetic, no oversaturated emissives

## QA truth

Source persistence on WebsitePublisher was verified by reading the live stored page after publication, and the missing `clamp` runtime blocker was corrected.

Full interactive visual QA has NOT yet been verified on this WebsitePublisher version. The Opera Browser Connector was attempted but returned `Browser not connected`, so no claim is made that the current WebGL scene has been visually inspected or that every input/combat path has been exercised in this runtime.

This distinction is mandatory: do not call this final visual QA until a real browser can load and play the published page.

## Next priorities

1. Real browser QA of title, WebGL boot and pointer-lock entry.
2. Exercise WASD/Shift and confirm coordinates update.
3. Confirm all six enemies visibly pursue the player and do not stall behind visual blockout walls.
4. Confirm melee strike can kill an enemy and increments count once.
5. Confirm player damage, death screen and restart.
6. Confirm 6/6 victory screen.
7. Improve collision/navigation against the measured internal citadel partitions, rather than only arena bounds.
8. Expand from one courtyard into the WalkMyPlan route: Threshold Hall -> First Combat Court + Guard Chambers -> Second Combat Court + Reliquaries -> Reward Shrine / Boss Antechamber.
9. Replace blockout/procedural geometry progressively with production assets from the canonical Godot/content branches.
10. Only then expand enemy archetypes, elite variants, boss phases, roguelite rewards, codex/progression, VFX/audio and cinematics.

## Canonical constraints

- Preserve existing CHRONICA canon.
- Frater Hārūn is a fictional canonical character.
- Real author credit is `Frater Horus Phosphorus`.
- Do not merge to `main` without explicit user approval.
- Do not treat blockout geometry as final art.
