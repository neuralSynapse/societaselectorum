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
- Mobile-first 9:16; stress QA target >=45 FPS.

---

### Task 1: V5 canonical progression
**Files:** Create `mundus/harun-survivor/js/progression-v5.js`.
- [ ] Encode pre-Ingressus three stages + initial ritual.
- [ ] Encode three Hórus Ingressus scrolls + ACTUS ritual.
- [ ] Encode twelve Student scrolls + rites.
- [ ] Preserve XXXIII Grau structure and reserved content.
- [ ] Add migration-safe `meta.v5Path` and QA API.

### Task 2: Room graph, minimap, transitions and special rooms
**Files:** Create `mundus/harun-survivor/js/world-v5.js`.
- [ ] Generate unique room/layout IDs per traversal.
- [ ] Add permanent minimap and TAB expanded map.
- [ ] Map wave milestones to rooms and special-room events.
- [ ] Add contextual transitions and room labels.
- [ ] Add MAGNES ELECTORUM drop/collection behavior.

### Task 3: Tarot + companions + pacts
**Files:** Create `mundus/harun-survivor/js/systems-v5.js`.
- [ ] Define 78 Thoth cards.
- [ ] No-repeat per-run tarot pool; one click selects and dismisses alternatives.
- [ ] Add Familiars, Seres, Daimons and Pactos catalogs/effects.
- [ ] Expose run registry for Livro Negro and QA.

### Task 4: Livro Negro + pause hub
**Files:** Create `mundus/harun-survivor/js/blackbook-v5.js`, `css/survivor-v5.css`.
- [ ] ESC intercept opens full Livro Negro safely.
- [ ] Tabs: status/map, tarot, relics, familiars, beings, daimons, pacts, scrolls, rituals, bestiary, settings.
- [ ] Include volume controls and run stat ledger.

### Task 5: Shared audio + faster feel
**Files:** Create `mundus/harun-survivor/js/audio-v5.js`.
- [ ] Configure shared MUNDUS Audio Core profile for Survivor.
- [ ] State music for menu/explore/combat/boss/ritual.
- [ ] SFX hooks for attacks, impacts, kills, damage, cards, rooms, book and bosses.
- [ ] Raise default loudness only when user has no saved preference.
- [ ] Increase movement speed and combat responsiveness once per run.

### Task 6: V5 page + QA
**Files:** Create `mundus/harun-survivor/v5.html`, `qa/playtest-v5.py`, `.github/workflows/mundus-survivor-v5-qa.yml`.
- [ ] Load V3/V4 core plus V5 modules; omit V4 progression ownership.
- [ ] Add Playwright gates for progression, ESC, TAB, tarot uniqueness, room uniqueness, audio, magnet, movement, boss and FPS.
- [ ] Publish `/harun-survivor-v5.html` as RC.
- [ ] Run QA against public RC and only then consider canonical promotion.
