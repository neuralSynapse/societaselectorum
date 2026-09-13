# MUNDUS · GAME SENTINEL — Design v1.0

Data: 2026-09-13
Estado: aprovado para implementação
Branch de trabalho: `agent/mundus-game-sentinel-v1`
Base: `integration/chronica-final-v1`
WebsitePublisher: projeto 27912

## 1. Objetivo

Criar um sentinela operacional contínuo para os três jogos ativos de MUNDUS. Os três jogos permanecem produtos jogáveis diferentes em câmera, ritmo, controles, estrutura de encontro, interface e metaprogressão de gênero, mas pertencem à mesma CHRONICA HĀRŪN e devem obedecer ao mesmo cânone, regras epistemológicas, terminologia, ordem narrativa, identidade de personagens, proveniência e limites institucionais.

O sentinela trabalha em somente um jogo por vez. Um jogo só libera a fila quando todos os gates obrigatórios estão verdes. Depois de um ciclo completo, a fila volta ao primeiro jogo.

## 2. Jogos governados

1. `chronica-harun-3d.html` — CHRONICA HĀRŪN 3D/FPS. Experiência canônica principal, primeira pessoa por padrão, câmera externa opcional, narrativa mais cinematográfica e sistemas mais completos.
2. `harun-roguelite.html` — Cidadela das Cinzas. Adaptação 2D/top-down roguelite da mesma história, com salas, Arcanas, relíquias e runs.
3. `harun-survivor.html` — Cidadela Viva. Adaptação mobile/survivor da mesma história, com ondas, atos, builds e metaprogressão própria.

Rotas de arquivo, laboratórios e snapshots não entram no ciclo ativo nem podem ser promovidos automaticamente: `mundus-fps.html`, `survivor-lab.html`, `fusion-v22-clean.html` e equivalentes.

## 3. Fonte de verdade canônica

A verdade narrativa não é decidida por cada runtime. A autoridade segue esta precedência:

1. `game/chronica-harun/data/narrative/chronica_story_bible.json`.
2. Documentos de cânone em `game/chronica-harun/docs/canon/`.
3. `game/chronica-harun/docs/chronica/CHRONICA_HARUN_CANONE_EXPANSAO_SISTEMICA_v3_0_2026-09-07.md` e documentos governantes correlatos.
4. Dados estruturados governantes em `game/chronica-harun/data/**`.
5. Contrato de compatibilidade web `ops/mundus-game-sentinel/canon-contract.json`.
6. Adaptadores específicos de gênero para os três jogos.

Nenhum adaptador pode sobrescrever uma camada superior. Se um jogo divergir, o adaptador é corrigido, não o cânone para acomodar a divergência.

## 4. Invariantes compartilhados

Os três jogos devem preservar, quando o conteúdo correspondente estiver presente:

- Hārūn como protagonista canônico padrão da campanha principal.
- Ammar → Hārūn como arco de origem, sem reescrever a escolha do nome.
- Aleppo como eixo geográfico com cronologia absoluta aberta onde o cânone ainda a mantém aberta.
- A jornada formativa de 15 etapas + Câmara de Iniciação.
- Ordem, nome e função das etapas governantes: O Olho, A Chama, A Fundação, A Eleição, A Balança, A Vontade, O Caráter, A Disciplina, A Clareza, A Transmutação, O Corpo, A Obra, A Fortuna, A Influência, O Legado e Câmara de Iniciação.
- A distinção entre conteúdo histórico/tradicional, interpretação Electorum e dramatização autoral.
- Nomes tradicionais não recebem funções históricas inventadas apenas porque funcionam bem como boss.
- Mentores históricos não recebem falsas citações.
- Conceitos científicos não são apresentados como prova de capacidades paranormais.
- Kinesis, poderes, salas e sistemas contemporâneos são gameplay ficcional quando assim definidos pelo cânone.
- `PEREGRINUS_IGNIS_GAME` é estado narrativo do videogame, nunca certificação de Grau real.
- Gameplay não escreve progresso institucional real nem `real_progress_gate`.
- A história e a progressão narrativa são separadas da implementação mecânica. Consequências mecânicas devem consumir hooks/adaptadores, não reescrever a narrativa.

## 5. Paridade sem homogeneização

“Mesma história e mesmas regras” não significa três jogos idênticos.

O 3D pode apresentar uma etapa como exploração, cinematografia, combate FPS e boss. O roguelite pode representar a mesma etapa como sequência de salas e escolhas. O survivor pode representar a mesma etapa como ato, ondas, elites e boss. A forma muda; o significado canônico, a ordem causal e o resultado narrativo não mudam.

Cada adaptador deve declarar explicitamente:

- `canonStageId`;
- `presentationUnit` (`stage`, `room`, `act`, `wave_block` etc.);
- `bossCanonicalId` ou `authorialBossId`;
- `provenance`;
- `storyEntryHook`;
- `storyCompletionHook`;
- `gameplayOnlyRewards`;
- `institutionalWrite: false`.

## 6. Estado do Sentinela

Arquivo governante: `ops/mundus-game-sentinel/state.json`.

Campos mínimos:

- `schemaVersion`;
- `cycle`;
- `activeGame`;
- `queue`;
- `status`;
- `lastRunAt`;
- `lastGreenAt`;
- `canonContractVersion`;
- `baseline` por jogo;
- `gates` por jogo;
- `failureFingerprint`;
- `repairAttempts`;
- `lastRepair`;
- `nextGame`;
- `notes`.

Estados: `QUEUED`, `TESTING`, `RED`, `REPAIRING`, `VERIFYING`, `GREEN`, `BLOCKED`.

`BLOCKED` não avança a fila. Apenas registra que o próximo ciclo deve continuar no mesmo jogo com outra estratégia ou intervenção.

## 7. Gates obrigatórios

Um jogo só recebe `GREEN` quando todos estiverem verdes:

1. `CANON_GREEN` — paridade narrativa e terminológica.
2. `RUNTIME_GREEN` — página/runtime abre sem erro fatal.
3. `ASSET_GREEN` — recursos críticos carregam.
4. `INPUT_GREEN` — controles primários funcionam para o gênero.
5. `COMBAT_GREEN` — ataque, dano, morte e condição de encontro não travam.
6. `PROGRESSION_GREEN` — etapa/run/ato progride e save não corrompe.
7. `UI_GREEN` — menus, overlays e HUD não bloqueiam a experiência.
8. `PLATFORM_GREEN` — desktop/mobile aplicável àquele jogo.
9. `REGRESSION_GREEN` — nenhum baseline crítico piorou.

Para o 3D, os gates existentes de Godot 4.3, import, boot, testes e validadores continuam governantes e são adicionados aos gates acima.

## 8. Ciclo operacional

Fluxo estrito:

`ACTIVE_GAME → TEST → DIAGNOSE → REPAIR → RETEST → COMPARE_BASELINE → GREEN → NEXT_GAME`.

Regras:

- nunca trabalhar em dois jogos simultaneamente;
- nunca avançar porque “a maior parte funciona”;
- falha canônica é bloqueante mesmo com gameplay funcional;
- falha de gameplay é bloqueante mesmo com cânone correto;
- correções devem ser mínimas e isoladas;
- após ficar verde, o agente pode executar no máximo uma melhoria controlada por ciclo antes de retestar todos os gates;
- qualquer regressão restaura o baseline ou reverte a melhoria;
- o agente não altera narrativa para consertar dificuldade, performance ou interface;
- o agente não usa versões de arquivo como fonte de produção.

## 9. Baseline e rollback

Cada jogo mantém:

- hash/versionamento dos assets e página ativos;
- último estado `GREEN` conhecido;
- snapshot lógico dos contratos canônicos;
- métricas de smoke test;
- registro da última mudança.

Antes de qualquer correção em produção, o sentinela registra o baseline. Se a correção falhar ou piorar outro gate, volta ao último baseline verde quando tecnicamente possível.

## 10. QA automatizado

A camada determinística roda em GitHub Actions e inclui:

- validação do contrato canônico;
- checagem de presença e resposta HTTP das três rotas ativas;
- checagem de referências de assets críticos;
- smoke de navegador com Playwright;
- captura de `console.error`, `pageerror` e falhas de request;
- viewport desktop para 3D e roguelite;
- viewport mobile para survivor;
- screenshots para evidência e comparação humana/automatizada futura;
- relatório JSON e Markdown por execução.

O QA não corrige. Ele mede e prova.

## 11. Reparador

A camada reparadora consome o relatório do QA e trabalha somente no `activeGame`.

Prioridade:

1. crash/boot;
2. progressão impossível;
3. divergência canônica;
4. input/combate;
5. save;
6. UI bloqueante;
7. asset quebrado;
8. performance;
9. polimento.

Toda correção precisa citar o gate afetado e conter um teste que falhava antes e passa depois sempre que o domínio permitir teste automatizado.

## 12. Melhoria contínua

Quando um jogo está verde, o agente procura somente uma melhoria de maior impacto. Critérios: legibilidade, sensação de combate, IA, feedback audiovisual, navegação, responsividade, performance ou integração canônica.

Melhoria visual nunca substitui clareza jogável. Melhoria mecânica nunca cria contradição narrativa. Melhoria narrativa nunca é inventada pelo agente sem estar ancorada no cânone governante.

## 13. Entrelinhas transformadas em regra

O pedido de “testar e aperfeiçoar sem parar” implica:

- autocorreção, não apenas relatório;
- verificação da correção, não confiança no commit;
- memória entre ciclos;
- prevenção de loop de reparo repetindo a mesma tentativa;
- detecção de regressão transversal entre jogos;
- auditoria de drift canônico;
- fila que não abandona um jogo vermelho;
- isolamento entre saves e runtimes, mas não entre história e regras;
- tratamento dos três jogos como três expressões da mesma obra;
- documentação automática de decisões para que uma aba/agente futuro não “reinvente” a verdade;
- nenhuma promoção automática de uma mudança que não possua evidência de teste.

## 14. Critério de sucesso

O sistema está operacional quando:

- existe um contrato canônico único legível por máquina;
- os três adaptadores são verificáveis contra esse contrato;
- a fila persistente identifica exatamente qual jogo está sendo trabalhado;
- o QA produz resultado por jogo e por gate;
- a automação recorrente continua no mesmo jogo se houver vermelho;
- uma build só é declarada verde com evidência;
- qualquer mudança futura pode ser rastreada até cânone, teste, reparo e verificação.
