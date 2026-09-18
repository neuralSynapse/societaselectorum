# MUNDUS · Game 4 · Roomrun V15

## Regra de integração

V15 é aditiva e isolada. Não substitui V14, não altera a rota canônica `mundus/chronica-harun-definitive.html` e não deve apagar trabalho concorrente. A integração final ocorre por troca explícita do entrypoint depois do playtest.

## Instrumenta contextual

A barra global de ferramentas deixa de ser parte da experiência. O mundo contém quatro estações físicas e espaçadas:

- Bancada de Sobrevivência
- Forja de Extração
- Mesa Agrária
- Mesa de Precisão

A interface de ferramenta só abre por interação deliberada com a estação. Cada ferramenta possui forma, função, requisito, custo, estágio e predecessor.

Sequência: Faca → Machado → Picareta → Martelo → Foice → Enxada → Pá → Gadanha → Tesoura → Berbequim → Arpão.

A ferramenta ativa afeta colheita e combate; a seleção persiste localmente. O HUD não exibe a árvore completa.

## Carry e anti-clutter

O empilhamento visível de recursos na mochila foi removido. Resta somente uma bolsa pequena e um contador compacto de carga. Sacas de cenário foram reduzidas e separadas das rotas de NPC.

## Arquitetura espacial

Bancas de mercado, trabalhadores, edifícios e mesas foram redistribuídos com corredores mais largos. O desenho usa 2.5D isométrico: tampo, extrusão, pernas, sombra, material e detalhe próprio por estação, sem fingir 3D físico onde o runtime ainda é Canvas 2D.

## Anti-jitter

Seguidores usam aproximação por velocidade com zona morta e snap final. A posição lógica não recebe bob visual. Quando o alvo está dentro do epsilon, o NPC para de recalcular microdeslocamentos.

## Motivos narrativos do Game 4

- Estágio 2: fronteira de guerra.
- Estágio 4: caverna das sombras.
- Estágio 6: véu mediado, sem copiar propriedade visual de Matrix.
- Estágio 8: Capra contra a corrente.

Os motivos entram como linguagem ambiental e de progressão, sem disputar espaço com a mecânica central.

## Caixa Negra · hook dormente

A Caixa Negra está arquitetada, mas não ativada nesta build. O contrato previsto é:

1. evento estratégico cria a Caixa;
2. Hārūn entra;
3. uma substância ficcional ritual inicia o estado de superposição;
4. surge um corredor com três portas;
5. cada porta corresponde ao mundo de um dos Jogos 1–3;
6. o estado do Game 4 é serializado;
7. o avatar assume temporariamente as regras do mundo escolhido;
8. uma missão é cumprida;
9. o estado de Hārūn é restaurado no retorno;
10. a Caixa desaparece e só reaparece por condição narrativa futura.

As rotas das três portas permanecem nulas até o registro canônico dos entrypoints dos Jogos 1–3. Isso impede links falsos e regressão entre mundos.
