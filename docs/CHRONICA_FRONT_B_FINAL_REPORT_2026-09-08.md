# CHRONICA HARUN · Frente B · Relatório Final

Data de validação: 2026-09-08

## Escopo

Branch dedicada: `feat/chronica-combat-entities`

A Frente B foi executada sem merge em `main` e sem substituir a versão Godot pelo projeto web. A árvore de trabalho contém a fonte Godot materializada em `game/chronica-harun/` e os sistemas de combate/entities foram validados por CI.

## Estado final validado

- FPS / player runtime preservado.
- World-space de combate com `TelegraphRoot`, `TelegraphOrigin`, `ProjectileOrigin` e `ImpactOrigin` nas cenas de entidades.
- Telegraphs legíveis para `line`, `fan`, `radial`, `zone` e `dash`.
- Projectiles/tracers/impact feedback integrados ao runtime.
- Feedback de dano e impacto integrado.
- Áudio espacial 3D com fallback procedural e variação por família/linhagem para inimigos e bosses.
- Arena automatizável em `scenes/test/CombatEntityArena.tscn` e arena vazia de smoke em `scenes/test/CombatEntityArenaEmpty.tscn`.
- 82 inimigos individualizados com IDs únicos e `model_path` único.
- 82 GLBs de inimigos gerados e validados.
- 16 bosses com IDs/modelos únicos.
- Cada boss possui 3 fases reais com ataques e pelo menos 3 IDs de ataque distintos no conjunto de fases.
- 16 GLBs de bosses gerados e validados.
- Linhagens/famílias influenciam o áudio espacial de windup/shot/phase.
- Runtimes exigidos presentes: `StageDirector.gd`, `StageFloorBuilder.gd`, `BuildResolver.gd`, `PowerMutationRuntime.gd`, `DaimonRuntime.gd`, `SpecialRoomDirector.gd`, `VisionDirector.gd`, `MetaRunDirector.gd`, catálogos, cenas e diretórios de AI/combat.

## Correções finais

1. `DataBossController.gd` passou a usar `AudioDirector.play_enemy_family(...)` para windup, shot e mudança de fase, com família derivada dos metadados do boss.
2. Foi adicionada `CombatEntityArenaEmpty.tscn`, eliminando a lacuna do contrato de arena/smoke.

Commits finais:

- `99c20a0a2420be59da41844c5702dcd78455f230` — `fix: route boss cues through spatial family audio`
- `0691aefcddb84237a4050d6c00912007eb5b6cdb` — `test: add empty combat arena smoke scene`

## Testes literais

Workflow: `CHRONICA Front B Combat`

Run final: `34180501743`

Resultado: `success`

Pytest:

```text
94 passed in 0.36s
```

Model generation:

```text
generated 82 enemy GLBs and 16 boss GLBs
```

Canonical validation:

```text
COMPLETE GAME VALIDATION: PASS
 - Student journey and 82+ enemy forms
 - 16 bosses / 3 phases
 - 78 Tarot / 72 Sigilla / 21 Pharmaka / 36 Talismans
 - 32 Instrumenta / 45 mutations / 7 Daimones
 - special rooms / visions / meta-run / transformations
 - Windows + Linux distribution contract
 - no gameplay institutional-grade writes
```

Narrative anti-regression validation:

```text
CHRONICA STORY CANON VALIDATION: PASS
 - 13 cinematic prologue sequences / 500 seconds
 - provenance boundaries preserved
 - 15 Student stages + Initiation dramatic arcs
 - Aleppo c. 1585 / Nadir / second shadow / LUCIFER continuity
 - 72 production shots / 16 strategic narrative choices
 - narrative runtime directors present
```

Godot:

```text
4.3.stable.official.77dcf97d8
```

- Godot headless import: PASS.
- Combat arena smoke: PASS.
- Marker emitido pelo runtime: `CHRONICA_FRONT_B_ARENA_READY`.

## Observação técnica

Durante o smoke headless com o renderer dummy, o Godot emitiu mensagens `ERROR: Parameter "m" is null` em `mesh_get_surface_count`. Elas não vieram acompanhadas de `SCRIPT ERROR`, `Parse Error`, `Failed to load script`, `Failed loading resource`, `Compilation failed`, `Invalid call` ou `Invalid access`; o processo permaneceu dentro do contrato de smoke e o job concluiu com sucesso. Isso é registrado aqui como ruído do renderer headless/dummy, não como falha de parser, script ou contrato de recurso detectada pela suíte atual.

## Modelos reais versus placeholders

- Os 82 modelos de inimigos e 16 modelos de bosses são GLBs gerados individualmente pelo pipeline `tools/generate_models.py` e têm paths individualizados.
- Os controllers mantêm fallback geométrico de segurança somente para o caso de um `model_path` não resolver em runtime. O caminho normal validado usa os GLBs gerados.

## Screenshots

Não foram produzidos screenshots nesta execução porque a validação final ocorreu em runner headless. O escopo foi comprovado por testes, validators, import headless e arena smoke.

## Blockers

Nenhum blocker funcional remanescente dentro do escopo da Frente B validado pela suíte atual.

## URLs

Branch:

https://github.com/neuralSynapse/societaselectorum/tree/feat/chronica-combat-entities

Workflow final:

https://github.com/neuralSynapse/societaselectorum/actions/runs/34180501743

Nenhum merge em `main` foi executado.
