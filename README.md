# H93-OF-001 — Oráculo Financeiro de THOTH

Repositório de publicação do **Oráculo Financeiro de THOTH — V8 Consolidado**.

## Estado atual

- Arquitetura canônica: 28 quadros.
- Ofertas: R$47 / R$97 / R$147.
- Downsell: Hórus IA R$17.
- Checkout oficial: **Stripe**.
- Quatro produtos e Prices já criados em produção.
- Payment Links aguardam liberação da conta Stripe para cobranças.
- Pix será usado quando estiver habilitado pela Stripe para a conta.

## Regra de fonte

Não reconstruir o funil a partir de versões antigas. A fonte canônica é a V8 FINAL recuperada do projeto H93-OF-001.

## Checkout

IDs e estado operacional ficam em `config/checkout.json`. Detalhes de implantação estão em `STRIPE.md`.

## Deploy

O `index.html` atual é um carregador temporário e só deve ser considerado funcional quando todas as partes/ativos da V8 estiverem presentes. Não direcionar tráfego pago antes do QA de publicação e do teste de compra completo.
