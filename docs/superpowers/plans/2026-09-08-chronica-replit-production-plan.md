# CHRONICA HĀRŪN Replit Production Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir no Replit o vertical slice 3D mais avançado possível de CHRONICA HĀRŪN e expandi-lo até o limite útil da plataforma, preservando o cânone e preparando handoff verificável para o próximo ambiente quando necessário.

**Architecture:** Replit em modo `3d_game` funciona como implementação jogável independente guiada pelo repositório e pelo cânone. O projeto é desenvolvido em fatias funcionais, com validação após cada fatia. Base44 fornece apenas referência estética. Nenhuma migração substitui o último estado funcional sem paridade comprovada.

**Tech Stack:** Replit Agent `3d_game`; stack interna escolhida pelo Replit; teclado+mouse; persistência local compatível com o runtime gerado; assets e conteúdo próprios/licenciados.

**Spec:** `docs/superpowers/specs/2026-09-08-chronica-cross-engine-production-design.md`

## Global Constraints

- Produto: `MUNDUS · CHRONICA HĀRŪN`.
- Primeira pessoa deve permanecer disponível e utilizável.
- Frater Hārūn é personagem ficcional; autoria real: `Frater Horus Phosphorus`.
- GitHub + cânone documental são fonte de verdade.
- Base44 é referência visual, não fonte canônica.
- Não usar proxies geométricos ou placeholders genéricos como arte final.
- Não fazer merge em `main` automaticamente.
- `VISUAL QA NOT VERIFIED` permanece até inspeção humana final.

---

### Task 1: Criar o projeto Replit 3D e o vertical slice jogável

**Interfaces:**
- Consome: especificação canônica e requisitos globais acima.
- Produz: app Replit 3D com preview executável, movimento, câmera, ataque, dano, uma arena, um inimigo e condição de vitória/morte.

- [ ] Criar um novo Replit App com stack `3d_game` chamado `MUNDUS · CHRONICA HĀRŪN`.
- [ ] Instruir o Replit Agent a priorizar runtime jogável sobre telas estáticas.
- [ ] Exigir primeira pessoa funcional, teclado+mouse e mouse-look.
- [ ] Exigir ataque primário, feedback de hit, vida do jogador e vida do inimigo.
- [ ] Exigir uma arena 3D histórica-occultista legível e sem aparência de dashboard.
- [ ] Validar no preview que o jogador controla personagem/câmera e consegue derrotar o inimigo.

### Task 2: Consolidar o loop roguelite

**Interfaces:**
- Consome: vertical slice funcional da Task 1.
- Produz: run com múltiplas salas, portas, recompensas e reinício.

- [ ] Pedir ao Replit Agent geração/seleção de sequência de salas com estado de run.
- [ ] Implementar portas travadas até limpar o encontro.
- [ ] Implementar recompensa de sala e escolha simples de melhoria.
- [ ] Implementar morte, restart e retorno consistente ao início do run.
- [ ] Validar que um run pode atravessar pelo menos três salas sem softlock.

### Task 3: Inimigos e combate sistêmico

**Interfaces:**
- Consome: loop de salas.
- Produz: framework de arquétipos que suporta expansão rumo aos 82 inimigos canônicos.

- [ ] Implementar pelo menos quatro padrões distintos: perseguidor melee, atirador, charger e hazard/controlador de área.
- [ ] Exigir telegraph visual antes de ataques fortes.
- [ ] Implementar colisão/dano sem hits invisíveis inevitáveis.
- [ ] Implementar elite variant com alteração clara de comportamento, não apenas mais HP.
- [ ] Validar que cada arquétipo exige resposta diferente do jogador.

### Task 4: Boss framework

**Interfaces:**
- Consome: combate sistêmico.
- Produz: arena de boss, fases e recompensa, pronta para expansão aos 16 bosses.

- [ ] Criar um boss de referência com pelo menos duas fases e padrões distintos.
- [ ] Implementar barra de vida, telegraphs, transição de fase e morte.
- [ ] Implementar arena que impeça saída durante o encontro sem aprisionar o jogador após a vitória.
- [ ] Implementar recompensa e handoff para continuidade do run.
- [ ] Validar vitória, derrota e restart do boss sem softlock.

### Task 5: Narrativa jogável e handoff

**Interfaces:**
- Consome: loop jogável estável.
- Produz: apresentação narrativa que não bloqueia indevidamente o gameplay.

- [ ] Integrar abertura em Aleppo c. 1578 e identidade de Hārūn sem alterar o cânone.
- [ ] Apresentar narrativa em trechos curtos, skippable quando permitido e com handoff explícito ao gameplay.
- [ ] Implementar fragmentos/codex para mover exposição longa para exploração voluntária.
- [ ] Garantir que o primeiro boot chega a controle jogável em tempo razoável.
- [ ] Validar que nenhuma sequência automática mantém o jogador preso por centenas de segundos.

### Task 6: Persistência e progressão

**Interfaces:**
- Consome: run, boss e narrativa.
- Produz: save/load confiável e estado de progressão.

- [ ] Salvar configurações, progresso relevante, desbloqueios e estado permitido entre runs.
- [ ] Implementar load defensivo para save ausente/inválido.
- [ ] Preservar distinção entre progressão de run e progressão permanente.
- [ ] Validar iniciar, salvar, recarregar e continuar sem duplicar/reverter estado.

### Task 7: Direção visual, HUD, VFX e áudio

**Interfaces:**
- Consome: gameplay completo do vertical slice.
- Produz: apresentação premium coerente.

- [ ] Refinar cenário para arquitetura levantina/otomana histórica inspirada, sem copiar propriedade visual alheia.
- [ ] Refinar iluminação, névoa, materiais e profundidade atmosférica.
- [ ] Tornar HUD discreto e legível, priorizando ação.
- [ ] Adicionar VFX de ataque, dano, morte, pickups e boss phase.
- [ ] Adicionar SFX/ambiente quando suportado sem criar dependência que impeça boot.
- [ ] Remover placeholders grosseiros das telas e encontros essenciais.

### Task 8: Expansão de conteúdo até o limite do Replit

**Interfaces:**
- Consome: frameworks estabilizados.
- Produz: maior quantidade possível de inimigos, bosses, salas e conteúdo canônico sem sacrificar estabilidade.

- [ ] Expandir catálogo de inimigos preservando comportamento distinto.
- [ ] Expandir bosses usando o framework de fases.
- [ ] Adicionar salas especiais, recompensas e variedade de run.
- [ ] Expandir fragmentos narrativos e progressão Student/Peregrinus Ignis conforme o cânone.
- [ ] Parar expansão de conteúdo quando regressões de performance/estabilidade superarem ganho real.

### Task 9: QA do Replit e handoff

**Interfaces:**
- Consome: estado mais avançado do app Replit.
- Produz: relatório objetivo e decisão de continuar no Replit ou migrar.

- [ ] Validar boot, input, câmera, combate, três salas, boss, morte/restart e save/load.
- [ ] Registrar bugs restantes e limitações de plataforma.
- [ ] Publicar somente quando o runtime estiver funcional e a ferramenta permitir.
- [ ] Se créditos/capacidade bloquearem avanço, registrar link do app, sistemas concluídos e pendências.
- [ ] Selecionar o próximo plugin capaz de continuar uma experiência 3D real, preferindo ferramenta com acesso a código/projeto sobre mero gerador visual.

## Self-review

- Cobertura: gameplay, roguelite, inimigos, bosses, narrativa, persistência, apresentação, conteúdo, QA e migração estão cobertos.
- Placeholders: nenhum item depende de `TBD`/`TODO`.
- Consistência: primeira pessoa, fonte de verdade, não-regressão e `VISUAL QA NOT VERIFIED` aparecem tanto no design quanto no plano.
- Escopo: o plano produz um vertical slice jogável primeiro e só depois escala conteúdo, evitando gastar créditos em quantidade antes de provar o loop.