# CHRONICA HARUN Roguelite Reconciliation V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reconciliar a profundidade roguelite histórica com a árvore combat-v2 atual, preservando catálogos canônicos, runtime de salas, buildcraft, segredos, metaprogressão e todos os gates já verdes.

**Architecture:** A árvore `feat/chronica-roguelite-reconcile-v2` governa e a branch `feat/chronica-roguelite-depth` serve apenas como referência semântica. As correções serão data-driven e isoladas em `game/chronica-harun`, mantendo `ContentRegistry`, `RogueliteContentService`, `BuildResolver`, `GameplayEffectBus`, `SpecialRoomDirector`, `SpecialRoomRuntime`, `MetaRunDirector` e `GameState` com responsabilidades separadas.

**Tech Stack:** Godot 4.3 / GDScript, Python 3 / pytest, JSON data catalogs, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-07-chronica-roguelite-reconcile-v2-design.md`

## Global Constraints

- Branch exclusiva: `feat/chronica-roguelite-reconcile-v2`.
- Base governante inicial: `4342dcdaf154de952620208ca36f1ab0e76b228e`.
- Não fazer merge em `main`.
- Não fazer merge em `integration/chronica-final-v1`.
- Não reescrever narrativa.
- Não redesenhar IA/inimigos/bosses.
- Não alterar backend institucional.
- Preservar `SpecialRoomDirector.eligible_rooms(..., for_generation)` e a regra de que `min_rooms_cleared` não bloqueia geração.
- Tarot = 78; Sigilla = 72; nunca misturar contagens.
- Não recriar `tarot.json`, `sigilla.json` ou `talismans.json`.
- TDD para bugs e lacunas.

---

### Task 1: Auditoria semântica e anti-duplicação

**Files:**
- Modify: `game/chronica-harun/tests/test_front_c_parity.py`
- Read: `game/chronica-harun/autoload/ContentRegistry.gd`
- Read: `game/chronica-harun/data/roguelite/*`

**Interfaces:**
- Consumes: `ContentRegistry.FILES`, catálogos atuais.
- Produces: testes que proíbem nomes legados e fixam contagens canônicas.

- [ ] **Step 1: Escrever teste RED de anti-duplicação**

Adicionar asserts para ausência de `tarot.json`, `sigilla.json`, `talismans.json` e para presença dos nomes canônicos no `ContentRegistry`.

- [ ] **Step 2: Rodar teste e registrar resultado**

Run: `pytest -q game/chronica-harun/tests/test_front_c_parity.py`
Expected: PASS se a árvore já estiver corretamente reconciliada; qualquer falha vira lacuna real.

- [ ] **Step 3: Corrigir somente se houver falha**

Ajustar `ContentRegistry.gd` ou remover duplicata apenas quando evidenciado pelo teste.

- [ ] **Step 4: Commit**

`test: lock canonical roguelite catalogs`

### Task 2: Buildcraft end-to-end e cobertura de efeitos

**Files:**
- Modify: `game/chronica-harun/tests/test_front_c_parity.py`
- Modify/Create: `game/chronica-harun/tests/test_roguelite_buildcraft_runtime.py`
- Modify: `game/chronica-harun/autoload/RogueliteContentService.gd`
- Modify: `game/chronica-harun/scripts/content/BuildResolver.gd`
- Modify only if required: `game/chronica-harun/scripts/content/GameplayEffectBus.gd`

**Interfaces:**
- Consumes: `RogueliteContentService.grant/use_*`, `ContentRegistry.get_item`, `GameplayEffectBus.dispatch`.
- Produces: resolução de build observável e data-driven para sinergias, exclusões, transformações e persistência.

- [ ] **Step 1: Escrever testes RED para grant -> slot -> uso/carga -> efeito**

Cobrir Arcana, Pharmaka, Sigilla, Instrumenta, Talismans, Relics, Daimones e mutations.

- [ ] **Step 2: Escrever testes RED para sinergias/exclusões**

O teste deve usar os campos reais `synergies` e `exclusions` dos catálogos, sem inventar IDs.

- [ ] **Step 3: Escrever teste RED para transformação elegível**

O resolver deve retornar transformações cuja condição esteja satisfeita pelo build/estado atual.

- [ ] **Step 4: Implementar mínima resolução genérica**

Adicionar ao `BuildResolver` funções focadas para coletar IDs do build, validar exclusões, detectar sinergias e retornar `eligible_transformations`, sem reescrever combate.

- [ ] **Step 5: Implementar somente os hooks de aquisição/uso ausentes**

Manter slots e consumo/cargas existentes. Adicionar apenas caminhos que o teste demonstrar ausentes.

- [ ] **Step 6: Rodar testes focados**

Run: `pytest -q game/chronica-harun/tests/test_front_c_parity.py game/chronica-harun/tests/test_roguelite_buildcraft_runtime.py`
Expected: PASS.

- [ ] **Step 7: Commit**

`feat: reconcile roguelite buildcraft runtime`

### Task 3: Salas especiais e geração física

**Files:**
- Modify/Create: `game/chronica-harun/tests/test_special_room_runtime_reconcile.py`
- Modify if required: `game/chronica-harun/scripts/generation/SpecialRoomDirector.gd`
- Modify if required: `game/chronica-harun/scripts/generation/StageFloorBuilder.gd`
- Modify if required: `game/chronica-harun/scripts/rooms/SpecialRoomRuntime.gd`

**Interfaces:**
- Consumes: `eligible_rooms(..., for_generation)`, `roll_floor_rooms`, floor layout builder, `resolve_room`.
- Produces: prova de materialização para todas as famílias canônicas de sala.

- [ ] **Step 1: Escrever teste de preservação do bugfix governante**

Um room com `min_rooms_cleared > 0` deve permanecer elegível com `for_generation=true` e ser bloqueado durante entrada/uso quando `for_generation=false`.

- [ ] **Step 2: Escrever teste de catálogo de salas**

Cobrir IDs atuais correspondentes a Arcana, Reliquarium, Instrumentarium, Laboratorium, Sigillar, Essence Market, Bibliotheca, Speculum, Planetary, Trial, Cursed, Secret, Super Secret, Archon, Theophany, Historical, Initiation, Pneumatic, Chthonic e Pact.

- [ ] **Step 3: Escrever teste de caminho físico**

Para cada sala selecionada pelo gerador, o floor builder deve criar entrada/slot físico ou representação de conexão que possa ser instanciada pelo runtime.

- [ ] **Step 4: Corrigir apenas lacunas comprovadas**

Não alterar probabilidades ou design fora do necessário para garantir caminho físico/runtime.

- [ ] **Step 5: Rodar testes focados**

Expected: PASS.

- [ ] **Step 6: Commit**

`feat: reconcile special room generation runtime`

### Task 4: Secret e Super Secret

**Files:**
- Modify: `game/chronica-harun/tests/test_special_room_runtime_reconcile.py`
- Modify if required: `game/chronica-harun/scripts/generation/SpecialRoomDirector.gd`
- Modify if required: `game/chronica-harun/scripts/generation/StageFloorBuilder.gd`
- Modify if required: `game/chronica-harun/scripts/rooms/SpecialRoomRuntime.gd`
- Modify if required: `game/chronica-harun/autoload/GameState.gd`

**Interfaces:**
- Consumes: `MAX_SECRET_ROOMS`, `can_open_secret`, `GameState.run_stats.rupture_charges`.
- Produces: ocultação, ruptura, consumo e persistência de descoberta.

- [ ] **Step 1: Escrever testes RED para limite físico <= 2**
- [ ] **Step 2: Escrever teste RED para ocultação pré-ruptura**
- [ ] **Step 3: Escrever teste RED para recurso correto e consumo de 1 carga**
- [ ] **Step 4: Escrever teste RED para requisitos adicionais da Super Secret**
- [ ] **Step 5: Implementar mínima transição `hidden -> revealed/open`**
- [ ] **Step 6: Persistir `secret_found`, `super_secret_found` e carga restante no snapshot**
- [ ] **Step 7: Rodar testes focados e commit**

Commit: `fix: make secret rooms physically stateful`

### Task 5: Metarun, pós-boss, gauntlets e endings

**Files:**
- Modify/Create: `game/chronica-harun/tests/test_roguelite_meta_runtime.py`
- Modify if required: `game/chronica-harun/scripts/progression/MetaRunDirector.gd`
- Modify if required: `game/chronica-harun/autoload/GameState.gd`

**Interfaces:**
- Consumes: routes/curses/blessings/gauntlets/completion marks/post-boss state.
- Produces: estado serializável e mutuamente exclusivo.

- [ ] **Step 1: Testar escolha pós-boss única entre `pneumatic`, `chthonic`, `pact_table`**
- [ ] **Step 2: Testar alternate route round-trip de save**
- [ ] **Step 3: Testar completion marks por personagem**
- [ ] **Step 4: Testar unlock e modifiers de gauntlet/boss rush**
- [ ] **Step 5: Auditar caminho de endings e adicionar bridge somente se ausente**
- [ ] **Step 6: Confirmar ausência de `real_progress_gate` e institutional writes**
- [ ] **Step 7: Rodar testes e commit**

Commit: `feat: reconcile roguelite metarun progression`

### Task 6: Gate CI completo Godot 4.3

**Files:**
- Create/Modify if required: `.github/workflows/chronica-roguelite-reconcile-v2.yml`
- Modify: `game/chronica-harun/scripts/boot/DepthRuntimeSmoke.gd` only if a new smoke assertion is required.

**Interfaces:**
- Consumes: full repository branch.
- Produces: evidência executável de pytest, validators, Godot import e runtime.

- [ ] **Step 1: Garantir workflow exclusivo da branch C2**

Workflow em `push` para `feat/chronica-roguelite-reconcile-v2`, sem writes automáticos de catálogo.

- [ ] **Step 2: Rodar `pytest -q game/chronica-harun/tests`**
- [ ] **Step 3: Rodar `validate_complete_game.py`**
- [ ] **Step 4: Rodar `validate_story_canon.py`**
- [ ] **Step 5: Instalar/usar Godot 4.3 e importar projeto headless**
- [ ] **Step 6: Executar smoke/runtime roguelite**
- [ ] **Step 7: Falhar workflow em `SCRIPT ERROR`, `Parse Error` ou regressão de validator**
- [ ] **Step 8: Commit**

Commit: `test: run roguelite reconciliation green gate`

### Task 7: Checkpoint, Drive e handoff de integração

**Files:**
- Create: `docs/chronica/CHRONICA_HARUN_FRENTE_C2_RECONCILIATION_FINAL_2026-09-07.md`

**Interfaces:**
- Consumes: HEAD final e evidências do CI.
- Produces: documento final e cópia no Google Drive.

- [ ] **Step 1: Registrar branch, HEAD, commits e diffs da frente**
- [ ] **Step 2: Registrar catálogos, contagens e sistemas funcionais**
- [ ] **Step 3: Registrar lacunas encontradas e correções efetivas**
- [ ] **Step 4: Registrar testes/salas/buildcraft/validators/Godot com IDs de runs**
- [ ] **Step 5: Registrar limitações reais sem inflar conclusão**
- [ ] **Step 6: Commit do checkpoint**

Commit: `docs: save final CHRONICA Frente C2 checkpoint`

- [ ] **Step 7: Salvar cópia do checkpoint no Google Drive**
- [ ] **Step 8: Entregar prompt para a aba principal integrar conscientemente a branch C2**

## Self-review

Coverage: catálogos canônicos e anti-duplicação, buildcraft end-to-end, salas especiais, segredos físicos, pós-boss, rotas, curses, blessings, transformations, completion marks, gauntlets/boss rush, endings, metaprogressão, save/load, institutional anti-regression, pytest, validators e Godot 4.3 estão mapeados. Nenhuma tarefa exige alteração narrativa, IA, bosses ou backend institucional.
