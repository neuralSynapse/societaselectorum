# H93-OF-001 — V12

## Objetivo

Transformar a etapa comercial do Oráculo Financeiro de THOTH em uma esteira segura e automatizada, preservando a build canônica V11.2 e removendo a dependência de Payment Links fixos ou de preços controlados pelo navegador.

## Arquitetura

1. O funil público continua sendo gerado pelo pipeline V10 → V11 → V11.1 → V11.2 → finalização canônica.
2. `scripts/apply-v12.mjs` é aplicado somente depois de todas as validações da build canônica.
3. A camada V12 intercepta o checkout e envia apenas plano, combinação de complementos e contexto ao domínio oficial da Societas Electorum.
4. O navegador nunca envia `amount`, `price_id` ou `unit_amount` como autoridade de cobrança.
5. O WebsitePublisher usa formulários SAPI existentes para transportar a solicitação ao backend AppDeploy.
6. O backend AppDeploy valida plano/combo contra mapeamentos fechados, cria a sessão Stripe server-side e registra a consulta.
7. No retorno da Stripe, o domínio oficial confirma a sessão e o backend repete a validação de pagamento, valor, moeda, metadata e vínculo da consulta.
8. Somente após a confirmação real são geradas a leitura privada, o PDF quando adquirido e a credencial privada de entrega.
9. O e-mail transacional envia apenas o link privado da consulta.
10. Dúvidas pós-compra são respondidas dentro da leitura original e não abrem uma nova tiragem.

## Mudanças comerciais

- Essencial: leitura privada escrita, 3 cartas e plano direto.
- Profunda: até 3 perguntas relacionadas, 5 cartas e plano de 7 dias.
- Completa: até 5 eixos ou perguntas relacionados, 9 posições e Ferramenta de Integração personalizada.
- Hórus IA: entrada objetiva de 1 pergunta e 1 carta.
- Bump PDF preservado.
- Bump de pergunta extra preservado e exige pergunta objetiva antes do checkout.
- Promessas de áudio/vídeo e de ferramenta gravada foram removidas quando não correspondem à entrega automatizada atual.
- Expansões pós-compra não são tratadas como compradas sem uma nova transação real.

## Segurança

- Origem e `event.source` são validados na ponte `postMessage`.
- Checkout direto fora do domínio oficial é bloqueado.
- Consentimento específico de processamento e entrega é exigido antes do checkout.
- Token privado de consulta não contém o conteúdo da leitura.
- O backend persiste somente hash do segredo de acesso.
- A mesma sessão Stripe não pode ser vinculada silenciosamente a outra consulta.
- Falha de IA ou e-mail não transforma pagamento confirmado em pagamento inexistente.

## CI

O workflow de Pages executa `scripts/apply-v12.mjs` e `scripts/validate-v12.mjs` depois dos testes canônicos existentes e antes do upload para GitHub Pages. Se qualquer requisito crítico falhar, o deploy não ocorre.
