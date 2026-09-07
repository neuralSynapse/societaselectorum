# CHRONICA HARUN Roguelite Depth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reconstruir e implementar a camada Godot data-driven de buildcraft, salas especiais, segredos e metarun da Frente C com catálogos completos chegando ao runtime.

**Architecture:** O projeto isolado vive em `game/chronica-harun`. Catálogos JSON obedecem a um contrato comum e são carregados por um serviço Godot. Resolvers pequenos e independentes convertem conteúdo em alterações serializáveis de estado e eventos de gameplay, enquanto salas e metarun mantêm regras próprias sem tocar combate, narrativa ou backend.

**Tech Stack:** Godot 4 / GDScript, JSON, Python 3 + pytest para validação estática.

**Spec:** `docs/superpowers/specs/2026-09-07-chronica-roguelite-depth-design.md`

## Global Constraints

- Branch exclusiva `feat/chronica-roguelite-depth`; nunca fazer merge em `main` nesta frente.
- Não modificar `mundus/chronica-harun/backend/`.
- Gameplay não escreve `real_progress_gate` nem qualquer Grau institucional.
- Tarot = 78, Sigilla = 72, Pharmaka = 21, Talismãs = 36, Instrumenta = 32, Poderes = 15, Mutações = 45, Daimones = 7, Relíquias >= 9, Transformações >= 10, Maldições >= 8, Bênçãos >= 6, Rotas = 8.
- Cada registro possui o contrato comum definido na spec.
- Até duas salas secretas por andar quando o layout suporta.
- Segredo exige abertura física por recurso/tag compatível.
- Pós-chefe oferece escolhas autorais condicionais e mutuamente exclusivas.
- Conteúdo sem nome histórico/canônico fixado é marcado como `dramatizacao_electorum`.

---

### Task 1: Fundação Godot + contrato de conteúdo

**Files:**
- Create: `game/chronica-harun/project.godot`
- Create: `game/chronica-harun/autoload/GameState.gd`
- Create: `game/chronica-harun/autoload/RogueliteContentService.gd`
- Create: `game/chronica-harun/scripts/content/GameplayEffectBus.gd`
- Create: `game/chronica-harun/tests/test_catalog_contracts.py`
- Create: `game/chronica-harun/tools/generate_roguelite_catalogs.py`

**Interfaces:**
- Produces: `RogueliteContentService.get_entry(id)`, `get_pool(pool)`, `eligible_entries(pool, context)`.
- Produces: `GameState.snapshot_run()` e `restore_run(snapshot)`.

- [ ] **Step 1: Write failing contract test**

```python
def test_required_catalog_counts(catalogs):
    assert len(catalogs['tarot']) == 78
    assert len(catalogs['sigilla']) == 72
    assert len(catalogs['pharmaka']) == 21
    assert len(catalogs['talismans']) == 36
    assert len(catalogs['instrumenta']) == 32
    assert len(catalogs['powers']) == 15
    assert len(catalogs['mutations']) == 45
    assert len(catalogs['daimones']) == 7
```

- [ ] **Step 2: Run RED**

Run: `pytest -q game/chronica-harun/tests/test_catalog_contracts.py`
Expected: FAIL because catalogs do not exist.

- [ ] **Step 3: Implement generator + Godot loader**

Generator writes every catalog with the exact common fields. `RogueliteContentService` loads all JSON files, rejects malformed records and indexes IDs/pools.

- [ ] **Step 4: Run GREEN and regression**

Run: `pytest -q game/chronica-harun/tests/test_catalog_contracts.py`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add game/chronica-harun
git commit -m "feat: reconstruct roguelite content foundation"
```

### Task 2: Buildcraft e Tarot/Sigilla despacháveis

**Files:**
- Create: `game/chronica-harun/scripts/content/BuildResolver.gd`
- Create: `game/chronica-harun/tests/test_buildcraft.py`
- Modify: generated catalog JSON files.

**Interfaces:**
- Consumes: common content record and run context dictionary.
- Produces: `BuildResolver.resolve(entry, context) -> Dictionary` with `state_changes`, `events`, `synergies_triggered`, `blocked_by`, `consumed`.

- [ ] **Step 1: Write failing tests for all effect kinds and cross-synergy references**

```python
def test_every_tarot_effect_is_dispatchable(catalogs, supported_effects):
    assert all(card['effect']['kind'] in supported_effects for card in catalogs['tarot'])

def test_synergy_targets_exist(catalogs, all_ids):
    for records in catalogs.values():
        for record in records:
            assert set(record['synergies']).issubset(all_ids | set(record.get('synergy_tags', [])))
```

- [ ] **Step 2: Run RED**

Run: `pytest -q game/chronica-harun/tests/test_buildcraft.py`
Expected: FAIL until resolver/effect vocabulary exists.

- [ ] **Step 3: Implement resolver**

Support stacking modes `none`, `refresh`, `additive`, `multiplicative`, `charges`, `unique_transform`; block exclusions; detect ID/tag synergies; emit generic gameplay events for damage, heal, focus, precision, armor break, reveal, movement, resource, summon/field, room/map operations and timed states.

- [ ] **Step 4: Run GREEN and regression**

Run: `pytest -q game/chronica-harun/tests/test_buildcraft.py game/chronica-harun/tests/test_catalog_contracts.py`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add game/chronica-harun
git commit -m "feat: make roguelite buildcraft effects dispatchable"
```

### Task 3: Salas especiais, segredos e pós-chefe

**Files:**
- Create: `game/chronica-harun/scripts/generation/SpecialRoomDirector.gd`
- Create: `game/chronica-harun/scripts/rooms/SpecialRoomRuntime.gd`
- Create: `game/chronica-harun/scenes/rooms/SpecialRoomRuntime.tscn`
- Create: `game/chronica-harun/tests/test_special_rooms.py`

**Interfaces:**
- Produces: `build_floor_rooms(context, layout_secret_capacity)`.
- Produces: `can_open_secret(room, opener_tags)`.
- Produces: `choose_postboss_options(context)`.
- Produces: `SpecialRoomRuntime.enter_room(room, run_state)` result dictionary.

- [ ] **Step 1: Write failing room tests**

```python
def test_secret_count_never_exceeds_two(room_rules):
    assert room_rules.max_secret_rooms == 2

def test_secret_openers_are_physical(room_records):
    for room in [r for r in room_records if r['room_role'] in {'secret','super_secret'}]:
        assert {'ritual_bomb','rupture_charge','wall_break'} & set(room['entry']['accepted_openers'])

def test_postboss_choices_are_exclusive(room_records):
    post = [r for r in room_records if r.get('postboss')]
    assert all(r['exclusive_group'] == 'postboss_path' for r in post)
```

- [ ] **Step 2: Run RED**

Run: `pytest -q game/chronica-harun/tests/test_special_rooms.py`
Expected: FAIL before runtime/rules exist.

- [ ] **Step 3: Implement director + runtime scene**

Selection is weighted and deterministic from seed/context. Secret placement obeys capacity and maximum two. Discovery emits feedback without labeled secret doors. Entry applies costs, risk and rewards. Post-boss options use `exclusive_group=postboss_path` and `postboss_choice_taken`.

- [ ] **Step 4: Run GREEN and regression**

Run: `pytest -q game/chronica-harun/tests/test_special_rooms.py game/chronica-harun/tests/test_buildcraft.py game/chronica-harun/tests/test_catalog_contracts.py`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add game/chronica-harun
git commit -m "feat: add playable special room and secret routing"
```

### Task 4: Metarun, rotas, curses, blessings, transformações e gauntlets

**Files:**
- Create: `game/chronica-harun/scripts/progression/MetaRunDirector.gd`
- Create: `game/chronica-harun/data/roguelite/gauntlets.json`
- Create: `game/chronica-harun/tests/test_meta_run.py`

**Interfaces:**
- Produces: `select_route(route_id, run_state)`.
- Produces: `apply_curse(id, run_state)`, `apply_blessing(id, run_state)`.
- Produces: `evaluate_transformations(run_state)`.
- Produces: `record_completion(character_id, challenge_id, run_state)`.
- Produces: `start_gauntlet(id, run_state)`.

- [ ] **Step 1: Write failing persistence/metarun tests**

```python
def test_exactly_eight_routes(catalogs):
    assert len(catalogs['routes']) == 8

def test_authorial_meta_content_is_labeled(catalogs):
    for key in ('routes','curses','blessings','transformations'):
        assert all(r['provenance']['level'] == 'dramatizacao_electorum' for r in catalogs[key])
```

- [ ] **Step 2: Run RED**

Run: `pytest -q game/chronica-harun/tests/test_meta_run.py`
Expected: FAIL before director/gauntlet state exists.

- [ ] **Step 3: Implement MetaRunDirector**

Keep all state JSON-serializable. Transformations are set/tag thresholds and never institutional progression. Completion marks key by character and challenge. Gauntlets only alter run modifiers.

- [ ] **Step 4: Run GREEN and full regression**

Run: `pytest -q game/chronica-harun/tests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add game/chronica-harun
git commit -m "feat: add roguelite meta run progression"
```

### Task 5: Smoke scene, global validator e anti-regressão

**Files:**
- Create: `game/chronica-harun/scripts/boot/DepthRuntimeSmoke.gd`
- Create: `game/chronica-harun/scenes/boot/DepthRuntimeSmoke.tscn`
- Create: `game/chronica-harun/tests/test_global_depth_validation.py`
- Create: `game/chronica-harun/README_ROGUELITE_DEPTH.md`

**Interfaces:**
- Smoke scene instantiates content service/directors and validates representative room/build/metarun operations.

- [ ] **Step 1: Write failing global validation**

```python
def test_no_institutional_write_surface(project_text):
    forbidden = ('real_progress_gate =', 'set_real_progress', 'grant_institutional_grade')
    assert not any(token in project_text for token in forbidden)
```

Also validate unique IDs, all references, room count, effect vocabulary, save-safe values and project autoload paths.

- [ ] **Step 2: Run RED**

Run: `pytest -q game/chronica-harun/tests/test_global_depth_validation.py`
Expected: FAIL until smoke/runtime manifest is complete.

- [ ] **Step 3: Implement smoke scene + documentation**

Smoke scene runs without enemies/combat and exercises content load, one card, one sigillum, one Instrumentum, a secret opener, a special room and metarun snapshot.

- [ ] **Step 4: Run full GREEN**

Run: `pytest -q game/chronica-harun/tests`
Expected: all tests pass.

If a Godot 4 executable is available in the execution environment, additionally run:

```bash
godot --headless --path game/chronica-harun --editor --quit
godot --headless --path game/chronica-harun game/chronica-harun/scenes/boot/DepthRuntimeSmoke.tscn --quit
```

Never claim these commands passed unless they were actually executed.

- [ ] **Step 5: Commit**

```bash
git add game/chronica-harun
git commit -m "test: validate CHRONICA roguelite depth runtime"
```

## Self-review

Coverage: catalog counts, common contract, Tarot minors/courts, Sigilla, buildcraft, rooms, secrets, post-boss, metarun, transformations, persistence and institutional anti-regression all map to explicit tasks. No backend files are touched. Direct wiring into the historical Player/Enemy code is intentionally absent because that source is not present in the remote repository and this front is forbidden from rewriting combat.