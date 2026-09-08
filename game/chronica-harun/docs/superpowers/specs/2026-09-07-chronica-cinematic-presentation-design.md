# CHRONICA HARUN Cinematic Presentation Design

## Scope
Transform the already-canonized CHRONICA HARUN narrative runtime into a cinematic, playable presentation without changing canon, bosses, combat design, roguelite catalogs, or institutional/backend state.

Branch: `feat/chronica-cinematics-v1`
Base: `4342dcdaf154de952620208ca36f1ab0e76b228e`

## Non-negotiable canon
- Preserve all 13 prologue sequences and their order/duration contracts.
- Preserve provenance classes: `source`, `tradition`, `interpretation`, `electorum_dramatization`.
- Preserve the 5-fragment gate before `GRIMORIUM ASCENSIONIS`.
- Preserve `VER -> GOVERNAR -> FAZER`.
- Preserve first-run skip lock and post-completion skip unlock with persistence.
- Preserve Student + Initiation journey semantics, Codex unlocks, Aleppo c.1585 epilogue, Nadir, second shadow, and final word `LUCIFER` followed by cut to black.
- Do not write institutional grade/certification state.

## Architecture
Narrative directors remain semantic/state owners. Rendering remains outside the story directors.

`NarrativeRuntimeBridge` emits semantic cinematic payloads. A new `CinematicPresentationDirector` resolves those payloads into staging instructions for a dedicated cinematic layer containing a `Camera3D`, environmental lighting, procedural proxy geometry, transition overlays, and post-process-like full-screen treatment. It never mutates combat mechanics.

`NarrativePresentationController` remains responsible for UI/letterbox/subtitles/messages/choices, but gains transition, blackout, title-reveal, command-reveal, and gameplay-handoff controls. Text remains sparse and timed; silence is represented as an intentional state rather than an empty subtitle bug.

`Main.tscn` instantiates `NarrativeRuntime.tscn`. `Main.gd` binds it to the existing `StageDirector`, starts the narrative entry flow, suppresses gameplay presentation/control while a blocking cinematic is active, and restores first-person gameplay at handoff. The FPS camera itself is not rewritten.

## Cinematic staging
### Prologue
Each Story Bible shot drives:
- camera profile: slow hold / controlled reveal / intimate / historical match-cut / first-person investigation / seamless first-person handoff;
- transition: `fade_from_black`, `match_cut`, `slow_dissolve`, `hard_reframe`, `motivated_cut`;
- tension scalar;
- semantic visual event;
- semantic audio event.

When final production assets are absent, procedural staging uses deliberately abstract proxy forms, light, fog/depth, and camera motion. These remain labeled runtime proxies, never final cinematic art.

### Dread rule
Presentation follows `dread_before_explanation`: consequence or anomaly appears first, explanatory text stays delayed/sparse, and several beats intentionally carry no subtitle.

### Grimorium
The title reveal cannot occur until all five canonical fragment ids are persisted. The presentation displays fragment accumulation as a restrained visual assembly, then reveals `GRIMORIUM ASCENSIONIS`. Commands appear as isolated beats in exact order `VER`, `GOVERNAR`, `FAZER`.

### Gameplay handoff
The final `see_govern_make` shot transitions from cinematic framing into the actual player camera. HUD remains hidden until gameplay handoff. Control resumes only after the handoff signal; the narrative runtime never rewrites combat code.

### Epilogue
Aleppo c.1585 uses warm low-key staging, Nadir framing hooks, an impossible second-shadow cue, final isolated `LUCIFER`, then a mandatory full black frame before the continuity target is emitted.

## Presentation UI
`NarrativePresentation.tscn` gains:
- full-screen blackout/fade overlay;
- cinematic vignette/veil layer;
- dedicated large reveal label;
- fragment counter/status treatment;
- optional scene/shot debug evidence label available only in QA mode;
- existing choice panel preserved.

`NarrativePresentationController.gd` gains a small state machine for cinematic phase, fade envelopes, sparse subtitle handling, skip availability refresh, fragment/title/command reveals, and final-black behavior.

## Runtime integration
`NarrativeRuntimeBridge` gains explicit signals for:
- fragment progress;
- title reveal;
- command reveal;
- cinematic sequence start/end;
- gameplay handoff;
- final black.

The bridge keeps Codex unlocks synchronized at scene/stage/epilogue boundaries.

## Tests
Add contract tests before production changes for:
1. Main scene/runtime integration and entry flow.
2. Dedicated cinematic presentation director and scene nodes.
3. all 13 prologue sequences in order and duration contract preservation.
4. first-run skip lock and persisted unlock.
5. five fragments before title reveal.
6. exact `VER -> GOVERNAR -> FAZER` order.
7. sparse presentation and silence support.
8. Codex synchronization.
9. gameplay handoff to `o_olho` without combat rewrites.
10. Aleppo epilogue, second-shadow hook, `LUCIFER`, mandatory final black.
11. cinematic asset manifest coverage and explicit proxy/final status.

A GitHub Actions gate on this branch runs pytest, story validator, complete validator, Godot 4.3 import, Main boot, dedicated narrative runtime probe, and captures runtime evidence artifacts.

## Asset policy
Existing manifest contracts are authoritative. Missing production assets are reported as missing. Procedural proxies may satisfy runtime staging but are not reported as final assets.

## Out of scope
- boss redesign;
- AI/combat changes;
- roguelite balance/catalog changes;
- backend/institutional progression;
- canon rewrites;
- merge to main or integration branches.
