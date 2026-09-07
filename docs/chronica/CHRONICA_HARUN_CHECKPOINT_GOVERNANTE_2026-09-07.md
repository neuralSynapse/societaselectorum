# CHRONICA HARUN · CHECKPOINT GOVERNANTE · 2026-09-07

Repositório: `neuralSynapse/societaselectorum`

Workspace governante local: `/mnt/data/chronica-godot-recovered/.worktrees/narrative-integration/`

Branch local governante: `feat/chronica-world-expansion-v3`

HEAD local governante: `a558da28caa4f9b0f475e2a7e81a78c15696f415`

## Estado validado localmente

- `pytest -q`: **87 passed**.
- `COMPLETE GAME VALIDATION: PASS`.
- `CHRONICA STORY CANON VALIDATION: PASS`.
- Frente C reconciliada conscientemente na árvore local.
- 82 inimigos e 16 bosses no contrato governante.
- 78 Tarot, 72 Sigilla, 21 Pharmaka, 36 Talismãs, 32 Instrumenta, 15 Poderes-Matriz, 45 mutações e 7 Daimones.
- 12 transformações, 8 rotas, curses/blessings, gauntlets e 26 salas especiais.
- Éden/Arbor Vitae e Arbor Mortis implementados como sistemas.
- Nove Libri, Kinesis, mentores, rupturas temporais, camada quântica e arsenal ritual implementados no runtime local.
- Primeira pessoa permanece padrão; câmera sobre o ombro existe como opção.
- Story Bible, prólogo cinematográfico, 16 arcos de etapa e epílogo Aleppo c.1585 integrados.

## Persistência

Google Drive continua bloqueando gravação: última tentativa via import de TXT retornou `storageQuotaExceeded`; tentativas de criar Google Doc retornaram `PERMISSION_DENIED`.

Enquanto isso, GitHub é a persistência governante.

## Caminho crítico até a build jogável

1. Persistir a fonte completa sem truncamento em GitHub.
2. Reconstruir archive no GitHub Actions e conferir SHA-256.
3. Regenerar 82 GLBs de inimigos e 16 GLBs de bosses.
4. Rodar pytest completo.
5. Rodar Godot 4.3 headless import.
6. Rodar boot smoke da Main.
7. Corrigir parser/resources/runtime conforme evidência.
8. Exportar Windows `CHRONICA_HARUN.exe`.
9. Publicar artifact ZIP jogável.
10. Absorver Frente B quando sua fonte final de combate estiver realmente disponível e rodar regressão completa.

## Regra de conclusão

Não declarar CHRONICA HARUN pronto para jogar até existir executável Windows validado ou um bloqueio externo real comprovado.
