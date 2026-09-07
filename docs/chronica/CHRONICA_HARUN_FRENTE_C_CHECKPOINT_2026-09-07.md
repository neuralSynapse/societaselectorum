# CHRONICA HARUN · FRENTE PARALELA C · CHECKPOINT FINAL

Data: 2026-09-07
Branch: `feat/chronica-roguelite-depth`
Repositório: `neuralSynapse/societaselectorum`
Estado: CONCLUÍDA E VERIFICADA, SEM MERGE EM `main`
Commit de código verificado: `091ab22ee05ea8224c87b87f7e991e4bcd6cf259`
CI verificado: GitHub Actions run `34157978052` · conclusão `success`

## Escopo respeitado

Esta frente implementa exclusivamente profundidade sistêmica roguelite/buildcraft da CHRONICA HARUN. Não altera narrativa cinematográfica principal, inimigos, reescrita de combate ou backend. Não foi feito merge em `main`.

A auditoria inicial confirmou que a antiga fonte Godot alegada em `feat/godot-o-olho` e commits locais citados no checkpoint anterior não existiam no remoto. A fundação foi, portanto, reconstruída na branch desta frente conforme autorização do checkpoint master, sem fingir recuperação de código inexistente.

## Fundação Godot criada

Raiz: `game/chronica-harun/`

Principais componentes:

- `project.godot`
- `autoload/RogueliteContentService.gd`
- `autoload/GameState.gd`
- `scripts/content/BuildResolver.gd`
- `scripts/content/GameplayEffectBus.gd`
- `scripts/generation/SpecialRoomDirector.gd`
- `scripts/generation/StageFloorBuilder.gd`
- `scripts/rooms/SpecialRoomRuntime.gd`
- `scripts/progression/MetaRunDirector.gd`
- `scripts/boot/DepthRuntimeSmoke.gd`
- `scenes/boot/DepthRuntimeSmoke.tscn`
- `scenes/rooms/SpecialRoomRuntime.tscn`
- `tools/generate_roguelite_catalogs.py`
- `data/roguelite/*.json`

## Catálogos materializados + runtime

Contagens verificadas no CI:

- Tarot de Thoth: 78
  - 22 Atu
  - 56 Menores
  - 14 por naipe
  - 16 cartas de corte mecanicamente distintas
- Sigilla Goetica: 72
- Pharmaka Hermetica: 21
- Talismãs decânicos: 36
- Instrumenta: 32
- Poderes-Matriz: 15
- Mutações: 45
- Daimones: 7
- Relíquias: 9
- Transformações: 12
- Maldições: 8
- Bênçãos: 6
- Rotas: 8
- Salas especiais: 20
- Gauntlets: 4

Todo registro é validado contra o contrato comum:

`id`, `name`, `rarity`, `pool`, `eligibility`, `effect`, `cost`, `duration`, `stacking`, `synergies`, `exclusions`, `vfx_hook`, `sfx_hook`, `save_state`, `codex`, `provenance`.

O `BuildResolver` mantém allowlist de tipos de efeito e os testes garantem que todo efeito materializado possui dispatch reconhecido. Sigilla possuem 72 assinaturas mecânicas distintas; as 32 Instrumenta possuem ações distintas; cada Mutação referencia Poder-Matriz existente e hook de runtime válido.

## Tarot

As 78 cartas chegam ao runtime. Os 22 Atu possuem funções especiais próprias. Os Menores seguem a lógica de naipe:

- Bastões: ataque, força, vontade, velocidade e fogo.
- Copas: foco, recuperação, vínculo e fluxo.
- Espadas: precisão, ruptura, revelação e análise.
- Discos: defesa, economia, matéria e investimento.

As Cortes não são bônus numéricos genéricos:

- Princesa: `manifest_field`
- Príncipe: `combo_engine`
- Rainha: `resource_aura`
- Cavaleiro: `suit_finisher`

## Salas especiais

Existem como dados e runtime:

- Câmara do Arcano
- Reliquarium
- Instrumentarium
- Laboratorium
- Câmara Sigillar
- Mercado de Essência
- Bibliotheca
- Speculum
- Câmara Planetária
- Câmara de Provação
- Câmara Maldita
- Sala Secreta
- Sala Duplamente Secreta
- Câmara do Arconte
- Câmara Teofânica
- Câmara Histórica
- Câmara de Iniciação

Foram adicionadas como dramatização Electorum três escolhas pós-boss próprias e mutuamente exclusivas:

- Câmara Pneumática
- Câmara Ctônica
- Mesa do Pacto

Cada sala possui contrato de spawn, entrada, risco, recompensa, evento runtime, persistência, mapa/ícone e feedback de descoberta.

## Segredos físicos

`SpecialRoomDirector.MAX_SECRET_ROOMS = 2`.

O número efetivo respeita a capacidade física do layout. Salas secretas são `hidden_wall`, não recebem porta/label escrito `SECRET`, e aceitam abertura física canônica por tags equivalentes a:

- `ritual_bomb`
- `rupture_charge`
- `wall_break`

O runtime registra descoberta em `discovered_secrets`.

## Buildcraft e metarun

Implementados:

- custos;
- stacking;
- exclusões;
- sinergias;
- dispatch de efeitos;
- seleção persistente de rota;
- maldições;
- bênçãos;
- avaliação e desbloqueio de transformações;
- completion marks por personagem/desafio;
- gauntlets e contagem de salas;
- escolha pós-boss exclusiva;
- estado serializável da run;
- save/load local em JSON.

Nenhum caminho desta frente escreve `real_progress_gate`, grau institucional ou promoção institucional.

## Save/load

`GameState.gd` possui:

- `snapshot_run()`
- `restore_run()`
- `save_run()`
- `load_run()`

O smoke altera estado, salva, corrompe intencionalmente o valor em memória, recarrega e verifica restauração.

## Verificação TDD e CI

RED final registrado no CI run `34157386684`:

- 4 falhas esperadas
- 27 testes passavam
- falhas: `Dictionary.get_or_add`, smoke ausente, save/load ausente e integração smoke ausente.

GREEN final no CI run `34157978052`:

- geração dos catálogos: sucesso;
- `pytest -q game/chronica-harun/tests`: `31 passed`;
- Godot instalado: `4.3.stable.official.77dcf97d8`;
- import headless do projeto: sucesso sem `SCRIPT ERROR`, `Parse Error` ou falha de carregamento;
- smoke runtime: `DEPTH_RUNTIME_SMOKE_OK`;
- job completo: `success`.

## Anti-regressão / fronteiras

Comparação `main...feat/chronica-roguelite-depth` no fechamento mostrou a branch somente à frente. As mudanças estão limitadas a:

- workflow específico desta frente;
- documentação da frente;
- nova raiz `game/chronica-harun/`.

Nenhum arquivo de `mundus/chronica-harun/backend/` foi alterado.

Não fazer merge automático em `main`. A integração futura deve ser feita conscientemente com as outras frentes Godot após reconciliar a fonte real do projeto.

## Prompt de transferência para outra guia

```text
CHRONICA HARUN · AVISO DE CONCLUSÃO DA FRENTE PARALELA C

A Frente C — ROGUELITE SYSTEMS + SPECIAL ROOMS + BUILDCRAFT foi concluída e persistida no GitHub.

Repositório:
neuralSynapse/societaselectorum

Branch:
feat/chronica-roguelite-depth

Checkpoint governante desta frente:
docs/chronica/CHRONICA_HARUN_FRENTE_C_CHECKPOINT_2026-09-07.md

Commit de código integralmente verificado:
091ab22ee05ea8224c87b87f7e991e4bcd6cf259

CI final:
GitHub Actions run 34157978052 — SUCCESS

Validação final:
- 31/31 testes Python verdes;
- Godot 4.3 headless importou o projeto sem erro de parser;
- smoke end-to-end retornou DEPTH_RUNTIME_SMOKE_OK;
- catálogos canônicos materializados e validados;
- save/load local validado;
- salas especiais e segredos físicos implementados;
- buildcraft, rotas, maldições, bênçãos, transformações, completion marks e gauntlets implementados;
- nenhuma alteração no backend;
- nenhum merge em main.

IMPORTANTE:
Não refaça a Frente C e não substitua seus catálogos por versões genéricas. Leia o checkpoint acima e inspecione a branch real antes de integrar qualquer coisa.

A antiga branch/commits locais alegados para feat/godot-o-olho não estavam persistidos no remoto; esta frente reconstruiu uma fundação Godot verificável conforme o checkpoint master. Qualquer integração com as Frentes A/B deve reconciliar a fonte Godot real em vez de presumir que os commits antigos existem.

Preserve as fronteiras:
- Frente C não governa narrativa cinematográfica;
- não governa inimigos;
- não reescreve combate;
- não governa backend;
- não escreve progressão institucional/real_progress_gate;
- não faça merge automático em main.

Use esta branch como fonte real da implementação roguelite até decisão explícita de integração.
```
