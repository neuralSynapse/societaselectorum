# CHRONICA HARUN · Backend Infrastructure

Backend persistente da CHRONICA HARUN, integrado de forma passiva à build web.

## Estado canônico

- Banco: Neon PostgreSQL 18, região São Paulo (`aws-sa-east-1`).
- Ambientes separados: DEV e PROD.
- Schema vigente em PROD: `1.5.0`.
- Neon Auth / Better Auth e Data API provisionados.
- RLS habilitado para dados de jogador.
- Identidade de usuário em RPCs é derivada do JWT no servidor. O cliente não fornece `user_id` autoritativo.
- `real_progress_gate` é somente leitura para o cliente autenticado. Confirmação ou revogação de progresso real é operação privilegiada e nunca decorre de XP, vitória, run ou desbloqueio digital.
- A build web carrega `adapter-v1.js`, `bootstrap-v1.js`, `auth-controller-v1.js`, `cloud-sync-controller-v1.js`, `auth-v1.js` e `sync-v1.js` depois do runtime v0.9. A ponte não altera câmera, áudio, narrativa, renderer ou IA de inimigos.
- Guest play permanece local. Quando existe sessão autenticada, o controller obtém o JWT via `auth.token()` e mantém fallback para `session.access_token` por compatibilidade.
- Persistência remota autenticada está habilitada. O bridge mantém fila local limitada quando ainda não existe token válido e faz flush após autenticação.
- `posthogTelemetry` e `rendererV2` continuam desativados no contrato de produção.

## Arquivos

- `adapter-v1.js`: cliente mínimo e allowlist das RPCs do backend.
- `bootstrap-v1.js`: ponte passiva, healthcheck, fila local limitada e configuração de token autenticado.
- `auth-controller-v1.js`: estado de sessão e resolução robusta do JWT Neon.
- `auth-v1.js`: integração da interface de conta com Neon Auth.
- `cloud-sync-controller-v1.js`: regras de sincronização e conflito local/nuvem.
- `sync-v1.js`: ligação da persistência remota ao runtime legado sem substituir seus sistemas visuais.
- `contract-v1.json`: contrato operacional e limites de payload.
- `MIGRATIONS.md`: histórico aplicado e invariantes de segurança.

## Healthcheck

O browser usa o endpoint server-side `https://chronica-harun-backend.vercel.app/api/health`. O endpoint consulta `public.backend_health()` no Neon com credencial mantida apenas no ambiente Vercel e devolve somente campos sanitizados. O navegador não chama mais o healthcheck diretamente na Neon Data API e nenhuma credencial privilegiada é embarcada no frontend.

## Verificação operacional

O E2E autenticado de produção validou Auth → JWT → save → snapshot → run → eventos → Speculi → Codex → estado mundial → relíquia → telemetria, além do isolamento cross-user. A tentativa de escrita cliente em `real_progress_gate` permanece rejeitada.

## Regra de anti-regressão

Mudanças nesta pasta não autorizam alteração direta de loader, câmera, áudio, narrativa, renderer ou sistemas trabalhados por outras frentes. A integração no HTML deve permanecer aditiva e depois do runtime vigente, usando leitura fresca e controle por hash antes de qualquer patch.
