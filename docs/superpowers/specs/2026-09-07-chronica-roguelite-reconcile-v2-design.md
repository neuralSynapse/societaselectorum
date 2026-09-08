# CHRONICA HARUN · Frente C2 Roguelite Reconciliation — Design

Data: 2026-09-07
Branch governante desta frente: `feat/chronica-roguelite-reconcile-v2`
Base exata: `feat/chronica-combat-v2` @ `4342dcdaf154de952620208ca36f1ab0e76b228e`
Fonte histórica para comparação semântica: `feat/chronica-roguelite-depth` @ `02da659233dc539a32a188634e1824db7a2a858b`

## Objetivo

Reconciliar a profundidade roguelite histórica com a árvore atual sem merge cego, sem cherry-pick em massa e sem reintroduzir nomes de catálogo legados. A árvore atual governa; a branch histórica serve somente como fonte de comportamentos que possam ter sido perdidos.

## Restrições

- Não fazer merge em `main`.
- Não fazer merge em `integration/chronica-final-v1`.
- Não reescrever narrativa.
- Não redesenhar IA, inimigos ou bosses.
- Não alterar backend institucional.
- Preservar combat-v2, save/retry, narrativa, proveniência, boot offline e ausência de institutional writes.
- TDD para bugs e lacunas comportamentais.

## Catálogos canônicos

A fonte de verdade atual permanece:

- `tarot_thoth.json`: 78
- `sigilla_goetia.json`: 72
- `pharmaka.json`: 21
- `talismans_decanic.json`: 36
- `instrumenta.json`: 32
- `powers.json`: 15 Power Matrices, cada uma com 3 mutations, total 45
- `daimones.json`: 7
- `relics.json`
- `transformations.json`
- `curses.json`
- `blessings.json`
- `routes.json`
- `gauntlets.json`
- `special_rooms.json`

Nomes históricos `tarot.json`, `sigilla.json`, `talismans.json` não serão recriados nem registrados no runtime atual.

## Estratégia de reconciliação

### 1. Current-first

Toda decisão começa pela árvore C2. Um comportamento antigo só é recuperado quando:

1. existe no checkpoint/implementação histórica;
2. continua dentro dos contratos canônicos atuais;
3. está realmente ausente ou parcial no runtime atual;
4. pode ser incorporado sem regressão em combat-v2, narrativa ou backend.

### 2. Buildcraft end-to-end

A definição de pronto para conteúdo equipável/consumível é um caminho observável:

`pickup/grant -> inventory/build -> uso/equipamento -> consumo/carga -> efeito runtime -> persistência quando aplicável -> sinergia/exclusão -> transformação`

JSON sem caminho de runtime não conta como sistema concluído.

O runtime deverá manter as responsabilidades separadas:

- `RogueliteContentService`: aquisição, slots, uso, cargas e operações de build.
- `BuildResolver`: estado derivado do build, sinergias, exclusões e transformações elegíveis.
- `GameplayEffectBus`: despacho de efeitos data-driven reconhecidos.
- `GameState`/`SaveService`: persistência local do estado roguelite.
- `MetaRunDirector`: rotas, curses, blessings, completion marks, gauntlets e metaprogressão de jogo.

### 3. Salas especiais

As salas canônicas devem possuir caminho de geração/runtime verificável:

Arcana, Reliquarium, Instrumentarium, Laboratorium, Sigillar, Essence Market/Rito de Troca, Bibliotheca, Speculum, Planetary, Trial, Cursed, Secret, Super Secret, Archon, Theophany, Historical, Initiation e pós-boss Pneumatic/Chthonic/Pact.

`SpecialRoomDirector.eligible_rooms(stage_index, cycle, context, for_generation)` permanece governante. Quando `for_generation == true`, `min_rooms_cleared` não pode impedir a sala de ser materializada no andar.

### 4. Segredos físicos

- `MAX_SECRET_ROOMS = 2` permanece.
- Secret e Super Secret selecionadas precisam existir como slots físicos no layout.
- Antes da ruptura, conexões secretas ficam ocultas.
- Abertura exige recurso canônico e consome carga no caminho runtime.
- Super Secret exige pré-condições adicionais sem transformar `min_rooms_cleared` em bloqueio de geração.
- Descoberta precisa persistir no estado da run.

### 5. Pós-boss e rotas

Pneumatic, Chthonic e Pact formam grupo mutuamente exclusivo por escolha pós-boss. Alternate routes, completion marks, gauntlets/boss rush, multiple endings e metaprogression devem continuar serializáveis e separados de qualquer progresso institucional.

## Testes

A frente adicionará testes focados em lacunas, sem substituir a suíte governante. O gate final inclui:

- `pytest -q game/chronica-harun/tests`
- `python game/chronica-harun/tools/validate_complete_game.py` ou caminho governante equivalente
- `python game/chronica-harun/tools/validate_story_canon.py` ou caminho governante equivalente
- Godot 4.3 import headless
- runtime smoke das alterações roguelite

Quando o ambiente local não estiver disponível, a verificação executável será feita por GitHub Actions na própria branch; nenhum PASS será alegado sem evidência de run/log.

## Entrega

O checkpoint final deve registrar:

- branch e HEAD final;
- commits;
- catálogos auditados;
- sistemas já funcionais;
- lacunas reais;
- implementações feitas;
- salas testadas;
- buildcraft testado;
- contagens finais;
- pytest;
- validators;
- Godot runtime;
- limitações restantes;
- instrução explícita para a branch principal integrar conscientemente, sem merge automático.
