# CHRONICA HĀRŪN — Handoff Hercules → próximo builder

Data: 2026-09-08
Branch: `feat/chronica-replit-migration-v1`

## Fonte de verdade
- Repositório canônico: `neuralSynapse/societaselectorum`
- Preservar o cânone existente.
- Frater Hārūn é personagem ficcional canônico.
- Crédito autoral real: Frater Horus Phosphorus.
- Não fazer merge em `main` sem aprovação explícita do usuário.

## Estado do Hercules
- App: `MUNDUS · CHRONICA HĀRŪN`
- App ID: `01M1ZK5HR3R8R7DAHGBBN0F8EE`
- Thread ID: `01M1ZK5J0WTF6HWCTWFV3D23SV`
- Slug: `mundus-chronica-harun`
- Public URL: https://mundus-chronica-harun.onhercules.app
- Builder: https://hercules.app/org/renan-baptist-1dmohswn/app/mundus-chronica-harun
- Créditos restantes ao encerrar: 0
- Última execução terminou com `out_of_credits`.

## Vertical slice implementado antes do esgotamento
- Primeira pessoa com teclado/mouse.
- Mouse-look e pointer lock, incluindo saída por Esc/retomada.
- WASD, sprint e limites da arena.
- Ataque primário corpo a corpo.
- Vida, dano, morte e restart.
- Grace period de 2 segundos no início de uma run normal.
- Feedback de hit e vignette de dano.
- IA de inimigos com estados e arquétipos GUARDIAN, SHADE e WARDEN.
- Atualização de IA consolidada em batch para reduzir writes Zustand por frame.
- Proteção contra contagem duplicada de kills.
- Vitória quando todos os inimigos morrem.
- EnemyRenderer persistente para corpos/overlays.
- HUD com VITAE, score, kill counter e crosshair.
- Arma visível em primeira pessoa (`WeaponView`) com animação de golpe/idle criada na rodada anterior.
- TITLE, PLAYER_DEAD e VICTORY overlays.

## QA confirmado antes da última passada visual
Uma execução de QA retornou:
- ESLint exit code: 0
- TypeScript/Vite TSC exit code: 0
- Convex TSC exit code: 0
- Hard refresh: sucesso
- Console frontend: zero erros; apenas warnings de deprecação do Three.js (`THREE.Clock` e `PCFSoftShadowMap`).
- Phase inicial restaurada para `TITLE`.

Screenshot TITLE validado:
https://hercules-cdn.com/file_IQ9lKebrEc60Id3JqvF8F5pa

Screenshot de gameplay anterior à correção visual final:
https://hercules-cdn.com/file_csWkWR3uSpzXH5LcGJiN19vG

Importante: o screenshot de gameplay foi produzido forçando temporariamente `PLAYING`; esse teste bypassava o fluxo normal de `restartGame()`. A fase foi posteriormente revertida para `TITLE`.

## Últimas alterações feitas antes de acabar o crédito
O agente iniciou uma rodada de correção visual, mas ficou sem créditos antes de revalidá-la. Portanto, estas mudanças devem ser consideradas **não validadas visualmente** até novo QA:

1. `Game.tsx`
   - tone mapping alterado de ACESFilmic para `NoToneMapping` (`toneMapping: 0`).
   - `toneMappingExposure={1.0}` adicionado.

2. `EnemyRenderer.tsx`
   - cores dos inimigos dessaturadas.
   - cores dos olhos reduzidas.
   - emissiveIntensity dos olhos reduzido para 0.6.
   - HP bars ajustadas para cores menos saturadas.

3. `Lighting.tsx`
   - torch lights reduzidas de ~2.2 para ~1.4.
   - alcance reduzido.
   - altar glow reduzido.
   - directional light reduzida.

4. `ArenaGeometry.tsx`
   - teto escurecido para `#0C0A06`.
   - sigil disc desaturado e emissiveIntensity reduzido.
   - o agente pretendia continuar reduzindo emissivos dos braseiros, mas ficou sem créditos no meio da tarefa.

5. `store.ts`
   - fase final devolvida para `TITLE`.
   - durante QA, `spawnTime` inicial foi alterado de `0` para `performance.now() / 1000`. Validar se isso é desejável no build final; o caminho normal `restartGame()` já define `spawnTime` corretamente.

## Pendências imediatas obrigatórias do próximo builder
1. Fazer novo lint + TypeScript depois das alterações visuais finais. Não assumir que continuam limpos.
2. Hard refresh e verificar console.
3. Validar visualmente TITLE e gameplay real sem deixar hacks de teste no estado final.
4. Confirmar `phase: "TITLE"` na entrega.
5. Confirmar `restartGame()` → enemies repopulam e grace period funciona.
6. Confirmar arma de primeira pessoa visível e animação de golpe.
7. Confirmar ataque/dano/kill/victory/death/restart em ciclos repetidos.
8. Revisar `spawnTime` inicial e remover qualquer alteração feita apenas para screenshot se desnecessária.
9. Terminar a correção visual de emissivos/braseiros e checar se NoToneMapping melhora de fato a cena; não manter a mudança apenas por hipótese.
10. Só depois expandir conteúdo.

## Próxima expansão após QA
- múltiplas salas conectadas;
- portas liberadas ao limpar encontro;
- recompensas/choices pós-sala;
- loop roguelite;
- variantes elite;
- boss framework com fases;
- fragmentos/codex;
- progressão coerente com o cânone;
- persistência;
- VFX/áudio/cinematics;
- substituição gradual de proxies geométricos por arte 3D de maior qualidade.

## Regra de migração
A próxima ferramenta deve continuar este estado conceitual e funcional, nunca reinterpretar CHRONICA HĀRŪN como site temático/dashboard e nunca reescrever o cânone para acomodar limitações técnicas.
