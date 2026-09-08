# CHRONICA HĀRŪN — Continuação em Sticklight

Data: 2026-09-08
Branch: `feat/chronica-replit-migration-v1`

## Motivo da migração
- Hercules chegou a 0 créditos após concluir QA técnico e iniciar uma passada visual não revalidada.
- Lovable workspace do projeto `43b794ec-620b-4f1d-982d-d2c92ba92687` também retornou `out of credits` ao tentar continuar.

## Novo builder
- Plataforma: Sticklight
- Project ID: `e847003a-f561-46aa-acc3-edd45d2ef772`
- Nome atual: `MUNDUS CHRONICA HARUN vlf6`
- Plano: Free
- Créditos antes da criação: 5
- Créditos após criação: 4

## Instruções entregues ao builder
O projeto foi criado como jogo 3D web, não site/dashboard, preservando:
- primeira pessoa;
- pointer lock / mouse-look;
- WASD + sprint;
- ataque corpo a corpo com arma visível;
- vida, dano, hit feedback, morte/restart;
- 6 inimigos com perseguição → windup → ataque → recovery;
- grace period após start/restart;
- proteção contra double-count de kills;
- vitória ao matar 6/6;
- menu/TITLE inicial;
- cenário histórico-ocultista inspirado em Aleppo/Halab otomana;
- Hārūn como personagem ficcional;
- crédito real Frater Horus Phosphorus.

## Primeira rodada de QA solicitada
Foi solicitado ao Sticklight verificar e corrigir o ciclo completo antes de expandir escopo: menu, gameplay, input, ataque, IA, dano, death, restart, repopulação, kill count e vitória; remover debug/hacks e reduzir custo de render quando necessário.

A resposta do agente informou que o projeto inicial ainda continha apenas template e que ele começou a construir o vertical slice e validar. O processamento foi iniciado, mas não foi considerado visualmente validado nesta etapa.

## Regra para próxima execução
1. Consultar o estado real do Sticklight primeiro.
2. Inspecionar créditos restantes antes de novas edições.
3. Não afirmar conclusão visual sem verificação.
4. Fechar o ciclo básico antes de múltiplas salas/roguelite.
5. Se Sticklight esgotar capacidade, registrar novo handoff e migrar para o próximo builder disponível.
