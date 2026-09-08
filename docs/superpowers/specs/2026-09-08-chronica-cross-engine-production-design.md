# CHRONICA HĀRŪN · Cross-Engine Production Design

## Objetivo

Levar MUNDUS · CHRONICA HĀRŪN até uma versão jogável, coerente e visualmente premium usando uma cadeia de ambientes de criação, começando pelo Replit em modo 3D game e migrando para outro ambiente apenas quando o atual bloquear por crédito, capacidade técnica ou qualidade comprovadamente insuficiente.

## Fonte de verdade

1. O repositório `neuralSynapse/societaselectorum` e o cânone documental existente governam narrativa, progressão, inimigos, bosses, câmera, roguelite e identidade do jogo.
2. O app Base44 `Chronica Hārūn: The Peregrinus Quest` é referência visual e de UX, não fonte canônica nem fonte de gameplay.
3. Nenhum ambiente seguinte pode reescrever o cânone para acomodar limitações da ferramenta.
4. Frater Hārūn é personagem ficcional canônico. O crédito autoral real permanece Frater Horus Phosphorus.

## Produto alvo

- Jogo 3D single-player para PC, jogável com teclado e mouse.
- Primeira pessoa como modo principal, com câmera sobre o ombro disponível quando tecnicamente viável.
- Loop de ação roguelite com salas, encontros, recursos, fragmentos, progressão, bosses e persistência.
- Aleppo c. 1578 como abertura histórica e atmosfera de base.
- Jornada de Hārūn, prólogo, Student/Peregrinus Ignis, Templo da Lua e epílogo preservados conforme o cânone.
- O prólogo não pode aprisionar o jogador em centenas de segundos de apresentação não-interativa. Narrativa e cinematics devem permitir handoff claro para gameplay.
- 82 inimigos e 16 bosses permanecem o escopo canônico. Implementação incremental é permitida, mas cada criatura final precisa de comportamento e leitura visual próprios.
- Não usar proxies geométricos ou placeholders genéricos como arte final.

## Direção visual

A experiência deve parecer um jogo histórico-ocultista premium, não um dashboard web tematizado. Prioridades: composição cinematográfica, iluminação volumétrica, profundidade atmosférica, materiais críveis, arquitetura do Levante otomano, HUD discreto, tipografia hierárquica, feedback de combate legível e menus coerentes com o universo.

## Arquitetura de migração

### Fase 1 · Replit 3D

Criar uma implementação 3D independente que reproduza primeiro o vertical slice jogável: controle, câmera, combate, sala, inimigo, boss, UI, salvamento e um trecho narrativo. Depois expandir sistemas e conteúdo até o limite útil da plataforma.

### Fase 2 · Handoff por limite

Quando a plataforma atual falhar por créditos, capacidade ou qualidade, registrar obrigatoriamente: sistemas concluídos, sistemas incompletos, bugs conhecidos, decisões de arquitetura, assets usados, links de preview/publicação e critérios de aceitação ainda pendentes. O ambiente seguinte recebe esse handoff e continua do estado funcional mais avançado.

### Fase 3 · Consolidação

O jogo só é considerado concluído quando o build final atende simultaneamente gameplay, narrativa, arte, áudio/VFX, persistência, QA e distribuição. Nenhum plugin isolado define conclusão por conta própria.

## Fatias de implementação

1. Vertical slice jogável: movimento, câmera, ataque, dano, morte, uma sala e um inimigo.
2. Loop roguelite: portas/salas, recompensas, escolhas, reinício e persistência.
3. Encontros: arquétipos de inimigos, telegraphs, projéteis, melee, hazards e elite variants.
4. Boss framework: fases, padrões, arena, vida, transições e recompensa.
5. Narrativa: prólogo, codex/fragments, handoff para gameplay, Student/Peregrinus Ignis e epílogo.
6. Apresentação: HUD, menus, VFX, SFX, iluminação, materiais, pós-processamento e cinematics sem proxies finais.
7. Conteúdo completo: 82 inimigos, 16 bosses e salas especiais, todos rastreados por catálogo.
8. QA e release: input, câmera, save/load, performance, resolução, crash-free boot e build distribuível.

## Critérios de aceitação globais

- O jogador chega a gameplay controlável sem ficar bloqueado por narrativa automática longa.
- Movimento, câmera, ataque e dano funcionam em runtime real.
- Primeira pessoa existe e é utilizável.
- Um run pode começar, avançar por salas, enfrentar inimigos, derrotar ao menos um boss e terminar/reiniciar.
- Save/load preserva progresso relevante sem corromper sessão.
- Nenhuma tela essencial depende de placeholder visual grosseiro.
- HUD e menus são legíveis em 16:9 e não cobrem ação importante.
- Erros de runtime impedem promoção para a próxima fase até serem classificados e corrigidos ou documentados como bloqueio de plataforma.
- `VISUAL QA NOT VERIFIED` permanece verdadeiro até inspeção humana do resultado final.

## Política anti-regressão

Cada migração preserva o último estado jogável conhecido. Um ambiente novo não substitui o anterior até demonstrar, no mínimo, paridade funcional nos critérios já atendidos. Não fazer merge em `main` automaticamente.