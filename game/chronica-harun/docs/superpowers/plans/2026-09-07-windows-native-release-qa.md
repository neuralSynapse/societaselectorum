# CHRONICA HARUN Windows Native Release QA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Windows-native GitHub Actions release-readiness gate that truthfully classifies automated checks, exports and launches `CHRONICA_HARUN.exe`, validates PE/resources/ZIP/SHA-256, and reports visual limits without false PASS results.

**Architecture:** A Godot-only runtime harness exercises save/load/retry/InputMap/camera/window contracts on `windows-latest`; a PowerShell probe validates the exported executable and distribution package; a dedicated workflow orchestrates existing tests, Godot 4.3, export templates, native launch, packaging, evidence collection, and artifact upload. Distribution metadata may be corrected only where evidence shows stale or missing deterministic metadata.

**Tech Stack:** GitHub Actions, Windows Server hosted runner, PowerShell 7/Windows PowerShell APIs, Python 3.12/pytest, Godot 4.3 stable Windows x86_64.

**Spec:** `game/chronica-harun/docs/superpowers/specs/2026-09-07-windows-native-release-qa-design.md`

## Global Constraints

- Work only on `qa/chronica-windows-visual-v1`.
- Base is `4342dcdaf154de952620208ca36f1ab0e76b228e`.
- Do not merge to `main` or any integration branch.
- Do not alter narrative or redesign gameplay.
- Production changes must be isolated, evidenced release-readiness fixes.
- Results are only `PASS`, `FAIL`, or `NOT TESTABLE IN CI`.
- Headless execution never proves visual render, real fullscreen, GPU/VFX quality, or physical pointer lock.
- When visual QA is not truly verified, report `VISUAL QA NOT VERIFIED` literally.

---

### Task 1: Runtime QA contract test

**Files:**
- Create: `game/chronica-harun/tests/test_windows_native_qa_contract.py`
- Later produce: `game/chronica-harun/runtime_qa/windows_native/WindowsNativeQA.gd`
- Later produce: `game/chronica-harun/runtime_qa/windows_native/WindowsNativeQA.tscn`
- Later produce: `game/chronica-harun/tools/windows_release_probe.ps1`

**Interfaces:**
- Consumes: existing `project.godot`, `SaveService.gd`, `GameState.gd`, `CameraModeController.gd`, `export_presets.cfg`.
- Produces: a static contract that forces the runtime harness and release probe to contain the required evidence markers.

- [ ] **Step 1: Write the failing test**

Create a pytest contract that asserts the future harness/probe files exist and contain explicit markers for Windows OS, save/load, retry reload, required input actions, camera toggling, PE AMD64 validation, ZIP integrity, version resources, icon resources, SHA-256, and truthful visual classification.

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest -q game/chronica-harun/tests/test_windows_native_qa_contract.py`
Expected: FAIL because the harness/probe files do not exist.

- [ ] **Step 3: Commit the RED test**

Commit only the contract test.

### Task 2: Windows-native Godot harness

**Files:**
- Create: `game/chronica-harun/runtime_qa/windows_native/WindowsNativeQA.gd`
- Create: `game/chronica-harun/runtime_qa/windows_native/WindowsNativeQA.tscn`

**Interfaces:**
- Consumes: `GameState`, `SaveService`, `CameraModeController`, `Player.tscn`, `project.godot` InputMap.
- Produces: process exit 0 on all runtime assertions and a line-delimited `WINDOWS_QA_*` evidence log; retry phase uses `user://windows_native_qa_retry_sentinel.txt`.

- [ ] **Step 1: Implement the minimal harness**

The harness must:

1. assert `OS.get_name() == "Windows"`;
2. assert `ProjectSettings.get_setting("application/run/main_scene")` is `res://scenes/boot/Main.tscn`;
3. globalize `user://chronica_harun_campaign.json` and assert it is an absolute Windows path;
4. remove previous QA save/sentinel files;
5. call `GameState.start_new_campaign(424242)` and assert baseline state;
6. save a modified snapshot, mutate memory, load it, and assert round-trip restoration;
7. create a Player + CameraModeController and assert `first_person -> over_shoulder -> first_person`;
8. assert all required InputMap actions exist;
9. print viewport/window size and configured FPS target without claiming measured FPS;
10. verify retry via a two-phase reload using a sentinel and `get_tree().reload_current_scene()`;
11. print `WINDOWS_QA_RUNTIME_PASS` and quit 0.

- [ ] **Step 2: Run the contract test**

Expected: harness-related assertions pass while release-probe assertions still fail.

- [ ] **Step 3: Commit harness**

Commit the runtime scene/script.

### Task 3: Windows release probe

**Files:**
- Create: `game/chronica-harun/tools/windows_release_probe.ps1`

**Interfaces:**
- Consumes: exported `build/windows/CHRONICA_HARUN.exe`.
- Produces: `runtime-qa/windows-native/release-probe.json`, ZIP, SHA-256, optional screenshot, and exit 0 only for hard release checks; icon absence is recorded as FAIL in the matrix without pretending an asset exists.

- [ ] **Step 1: Implement PE/resource/package inspection**

The script must read binary headers directly to assert `MZ`, `PE\0\0`, AMD64 `0x8664`, and PE32+ `0x20b`; inspect `FileVersionInfo`; use Win32 resource enumeration for `RT_GROUP_ICON`/`RT_ICON`; launch the EXE normally for a bounded smoke interval; capture exit state; optionally attempt desktop screenshot; build a ZIP containing the EXE; test archive extraction; compute SHA-256; and serialize all evidence to JSON.

- [ ] **Step 2: Run contract test**

Run: `pytest -q game/chronica-harun/tests/test_windows_native_qa_contract.py`
Expected: PASS.

- [ ] **Step 3: Commit release probe**

Commit PowerShell probe.

### Task 4: Isolated distribution metadata fixes

**Files:**
- Modify: `game/chronica-harun/export_presets.cfg`
- Modify: `game/chronica-harun/distribution/release_manifest.json`

**Interfaces:**
- Consumes: release version `0.12-recovery`, implemented camera modes.
- Produces: deterministic Windows version-resource fields and accurate camera-mode distribution metadata.

- [ ] **Step 1: Add contract assertions for metadata**

Extend `test_windows_native_qa_contract.py` to require product/file description, version fields, copyright-neutral product metadata, and a camera contract that names `first_person` default plus `over_shoulder` alternate. The test must fail against the base metadata.

- [ ] **Step 2: Update metadata minimally**

Set Windows resource strings/version fields in the export preset. Do not invent `application/icon`; leave it empty and preserve icon absence as a blocker. Replace stale `first_person_only` manifest metadata with explicit camera modes/default.

- [ ] **Step 3: Run test and commit**

Expected: PASS.

### Task 5: Windows GitHub Actions workflow

**Files:**
- Create: `.github/workflows/chronica-windows-native-qa.yml`

**Interfaces:**
- Consumes: tasks 1-4.
- Produces: automated Windows-native run and `chronica-windows-native-qa` artifact.

- [ ] **Step 1: Add workflow**

Use `windows-latest`; checkout the QA branch commit; setup Python 3.12; install pytest/trimesh/numpy; run existing model generation/tests/validators; download Godot 4.3 stable Windows and export templates; import project; run `WindowsNativeQA.tscn`; export release; run `windows_release_probe.ps1`; generate Markdown/JSON matrix; upload EXE/ZIP/hash/logs/report/screenshot-if-present.

The workflow must trigger on `workflow_dispatch` and pushes to `qa/chronica-windows-visual-v1` so its creation triggers a real run.

- [ ] **Step 2: Commit workflow**

The push should start the first Windows-native QA run.

### Task 6: Observe CI, repair only evidenced QA defects, finalize report

**Files:**
- Create/update: `game/chronica-harun/runtime_qa/windows_native/QA_REPORT.md`
- Potentially modify only QA harness/workflow/probe/metadata files when run evidence proves a defect.

**Interfaces:**
- Consumes: GitHub Actions run/jobs/logs/artifacts.
- Produces: concrete final HEAD, commit list, run ID, Godot version, runner, EXE launch result, save/load/retry/input/PE/resource results, artifact ID, SHA-256, QA matrix, blockers, and `VISUAL QA NOT VERIFIED` when appropriate.

- [ ] **Step 1: Inspect run/jobs/logs**

Fetch the workflow run created by the workflow commit. If a QA infrastructure defect occurs, fix the smallest proven issue and let push trigger a new run. Never change gameplay to make CI green.

- [ ] **Step 2: Fetch artifact evidence**

Record artifact ID, EXE SHA-256 and probe/report evidence. Inspect screenshot only if a real non-trivial capture exists; otherwise keep visual items `NOT TESTABLE IN CI`.

- [ ] **Step 3: Commit final QA report**

Commit concrete evidence and blockers to `QA_REPORT.md`. Do not merge.

- [ ] **Step 4: Verify final branch state**

Confirm branch HEAD, changed paths, and absence of merges.
