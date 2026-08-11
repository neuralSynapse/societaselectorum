# Stripe — H93-OF-001

Checkout oficial: **Stripe**. Hotmart não faz parte da implementação vigente.

## Produtos em produção

| Oferta | Valor | Product | Price |
|---|---:|---|---|
| Essencial | R$47 | `prod_V2RBmzy4RBIXEC` | `price_1U2MJK2aHZ9yiNGq8qWD2nC8` |
| Profunda | R$97 | `prod_V2RBqRQqWNFAA9` | `price_1U2MJQ2aHZ9yiNGqKFQxHnFY` |
| Completa | R$147 | `prod_V2RB6DYx4oxtJV` | `price_1U2MJW2aHZ9yiNGquVnBSuRd` |
| Hórus IA | R$17 | `prod_V2RCU5PjRynFp6` | `price_1U2MJe2aHZ9yiNGqIG82EJcZ` |

## Estado operacional

A conta Stripe está em verificação. Enquanto `charges_enabled` permanecer falso, não criar produtos duplicados nem inventar URLs de checkout.

Assim que a conta for liberada:

1. Criar um Payment Link para cada Price existente.
2. Habilitar métodos compatíveis em BRL, incluindo Pix quando disponível na conta.
3. Gravar as quatro URLs em `config/checkout.json`.
4. Substituir a configuração antiga do funil por Stripe.
5. Testar Essencial, Profunda, Completa e downsell de ponta a ponta antes de tráfego pago.

## Regra de implementação

Os botões do funil devem depender de uma única configuração central de checkout. Nunca espalhar URLs de pagamento manualmente por vários quadros.
