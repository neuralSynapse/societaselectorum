# H93-OF-001 — Changelog V10

## V10.2 — 2026-08-12

### Abertura híbrida da pergunta

- Headline principal alterada para: **“O que está impedindo o dinheiro de entrar ou permanecer na sua vida?”**
- Abertura agora oferece dois caminhos:
  1. **Quero descobrir o que está bloqueando** — segue pelo diagnóstico guiado.
  2. **Já tenho uma questão específica** — abre campo livre para a pessoa escrever a própria situação.
- No caminho livre, o sistema identifica um eixo inicial entre **entrada**, **permanência**, **crescimento**, **decisão sob pressão** ou **entrada e permanência**.
- O sistema apresenta uma **pergunta sugerida para a tiragem**, permitindo que a pessoa escolha entre usar a formulação sugerida, manter a própria pergunta ou editar.
- A reformulação funciona como primeiro microganho antes da escolha das cartas.

### Continuidade da personalização

- A pergunta aprovada passa a acompanhar o restante do percurso.
- A etapa “Comece pela situação real” mostra a pergunta que está orientando a tiragem.
- Na coleta de dados, a pergunta de abertura já aparece preenchida e pode receber contexto adicional, evitando perguntar tudo novamente.
- O diagnóstico final exibe a pergunta que organizou a leitura e o eixo identificado.
- O PDF passa a incluir a pergunta da tiragem antes do padrão dominante.

### Estado e QA

- Estado migrado para `H93_OF_001_V10_2_STATE`, invalidando a sessão V10 anterior para que a nova abertura apareça imediatamente.
- A etapa inicial não pode avançar sem uma pergunta definida.
- Smoke test cobre abertura híbrida, pergunta específica, refinamento, aceitação da sugestão e propagação até o diagnóstico.
