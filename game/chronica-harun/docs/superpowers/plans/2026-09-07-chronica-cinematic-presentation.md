# CHRONICA HARUN Cinematic Presentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the existing canonized narrative runtime into a real cinematic playable presentation with camera/staging/transitions, correct persistence/skip/Codex behavior, seamless FPS handoff, and Aleppo final-black closure.

**Architecture:** Story directors remain semantic/state owners. A dedicated cinematic presentation director consumes bridge shot payloads and drives a cinematic camera/staging layer; the CanvasLayer presentation handles titles, sparse subtitles, overlays, fragment/title/command reveals, and final black. Main boot instantiates/binds the narrative runtime and hands control back to the existing FPS runtime without rewriting combat.

**Tech Stack:** Godot 4.3, GDScript, Python 3.12/pytest, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-07-chronica-cinematic-presentation-design.md`

## Global Constraints
- Branch is `feat/chronica-cinematics-v1` from exact base `4342dcdaf154de952620208ca36f1ab0e76b228e`.
- Do not merge.
- Do not rewrite canon, bosses, combat, roguelite catalogs, backend, or institutional progression.
- Preserve 13 prologue sequences, 500-second profile contract, five-fragment title gate, `VER -> GOVERNAR -> FAZER`, persistence, Codex unlocks, Aleppo c.1585, Nadir, second shadow, final `LUCIFER`, and final cut to black.
- Missing final art remains explicitly proxy/missing.

---

### Task 1: RED cinematic/runtime integration contracts

**Files:**
- Create: `tests/test_cinematic_presentation_runtime_v1.py`

**Interfaces:**
- Consumes: existing Story Bible, Main scene/script, NarrativeRuntime, bridge, presentation, manifest.
- Produces: failing contracts for the production implementation.

- [ ] **Step 1: Write failing tests** checking Main instantiates NarrativeRuntime, a dedicated `CinematicPresentationDirector` exists, presentation has blackout/reveal/fragment nodes, bridge exposes cinematic lifecycle/handoff/final-black signals, five-fragment/title/command order stays intact, epilogue final black is wired, and manifest rows expose asset status.
- [ ] **Step 2: Run** `pytest -q tests/test_cinematic_presentation_runtime_v1.py`.
- [ ] **Step 3: Confirm RED** failures are caused by missing production features, not syntax or fixture errors.
- [ ] **Step 4: Commit** `test: define cinematic presentation runtime contracts`.

### Task 2: CI RED/GREEN gate

**Files:**
- Create: `.github/workflows/chronica-cinematics-v1.yml`

**Interfaces:**
- Consumes: branch source and tests.
- Produces: automated pytest, validators, Godot import/boot/runtime evidence and uploaded artifacts.

- [ ] **Step 1:** Add branch-scoped workflow using Godot 4.3 and Python 3.12.
- [ ] **Step 2:** Run pytest and both validators.
- [ ] **Step 3:** Strict Godot import and Main boot smoke.
- [ ] **Step 4:** Add a dedicated `CinematicPresentationProbe.gd/.tscn` generated in CI that instantiates Main, verifies NarrativeRuntime/Presentation/CinematicStage presence, emits deterministic markers, saves a viewport screenshot, and checks final-black callable behavior without advancing 500 real seconds.
- [ ] **Step 5:** Upload logs and screenshot evidence.
- [ ] **Step 6:** Commit `ci: add cinematic presentation green gate` and verify the new contract test fails before production implementation.

### Task 3: Cinematic presentation director

**Files:**
- Create: `scripts/narrative/CinematicPresentationDirector.gd`
- Modify: `scenes/narrative/NarrativeRuntime.tscn`

**Interfaces:**
- Consumes: `cinematic_visual(payload)`, `cinematic_audio(payload)`, sequence lifecycle signals.
- Produces: `shot_staged(sequence_id, shot_id)`, `transition_started(kind)`, `proxy_asset_used(asset_key)`, `handoff_ready()`.

- [ ] **Step 1:** Implement a focused Node3D child under NarrativeRuntime containing `CinematicRoot`, `CameraRig/Camera3D`, key/fill lights, fog/veil-compatible environment hooks, and reusable procedural proxy nodes.
- [ ] **Step 2:** Map canonical camera text to bounded motion profiles without parsing lore into mechanics.
- [ ] **Step 3:** Map transition names to deterministic transition envelopes.
- [ ] **Step 4:** Resolve visual events into abstract/procedural staging and label every such resolution as proxy.
- [ ] **Step 5:** Run contract test; keep production additions minimal until it passes.
- [ ] **Step 6:** Commit `feat: add cinematic staging director`.

### Task 4: Presentation UI and sparse cinematic state

**Files:**
- Modify: `scenes/narrative/NarrativePresentation.tscn`
- Modify: `scripts/narrative/NarrativePresentationController.gd`

**Interfaces:**
- Consumes: bridge lifecycle, fragment/title/command/final-black signals.
- Produces: cinematic fade/black/reveal presentation and skip UI state.

- [ ] **Step 1:** Add `Blackout`, `CinematicVeil`, `RevealLabel`, `FragmentStatus`, `EvidenceLabel` nodes while preserving choices.
- [ ] **Step 2:** Add fade envelope methods `begin_transition(kind, tension)`, `show_fragment_progress(current, required)`, `show_title_reveal(text)`, `show_command_reveal(command, index)`, `enter_final_black()` and `release_to_gameplay()`.
- [ ] **Step 3:** Honor shot `subtitle_mode == silence` by clearing/hiding subtitle rather than immediately advancing exposition.
- [ ] **Step 4:** Refresh skip state after prologue completion persistence.
- [ ] **Step 5:** Run presentation/codex tests plus new contracts.
- [ ] **Step 6:** Commit `feat: upgrade narrative cinematic presentation`.

### Task 5: Bridge lifecycle, Grimorium and final-black wiring

**Files:**
- Modify: `scripts/narrative/NarrativeRuntimeBridge.gd`
- Modify only if necessary: `scripts/narrative/HarunOriginDirector.gd`, `scripts/narrative/ChronicaStoryDirector.gd`

**Interfaces:**
- Produces signals: `cinematic_sequence_started`, `cinematic_sequence_finished`, `fragment_progress`, `grimorium_title_reveal`, `command_reveal`, `gameplay_handoff_requested`, `final_black_requested`.

- [ ] **Step 1:** Forward fragment progress and exact title/command signals from HarunOrigin.
- [ ] **Step 2:** Wire `CinematicShotDirector.sequence_started/sequence_finished` into presentation lifecycle.
- [ ] **Step 3:** On origin completion emit gameplay handoff to `o_olho` only after `FAZER` and current cinematic sequence completion.
- [ ] **Step 4:** On epilogue completion, emit `final_black_requested` before continuity transition, with `LUCIFER` isolated by presentation.
- [ ] **Step 5:** Preserve Codex unlock/persistence paths unchanged.
- [ ] **Step 6:** Run narrative runtime and story contract tests.
- [ ] **Step 7:** Commit `feat: wire cinematic narrative lifecycle`.

### Task 6: Boot integration and FPS handoff

**Files:**
- Modify: `scenes/boot/Main.tscn`
- Modify: `scripts/boot/Main.gd`

**Interfaces:**
- Consumes: NarrativeRuntime and gameplay handoff signals.
- Produces: new-campaign cinematic entry, correct world/UI suppression, existing FPS restoration.

- [ ] **Step 1:** Instance `NarrativeRuntime.tscn` in Main.
- [ ] **Step 2:** Bind it to `StageDirector` after stage configuration.
- [ ] **Step 3:** Start entry flow after save/new-game state is loaded.
- [ ] **Step 4:** Disable player processing/input and hide gameplay HUD while a blocking prologue/origin cinematic is active; never alter combat logic.
- [ ] **Step 5:** On gameplay handoff, restore player processing/input, make existing player camera current, and reveal HUD after the handoff.
- [ ] **Step 6:** Run Main boot and integration tests.
- [ ] **Step 7:** Commit `feat: integrate cinematics into playable boot flow`.

### Task 7: Manifest asset-status audit

**Files:**
- Modify: `data/narrative/cinematic_asset_manifest.json`
- Modify: `tools/generate_cinematic_asset_manifest.py`
- Modify: `tests/test_cinematic_asset_manifest.py`

**Interfaces:**
- Produces explicit `asset_status` (`proxy_runtime`, `final`, `missing`) and `final_asset_paths` contracts without lying about generated placeholders.

- [ ] **Step 1:** Update generator to emit status metadata for every shot.
- [ ] **Step 2:** Regenerate manifest without changing story contracts or ordering.
- [ ] **Step 3:** Require all rows to expose status and forbid claiming final assets when no concrete final paths exist.
- [ ] **Step 4:** Run manifest + story validator tests.
- [ ] **Step 5:** Commit `chore: audit cinematic asset readiness`.

### Task 8: Final verification and evidence

**Files:**
- Create: `docs/qa/CHRONICA_CINEMATICS_V1_EVIDENCE.md`

**Interfaces:**
- Consumes: CI logs/artifacts, final commit SHA.
- Produces: integration evidence and missing-asset list for coordinator.

- [ ] **Step 1:** Run full GitHub Actions cinematic gate on final HEAD.
- [ ] **Step 2:** Verify pytest, story validator, complete validator, Godot 4.3 import, Main boot, runtime probe all green.
- [ ] **Step 3:** Download/inspect screenshot artifact and logs.
- [ ] **Step 4:** Document implemented sequences/shots/transitions/camera/hooks and explicitly list remaining final-art gaps.
- [ ] **Step 5:** Commit `docs: record cinematic runtime evidence`.
- [ ] **Step 6:** Do not merge.
