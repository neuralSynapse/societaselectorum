# MUNDUS · GAME SENTINEL

Sentinela de QA, paridade canônica, anti-regressão e manutenção dos três jogos ativos de MUNDUS.

## Produção governada

- Central: `https://project27912.websitepublisher.ai/`
- 3D/FPS: `/chronica-harun-3d.html`
- Roguelite 2D: `/harun-roguelite.html`
- Survivor mobile: `/harun-survivor.html`

Arquivos como `mundus-fps.html`, `survivor-lab.html` e `fusion-v22-clean.html` são preservação/rollback e não entram na fila ativa.

## Regra central

Os três jogos são mecanicamente diferentes, mas contam a mesma CHRONICA HĀRŪN e obedecem ao mesmo contrato canônico. A forma de apresentar uma etapa pode mudar por gênero; ordem causal, identidade, proveniência e regras institucionais não.

A fila é estrita:

`chronica-3d → harun-roguelite → harun-survivor → repetir`

RED, UNKNOWN ou BLOCKED impedem avanço.

## Fonte de verdade

1. `game/chronica-harun/data/narrative/chronica_story_bible.json`
2. `game/chronica-harun/docs/canon/`
3. `game/chronica-harun/docs/chronica/CHRONICA_HARUN_CANONE_EXPANSAO_SISTEMICA_v3_0_2026-09-07.md`
4. `game/chronica-harun/data/**`
5. `canon-contract.json`
6. adaptadores de gênero

O contrato operacional não substitui o story bible; ele torna as invariantes verificáveis por máquina.

## Gates

`CANON_GREEN`, `RUNTIME_GREEN`, `ASSET_GREEN`, `INPUT_GREEN`, `COMBAT_GREEN`, `PROGRESSION_GREEN`, `UI_GREEN`, `PLATFORM_GREEN`, `REGRESSION_GREEN`.

Nenhum relatório pode declarar GREEN com gate ausente.

## Limites duros

- `PEREGRINUS_IGNIS_GAME` é estado narrativo de videogame, não Grau institucional.
- gameplay não escreve `real_progress_gate`.
- mentores históricos não recebem falsas citações.
- sistemas científicos não são usados como prova de poderes paranormais.
- dramatização autoral precisa permanecer distinguível de história/tradição.
- bug mecânico não autoriza reescrever cânone.
- build de arquivo não é promovida automaticamente.
- uma tentativa de reparo já falha para o mesmo fingerprint não é repetida indefinidamente.

## Arquivos

- `canon-contract.json`: invariantes compartilhados.
- `adapters/*.json`: tradução canônica por gênero.
- `validate_canon.py`: detector de drift.
- `state.json`: máquina de estados e jogo ativo.
- `sentinel.py`: transições de fila.
- `smoke_http.py`: rotas e assets críticos.
- `browser-smoke.spec.mjs`: browser QA real.
- `report.py`: relatório baseado em evidência.
- `baselines.json` / `baselines.py`: último estado verde e proteção de reparo.
- `repair-log.jsonl`: ledger append-only quando houver reparos.

## Comandos

```bash
pytest -q ops/mundus-game-sentinel/tests
python ops/mundus-game-sentinel/validate_canon.py
python ops/mundus-game-sentinel/sentinel.py check
python ops/mundus-game-sentinel/smoke_http.py
cd ops/mundus-game-sentinel && npm install && npx playwright install chromium && npm test
```

## Política de reparo

Prioridade: boot/crash → progressão impossível → cânone → input/combate → save → UI bloqueante → asset → performance → polimento.

Toda correção precisa de evidência posterior. Uma melhoria controlada só entra depois de o jogo ficar verde e obriga novo ciclo de testes.
