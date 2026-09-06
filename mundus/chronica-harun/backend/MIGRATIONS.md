# CHRONICA HARUN · Migration History

Registro do estado aplicado no Neon DEV e PROD. O banco é a evidência operacional; este arquivo preserva a sequência e as invariantes que não podem regredir.

## 1.0.0

Schema persistente inicial com `profiles`, `real_progress_gate`, `real_progress_gate_audit`, `runs`, `run_events`, `speculi_entries`, `codex_unlocks`, `relic_states`, `world_state`, `save_slots`, `telemetry_events`, `feature_flags`, `backend_meta` e `infra_migrations`. RLS e `backend_health()` incluídos.

## 1.1.0

Guards de ownership entre usuário e run para impedir anexação cross-user de eventos, relíquias, Speculi ou Codex. Triggers de `updated_at` adicionados.

## 1.2.0

Função privilegiada de mutação canônica do `real_progress_gate`. `anonymous` e `authenticated` não recebem EXECUTE dessa função.

## 1.3.0

Contrato RPC autenticado. RPCs públicas do gameplay derivam identidade a partir do JWT no servidor: `start_run`, `append_run_event`, `finish_run`, `upsert_speculi`, `unlock_codex`, `save_campaign`, `update_world_state`, `record_relic`, `record_telemetry` e `campaign_snapshot`.

## 1.4.0

Guardrails de tamanho para JSON de cliente, limitando amplificação de request e crescimento de storage. Entre os tetos: save 1 MiB, world state 512 KiB, stats/Speculi 256 KiB e evento/telemetria 64 KiB.

## Invariantes obrigatórias

1. O cliente nunca decide nem escreve sozinho `real_progress_gate`.
2. `user_id` de operações autenticadas vem do JWT do servidor, não do payload do navegador.
3. RLS permanece habilitado nas tabelas expostas ao cliente.
4. Escritas associadas a uma run devem validar ownership.
5. Nenhuma chave privilegiada é embarcada no frontend.
6. O runtime legado continua funcionando quando backend, autenticação ou telemetria estiverem desativados.
7. Alterações futuras devem validar DEV antes de PROD e executar healthcheck e testes negativos de segurança depois da migration.

## Verificações de referência

Em 2026-09-06, DEV e PROD reportaram `backend_health().ok=true` e `schema_version=1.4.0`. Testes negativos de ownership e payload oversized foram rejeitados sem resíduos. `anonymous` e `authenticated` não conseguem executar a mutação canônica do progresso real.
