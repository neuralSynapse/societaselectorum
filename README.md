# H93-OF-001 — Oráculo Financeiro de THOTH

Repositório de publicação do **Oráculo Financeiro de THOTH — V9**, preservando integralmente a **V8** como fonte canônica.

## Produção

- URL pública: `https://neuralsynapse.github.io/societaselectorum/`
- Arquitetura canônica: 28 quadros.
- Fonte preservada: `source/v8/part-00.txt` a `part-08.txt`.
- Evolução V9: `source/v9/patcher.js` + `source/v9/state-fix.js`.
- Validação obrigatória antes de cada deploy: `scripts/validate-v9.mjs`.
- GitHub Actions bloqueia a publicação se uma regressão crítica for detectada.

## V9 implementada

- Estado isolado em `H93_OF_001_V9_STATE`, removendo contaminação das versões anteriores.
- Nenhuma seleção automática de carta no fluxo normal.
- Três cartas continuam ocultas até escolha do visitante.
- Paleta preta, violeta, dourado antigo e CTA vinho/dourado.
- Processamento visual em seis camadas: linguagem, arquétipos, simbologia, padrões comportamentais, ciclos e dinâmica financeira.
- Diagnóstico adaptativo: padrão dominante, custo invisível, mecanismo de repetição, primeiro comando de correção, leitura da carta e verdade percebida ainda não executada.
- Conselho operacional para as próximas 72 horas.
- Plano inicial com ação, risco de recaída, critério de execução, sinal de progresso e aprofundamento correspondente.
- Opção de salvar o diagnóstico em PDF pelo diálogo de impressão do navegador.
- Quatro depoimentos reais disponíveis no CDN são usados de forma adaptativa. Nenhum depoimento fictício foi criado.
- Selo canônico substitui o espaço visual quebrado enquanto a foto de autoridade aprovada não estiver disponível no CDN.

## Estrutura comercial

- Essencial: R$47.
- Profunda: R$97.
- Completa: R$147.
- Downsell exclusivo após recusa das ofertas principais: Hórus IA R$17.
- Pós-compra previsto: Ímã de Dinheiro R$9,97 e Mapa Numerológico Financeiro R$147.
- Checkout oficial: **Stripe**.

## Estado do checkout

Produtos e Prices estão registrados em `config/checkout.json`, porém os Payment Links permanecem vazios enquanto a Stripe não habilitar cobranças na conta. O botão de checkout falha de forma segura e não simula pagamento.

## Regra de fonte

Não reconstruir o funil a partir de versões antigas. A V8 permanece imutável e toda evolução deve ser aplicada por camada versionada, com QA automatizado e changelog.

## Tráfego

A página permanece `noindex` e não deve receber tráfego pago até: Stripe habilitar cobranças, Payment Links reais serem gravados, testes de compra serem concluídos, o canal transacional de e-mail estar operacional e a revisão visual desktop/mobile ser aprovada.
