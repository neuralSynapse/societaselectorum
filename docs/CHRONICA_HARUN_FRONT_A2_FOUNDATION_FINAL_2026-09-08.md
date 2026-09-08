# CHRONICA HARUN · FRENTE PARALELA A2
## FOUNDATION RECONCILIATION + ANTI-REGRESSION
### Relatório final + handoff de integração · 2026-09-08

## Branch e base

- Branch: `feat/chronica-foundation-reconcile-v2`
- Base exata: `feat/chronica-combat-v2`
- Base commit: `4342dcdaf154de952620208ca36f1ab0e76b228e`
- Implementation HEAD GREEN antes deste commit documental: `989be9ea903cf9f90d950423e2d218079f7422cc`
- Linhagem verificada nesse implementation HEAD: `ahead_by=16`, `behind_by=0`

Nenhum merge foi realizado em `main` ou `integration/chronica-final-v1`. A antiga `feat/chronica-foundation-audit` foi usada somente como fonte histórica de garantias. Não houve merge nem cherry-pick em massa. A fonte governante foi `game/chronica-harun/`.

## Commits A2 de implementação/TDD

1. `e9ec3913e14101feef3b86d8591f5a8a57d2ade4` — `test: add foundation reconciliation red gate`
2. `1a54fcf5cb1b073792f7ef604ed7b225f7594fde` — `test: align foundation assertions with current data contracts`
3. `bf6629494c8215cd608e650d2f83f1e0aa3558c9` — `fix: reject incompatible campaign saves at boot`
4. `fdba045e0e6a80ad659d4de45a0e71dff5594a54` — `test: expose loaded journey state inconsistency`
5. `357b2b39be1bd3594600e4af27ac84d2c40f4534` — `fix: reconcile loaded campaign journey state`
6. `eb08c85d7645ebc0e98716580dc4ab56eca06f2d` — `test: lock remaining foundation anti-regression contracts`
7. `be8d33079980b650579ec42b428d6ef4c306b3f4` — `test: fail foundation runtime on engine errors`
8. `5001411cf416760240a7d5321c5aaf2171926c97` — `fix: parse corrupt campaign saves without engine errors`
9. `08dc0bf909eca6af44c6aeee3f296bd593e21664` — `test: reject seedless campaign restoration`
10. `e2e0cdb57a28960cb2b127a34411649a010bfdaf` — `fix: reject seedless campaign saves`
11. `7fcb31453451c6ec5064d8ca101485ce5cce10bf` — `test: expose remaining restore and final-state regressions`
12. `3adb1eac45a401ac460870d5e46710df7319b26f` — `fix: reject nondeterministic direct run restore`
13. `6f22d9d009c93fec3cae25e1f177d523dc6a2e1c` — `test: target final-state preservation at boot boundary`
14. `b28dfb172f77f5451020fd18a099cdc964cf7ef9` — `fix: preserve final narrative state through boot reload`
15. `cc35b76b87146cf5e737f3d15c9a065e41f28ab9` — `test: expose camera distribution contract mismatch`
16. `989be9ea903cf9f90d950423e2d218079f7422cc` — `fix: align release camera contract with runtime modes`

## Arquivos técnicos alterados

- `.github/workflows/chronica-foundation-reconcile-v2.yml`
- `game/chronica-harun/autoload/GameState.gd`
- `game/chronica-harun/autoload/SaveService.gd`
- `game/chronica-harun/distribution/release_manifest.json`
- `game/chronica-harun/scripts/boot/Main.gd`
- `game/chronica-harun/tests/test_foundation_camera_distribution_contract.py`
- `game/chronica-harun/tests/test_foundation_reconcile_v2.py`

Nenhum catálogo roguelite/inimigo/boss, arquivo narrativo/codex, script de combate ou backend institucional foi alterado.

## Bugs reais encontrados e corrigidos

1. Saves de versão/schema incompatível podiam chegar ao `GameState` como campanha válida. `SaveService` agora os rejeita.
2. `stage_index`, `current_stage_id` e `journey_state` podiam ser restaurados de modo inconsistente. `GameState` agora reconcilia a jornada carregada contra a cadeia Student real.
3. JSON corrompido era rejeitado funcionalmente, mas `JSON.parse_string()` deixava `ERROR: Parse JSON failed` no runtime. O parsing passou a usar `JSON.new().parse()` e a rejeição ficou limpa.
4. Save schema-válido sem `run_seed` era aceito, quebrando restauração determinística. `SaveService` agora rejeita ausência de seed.
5. `GameState.restore_run()` aceitava snapshot direto sem `run_seed`. Agora rejeita.
6. Uma campanha concluída em `PEREGRINUS_IGNIS_GAME` podia ter `current_stage_id` sobrescrito pela configuração da última etapa no boot. `Main.gd` agora preserva e reestabelece o estado narrativo final após `StageDirector.configure()`.
7. `release_manifest.json` declarava `first_person_only=true`, enquanto o runtime real já oferece `first_person` + `over_shoulder` e permite alternância durante gameplay. O manifesto foi alinhado para `first_person_only=false`, `default_camera=first_person` e `camera_modes=[first_person, over_shoulder]`.

## Garantias anti-regressão preservadas

- `PEREGRINUS_IGNIS_GAME` continua somente estado narrativo.
- Nenhuma escrita em `real_progress_gate`.
- Nenhuma promoção institucional.
- Backend permanece opcional/offline-first.
- Nenhuma chave privilegiada incorporada ao runtime.
- Special rooms permanecem validados.
- Combat-v2 permanece protegido por runtime probe.
- Narrativa/codex permanecem protegidos pelo story canon validator.
- Nova campanha não toca `InputMap`, `ProjectSettings` ou configuração de câmera.
- Retry/reload salva e recarrega sem avançar campaign.
- Roster Harun/Caim/Lilith e input map estão cobertos por contrato de teste.
- Referências estáticas `res://`/`preload()` são auditadas.

## Resultado literal do último ciclo completo no implementation HEAD

```text
FOUNDATION_BRANCH_LINEAGE=PASS
generated 82 enemy GLBs and 16 boss GLBs
104 passed in 0.43s
COMPLETE GAME VALIDATION: PASS
CHRONICA STORY CANON VALIDATION: PASS
4.3.stable.official.77dcf97d8
FOUNDATION_IMPORT=PASS
FOUNDATION_BOOT=PASS
FOUNDATION_RUNTIME_PASS
COMBAT_FAMILY_RUNTIME_PASS
FOUNDATION_WINDOWS_EXPORT=PASS
CHRONICA_FOUNDATION_RECONCILE_V2=PASS
```

O `COMPLETE GAME VALIDATION` confirmou Student journey e 82+ enemy forms; 16 bosses / 3 phases; 78 Tarot / 72 Sigilla / 21 Pharmaka / 36 Talismans; 32 Instrumenta / 45 mutations / 7 Daimones; special rooms / visions / meta-run / transformations; Windows + Linux distribution contract; e ausência de gameplay institutional-grade writes.

O story validator confirmou 13 cinematic prologue sequences / 500 seconds; provenance boundaries; 15 Student stages + Initiation; Aleppo c.1585 / Nadir / second shadow / LUCIFER; 72 production shots / 16 strategic narrative choices; e narrative runtime directors presentes.

## Windows export

`FOUNDATION_WINDOWS_EXPORT=PASS`

O executável foi produzido e verificado como não vazio. O runner Linux emitiu warning de ambiente por ausência de `rcedit` para modificação de recursos Windows. Não houve parser/runtime failure. A validação Windows nativa permanece responsabilidade da frente específica de QA Windows.

## Limitações e riscos residuais

1. A persistência de bindings personalizados não possui serviço dedicado nesta fundação; foi verificado que reset/new campaign não altera `InputMap` nem `ProjectSettings`.
2. O contrato Linux foi validado estruturalmente, mas esta frente não produziu o binário Linux final.
3. Em save pós-conclusão, a última etapa ainda funciona como mundo-base de inicialização antes de `PEREGRINUS_IGNIS_GAME` ser reafirmado como estado narrativo. Se a integração principal possuir uma cena pós-campanha/epílogo dedicada, preservar a garantia sem transformar o estado em promoção institucional.
4. Pontos de conflito mais prováveis na integração: `GameState.gd`, `SaveService.gd`, `Main.gd`, `release_manifest.json`.

# Prompt de integração para o coordenador principal

```text
CHRONICA HARUN · INTEGRAÇÃO DA FRENTE A2
FOUNDATION RECONCILIATION + ANTI-REGRESSION

REPOSITÓRIO:
neuralSynapse/societaselectorum

FONTE A INTEGRAR:
feat/chronica-foundation-reconcile-v2

IMPLEMENTATION HEAD A2 VERIFICADO:
989be9ea903cf9f90d950423e2d218079f7422cc

BASE ORIGINAL EXATA:
feat/chronica-combat-v2
4342dcdaf154de952620208ca36f1ab0e76b228e

DESTINO:
integration/chronica-final-v1

Integre a Frente A2 sobre o HEAD ATUAL da integration/chronica-final-v1 preservando simultaneamente as mudanças válidas das demais frentes paralelas.

NÃO faça overwrite cego de GameState.gd, SaveService.gd, Main.gd ou release_manifest.json. Resolva conflitos por contrato e comportamento.

NÃO integre feat/chronica-foundation-audit.
NÃO use godot/chronica_harun/.
A fonte real é game/chronica-harun/.

GARANTIAS QUE DEVEM SOBREVIVER À INTEGRAÇÃO

1. SaveService rejeita campaign_version incompatível.
2. SaveService rejeita JSON corrompido sem deixar ERROR de parser no runtime.
3. SaveService rejeita save sem run_seed.
4. GameState.restore_run() rejeita snapshot sem run_seed.
5. Seed explícita permanece determinística.
6. GameState reconcilia stage_index/current_stage_id/journey_state pela jornada real.
7. PEREGRINUS_IGNIS_GAME permanece SOMENTE estado narrativo.
8. Boot preserva PEREGRINUS_IGNIS_GAME após StageDirector.configure().
9. Retry/reload salva e recarrega sem avançar campaign.
10. Nova campanha reseta campaign/run sem alterar InputMap, ProjectSettings ou câmera/settings.
11. Roster Harun/Caim/Lilith permanece: harun default; caim unlock a_balanca; lilith unlock a_eleicao.
12. Input map obrigatório permanece completo.
13. Câmera default é first_person.
14. Runtime mantém first_person + over_shoulder com toggle permitido.
15. release_manifest permanece coerente: first_person_only=false, default_camera=first_person, camera_modes=[first_person, over_shoulder].
16. Nenhuma escrita em real_progress_gate.
17. Nenhuma promoção institucional.
18. Backend continua opcional/offline-first.
19. Nenhuma chave privilegiada no runtime/distribuição.
20. Não regredir special-room generation, combat-v2, narrativa ou codex.

ARQUIVOS TÉCNICOS A2 ALTERADOS

.github/workflows/chronica-foundation-reconcile-v2.yml
game/chronica-harun/autoload/GameState.gd
game/chronica-harun/autoload/SaveService.gd
game/chronica-harun/distribution/release_manifest.json
game/chronica-harun/scripts/boot/Main.gd
game/chronica-harun/tests/test_foundation_camera_distribution_contract.py
game/chronica-harun/tests/test_foundation_reconcile_v2.py

RESULTADO LITERAL VERIFICADO

FOUNDATION_BRANCH_LINEAGE=PASS
generated 82 enemy GLBs and 16 boss GLBs
104 passed in 0.43s
COMPLETE GAME VALIDATION: PASS
CHRONICA STORY CANON VALIDATION: PASS
4.3.stable.official.77dcf97d8
FOUNDATION_IMPORT=PASS
FOUNDATION_BOOT=PASS
FOUNDATION_RUNTIME_PASS
COMBAT_FAMILY_RUNTIME_PASS
FOUNDATION_WINDOWS_EXPORT=PASS
CHRONICA_FOUNDATION_RECONCILE_V2=PASS

DEPOIS DA INTEGRAÇÃO, RODE OBRIGATORIAMENTE

pytest -q game/chronica-harun/tests
python game/chronica-harun/tools/validate_complete_game.py
python game/chronica-harun/tools/validate_story_canon.py
Godot 4.3 headless strict import
Main.tscn headless boot
runtime combat/anti-regression
Windows export

Faça também testes específicos para save válido, save incompatível, JSON corrompido, save sem run_seed, restore direto sem run_seed, campanha em PEREGRINUS_IGNIS_GAME, retry/reload, toggle first_person/over_shoulder, boot offline e ausência de real_progress_gate/institutional writes.

Não aceite parser warning/error como sucesso.
Não altere narrativa para resolver conflito técnico.
Não redesenhe combate.
Não reverta special rooms.
Não torne backend obrigatório.
Não faça promoção institucional.

Ao final reporte: HEAD de integração, commits integrados, conflitos encontrados e resolução, arquivos finais alterados, resultado literal de toda a suíte, Godot import/boot, Windows export e qualquer regressão remanescente.

A Frente A2 só é considerada integrada se o HEAD combinado permanecer GREEN.
```
