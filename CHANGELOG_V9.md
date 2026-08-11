# CHANGELOG — H93-OF-001 — V9

Data: 2026-08-11

## Princípio de atualização

A V8 não foi reescrita. Ela permanece em `source/v8/` como fonte canônica. A V9 é uma camada de evolução aplicada durante a montagem do HTML.

## Correções

- Isolamento de estado da V9 com chave própria.
- Remoção do estado legado que podia revelar uma carta antiga de sessão anterior.
- Remoção da seleção automática da primeira carta ao saltar para quadros avançados no fluxo normal.
- Proteção para exigir escolha real de uma das três cartas.
- Roteamento de depoimentos limitado aos quatro screenshots reais existentes no CDN.
- Espaço de autoridade sem imagem quebrada; selo canônico utilizado enquanto a fotografia aprovada não estiver publicada.

## Experiência e direção visual

- Migração visual para preto profundo, violeta e dourado antigo.
- CTA principal em vinho com contorno dourado.
- Versos das cartas reforçados em violeta/preto/dourado.
- Processamento visual reorganizado em seis linguagens interpretativas.

## Diagnóstico

A leitura inicial agora apresenta:

1. Padrão dominante.
2. Custo invisível.
3. Mecanismo de repetição.
4. Primeiro comando de correção.
5. Carta escolhida aplicada à situação.
6. Verdade percebida ainda não executada.

## Ação

- Conselho dividido em interromper, sustentar e executar nas próximas 72 horas.
- Plano inicial com ação, risco de recaída, critério de execução, sinal de progresso e aprofundamento correspondente.
- Diagnóstico pode ser salvo em PDF pelo mecanismo de impressão do navegador.

## Dados e entrega

- Campo de e-mail adicionado à etapa de dados.
- A interface não afirma envio automático enquanto o provedor transacional não estiver operacional.

## Comercial

- Mantidas as ofertas R$47, R$97 e R$147.
- Hórus IA R$17 permanece exclusivamente como downsell após recusa das ofertas principais.
- Stripe permanece como checkout oficial.
- Hotmart não faz parte da V9.
- Sem Payment Link real, nenhum pagamento é simulado.

## QA

- Foi criado `scripts/validate-v9.mjs`.
- O workflow do GitHub Pages executa o validador antes de publicar.
- Uma regressão crítica interrompe o deploy.
