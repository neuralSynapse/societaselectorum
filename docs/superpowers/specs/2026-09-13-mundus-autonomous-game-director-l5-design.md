# MUNDUS · AUTONOMOUS GAME DIRECTOR L5 — Design v1.0

Data: 2026-09-13
Estado: aprovado em conceito; aguardando revisão do documento antes da implementação
Branch de trabalho: `agent/mundus-game-sentinel-v1`
Origem: evolução do MUNDUS · GAME SENTINEL L4
WebsitePublisher: projeto 27912
Repositório: `neuralSynapse/societaselectorum`

## 1. Objetivo

Transformar o atual MUNDUS · GAME SENTINEL L4, hoje predominantemente orientado a supervisão, QA, anti-regressão e reparo, em um diretor autônomo de desenvolvimento contínuo capaz de construir, testar, reparar, publicar e elevar os três jogos ativos de CHRONICA HĀRŪN, um por vez, sem abandonar os controles de segurança, cânone e rollback já estabelecidos.

O L5 deixa de considerar “verificação sem mudança” como trabalho suficiente quando existe avanço seguro disponível. A função principal passa a ser:

`DESCOBRIR ESTADO → ESCOLHER PRÓXIMO AVANÇO SEGURO → IMPLEMENTAR → PUBLICAR → TESTAR JOGANDO → COMPARAR → ACEITAR OU REVERTER → REGISTRAR → CONTINUAR`

O L5 continua sendo um supervisor, mas também se torna o executor do backlog de produção do jogo ativo.

## 2. Princípio central

A mudança essencial é separar duas noções que no L4 ficaram acopladas:

1. **aptidão para continuar desenvolvendo o jogo ativo**;
2. **aptidão para declarar o jogo integralmente GREEN e promover a fila**.

No L5, um gate UNKNOWN não relacionado à área sendo trabalhada não paralisa automaticamente o desenvolvimento. Ele continua impedindo promoção do jogo para o próximo item da fila, mas não impede avanços seguros e localizados que não dependam daquele gate.

Exemplo: `WEBGL_FALLBACK=UNKNOWN` não deve impedir melhoria isolada de feedback de melee se CANON, RUNTIME, INPUT, COMBAT local e REGRESSION da área relevante forem suficientes para executar e provar a mudança.

## 3. Jogos ativos e fila exclusiva

Fila canônica:

`chronica-3d → harun-roguelite → harun-survivor → repetir`

Runtimes ativos:

1. `/chronica-harun-3d.html` — CHRONICA HĀRŪN 3D/FPS.
2. `/harun-roguelite.html` — HĀRŪN · Cidadela das Cinzas, 2D roguelite.
3. `/harun-survivor.html` — HĀRŪN · Cidadela Viva, survivor/mobile.

Somente o `activeGame` pode receber mudanças de produto em um ciclo. Mudanças compartilhadas de contrato, guardião, QA ou assets comuns exigem smoke transversal dos três jogos.

Rotas arquivadas, laboratórios e builds de teste não podem ser promovidos automaticamente.

## 4. Cânone imutável

O L5 preserva integralmente a precedência canônica já estabelecida:

1. `game/chronica-harun/data/narrative/chronica_story_bible.json`;
2. `game/chronica-harun/docs/canon/`;
3. `game/chronica-harun/docs/chronica/CHRONICA_HARUN_CANONE_EXPANSAO_SISTEMICA_v3_0_2026-09-07.md`;
4. dados governantes em `game/chronica-harun/data/**`;
5. `ops/mundus-game-sentinel/canon-contract.json`;
6. adapters por jogo.

Invariantes obrigatórios:

- Ammar → Hārūn permanece a causalidade de origem;
- Hārūn é o protagonista canônico padrão;
- a ordem das 16 etapas permanece:
  `o_olho`, `a_chama`, `a_fundacao`, `a_eleicao`, `a_balanca`, `a_vontade`, `o_carater`, `a_disciplina`, `a_clareza`, `a_transmutacao`, `o_corpo`, `a_obra`, `a_fortuna`, `a_influencia`, `o_legado`, `initiation_chamber`;
- `PEREGRINUS_IGNIS_GAME` é estado narrativo do videogame;
- `institutionalWrite=false` é absoluto;
- gameplay não concede grau real, progresso institucional real ou autoridade ritual real;
- adaptação mecânica pode mudar apresentação, nunca ordem causal ou significado canônico governante.

## 5. Arquitetura L5 em duas lanes

O L5 possui duas lanes lógicas, mas uma única autoridade de escrita no jogo ativo.

### 5.1 Safety Lane

Responsável por impedir dano estrutural, regressão, corrupção e drift canônico.

Escopo:

- CANON;
- RUNTIME;
- ASSET crítico;
- INPUT crítico;
- REGRESSION;
- ASYNC_RUNTIME;
- SECURITY;
- SAVE_INTEGRITY;
- CROSS_GAME_CONTRACT;
- EVIDENCE_FRESHNESS;
- SELF_HEALTH;
- rollback e circuit breaker.

Uma falha crítica nessa lane interrompe desenvolvimento somente quando a falha pode invalidar, corromper ou tornar insegura a mudança pretendida.

### 5.2 Development Lane

Responsável por produzir avanço real no jogo ativo.

Escopo:

- gameplay;
- combate;
- inimigos;
- bosses;
- progressão;
- level design;
- apresentação narrativa;
- câmera;
- input e sensação de controle;
- UI/HUD;
- arte e ambiente;
- materiais e iluminação;
- VFX;
- áudio;
- performance;
- mobile/desktop compatibility;
- save/recovery;
- polish;
- conteúdo adicional permitido pelo cânone.

A Development Lane é obrigada a escolher o próximo avanço seguro de maior valor quando não existir blocker crítico relacionado.

## 6. Novo estado operacional

`ops/mundus-game-sentinel/state.json` evolui para `schemaVersion: 5` e `directorLevel: 5`.

Campos adicionais propostos:

- `mode`: `REPAIR`, `DEVELOP`, `VERIFY`, `RELEASE_CHECK`, `BLOCKED`;
- `developmentLane`;
- `safetyLane`;
- `currentObjective`;
- `objectiveClass`;
- `objectiveStartedAt`;
- `objectiveExpectedEvidence`;
- `objectiveRollbackRef`;
- `lastMaterialAdvanceAt`;
- `consecutiveNoMaterialAdvanceCycles`;
- `productivityStatus`;
- `backlogCursor`;
- `acceptedChangeRef`;
- `rejectedChangeRef`;
- `releaseReadiness`;
- `promotionBlockedBy`;
- `activeBaselineRef`;
- `goldenBaselineRef`;
- `lastProductChangeAt`;
- `lastSharedChangeAt`.

Estados de produtividade:

- `ADVANCING`;
- `NO_SAFE_WORK`;
- `PRODUCTIVITY_STALL`;
- `EXTERNAL_BLOCKER`.

## 7. Backlog vivo hierárquico

Novo arquivo governante:

`ops/mundus-game-sentinel/development-backlog.json`

Estrutura por jogo e domínio:

- `gameplay`;
- `combat`;
- `enemies`;
- `bosses`;
- `progression`;
- `level_design`;
- `narrative_presentation`;
- `camera`;
- `input`;
- `ui_hud`;
- `art_environment`;
- `materials_lighting`;
- `vfx`;
- `audio`;
- `performance`;
- `platform_mobile_desktop`;
- `save_recovery`;
- `qa`;
- `polish`.

Cada item possui no mínimo:

- `id`;
- `game`;
- `domain`;
- `title`;
- `problem`;
- `desiredOutcome`;
- `priority`;
- `impact`;
- `risk`;
- `dependencies`;
- `relatedGates`;
- `canonRefs`;
- `evidenceRequired`;
- `rollbackStrategy`;
- `status`;
- `source`;
- `createdAt`;
- `updatedAt`.

Status:

- `DISCOVERED`;
- `READY`;
- `ACTIVE`;
- `VERIFYING`;
- `ACCEPTED`;
- `REJECTED`;
- `BLOCKED`;
- `DEFERRED`.

O L5 pode descobrir novos itens automaticamente, mas não pode inventar conteúdo canônico. Novos itens de produto devem derivar de lacuna observada, requisito já definido, bug, métrica, regressão, comparação com baseline ou conteúdo já autorizado.

## 8. Seleção do próximo avanço

A cada ciclo, após o preflight:

1. identificar blockers críticos;
2. se houver blocker crítico relacionado ao objetivo, entrar em `REPAIR`;
3. se não houver, consultar backlog do `activeGame`;
4. priorizar maior valor seguro;
5. evitar escolher item dependente de gate estrutural ainda não comprovado quando isso tornar a evidência inválida;
6. escolher exatamente um objetivo principal por ciclo;
7. registrar hipótese, resultado esperado, evidência necessária e rollback antes da alteração;
8. implementar somente o menor conjunto coerente de mudanças necessário;
9. retestar área afetada e smoke transversal quando aplicável;
10. aceitar ou reverter.

Critério de prioridade sugerido:

`blocker de jogabilidade > progressão impossível > combate/controle > estabilidade > inimigos/bosses > level design > feedback audiovisual > UI/UX > performance > conteúdo/polish`.

## 9. Regra de avanço material por ciclo

Cada execução deve terminar em uma destas condições legítimas:

1. **MATERIAL_ADVANCE** — produto ou QA relevante avançou de forma comprovada;
2. **REPAIR_APPLIED** — falha material corrigida e verificada;
3. **ROLLBACK_PERFORMED** — mudança ruim revertida com estado restaurado;
4. **BLOCKED_WITH_EVIDENCE** — existe blocker externo ou estrutural real e documentado;
5. **NO_SAFE_WORK** — raro, quando nenhuma tarefa pode ser executada sem violar segurança/cânone.

Somente “verifiquei e continua igual” não satisfaz o ciclo quando existe item `READY` seguro no backlog.

Mudanças exclusivamente administrativas, de logging ou da própria Sentinel não contam como avanço material de produto, salvo quando forem necessárias para remover um blocker real de produção.

## 10. Meta-work budget

O L5 não pode transformar a própria infraestrutura no produto principal.

Regras:

- no máximo uma intervenção de meta-infra por ciclo;
- meta-infra só pode preceder produto se remover blocker real;
- mudanças em CI, ledger, scheduler, adapters de QA ou state machine precisam estar ligadas a falha observada;
- após reparar meta-infra, o agente deve voltar ao backlog do jogo ativo no mesmo ciclo quando ainda houver tempo e segurança;
- dois ciclos consecutivos consumidos apenas por meta-work abrem `PRODUCTIVITY_STALL`.

## 11. PRODUCTIVITY_STALL watchdog

Se `consecutiveNoMaterialAdvanceCycles >= 2` sem blocker externo comprovado:

1. marcar `PRODUCTIVITY_STALL`;
2. registrar fingerprint estável;
3. analisar por que o agente está preso;
4. impedir repetição da mesma atividade de auditoria;
5. escolher uma tarefa independente de alto valor;
6. se necessário, reduzir escopo para um microavanço verificável;
7. somente manter stall se nenhuma tarefa segura existir.

O objetivo é impedir que o agente passe horas verificando o mesmo estado sem construir nada.

## 12. Gates L5

Os 18 gates L4 permanecem:

- CANON;
- RUNTIME;
- ASSET;
- INPUT;
- COMBAT;
- PROGRESSION;
- UI;
- PLATFORM;
- REGRESSION;
- PERFORMANCE;
- ASYNC_RUNTIME;
- DEVICE_MATRIX;
- SECURITY;
- EVIDENCE_FRESHNESS;
- SAVE_INTEGRITY;
- RECOVERY;
- CROSS_GAME_CONTRACT;
- SELF_HEALTH.

O L5 adiciona gates de processo:

- `DEVELOPMENT_CONTINUITY`;
- `BACKLOG_INTEGRITY`;
- `PRODUCTIVITY`;
- `ROLLBACK_READINESS`;
- `RELEASE_READINESS`.

Estes gates não substituem os gates técnicos. Eles medem se o agente está de fato trabalhando e se consegue promover o jogo com segurança.

## 13. Semântica de bloqueio refinada

Classificação de gate:

- `CRITICAL_BLOCKER`: impede qualquer mudança relacionada e pode suspender desenvolvimento;
- `LOCAL_BLOCKER`: impede apenas domínio/tarefa relacionada;
- `RELEASE_BLOCKER`: não impede desenvolvimento, mas impede promoção para próximo jogo;
- `OBSERVATION`: requer evidência futura, mas não bloqueia tarefa independente.

Exemplo:

- `CANON_RED` = CRITICAL_BLOCKER;
- `RUNTIME_RED` = CRITICAL_BLOCKER;
- `COMBAT_UNKNOWN` = LOCAL_BLOCKER para mudanças que exigem validação completa de combate, mas pode ser justamente o próximo alvo a provar;
- `WEBGL_FALLBACK_UNKNOWN` = RELEASE_BLOCKER/OBSERVATION para trabalho de áudio ou HUD não relacionado;
- `PERFORMANCE_UNKNOWN` = RELEASE_BLOCKER, salvo quando a mudança pode piorar performance de forma material.

## 14. Prova de vida real

O L5 deve aumentar gradualmente a prova de jogabilidade, especialmente no `activeGame`.

Para CHRONICA 3D, cadeia alvo:

`boot → iniciar run → movimento → câmera → ataque → hit/dano → reação do inimigo → morte/estado pós-combate → resolução do encontro → transição de etapa → save QA isolado → reload → retomada → pause/retry → ausência de erros fatais`.

`COMBAT_GREEN` exige cadeia observável de combate.

`PROGRESSION_GREEN` exige transição legítima ou simulação determinística explicitamente marcada, sem adulterar save real.

O L5 pode introduzir hooks QA read-only e isolados quando necessários para provar estados internos, desde que:

- não alterem comportamento normal;
- não exponham segredo;
- não concedam cheat ao jogador público;
- não escrevam progresso institucional;
- sejam removíveis/reversíveis;
- sejam cobertos por teste.

## 15. SAVE_INTEGRITY e namespace QA

Todo teste destrutivo de persistência deve usar namespace/perfil de QA isolado.

Requisitos:

- save real do usuário nunca é usado para limpeza ou simulação destrutiva;
- reload deve preservar estado esperado;
- migrações devem ser backward-safe quando aplicável;
- corrupção, schema mismatch ou overwrite inesperado são RED;
- se não existir isolamento seguro, criar mecanismo QA limitado antes de testar progressão destrutiva.

## 16. Recovery e fault injection seguro

O L5 deve testar recovery sem afetar usuários reais.

Métodos preferidos:

- interceptação Playwright;
- fixtures locais/QA;
- request abort em sessão de teste;
- simulação de asset ausente;
- fallback de reload;
- fallback WebGL quando possível;
- pause/resume e retry;
- recovery de save QA.

Falha induzida não deve ser implantada globalmente em produção.

## 17. Performance orientada a tendência

O L5 mantém coleta por rota/viewport:

- `sentinelReadyMs`;
- DOMContentLoaded;
- loadEventEnd;
- transfer size;
- decoded body size;
- long tasks quando disponíveis;
- memória quando disponível;
- FPS/frame pacing quando mensurável com baixo ruído.

Não corrigir com base em um único outlier. Regressão exige tendência ou reprodução consistente.

Mudanças de produto que piorarem performance de forma material devem ser revertidas ou ajustadas antes de aceitação.

## 18. Segurança

Continuam obrigatórios:

- `npm audit --audit-level=high` ou equivalente;
- nenhum segredo, token ou credencial em runtime público, logs ou artefatos;
- dependências de QA sem vulnerabilidade HIGH/CRITICAL conhecida;
- nenhum endpoint privado exposto sem necessidade;
- nenhum dado sensível em screenshots/artefatos;
- nenhuma automação recebe autoridade financeira ou institucional por causa de gameplay.

## 19. Anti-regressão transversal

Depois de qualquer alteração no `activeGame`:

- retestar os gates diretamente afetados;
- executar smoke do activeGame;
- executar smoke transversal dos três jogos quando a mudança tocar shared contract, guard, assets comuns, input infra, CSS/JS compartilhado ou publisher infra;
- rejeitar mudança local que quebre outro runtime;
- preservar evidência de antes/depois.

## 20. Baselines

Dois níveis de baseline:

### 20.1 Working Baseline
Último estado aceito do jogo durante desenvolvimento contínuo.

### 20.2 Golden Baseline
Estado integralmente GREEN e elegível para promoção de fila.

O L5 pode continuar desenvolvendo usando Working Baseline sem fingir que o jogo já possui Golden Baseline.

Golden Baseline exige:

- todos os gates técnicos GREEN;
- gates de processo GREEN;
- commit/hash de produção;
- page/asset hashes;
- device matrix;
- performance baseline;
- screenshots/evidências;
- save/recovery comprovados;
- smoke transversal;
- ausência de blocker conhecido.

## 21. Promotion policy

Promoção `chronica-3d → harun-roguelite` só ocorre quando:

- todos os 18 gates técnicos estão GREEN;
- gates L5 de processo estão GREEN;
- Golden Baseline salvo;
- cross-game smoke aprovado;
- nenhuma evidência é stale;
- nenhum blocker está UNKNOWN/RED/BLOCKED;
- ledger e backlog estão reconciliados;
- o jogo ativo possui release-readiness explícita.

Depois de survivor, a fila retorna à CHRONICA para novo ciclo de refinamento, usando o Golden Baseline anterior como referência.

## 22. CHRONICA 3D — prioridade inicial L5

Como `chronica-3d` é o jogo ativo, o primeiro ciclo L5 deve priorizar:

1. prova real de COMBAT;
2. prova real de PROGRESSION;
3. namespace QA e SAVE_INTEGRITY;
4. recovery seguro e WebGL fallback;
5. estabelecer Working Baseline atual;
6. concluir baseline de performance;
7. inventariar backlog real de produto já existente;
8. retomar evolução visível e mecânica.

Após desbloquear a cadeia de prova, a ordem de desenvolvimento privilegia:

- sensação e legibilidade do combate;
- diversidade real de inimigos e bosses;
- feedback de hit/dano/morte;
- arenas/salas e progressão das 16 etapas;
- primeira pessoa e câmera opcional sem regressão;
- arquitetura/ambiente/materiais/iluminação;
- VFX e áudio espacial/feedback;
- HUD/UX;
- performance;
- persistência e recovery;
- polish.

## 23. Roguelite e Survivor

Quando promovidos a activeGame:

### Roguelite
Priorizar:

- salas e encounter design;
- padrões distintos de inimigos/bosses;
- Arcanas/reliquias/builds;
- combate top-down responsivo;
- paridade das 16 etapas;
- desktop + mobile compatibility;
- run persistence;
- readability e polish.

### Survivor
Priorizar:

- mobile-first input;
- ondas/atos coerentes com a ordem canônica;
- elites/bosses;
- builds/metaprogressão apenas gameplay;
- legibilidade em tela pequena;
- performance mobile;
- compatibilidade desktop;
- save/recovery;
- polish.

## 24. Repair budget e circuit breaker

Mantém-se o máximo de duas tentativas distintas por fingerprint por execução.

Antes de editar:

- capturar commit/hash/version;
- registrar hipótese;
- registrar rollback;
- definir evidência de sucesso.

Se a primeira hipótese falhar, a segunda deve ser causalmente diferente. Duas falhas abrem `CIRCUIT_OPEN` para aquele fingerprint no ciclo.

O agente então deve buscar tarefa independente segura em vez de encerrar todo o ciclo, salvo blocker crítico global.

## 25. Ledger append-only

O `repair-ledger` evolui para registrar também desenvolvimento.

Novo ledger recomendado:

`ops/mundus-game-sentinel/director-ledger.jsonl`

Eventos:

- `DISCOVERY`;
- `OBJECTIVE_SELECTED`;
- `CHANGE_ATTEMPT`;
- `TEST_FAILURE`;
- `PRODUCT_FAILURE`;
- `REPAIR`;
- `MATERIAL_ADVANCE`;
- `ROLLBACK`;
- `BASELINE_ACCEPTED`;
- `GOLDEN_BASELINE`;
- `PRODUCTIVITY_STALL`;
- `PROMOTION`;
- `EXTERNAL_BLOCKER`.

Nada histórico é reescrito para parecer que uma tentativa fracassada nunca ocorreu.

## 26. Automação e scheduler

O supervisor horário existente deve ser atualizado para L5.

Cada execução deve:

1. fazer preflight de estado/branch/produção;
2. validar freshness;
3. verificar blockers críticos;
4. reparar quando necessário;
5. selecionar um objetivo de desenvolvimento se houver trabalho seguro;
6. implementar;
7. publicar/patch quando aplicável;
8. testar;
9. aceitar ou reverter;
10. atualizar backlog/state/ledger;
11. avaliar promoção;
12. notificar somente mudança material ou blocker real.

O GitHub CI continua preferencialmente read-only como produtor de evidência. A automação de reparo/desenvolvimento consome essa evidência e efetua mudanças controladas. Evitar workflows que auto-commitam o próprio estado em loop.

## 27. Self-health

O L5 deve monitorar:

- `last_run_time` da automação;
- último workflow relevante;
- branch head;
- freshness de artefatos;
- scheduler independente;
- divergência entre state e produção;
- execução perdida > 90 min;
- loop de no-op;
- loop de meta-work;
- backlog sem cursor válido;
- objective ACTIVE sem progresso por ciclos sucessivos.

`SELF_HEALTH_GREEN` não significa apenas “a automação disparou”; significa que disparou, conseguiu ler fontes, produziu decisão coerente e não ficou travada silenciosamente.

## 28. Métricas de sucesso L5

A eficácia do L5 deve ser medida por:

- ciclos com avanço material;
- bugs detectados antes do usuário;
- bugs reparados e verificados;
- regressões revertidas automaticamente;
- itens de backlog aceitos;
- tempo entre descoberta e reparo;
- tempo entre objetivos de desenvolvimento;
- proporção de ciclos consumidos por meta-work;
- gates convertidos de UNKNOWN/RED para GREEN por evidência real;
- estabilidade do Golden Baseline;
- promoções legítimas de fila;
- ausência de drift canônico.

A métrica principal não é “quantos checks rodaram”, e sim “quanto o jogo avançou sem regredir”.

## 29. Limites de autonomia

O L5 pode autonomamente:

- editar código do jogo ativo;
- corrigir bugs;
- criar/ajustar testes;
- adicionar hooks QA read-only;
- ajustar UI/UX;
- melhorar gameplay e feedback;
- otimizar performance;
- melhorar arte procedural, materiais, iluminação, VFX e áudio quando o pipeline permitir;
- atualizar backlog/state/ledger;
- publicar mudanças reversíveis no WebsitePublisher;
- reverter mudança própria ruim.

O L5 não pode autonomamente:

- reescrever cânone governante;
- conceder progressão institucional real;
- alterar identidade autoral/institucional;
- ativar cobrança ou dinheiro real;
- apagar histórico para “limpar” falhas;
- usar save real do usuário em teste destrutivo;
- promover jogo com gate obrigatório não comprovado;
- declarar produção art final quando houver apenas placeholder/procedural provisório;
- mascarar blocker como sucesso.

## 30. Migração L4 → L5

Migração deve ser incremental e reversível:

1. criar spec e plano;
2. adicionar testes RED para semântica L5;
3. elevar schema de estado;
4. adicionar backlog governante;
5. implementar classificação de blockers;
6. implementar seleção de objetivo;
7. implementar watchdog de produtividade;
8. implementar Working vs Golden Baseline;
9. estender ledger;
10. atualizar automação para L5;
11. executar CI completo;
12. executar ciclo controlado apenas em CHRONICA 3D;
13. provar um avanço material real;
14. manter fila travada até release-readiness integral.

Rollback da migração: restaurar prompt L4, state schema anterior e ignorar os novos arquivos L5 sem alterar os três runtimes.

## 31. Critério de conclusão da implementação L5

A implementação do L5 só é considerada concluída quando existir evidência de que:

- o state machine conhece L5;
- backlog vivo é persistido;
- um ciclo escolhe objetivo de produto;
- pelo menos um teste de produtividade impede no-op injustificado;
- um blocker local não paralisa tarefa independente;
- um blocker crítico ainda bloqueia corretamente;
- Working Baseline e Golden Baseline são distintos;
- promotion continua fail-closed;
- automação horária está atualizada;
- CI passa;
- CHRONICA 3D recebe pelo menos um avanço material aceito após a migração;
- smoke transversal continua verde;
- nenhum cânone foi alterado para acomodar implementação.

## 32. Resultado esperado

O MUNDUS · AUTONOMOUS GAME DIRECTOR L5 deve deixar de ser um sistema que apenas impede regressões e passar a ser um sistema que **constrói continuamente sob disciplina de engenharia**.

O estado saudável desejado é:

`SEGURO → PRODUTIVO → TESTADO → REVERSÍVEL → DOCUMENTADO → CONTÍNUO`

A fila só promove jogos integralmente prontos, mas o desenvolvimento do jogo ativo não fica parado esperando perfeição administrativa em gates não relacionados.
