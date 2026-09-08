# CHRONICA HARUN · WINDOWS NATIVE QA + RELEASE READINESS

## Final evidence record

- Branch: `qa/chronica-windows-visual-v1`
- Exact base: `feat/chronica-combat-v2` @ `4342dcdaf154de952620208ca36f1ab0e76b228e`
- Windows-native code/config validation commit: `0ce4082f6c0fca7a52479f24e784a13e2bd78eab`
- Primary evidence run: GitHub Actions `34176749910` (`CHRONICA HARUN Windows Native QA`, run #9)
- Primary artifact ID: `10037535853`
- Artifact digest: `sha256:6bbfcb3e4de1a58c16a6549e1d0a8de50bb63e5f57169be9a5c671e06b0d4cec`
- Artifact retention expiry: `2026-09-22T01:29:39Z`
- Runner: Microsoft Windows Server 2025, image `windows-2025-vs2026`, `X64`
- Godot: `4.3.stable.official.77dcf97d8`
- Python: `3.12.10`
- rcedit: `2.0.0` x64, SHA-256 `3e7801db1a5edbec91b49a24a094aad776cb4515488ea5a4ca2289c400eade2a`

No merge to `main` or `integration/chronica-final-v1` was performed.

## Pipeline result

The Windows-native pipeline reached the distribution probe. The job conclusion is intentionally `failure` because one real release blocker remains: no canonical custom Windows icon is configured. The failure is not a crash, test regression, PE error, packaging error, or rcedit failure.

The earlier `Could not start rcedit executable` warning was reproduced on Windows-native CI before the fix. The workflow now installs and resolves rcedit before export. On run `34176749910`, the Windows export step completed successfully and the warning did not recur. Version resources were stamped and read back from the exported executable.

## Test and validator evidence

- Procedural QA asset generation: `82` enemy GLBs + `16` boss GLBs: PASS
- Pytest suite: `94 passed in 0.44s`: PASS
- Complete game validator: `COMPLETE GAME VALIDATION: PASS`
- Story validator: `CHRONICA STORY CANON VALIDATION: PASS`
- Strict Godot import: PASS
- Windows-native runtime harness: `WINDOWS_QA_RUNTIME_PASS`

The original baseline contained 90 tests. This front adds four Windows QA contract tests, producing the current 94-test total.

## Windows runtime evidence

The Godot runtime harness executed on the Windows runner with:

- `WINDOWS_QA_OS=Windows`
- `WINDOWS_QA_DISPLAY_DRIVER=headless`
- main scene: `res://scenes/boot/Main.tscn`
- resolved save path: `C:/Users/runneradmin/AppData/Roaming/Godot/app_userdata/CHRONICA HARUN/chronica_harun_campaign.json`
- new campaign: PASS
- save/load round-trip: PASS
- input map: PASS
- camera default/toggle contract: PASS (`first_person -> over_shoulder -> first_person`)
- viewport configuration: `1920x1080`
- window override: `1280x720`
- `Engine.max_fps=0` (engine cap is uncapped by default)
- distribution 1080p quality target: `60 FPS`
- retry/reload two-phase persistence: PASS

The headless harness does not prove physical pointer lock, final rendering, GPU behavior, fullscreen behavior, or VFX quality.

## Native EXE / PE / package evidence

Exported executable:

- filename: `CHRONICA_HARUN.exe`: PASS
- size: `87,854,800` bytes
- SHA-256: `66b0b248f5b1edc767ae29a10cb2044305cc7fd7725658ea57c03d02d57cebd7`
- DOS signature `MZ`: PASS
- PE signature: PASS
- machine: `0x8664` / AMD64: PASS
- optional header: `0x20b` / PE32+: PASS
- native process launch: PASS
- no immediate crash: PASS
- observed smoke lifetime before controlled termination: `11.64 s`

Windows version resources read back from the exported EXE:

- FileVersion: `0.12.0.0`
- ProductVersion: `0.12.0.0`
- CompanyName: `SOCIETAS ELECTORUM`
- ProductName: `CHRONICA HARUN`
- FileDescription: `CHRONICA HARUN`
- version metadata: PASS

Icon resources:

- `RT_ICON`: present
- `RT_GROUP_ICON`: present
- PE icon-resource structure: PASS
- `application/icon`: empty
- canonical custom project icon configured: FAIL

The PE therefore contains icon resources from the Windows template, but it does not contain a project-owned canonical CHRONICA HARUN icon configured by this repository. This distinction is intentional and prevents a template/default icon from being mislabeled as release branding.

Package:

- ZIP: `CHRONICA_HARUN-Windows-x86_64.zip`
- archive extraction: PASS
- extracted EXE byte hash equals source EXE: PASS
- ZIP integrity: PASS

The Windows-native rebuilt EXE SHA differs from the coordinator RC SHA `038402a48ab94492ea52e49beb08080fdf41f38b1104618f715caf57e9665190` because this build includes the Windows resource-metadata changes and was rebuilt natively. The current Windows-native candidate SHA is the one recorded above.

## Screenshot evidence

The normal exported EXE launch produced `runtime-qa/windows-native/windows-native-smoke.png` (1024x768 desktop capture, 30,213 bytes). Manual inspection of the captured frame confirms that a game frame was present: HUD text includes `O OLHO · PERCEPÇÃO`, `CÂMERA · PRIMEIRA PESSOA`, a central crosshair, lower HUD/loadout text, and rendered gray geometry on the right side of a predominantly dark scene.

This is evidence of a rendered frame during the native smoke process. It is not an interactive human QA session and does not establish final visual quality, GPU correctness, real fullscreen behavior, physical mouse capture, or VFX quality.

**VISUAL QA NOT VERIFIED**

## QA matrix

| Check | Result | Evidence |
|---|---|---|
| Windows runner | PASS | Windows Server 2025 / X64 |
| Godot 4.3 | PASS | `4.3.stable.official.77dcf97d8` |
| Python suite | PASS | 94 passed |
| Complete validator | PASS | explicit PASS marker |
| Story validator | PASS | explicit PASS marker |
| Strict import | PASS | Windows Godot import |
| Main scene | PASS | `Main.tscn` runtime assertion |
| Windows save path | PASS | resolved AppData Godot path |
| New campaign | PASS | runtime assertion |
| Save/load | PASS | round-trip marker restored |
| Retry/reload | PASS | two-phase scene reload + persisted marker |
| Input map | PASS | required actions asserted |
| Camera default/toggle contract | PASS | first-person / over-shoulder / first-person |
| Resolution configuration | PASS | viewport 1920x1080, window override 1280x720 |
| FPS configuration | PASS | Engine cap 0; 1080p quality target 60 FPS |
| `CHRONICA_HARUN.exe` exact name | PASS | exported file |
| Native EXE launch | PASS | process remained alive beyond smoke window |
| No immediate crash | PASS | 11.64 s smoke lifetime |
| PE validity | PASS | MZ + PE + PE32+ |
| x86_64 architecture | PASS | machine 0x8664 |
| rcedit availability | PASS | resolved `rcedit.exe` 2.0.0 x64 |
| rcedit stamping warning | PASS | warning absent after tool installation |
| Version resource metadata | PASS | FileVersionInfo read-back |
| PE icon resources | PASS | RT_ICON + RT_GROUP_ICON exist |
| Canonical custom icon configured | FAIL | `application/icon=""` and no canonical icon asset in base |
| ZIP integrity | PASS | extraction + SHA equality |
| SHA-256 generation | PASS | exact hash recorded |
| Screenshot capture | PASS | native smoke PNG artifact exists |
| Final visual quality | NOT TESTABLE IN CI | no interactive visual acceptance |
| Physical mouse pointer lock | NOT TESTABLE IN CI | headless harness/native smoke insufficient |
| GPU behavior | NOT TESTABLE IN CI | no controlled GPU acceptance session |
| VFX quality | NOT TESTABLE IN CI | no interactive visual acceptance |
| Real fullscreen behavior | NOT TESTABLE IN CI | no interactive desktop acceptance |

## Real blockers

### BLOCKER 1: canonical Windows icon missing

`export_presets.cfg` intentionally remains `application/icon=""`. No canonical `.ico` release asset exists in the exact base tree. This QA front did not invent or synthesize branding artwork. Distribution should not be declared fully release-ready until a canonical CHRONICA HARUN Windows icon is supplied, configured, exported, and the Windows-native workflow is rerun.

### Residual manual acceptance gate

The build can launch and render a captured frame in hosted Windows CI, but final visual presentation still requires a real interactive desktop/GPU QA pass for pointer lock, fullscreen transitions, VFX quality, and final scene appearance.

## Material workflow run history

- `34176059866`: first Windows workflow attempt; infrastructure failure from Windows default text encoding while reading Unicode project data.
- `34176208241`: UTF-8 fixed; baseline 90 tests passed and four new Windows QA contract tests failed RED as intended because harness/probe/metadata were not implemented yet.
- `34176454952`: 94 tests + validators + Windows runtime harness passed; Windows export reproduced `Could not start rcedit executable`, proving the stamping dependency was absent.
- `34176749910`: rcedit installed/resolved; export and resource stamping passed; PE/native launch/package checks passed; final gate fails only on missing canonical custom icon.

## Integration boundary

The integration owner should bring this branch forward without altering the evidence semantics. In particular:

1. preserve `VISUAL QA NOT VERIFIED` until an actual interactive acceptance pass exists;
2. preserve the custom-icon failure until a canonical icon asset is supplied;
3. do not interpret PE template icon resources as proof of final project branding;
4. do not convert `NOT TESTABLE IN CI` rows into PASS;
5. rerun `CHRONICA HARUN Windows Native QA` after integration and after any icon configuration;
6. do not merge this QA branch directly to `main` as part of this front.
