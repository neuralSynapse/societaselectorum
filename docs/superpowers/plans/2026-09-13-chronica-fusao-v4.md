# CHRONICA HĀRŪN · FUSÃO V4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Elevar a build 3D/FPS de CHRONICA HĀRŪN em estabilidade, combate, IA, bosses, progressão, apresentação, performance, UX e QA sem quebrar o cânone nem interromper a build jogável.

**Architecture:** Evolução incremental do runtime WebsitePublisher 27912. `chronica-v2.js` continua como orquestrador enquanto responsabilidades são extraídas para módulos pequenos e testáveis, cada lote publicado com cache-bump, read-back e rollback simples.

**Tech Stack:** JavaScript ES modules + scripts globais, Three.js via import map atual, WebsitePublisher 27912, localStorage, GitHub `neuralSynapse/societaselectorum` branch `feat/chronica-web-runtime`.

**Spec:** `docs/superpowers/specs/2026-09-13-chronica-fusao-v4-design.md`

## Global Constraints
- Hārūn é ficcional; autoria real: Frater Horus Phosphorus.
- O OLHO é percepção, nunca ataque.
- Psyball básica no botão direito; Kinesis 1/2/3 começam vazias.
- Arma física antes do primeiro combate obrigatório; melee ~1,65 m.
- Caim, Sabaoth e 72 Goéticos não entram indevidamente em roster hostil.
- Peregrinus Ignis somente após Câmara + rito; gameplay não certifica grau institucional.
- WebsitePublisher 27912 é runtime principal; mudanças devem usar optimistic concurrency quando possível.
- Nenhuma claim de correção sem verificação fresca.

---

### Task 1: Fechar Encounter Director em todos os caminhos de spawn
**Files:**
- Modify: `js/chronica-encounter-director.js`
- Modify: `js/chronica-v2.js`
- Modify: `js/chronica-diagnostics.js`
- Modify: `chronica-harun-3d.html`

**Interfaces:**
- Consumes: `CHRONICA_ENCOUNTER_CANON.stages[i].pacing`
- Produces: `CHRONICA_ENCOUNTER_DIRECTOR.createState`, `step`, `canMove`, `canAttack`, `spawnGate`

- [ ] Add regression validation proving MANIFEST/READ cannot move or attack.
- [ ] Route common enemy spawn, boss activation, adds, extraordinary threat and respawn through the same gate.
- [ ] Emit `chronica:enemy-manifest`, `chronica:enemy-active`, `chronica:room-clear` consistently.
- [ ] Run module `validate()` and diagnostics read-back.
- [ ] Cache-bump Encounter Director/runtime/diagnostics in the 3D page.

### Task 2: Performance Foundation
**Files:**
- Create: `js/chronica-performance.js`
- Modify: `js/chronica-v2.js`
- Modify: `js/chronica-diagnostics.js`
- Modify: `css/chronica-v2.css`

**Interfaces:**
- Produces: `CHRONICA_PERFORMANCE.tier()`, `budget(kind)`, `scheduler(name,hz,fn)`, `roomActive(room)`, `snapshot()`

- [ ] Implement AUTO/HIGH/MEDIUM/LOW quality profiles with DPR, VFX, light and AI budgets.
- [ ] Add EMA frame-time adaptation with hysteresis so tiers do not flap.
- [ ] Suspend noncritical updates on `document.hidden`.
- [ ] Gate distant/inactive-room AI/VFX/audio updates.
- [ ] Add performance diagnostics panel metrics.

### Task 3: Player Combat Feel
**Files:**
- Create: `js/chronica-player-combat.js`
- Modify: `js/chronica-v2.js`
- Modify: `js/chronica-audio.js`

**Interfaces:**
- Produces: melee resolution, hit-stop request, stagger, whiff feedback, Psyball policy.

- [ ] Freeze melee range contract at 1.65 m.
- [ ] Add short hit-stop on confirmed melee hits only.
- [ ] Add enemy stagger/recovery response and whiff feedback.
- [ ] Preserve Psyball focus/cooldown and O OLHO nonoffensive invariant.
- [ ] Add diagnostics for melee/O OLHO/Psyball contracts.

### Task 4: Enemy AI Archetypes
**Files:**
- Create: `js/chronica-enemy-ai.js`
- Modify: `js/chronica-v2.js`
- Modify: `js/chronica-encounter-canon.js`

**Interfaces:**
- Produces archetype policies: preferred range, strafe/flank, retreat, attack cadence, recovery, low-health behavior.

- [ ] Define at least six mechanically distinct base archetypes.
- [ ] Map inner-shadow, archontic and angelic entities onto policies without changing provenance.
- [ ] Enforce telegraph-before-damage for every ranged/melee policy.
- [ ] Verify no inactive-room AI attacks.

### Task 5: Boss Director
**Files:**
- Create: `js/chronica-boss-director.js`
- Modify: `js/chronica-v2.js`
- Modify: `js/chronica-stage-copy.js`

**Interfaces:**
- Produces three-phase boss state machine with phase rules and arena hooks.

- [ ] Define phase thresholds and transitions for all 16 bosses.
- [ ] Give each boss a unique rule inversion or arena mechanic tied to its Pergaminho/microprova.
- [ ] Route boss spawn through Encounter Director.
- [ ] Add phase telegraph/audio/VFX and boss diagnostic checks.

### Task 6: Buildcraft, Loot e Sinergias
**Files:**
- Create: `js/chronica-buildcraft.js`
- Modify: `js/chronica-parity.js`
- Modify: `js/chronica-consumables.js`
- Modify: `js/chronica-pocket-controller.js`

**Interfaces:**
- Produces weighted pools, anti-repeat history, synergy tags, physical reward descriptors.

- [ ] Add per-run anti-repetition and weighted pools.
- [ ] Add synergy/trade-off evaluation across Arcana, Pharmaka, Sigilla, Daimon, Instrumenta, Talismãs, Kinesis and transformations.
- [ ] Prefer physical pickups/rewards over blocking modal where practical.
- [ ] Keep 72 Goéticos allied/pact layer only.

### Task 7: World Director e 16 Etapas
**Files:**
- Create: `js/chronica-world-director.js`
- Modify: `js/chronica-v2.js`
- Modify: `js/chronica-minimap.js`

**Interfaces:**
- Produces stage profile, room topology hooks, props, route variants, special-room candidates.

- [ ] Give every stage a deterministic but distinct spatial/environment profile.
- [ ] Add route variation and optional side-room hooks without breaking the 7-room baseline.
- [ ] Make minimap reflect actual visited/optional rooms.
- [ ] Ensure rooms outside the active topology are culled and noninteractive.

### Task 8: Audio e VFX Director
**Files:**
- Create: `js/chronica-vfx-director.js`
- Modify: `js/chronica-audio.js`
- Modify: `js/chronica-v2.js`

**Interfaces:**
- Produces pooled VFX requests, per-tier budgets, audio ducking/signatures.

- [ ] Unify important combat events under the mixer.
- [ ] Add archetype/boss sound signatures.
- [ ] Add impact ducking/silence windows for major moments.
- [ ] Pool VFX and respect reduced-motion and quality tier budgets.

### Task 9: Narrative, UX e Save
**Files:**
- Create: `js/chronica-save.js`
- Modify: `js/chronica-blackbook.js`
- Modify: `js/chronica-i18n.js`
- Modify: `chronica-harun-3d.html`
- Modify: `css/chronica-v2.css`

**Interfaces:**
- Produces versioned save envelope, migration, recovery snapshot, settings.

- [ ] Version and migrate saves without losing discovered collection.
- [ ] Add settings for FOV, sensitivity, reduced motion, contrast, audio buses.
- [ ] Move tutorial messaging toward contextual prompts and world events.
- [ ] Preserve source/tradition/dramatization separation in Livro Negro.

### Task 10: QA, Anti-Regressão e Release Gate
**Files:**
- Modify: `js/chronica-diagnostics.js`
- Create: `js/chronica-qa.js`
- Modify: `chronica-harun-3d.html`

**Interfaces:**
- Produces `CHRONICA_QA.run()` with pass/fail result and named invariants.

- [ ] Check runtime ready, encounter state contract, roster protection, Kinesis initial state, weapon gate, melee range, nonoffensive OLHO, save migration, overlays/input, inactive-room AI and budgets.
- [ ] Add F2 diagnostics summary and explicit release gate.
- [ ] Perform WebsitePublisher read-back for page and modified assets.
- [ ] Perform browser playtest when connector is available; otherwise retain `VISUAL QA NOT VERIFIED`.

## Self-review
- Covers every V4 design section.
- No planned rewrite of the entire runtime.
- Every task leaves a testable deliverable.
- Canon invariants remain global constraints.
