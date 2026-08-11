# QA — H93-OF-001

## Validado antes da publicação

- Fonte montada em 9 partes em `source/v8/part-00.txt` a `part-08.txt`.
- HTML montado localmente: 71.816 caracteres / 72.638 bytes.
- Documento inicia com `<!doctype html>` e termina em `</html>`.
- JavaScript passou em `node --check` sem erro de sintaxe.
- 28 quadros presentes, numerados logicamente de 0 a 27.
- Nenhuma referência a Hotmart no HTML de staging.
- Checkout configurado para Stripe via `config/checkout.json`.
- Ofertas principais: R$47, R$97, R$147; downsell R$17.
- Bumps e upsells já possuem produtos/Prices Stripe em produção.
- Botão de pagamento não cobra enquanto o Payment Link estiver vazio; exibe aviso seguro.
- Layout contém regras responsivas para mobile.

## Bloqueios antes de tráfego

1. Stripe deve mudar `charges_enabled` para `true`.
2. Pix/cartão devem estar habilitados para os Payment Links em BRL.
3. Criar Payment Links reais e gravar em `config/checkout.json`.
4. Testar uma compra de cada rota comercial.
5. Revisar visualmente desktop e mobile na URL pública.
6. Completar os ativos visuais ainda ausentes no staging (foto de autoridade e depoimentos que não estão no CDN público).
7. Só depois remover o bloqueio de indexação em `robots.txt` e iniciar tráfego.
