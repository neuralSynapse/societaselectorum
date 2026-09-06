# CHRONICA HARUN · Backend Infrastructure

Backend persistente da CHRONICA HARUN, integrado de forma passiva à build web.

## Estado canônico

- Banco: Neon PostgreSQL 18, região São Paulo (`aws-sa-east-1`).
- Ambientes separados: DEV e PROD.
- Schema vigente: `1.4.0`.
- Neon Auth / Better Auth e Data API provisionados.
- RLS habilitado para dados de jogador.
- Identidade de usuário em RPCs é derivada do JWT no servidor. O cliente não fornece `user_id` autoritativo.
- `real_progress_gate` é somente leitura para o cliente autenticado. Confirmação ou revogação de progresso real é operação privilegiada e nunca decorre de XP, vitória, run ou desbloqueio digital.
- A build web carrega `adapter-v1.js` e `bootstrap-v1.js` depois do runtime v0.9. A ponte não altera câmera, áudio, narrativa, renderer ou IA de inimigos.
- Escritas remotas só ocorrem quando um `tokenProvider` autenticado é configurado. Antes disso, chamadas de escrita feitas pela ponte ficam em fila local limitada e o jogo continua no runtime legado.
- Telemetria, persistência remota e renderer v2 permanecem atrás de kill switches.

## Arquivos

- `adapter-v1.js`: cliente mínimo e allowlist das RPCs do backend.
- `bootstrap-v1.js`: ponte passiva, healthcheck, fila local limitada e integração futura de token autenticado.
- `contract-v1.json`: contrato operacional e limites de payload.
- `MIGRATIONS.md`: histórico aplicado e invariantes de segurança.

## Healthcheck

A ponte tenta primeiro o RPC público `backend_health` diretamente na Neon Data API. O proxy WebsitePublisher é apenas fallback. Nenhuma credencial privilegiada é enviada ao navegador.

## Regra de anti-regressão

Mudanças nesta pasta não autorizam alteração direta de loader, câmera, áudio, narrativa, renderer ou sistemas trabalhados por outras frentes. A integração no HTML deve permanecer aditiva e depois do runtime vigente, usando leitura fresca e controle por hash antes de qualquer patch.
