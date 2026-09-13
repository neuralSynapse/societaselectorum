# HĀRŪN Survivor V5 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ship the approved V5 epic systems on top of the existing V4 combat core and publish a separate release-candidate URL before canonical promotion.

**Architecture:** Keep V3/V4 engine/render/performance modules intact. V5 owns progression, room graph, tarot/companions/pacts, Livro Negro/map UI, transitions and shared audio integration through additive modules loaded after the core. V5 uses a separate page shell so the production V4 remains rollback-safe.

**Tech Stack:** Canvas2D, DOM overlays, WebAudio via MUNDUS Audio Core, localStorage, Playwright CI, WebsitePublisher.

**Spec:** `docs/superpowers/specs/2026-09-13-harun-survivor-v5-design.md`

## Global Constraints
- Public game progression is lúdica; `institutionalWrite=false`.
- Estudante is not a Grau.
- No copyrighted Isaac assets, item names, room layouts or text.
- Mobile-first 9:16; performance must be evaluated against a same-runner baseline plus an absolute safety floor.

---

### Task 1: V5 canonical progression
**Files:** Create `mundus/harun-survivor/js/progression-v5.js`.
- [x] Encode pre-Ingressus three stages + initial ritual.
- [x] Encode three Hórus Ingressus scrolls + ACTUS ritual.
- [x] Encode twelve Student scrolls + rites.
- [x] Preserve XXXIII Grau structure and reserved content.
- [x] Add migration-safe `meta.v5Path` and QA API.

### Task 2: Room graph, minimap, transitions and special rooms
**Files:** Create `mundus/harun-survivor/js/world-v5.js`.
- [x] Generate unique room/layout IDs per traversal.
- [x] Add permanent minimap and TAB expanded map.
- [x] Map wave milestones to rooms and special-room events.
- [x] Add contextual transitions and room labels.
- [x] Add MAGNES ELECTORUM drop/collection behavior.
- [x] Prevent special-room overlays from pausing a boss wave.

### Task 3: Tarot + companions + pacts
**Files:** Create `mundus/harun-survivor/js/systems-v5.js`, `js/companions-v5.js`.
- [x] Define 78 Thoth cards.
- [x] No-repeat per-run tarot pool; one click selects and dismisses alternatives.
- [x] Add Familiars, Seres, Daimons and Pactos catalogs/effects.
- [x] Expose run registry for Livro Negro and QA.
- [x] Render owned Familiars in combat and give them actual runtime behaviors.
- [x] Offer the first Familiar early when a run has none.

### Task 4: Livro Negro + pause hub
**Files:** Create `mundus/harun-survivor/js/blackbook-v5.js`, `css/survivor-v5.css`.
- [x] ESC intercept opens full Livro Negro safely.
- [x] Tabs: status/map, tarot, familiars, beings, daimons, pacts, scrolls, rituals, bestiary, settings.
- [x] Include volume controls and run stat ledger.

### Task 5: Shared audio + faster feel
**Files:** Create `mundus/harun-survivor/js/audio-v5.js`, `js/art-v5.js`.
- [x] Configure shared MUNDUS Audio Core profile for Survivor.
- [x] State music for menu/explore/combat/boss/ritual.
- [x] SFX hooks for attacks, impacts, kills, damage, cards, rooms, book and bosses.
- [x] Raise default loudness only when user has no saved preference.
- [x] Raise gameplay movement to a responsive 220+ floor and gate real displacement in browser QA.
- [x] Replace the generic soldier-like Hārūn silhouette with a ritual/initiatic procedural renderer.

### Task 6: V5 page + QA
**Files:** Create `mundus/harun-survivor/v5.html`, `qa/playtest-v5.py`, `.github/workflows/mundus-survivor-v5-qa.yml`.
- [x] Load V3/V4 core plus V5 modules; omit V4 progression ownership.
- [x] Add Playwright gates for progression, ESC, TAB, tarot uniqueness, room uniqueness, audio, magnet, movement, boss and performance.
- [x] Publish `/harun-survivor-v5.html` as RC.
- [x] Promote V5 to `/harun-survivor.html` after public smoke.
- [x] Add V5.1 regression gates for actual movement displacement, hero renderer, live familiars, boss-wave pause authority and no boss resurrection.

## V5.1 Regression Contract
- Combat movement must start at >=220 logical px/s and displace >=65 px in a 360ms browser input check.
- `HarunV5Art.version` must be `5.1.0`.
- An owned Familiar must have a visible combat representation and active behavior.
- Boss rooms cannot be paused by a special-room overlay.
- Defeating Observador Cego on wave 10 must advance to wave 11 with no boss respawn.
- Public RC and canonical WebsitePublisher routes must pass the same smoke assertions before the regression fix is considered shipped.
