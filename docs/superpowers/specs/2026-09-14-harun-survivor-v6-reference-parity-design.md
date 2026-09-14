# HĀRŪN Survivor V6 — Reference Parity Design

## Goal
Elevar MUNDUS · HĀRŪN · Cidadela Viva do V5.1 para um Survivor mobile de produção, usando os quatro vídeos de referência de 14/09/2026 como benchmark de game feel, apresentação, densidade visual, progressão e metajogo, sem copiar personagens, nomes, arte, texto ou identidade do jogo de referência.

## Source audit
Foram auditados quatro screen recordings em 512×1108, 30 FPS, total aproximado de 235,6 s. O benchmark mostra um loop de combate portrait full-screen com legibilidade extrema, interrupções de escolha cinematográficas, chefes a cada marco, vários companheiros simultâneos, grandes efeitos de habilidade e uma metacamada extensa fora da partida.

### O que o benchmark possui e a V5.1 ainda não possui no mesmo nível
1. Gameplay full-bleed no aspect ratio real do celular, sem grandes faixas vazias.
2. Arena com moldura 2.5D: paredes laterais, colunas, correntes, portão inferior, tochas, sombras e iluminação local.
3. Personagem principal maior, com silhueta instantaneamente legível e animação viva de locomoção/ataque.
4. Familiares como criaturas/personagens reais, em formação dinâmica, não glifos circulares.
5. Inimigos com silhuetas distintas, sombras de contato, hit squash, recoil, flash e morte em puff/fragmentos.
6. Enxames densos sem perder leitura do jogador.
7. Lasers, feixes, ricochetes, multi-shot, projéteis curvos, meteoros, áreas tóxicas, explosões, orbitais e trails simultâneos.
8. Números de dano flutuantes com hierarquia: normal, crítico, dano recebido, cura e bloqueio.
9. Drops físicos legíveis: cura, moedas/essência, pickups especiais e ímã.
10. HUD superior compacto com nível, XP, recurso, onda e trilha de marcos da run.
11. Barra de chefe de alta prioridade e aviso de entrada do chefe em múltiplas etapas.
12. `DANGER` pré-boss com repetição lateral, pulso, pausa dramática e spawn ritualizado.
13. Escolhas de nível com fundo escurecido/desfocado, banner, raridade, cards grandes e reveal por feixes/radiais.
14. Eventos distintos de benção, pacto e cura, com quantidade de cards e custo diferentes.
15. Feedback de habilidade dominada/máxima e `Lv.Max`.
16. Pause com grade visual de todas as habilidades adquiridas, botão continuar e sair.
17. Interações de sala/cofre/evento com objeto físico no campo antes do modal.
18. Final de desafio em etapas: banner de conclusão, estatística da run, badge de nível/estrela, confete e recompensas.
19. Metajogo com campanha, equipamento, personagens, runas/relíquias, coleção/talentos e navegação inferior persistente.
20. Equipamentos por slot, raridade, nível, upgrade, inventário e filtro.
21. Cartas/talentos com estrelas, slots bloqueados, sorteio e progressão.
22. Check-in diário, metas diárias/semanais e conquistas.
23. Indicadores de novidade/notificação no metajogo.
24. Economia separada em energia, moeda comum, moeda premium/essência e poder total.
25. Transições e celebrações: flashes, rays, confetti, scale punch, bounce, glow, vignette e screen shake.
26. Mix de áudio orientado a evento: ataque, impacto, crítico, pickup, upgrade, reveal, danger, boss, vitória e UI.
27. Ritmo: combate → escolha → pico de poder → encontro → boss → recompensa → metajogo.

## V6 architecture
V6 será aditiva e isolada. V5.1 continua rollback-safe. A nova rota carregará o core V3/V4/V5 existente e acrescentará módulos V6 com responsabilidade única.

### Modules
- `js/art-v6.js`: renderer premium procedural 2.5D para arena, Hārūn, inimigos, chefes, pickups e projéteis.
- `js/feel-v6.js`: partículas, trails, hit-stop visual, damage numbers, morte, telegraphs, screen shake e boss entrance.
- `js/hud-v6.js`: HUD compacto, faixa de skills adquiridas, boss presentation, pause V6 e full-bleed mobile shell.
- `js/events-v6.js`: skins e reveal cinematográfico para upgrade, benção, pacto, cura e recompensa de encontro.
- `js/meta-v6.js`: pós-run, check-in, missões, equipamento, talentos/cartas, indicadores e economia lúdica.
- `css/survivor-v6.css`: layout full-screen e toda direção de interface V6.
- `v6.html`: release candidate isolada.
- `qa/playtest-v6.py`: gates de browser, visual state, responsive, boss, familiar, events e metajogo.

## Visual direction
Não copiar o chibi, a paleta, os ícones, as cartas ou a interface do benchmark. MUNDUS permanece ritual-iniciático: obsidiana, bronze, ouro queimado, vermelho profundo, turquesa arcano e luz espectral. O aumento de qualidade vem de volume, contraste, silhueta, animação, composição, efeitos e hierarquia, não de clonagem de trade dress.

Hārūn deve ler como iniciado/protagonista, não soldado. Forma maior, cabeça e tecido mais expressivos, manto com secondary motion, faixa ritual, halo/selo solar discreto, arma ritual clara e animações de respiração/corrida/ataque.

Familiares devem ter corpos procedurais diferentes (escaravelho, íbis, falcão, serpente, chacal, besouro, lótus, esfinge, coruja, leão, corvo, mariposa), órbitas/formações diferentes e telegraph próprio quando ativam efeitos.

## Gameplay feel requirements
- Velocidade V5.1 de 242 é piso, nunca regressão.
- Input deve permanecer direto, sem smoothing pesado.
- Ataques automáticos devem produzir feedback já no primeiro segundo.
- Boss wave não pode ser pausada por evento de sala.
- Um boss derrotado não pode reaparecer na mesma onda.
- Dano crítico usa escala e cor próprias; cura e bloqueio usam canais próprios.
- Densidade visual pode crescer sem esconder Hārūn: o protagonista ganha outline/glow de prioridade quando há sobreposição.

## Mobile viewport
A V6 deve ocupar `100svh` no mobile. O playfield será tratado como full-bleed e as zonas superiores/inferiores passam a fazer parte da composição, respeitando safe-area. A lógica do core continua em 540×960 para não quebrar física; V6 usa uma moldura DOM/canvas estendida e composição cover com safe-zone protegida, evitando cortar informação crítica.

## Meta progression
A metacamada é lúdica e não concede Grau institucional. Deve incluir:
- resumo de run e recompensa;
- energia de campanha;
- moedas + essência;
- inventário por slots e raridade;
- cartas de talento com estrelas;
- check-in de 14 dias;
- missões diárias/semanais;
- conquistas;
- marcadores de novidade;
- nenhuma compra com dinheiro real nesta versão.

## Audio
Reutilizar `MUNDUSAudio`, adicionando cues V6. Não reproduzir música ou SFX do benchmark. Criar efeitos originais para laser, corte, impacto, crítico, cura, familiar, card reveal, pacto, DANGER, boss emergence, vitória, confetti e reward reveal.

## Acceptance gates
1. V6 carrega sem erro JS em 390×844 e 430×932.
2. Nenhuma faixa preta estrutural externa no mobile: frame ocupa a viewport.
3. Movimento >=242 e deslocamento real continua responsivo.
4. Hārūn V6 e pelo menos 3 familiares renderizam como formas corporais diferentes.
5. Damage numbers incluem normal, crítico, cura e bloqueio.
6. DANGER executa sequência e boss nasce uma única vez.
7. Boss morto avança sem respawn.
8. Upgrade/event cards têm reveal V6 e raridade visual.
9. Pause mostra build completa por ícones.
10. Pós-run e ao menos cinco telas/meta módulos ficam acessíveis.
11. Check-in, missão e talento persistem em localStorage.
12. Stress gate não fica abaixo de 30 FPS medianos no runner e não regride materialmente frente V5.
13. Screenshot QA pública comprova gameplay V6, evento V6 e metajogo V6.
