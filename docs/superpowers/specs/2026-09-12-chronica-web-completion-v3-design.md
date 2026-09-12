# CHRONICA HĀRŪN Web Completion V3 Design

## Status
Approved by continuation directive after the V2.7 audit: proceed until the playable web experience is coherent, complete enough to traverse end-to-end, and aligned with the current canon. The authoritative playable entry is the first-person Three.js runtime at WebsitePublisher project 27912. The former `harun-roguelite.html` top-down runtime is a sandbox, not the canonical game.

## Goal
Deliver a single canonical web entry that a player can understand and finish without softlocks, with a complete 16-stage loop, explicit story communication, causal memory, roguelite buildcraft, distinct bosses, special rooms, persistent progression, and safe anti-regression behavior.

## Governing constraints
- First-person is the default camera. Shoulder camera is optional.
- Hārūn is fictional. Real authorship remains Frater Horus Phosphorus.
- Gameplay never certifies or grants institutional grades. `PEREGRINUS_IGNIS_GAME` is an internal narrative state only.
- Absolute chronology for Ammar/Hārūn remains open. Aleppo is a geographic reference, not a fixed year.
- Provenance remains explicit: tradition, history, Electorum synthesis, and game dramatization are separate layers.
- The 2D sandbox must never be confused with the canonical runtime.
- No progression gate may depend on an invisible interaction or undocumented control.
- Every room transition must have an explicit objective, a visible affordance, and a failsafe state invariant.
- Preserve current combat, canon data, Book of Black/Liber Speculi, 9 relic rules, 16 stage powers, and 16 boss identities unless a verified bug requires an isolated fix.

## Architecture

### 1. Canonical entry routing
`/` and `/index.html` are the only production game entry points. Legacy `/harun-roguelite.html` redirects to `/` while preserving query context. The old sandbox remains recoverable through page history and its JS asset, but no public link sends players there.

### 2. Explicit journey state machine
The runtime exposes a small, deterministic journey state layer for stage/room/tutorial progression. Room zero uses explicit states:
1. `SEEK_TOTEM`
2. `BLADE_REVEALED`
3. `ARMED`
4. `GATE_OPEN`

The invariant `ARMED => gate 0 open` is enforced every frame or on state transition. Interaction uses horizontal XZ distance for world targets. Objectives and prompts derive from state, not duplicated booleans.

### 3. Story communication
The 13-sequence prologue remains before stage 1. During gameplay, story is delivered through:
- stage-intro card,
- room objective copy,
- short encounter line,
- boss intro line,
- stage-complete reflection,
- Black Book entries.
No essential progression instruction is stored only in lore text.

### 4. Complete stage loop
Each of the 16 stages contains the seven-room rhythm already present:
Limiar → Combat I → Relicário → Combat II → Santuário → Combat III → Trono.
The environment, mechanics, roster, stage power, boss grammar, rewards, and copy vary by stage. All transitions are physically traversable.

### 5. Roguelite buildcraft
Preserve the official catalogs and make all offered systems materially affect a run:
- Tarot/Arcana
- Kinesis
- Instrumenta
- Relics
- Pharmaka
- Sigilla
- Talismans
- Daimones
- Blessings/Curses
- Transformations/Mutations when catalog conditions are met
Reward choice overlays must always resume play after selection and must never leave the runtime paused without a visible modal.

### 6. Special rooms and route variation
The runtime consumes the official special-room catalog. At least one eligible special-room event can occur per stage band, without replacing mandatory seven-room traversal. Secret/rupture access remains optional and never blocks campaign completion.

### 7. Liber Speculi causal memory
Persist and surface:
- deaths by stage,
- bosses defeated,
- ruptures opened,
- major choices,
- prologue completion,
- campaigns completed,
- narrative state,
- Archontic Attention.
Memory can influence copy and pressure, but may not create an unwinnable run.

### 8. Anti-softlock and recovery
Every mandatory gate has an invariant checker. If a valid progression condition is met but the corresponding gate is still closed for more than a short grace period, the runtime repairs that gate and records a diagnostic. Recovery never skips a combat requirement; it only reconciles state and presentation.

### 9. Performance and error recovery
The existing lite/critical performance modes stay. Boot errors are accumulated in `window.__chronicaBootErrors`. Add runtime diagnostics for stage, room, objective state, gate state, modal state, pointer lock, and last progression event. A small recovery message appears only when a state mismatch is detected.

## Completion criteria
- Original legacy URL routes into the canonical FPS runtime.
- A fresh save can complete stage 1 without hidden knowledge.
- The first-room tutorial cannot softlock after the blade is acquired.
- All 16 stages can advance through the same deterministic transition contract.
- Each boss has its own name and attack grammar.
- Reward overlays close and return control.
- Death/restart does not corrupt stage index, room gates, or persistent build state.
- Final campaign completion records only the internal narrative state.
- Static/syntax tests cover routing and pure progression invariants.
- Live browser QA is required before a 100% completion claim; if browser automation is unavailable, status remains below 100% and the exact blocker is documented.
