# CHRONICA HARUN · Windows Native QA + Release Readiness Design

## Scope

This front is limited to Windows-native QA and distribution readiness for `game/chronica-harun` on branch `qa/chronica-windows-visual-v1`, based on `feat/chronica-combat-v2` commit `4342dcdaf154de952620208ca36f1ab0e76b228e`.

No merge to `main` or any integration branch is permitted. Narrative and gameplay behavior are frozen. Production changes are limited to isolated, evidenced release-metadata fixes.

## Governing distinction

The pipeline must never equate headless/runtime automation with visual QA. Results are classified only as:

- `PASS`
- `FAIL`
- `NOT TESTABLE IN CI`

When an interactive/GPU-capable desktop cannot be demonstrated, the report must include the literal line:

`VISUAL QA NOT VERIFIED`

## Architecture

A dedicated GitHub Actions workflow runs on `windows-latest` and installs Godot 4.3 stable Windows x86_64 plus 4.3 stable export templates. It executes the existing Python suite and validators, performs a strict Godot import, runs a Windows-native QA harness, exports `CHRONICA_HARUN.exe`, launches the exported EXE for a native smoke window, validates the PE structure/resources, packages a ZIP, verifies ZIP integrity, computes SHA-256, and uploads a consolidated artifact.

The harness is a Godot scene/script under `runtime_qa/windows_native` rather than a gameplay modification. It validates OS identity, main-scene configuration, `user://` save path resolution, new campaign defaults, save/load round-trip, retry/reload persistence, InputMap actions, camera-mode toggle contract, and window/resolution state that can be queried without claiming visual proof.

A PowerShell release probe inspects the exported executable as PE/PE32+, checks the AMD64 machine type, extracts Windows version resources where available, detects icon resources, performs a timed native launch, creates the ZIP, verifies extraction, and writes machine-readable results.

## Release metadata policy

The current Windows export path is already `build/windows/CHRONICA_HARUN.exe`. The current preset contains `application/icon=""`, and no canonical icon asset exists in the base tree. Therefore this QA front must not invent branding artwork. Missing icon metadata remains a real release blocker unless a canonical icon is supplied by the art/branding owner.

Version-resource metadata may be added to the Windows export preset because it is deterministic distribution metadata and does not alter gameplay. The source version is the release manifest version `0.12-recovery`; Windows numeric resource fields use `0.12.0.0`, while product/file description strings preserve `CHRONICA HARUN` and the release label.

The stale distribution runtime contract `first_person_only: true` conflicts with the implemented and tested camera toggle. As an isolated distribution-metadata correction, the manifest will describe first person as default while exposing the implemented `over_shoulder` alternate mode.

## Windows-native checks

The CI matrix covers:

- Godot version 4.3 stable
- Windows runner identity
- existing Python test suite and validators
- strict Godot import
- main scene configured and loadable
- Windows-native runtime harness
- save path under Windows user data
- new campaign
- save/load round-trip
- retry/reload
- required input actions
- default camera mode and camera toggle contract
- configured/default viewport/window information
- Windows export filename
- native EXE process launch and no immediate crash
- DOS `MZ`, PE signature, PE32+ optional header and AMD64 machine (`0x8664`)
- Windows version-resource inspection
- icon-resource inspection
- ZIP creation and extraction integrity
- SHA-256
- artifact publication

## Visual evidence

The workflow may attempt a screenshot only when a desktop capture API produces a non-trivial bitmap after a normal EXE launch. A captured bitmap is evidence that a desktop surface was available, not automatic proof of final visual quality. Final visual render, GPU behavior, fullscreen behavior, physical mouse pointer lock, and VFX quality remain `NOT TESTABLE IN CI` unless explicitly evidenced and manually inspected.

## Reporting

`runtime-qa/windows-native/qa-report.md` and `qa-report.json` are generated from the workflow evidence. CI logs and release files are uploaded as the `chronica-windows-native-qa` artifact. The committed source report template documents static findings and is updated after a completed workflow run with concrete run/artifact identifiers when available.
