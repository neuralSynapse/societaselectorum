# MUNDUS · GAME SENTINEL — Implementation Plan

> **For implementers:** execute tasks in order. Do not skip RED/GREEN evidence. This plan is scoped to the isolated branch `agent/mundus-game-sentinel-v1`.

**Goal:** Criar um sistema contínuo que valide, monitore e mantenha os três jogos ativos de MUNDUS como três experiências mecânicas distintas que obedecem a um único cânone, trabalhando em somente um jogo por vez e recusando avanço de fila enquanto qualquer gate estiver vermelho.

**Architecture:** Um contrato canônico JSON governa invariantes; adaptadores JSON mapeiam cada gênero ao contrato; um validador Python prova paridade; um runner Python mantém a máquina de estados e compõe relatórios; Playwright testa as rotas WebsitePublisher; GitHub Actions executa QA determinístico; uma automação horária do ChatGPT usa os relatórios para reparar somente o jogo ativo.

**Stack:** Python 3.12, pytest, Node 20, Playwright Chromium, GitHub Actions, WebsitePublisher projeto 27912.

---

## Task 1 — Congelar contrato canônico compartilhado

**Files:**
- Create: `ops/mundus-game-sentinel/canon-contract.json`
- Create: `ops/mundus-game-sentinel/adapters/chronica-3d.json`
- Create: `ops/mundus-game-sentinel/adapters/harun-roguelite.json`
- Create: `ops/mundus-game-sentinel/adapters/harun-survivor.json`
- Test: `ops/mundus-game-sentinel/tests/test_canon_contract.py`

**Step 1 RED:** criar teste que exige `contractVersion`, 16 etapas ordenadas, `PEREGRINUS_IGNIS_GAME`, `institutionalWrite=false` e três adaptadores com a mesma sequência canônica.

**Step 2:** executar `pytest -q ops/mundus-game-sentinel/tests/test_canon_contract.py`; confirmar falha por arquivos ausentes.

**Step 3 GREEN:** criar contrato e adaptadores mínimos que satisfaçam as regras sem homogeneizar as mecânicas.

**Step 4:** executar teste novamente; confirmar verde.

## Task 2 — Validador de drift canônico

**Files:**
- Create: `ops/mundus-game-sentinel/validate_canon.py`
- Extend: `ops/mundus-game-sentinel/tests/test_canon_contract.py`

**Step 1 RED:** adicionar casos que falham quando um adaptador troca ordem, fixa cronologia aberta, marca escrita institucional como verdadeira ou inventa proveniência tradicional.

**Step 2 GREEN:** implementar validador que devolve erros estruturados por jogo/gate.

**Step 3:** rodar suíte do sentinela.

## Task 3 — Máquina de estados persistente

**Files:**
- Create: `ops/mundus-game-sentinel/state.json`
- Create: `ops/mundus-game-sentinel/sentinel.py`
- Test: `ops/mundus-game-sentinel/tests/test_sentinel_state.py`

**Step 1 RED:** testar: fila 3D → roguelite → survivor; RED não avança; BLOCKED não avança; GREEN completo avança; fim do terceiro volta ao 3D e incrementa ciclo.

**Step 2 GREEN:** implementar transições determinísticas, fingerprints e contador de tentativas.

**Step 3:** verificar que `advance` exige todos os gates verdes.

## Task 4 — Smoke HTTP e assets

**Files:**
- Create: `ops/mundus-game-sentinel/smoke_http.py`
- Test: `ops/mundus-game-sentinel/tests/test_smoke_http.py`

**Step 1 RED:** testar parsing de página, status inválido, asset crítico ausente e rota de arquivo erroneamente inserida na fila.

**Step 2 GREEN:** implementar checks para as três rotas ativas no projeto 27912.

**Step 3:** saída JSON deve alimentar `RUNTIME_GREEN` e `ASSET_GREEN`.

## Task 5 — Browser QA com Playwright

**Files:**
- Create: `ops/mundus-game-sentinel/package.json`
- Create: `ops/mundus-game-sentinel/playwright.config.mjs`
- Create: `ops/mundus-game-sentinel/browser-smoke.spec.mjs`

**Step 1 RED:** smoke inicialmente exige seletor/estado de entrada e captura fatal de console/page/request.

**Step 2 GREEN:** implementar perfis:
- 3D: desktop 1440×900;
- roguelite: desktop 1280×720 + viewport móvel de compatibilidade;
- survivor: mobile 390×844.

**Step 3:** screenshots e JSON em `ops/mundus-game-sentinel/artifacts/`.

## Task 6 — Relatório e gates

**Files:**
- Create: `ops/mundus-game-sentinel/report.py`
- Test: `ops/mundus-game-sentinel/tests/test_report.py`

**Step 1 RED:** relatório deve recusar `GREEN` se qualquer gate obrigatório estiver ausente, desconhecido ou vermelho.

**Step 2 GREEN:** produzir `latest-report.json` e `latest-report.md` com evidência, fingerprints e prioridade de reparo.

## Task 7 — Workflow CI isolado

**Files:**
- Create: `.github/workflows/mundus-game-sentinel.yml`

**Step 1:** configurar `push` para `agent/mundus-game-sentinel-v1`, `workflow_dispatch` e execução horária quando o workflow for promovido à branch padrão.

**Step 2:** instalar Python/pytest, Node/Playwright, executar testes unitários, validador canônico e browser smoke.

**Step 3:** fazer upload dos relatórios e screenshots mesmo em falha.

**Step 4:** não escrever em produção, não auto-merge, não alterar main.

## Task 8 — Publicar contrato canônico no WebsitePublisher

**Files/Assets WebsitePublisher 27912:**
- Create asset: `data/mundus-canon-contract.json`
- Create asset: `js/mundus-canon-guard.js`
- Modify pages: `chronica-harun-3d.html`, `harun-roguelite.html`, `harun-survivor.html`

**Step 1 RED:** auditoria deve demonstrar que roguelite e survivor hoje não consomem o mesmo contrato canônico do 3D.

**Step 2 GREEN:** publicar contrato read-only e guard leve; cada página declara `data-mundus-game-id` e carrega o guard.

**Step 3:** guard não reescreve narrativa; apenas expõe identidade, versão e incongruências para diagnóstico.

## Task 9 — Corrigir drift inicial entre os três jogos

**Files WebsitePublisher:**
- Modify: `js/harun-roguelite.js`
- Modify: `js/harun-survivor-data-v3.js`
- Modify somente quando necessário: `js/harun-survivor-engine-v3.js`

**Step 1 RED:** gerar lista de divergências: survivor atual comprime a jornada em cinco atos e usa boss mapping próprio; roguelite possui 16 câmaras, mas nomes/semântica não equivalem 1:1 ao contrato das 16 etapas.

**Step 2:** classificar cada diferença como adaptação permitida ou drift.

**Step 3 GREEN:** acrescentar mapeamento explícito `canonStageId` sem destruir a mecânica existente. Preservar atos/salas enquanto deixa a relação com a cronologia governante legível por máquina.

**Step 4:** nunca transformar vitória de run em Grau real.

## Task 10 — Baseline, rollback e histórico

**Files:**
- Create: `ops/mundus-game-sentinel/baselines.json`
- Create: `ops/mundus-game-sentinel/repair-log.jsonl`
- Test: `ops/mundus-game-sentinel/tests/test_baselines.py`

**Step 1 RED:** garantir que reparo sem baseline conhecido seja recusado.

**Step 2 GREEN:** registrar version hashes WebsitePublisher e commit SHA GitHub por jogo.

**Step 3:** fingerprints iguais não podem consumir tentativa idêntica infinitamente.

## Task 11 — Verificação completa

Run:

```bash
pytest -q ops/mundus-game-sentinel/tests
python ops/mundus-game-sentinel/validate_canon.py
python ops/mundus-game-sentinel/sentinel.py check
npm --prefix ops/mundus-game-sentinel ci
npx --prefix ops/mundus-game-sentinel playwright install --with-deps chromium
npm --prefix ops/mundus-game-sentinel test
```

Além disso, preservar a suíte governante do jogo 3D conforme os workflows já existentes. Nenhuma alegação de sucesso sem resultado do GitHub Actions.

## Task 12 — Automação operacional horária

Criar automação ChatGPT `MUNDUS Game Sentinel` executada no máximo uma vez por hora. Em cada execução:

1. ler `state.json` e último relatório;
2. trabalhar somente no `activeGame`;
3. auditar produção WebsitePublisher e branch de reparo;
4. se vermelho, diagnosticar e aplicar a menor correção possível;
5. retestar/evidenciar;
6. atualizar ledger;
7. avançar apenas com todos os gates verdes;
8. se verde, executar no máximo uma melhoria controlada e retestar;
9. não tocar em builds de arquivo;
10. não alterar cânone para acomodar bugs mecânicos.

## Task 13 — Handoff e observabilidade

**Files:**
- Create: `ops/mundus-game-sentinel/README.md`

Documentar URL da Central, três rotas ativas, branch, fontes de verdade, comandos, estados, política de reparo e regra de paridade. Um agente futuro deve conseguir continuar sem depender de contexto oral da conversa.
