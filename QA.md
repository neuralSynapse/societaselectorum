# QA — H93-OF-001 — V9

## Validado automaticamente antes da publicação

- V8 preservada em 9 partes: `source/v8/part-00.txt` a `part-08.txt`.
- V9 aplicada por camadas separadas, sem reescrever a fonte canônica.
- `source/v9/patcher.js` passou pela execução real do Node durante o workflow.
- `source/v9/state-fix.js` passou pela execução real do Node durante o workflow.
- Montagem V9 validada por `scripts/validate-v9.mjs` antes do deploy.
- 28 quadros continuam presentes.
- Chave de estado antiga `h93of001v8` não permanece como chave ativa de gravação.
- Seleção automática da primeira carta foi removida do fluxo normal.
- Diagnóstico V9 contém padrão dominante, custo invisível, mecanismo de repetição, primeiro comando de correção, leitura da carta e verdade ainda não executada.
- Conselho de 72 horas e plano operacional V9 presentes.
- Campo de e-mail e função de salvamento em PDF presentes.
- Quatro screenshots reais de depoimentos disponíveis no CDN permanecem integrados.
- Nenhuma referência a Hotmart no HTML montado.
- Checkout configurado para Stripe live em `config/checkout.json`.
- IDs das quatro ofertas principais são validados no CI.
- Ofertas principais: R$47, R$97, R$147; downsell Hórus IA R$17.
- Botão de pagamento não cobra enquanto o Payment Link estiver vazio.
- Deploy GitHub Pages só ocorre após o validador passar.

## Deploy confirmado

Workflow `Deploy H93 to GitHub Pages` concluído com sucesso para a V9 depois da validação automatizada.

URL: `https://neuralsynapse.github.io/societaselectorum/`

## Bloqueios reais antes de tráfego

1. Stripe precisa mudar `charges_enabled` para `true`.
2. Pix/cartão precisam estar efetivamente habilitados para cobrança em BRL.
3. Payment Links reais precisam ser criados e gravados em `config/checkout.json`.
4. Uma compra real de cada rota comercial precisa ser testada.
5. O provedor transacional de e-mail precisa ser ativado; o serviço de saída ainda não está operacional.
6. Revisão visual humana desktop e mobile ainda é necessária na URL pública.
7. A foto de autoridade aprovada precisa ser disponibilizada no CDN; até lá, a V9 usa o selo canônico sem fingir que ele é uma fotografia.
8. Só depois remover `noindex` e iniciar tráfego pago.

## Regra de segurança

Não simular pagamento, confirmação, entrega, envio de e-mail ou disponibilidade de ativo que ainda não esteja operacional e verificável.
