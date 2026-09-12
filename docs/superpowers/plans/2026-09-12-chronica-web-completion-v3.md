# CHRONICA HĀRŪN Web Completion V3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make WebsitePublisher project 27912 a single, understandable, end-to-end playable first-person CHRONICA HĀRŪN experience with no first-room softlock and with the remaining roguelite/canonical systems connected.

**Architecture:** Keep the existing Three.js runtime and split only progression logic that benefits from pure tests. Route the obsolete 2D entry to the canonical FPS, centralize room-zero state/invariants, then close progression/reward/special-room gaps without rewriting the combat core.

**Tech Stack:** WebsitePublisher HTML/CSS/ES modules, Three.js 0.180, localStorage persistence, official JSON catalogs from `neuralSynapse/societaselectorum`, Node.js pure regression tests.

**Spec:** `docs/superpowers/specs/2026-09-12-chronica-web-completion-v3-design.md`

## Global Constraints
- FPS is canonical; shoulder camera is optional.
- No gameplay result grants institutional grades.
- Ammar/Hārūn chronology remains absolute-year open.
- Provenance layers stay distinct.
- No mandatory gate may rely on an invisible instruction.
- Preserve current boss identities, stage powers, relic rules, Book/Liber Speculi, and anti-regression baselines unless a verified bug requires an isolated change.

---

### Task 1: Unify the public entry

**Files:**
- Create: WebsitePublisher `js/entry-router.js`
- Modify: WebsitePublisher `harun-roguelite.html`
- Test: local `entry-router.test.mjs`

**Interfaces:**
- Produces: `routeForLocation(pathname:string, search:string): string|null`
- Legacy route `/harun-roguelite.html?...` returns `/?source=harun-roguelite&...`.

- [x] **Step 1: Write failing routing test**
- [x] **Step 2: Run and verify RED (`ERR_MODULE_NOT_FOUND`)**
- [x] **Step 3: Implement `routeForLocation`**
- [x] **Step 4: Run and verify GREEN**
- [ ] **Step 5: Replace legacy page with redirect bridge and verify readback**

### Task 2: First-room deterministic tutorial state

**Files:**
- Create: WebsitePublisher `js/chronica-flow.js`
- Modify: WebsitePublisher `js/chronica-v2.js`
- Modify: WebsitePublisher `index.html`
- Test: local `chronica-flow.test.mjs`

**Interfaces:**
- `createTutorialState()` -> `{state:'SEEK_TOTEM', weapon:false, revealed:false, gateOpen:false}`
- `tutorialInteract(state, context)` -> new immutable state
- `tutorialInvariant(state)` -> state with `gateOpen === true` whenever `weapon === true`
- `tutorialObjective(state)` -> `{value, small, prompt}`

- [ ] **Step 1: Test `SEEK_TOTEM -> BLADE_REVEALED` only within horizontal range**
- [ ] **Step 2: Verify RED**
- [ ] **Step 3: Test `BLADE_REVEALED -> ARMED -> GATE_OPEN`**
- [ ] **Step 4: Verify RED**
- [ ] **Step 5: Implement minimal pure state module**
- [ ] **Step 6: Verify GREEN**
- [ ] **Step 7: Integrate runtime prompts/gate state with module**
- [ ] **Step 8: Add visible waypoint line and recovery message**

### Task 3: Mandatory gate reconciliation

**Files:**
- Modify: WebsitePublisher `js/chronica-v2.js`
- Test: local `gate-invariants.test.mjs`

**Interfaces:**
- `expectedGateState(room, context)` returns open/closed state for each mandatory threshold.
- Runtime diagnostic object: `window.__chronicaDiagnostics`.

- [ ] **Step 1: Write tests for room 0, combat rooms, relic room, sanctuary, boss threshold**
- [ ] **Step 2: Verify RED**
- [ ] **Step 3: Implement gate expectation helpers**
- [ ] **Step 4: Integrate a non-skipping reconciler that repairs presentation/state mismatch only**
- [ ] **Step 5: Verify GREEN and inspect readback**

### Task 4: Reward/modal resume contract

**Files:**
- Modify: WebsitePublisher `js/chronica-parity.js`
- Modify: WebsitePublisher `js/chronica-v2.js`
- Test: local `reward-flow.test.mjs`

**Interfaces:**
- Every reward flow ends in `choiceOpen=false`, overlay hidden, `paused=false` unless a follow-on choice is immediately visible.

- [ ] **Step 1: Write state tests for tarot, kinesis replacement, relic, blessing, sigillum, curse**
- [ ] **Step 2: Verify RED where contract is incomplete**
- [ ] **Step 3: Implement explicit modal state transitions**
- [ ] **Step 4: Verify GREEN**

### Task 5: Complete special-room routing

**Files:**
- Modify: WebsitePublisher `js/chronica-parity.js`
- Modify: WebsitePublisher `js/chronica-content.js`
- Test: local `special-room.test.mjs`

**Interfaces:**
- `eligibleSpecialRooms(catalog, stageIndex, state)` filters official catalog without inventing entries.
- Secret/rupture content stays optional.

- [ ] **Step 1: Test stage/condition filtering with official catalog shapes**
- [ ] **Step 2: Verify RED**
- [ ] **Step 3: Implement eligible pool + deterministic no-repeat tracking**
- [ ] **Step 4: Integrate one eligible special event per stage band without replacing mandatory rooms**
- [ ] **Step 5: Verify GREEN**

### Task 6: Buildcraft completion

**Files:**
- Modify: WebsitePublisher `js/chronica-parity.js`
- Modify: WebsitePublisher `js/chronica-v2.js`
- Test: local `buildcraft.test.mjs`

**Interfaces:**
- Official categories materially change state or gameplay: `tarot`, `kinesis`, `instrumenta`, `relics`, `pharmaka`, `sigilla`, `talismans`, `daimones`, `blessings`, `curses`, conditional `transformations`/`mutations`.

- [ ] **Step 1: Write one behavior test per category**
- [ ] **Step 2: Verify RED for unconnected categories**
- [ ] **Step 3: Implement minimal effects through existing `PARITY_API` hooks**
- [ ] **Step 4: Verify GREEN**

### Task 7: Story communication and Book Zero handoff

**Files:**
- Modify: WebsitePublisher `js/chronica-canon.js`
- Modify: WebsitePublisher `js/chronica-v2.js`
- Modify: WebsitePublisher `js/chronica-blackbook.js`

**Interfaces:**
- Each stage exposes intro, room objective, boss intro, completion reflection.
- Essential control instructions never live only in lore.
- Book Zero remains a canonical lead-in; gameplay starts after Hārūn chooses his name.

- [ ] **Step 1: Audit all 16 stage copy surfaces against canon**
- [ ] **Step 2: Add missing stage-intro/completion copy from current canon only**
- [ ] **Step 3: Ensure Black Book unlocks are additive and never progression blockers**
- [ ] **Step 4: Read back all changed assets**

### Task 8: Verification and release gate

**Files:**
- WebsitePublisher `index.html`, runtime assets, TAPI history
- GitHub branch `feat/chronica-web-completion-v3`

- [ ] **Step 1: Run all local Node regression tests; require zero failures**
- [ ] **Step 2: Read back WebsitePublisher page/assets and verify expected version markers**
- [ ] **Step 3: Check public analytics/entry routing after deployment**
- [ ] **Step 4: Attempt browser QA through an available browser connector**
- [ ] **Step 5: If browser is unavailable, document blocker and do not claim 100%**
- [ ] **Step 6: Add TAPI progress + handover with exact version hashes and remaining QA status**
