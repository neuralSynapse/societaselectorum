# CHRONICA HĀRŪN · FUSÃO V4 — Design

## Objetivo
Elevar a build 3D/FPS de MUNDUS · CHRONICA HĀRŪN no WebsitePublisher 27912 em todos os níveis sem quebrar o cânone, preservando a build jogável após cada lote.

## Invariantes canônicos e técnicos
- Hārūn é personagem ficcional; autoria real: Frater Horus Phosphorus.
- Primeira pessoa é a visão primária. V pode alternar câmera quando disponível.
- O OLHO é percepção/interação, nunca arma.
- Hārūn recebe arma física antes do primeiro combate obrigatório.
- Alcance melee alvo ~1,65 m.
- Clique direito começa com Psyball básica.
- Slots 1/2/3 de Kinesis começam vazios e são conquistados.
- Caim é iniciador não hostil.
- Os 72 Goéticos/Daimones são aliados, pactuáveis ou narrativos, nunca bestiário hostil automático.
- Sabaoth preserva a camada de ruptura/rebelião e não entra automaticamente no roster hostil.
- Oposição do Estudante escala de sombra interna para governo do impulso, depois Arcontes e hoste angelical demiúrgica.
- Estudante precede Grau I; Peregrinus Ignis só é registrado após Câmara de Iniciação e rito de passagem. Gameplay não certifica grau institucional real.
- WebsitePublisher project 27912 é o runtime/deploy principal. GitHub é fonte de verdade de documentação/versões.
- Procedural/prototype art nunca deve ser chamado de production art.
- Nenhuma claim de “pronto” sem read-back e QA correspondente.

## Arquitetura V4

### 1. Runtime modular incremental
Não reescrever o monólito de uma vez. Extrair responsabilidades de `chronica-v2.js` gradualmente para módulos estáveis, mantendo compatibilidade com o runtime atual.

Módulos-alvo:
- `chronica-encounter-director.js`: manifestação, ativação, simultaneidade, spawn budget.
- `chronica-player-combat.js`: melee, Psyball, hit-stop, stagger, cancel windows.
- `chronica-enemy-ai.js`: estados, preferências de distância, retreat/flank, recovery.
- `chronica-boss-director.js`: fases, arena, regras exclusivas, transições.
- `chronica-performance.js`: quality tiers, schedulers, culling, object budgets.
- `chronica-world-director.js`: identidade de etapa, rooms, topology hooks, eventos.
- `chronica-vfx-director.js`: pools, budgets, readability, reduced motion.
- `chronica-save.js`: migração, snapshots, recuperação e anti-corruption.

`chronica-v2.js` permanece orquestrador até a migração gradual terminar.

### 2. Encounter Director
Contrato obrigatório para todo spawn hostil:
`MANIFEST → READ → CHASE → WINDUP → TELEGRAPH → RELEASE/EMISSION → TRAVEL → IMPACT → RECOVERY`.

- MANIFEST e READ: imóvel, não causa dano, não reduz distância.
- Primeiro ataque recebe atraso adicional após CHASE.
- Microprovas 1–10: máximo 1 hostil ativo simultâneo.
- 11–15/Câmara: até 2, salvo boss mechanics explicitamente limitadas.
- Boss, adds, respawn e ameaças extraordinárias passam pelo mesmo gate.
- Sala inativa não atualiza IA ofensiva.

### 3. Inimigos como argumentos mecânicos
Cada arquétipo deve possuir movimento, distância preferida, tell visual, tell sonoro, ataque, contra-jogo, recovery e comportamento de baixa vida. O nome/cânone da entidade não substitui comportamento real.

Camadas:
1. sombras internas/condicionamentos;
2. impulso/governo;
3. Arcontes hostis elegíveis;
4. hoste angelical demiúrgica;
5. Câmara e Yaldabaoth/estruturas superiores em conteúdo futuro apropriado.

### 4. Bosses
16 bosses autorais canônicos funcionam como “argumentos mecânicos”. Cada boss tem 3 fases que alteram regra, arena e decisão do jogador, não apenas HP/velocidade/projéteis.

### 5. Player feel
- melee ~1,65 m, impacto legível, micro hit-stop, stagger e feedback de whiff;
- Psyball básica com foco/cooldown e identidade visual própria;
- O OLHO continua perceptivo;
- Kinesis avançadas entram por conquista e têm custo/cooldown/efeito individual;
- combate evita spam e mantém telegraphs legíveis.

### 6. Roguelite/buildcraft
Arcana, Pharmaka, Sigilla, Talismãs, Instrumenta, Daimon, Relíquias, Bênçãos, Maldições, Transformações e Kinesis precisam gerar runs mecanicamente distintas.

Regras:
- anti-repetição por run;
- pools condicionais por etapa/estado;
- trade-offs explícitos;
- synergies rotuladas sem inventar atribuições históricas;
- loot físico sempre que possível;
- coleção persistente e descoberta separadas do loadout da run.

### 7. Mundo e etapas
As 16 etapas mantêm identidade própria de arquitetura, iluminação, som, props, ritmo, roster e desafio. A espinha de 7 rooms pode ser preservada onde útil, mas topologia, bloqueios, caminhos laterais, eventos e espaços especiais devem variar progressivamente.

### 8. Narrativa jogável
Priorizar espaço, objetos, aparições, Livro Negro, áudio e eventos sobre paredes de texto. O Livro Negro separa fonte/tradição, interpretação, dramatização Electorum e papel em CHRONICA.

### 9. Áudio/VFX
- mixer único para SFX/UI/ambience;
- signatures por arquétipo/boss;
- silence/ducking antes de impacto importante;
- VFX poolados com orçamento por tier;
- reduced motion respeitado.

### 10. Performance
- quality tiers AUTO/HIGH/MEDIUM/LOW;
- culling por sala/distância;
- IA e sistemas não críticos em schedulers 10/20/30 Hz;
- objetos repetidos compartilhando geometria/material quando seguro;
- zero novas alocações evitáveis em hot loops;
- render/AI pausados ou reduzidos quando documento oculto;
- VFX/light budgets por tier.

### 11. UX/Acessibilidade/mobile-readiness
- tutorial contextual;
- minimapa e objetivo legíveis;
- FOV/sensibilidade/volume/reduced motion/contraste;
- input abstraction para futuro controller/touch sem degradar desktop.

### 12. QA/anti-regressão
Diagnósticos devem testar:
- `window.__chronicaReady===true`;
- Encounter Director presente e válido;
- MANIFEST/READ imóveis;
- nenhuma Goetia/Caim/Sabaoth indevida em roster hostil;
- Kinesis iniciais vazias;
- arma física antes de combate obrigatório;
- O OLHO não ofensivo;
- melee dentro do contrato;
- nenhuma IA ativa em sala inativa;
- save migrável;
- nenhum overlay invisível prendendo input;
- budgets de entidades/VFX/luzes.

## Estratégia de entrega
Implementação incremental por lotes, cada um com read-back e rollback simples:
1. encounter + spawn/boss gates;
2. performance foundation;
3. player feel;
4. enemy AI/archetypes;
5. bosses;
6. buildcraft/loot;
7. world/stages;
8. audio/VFX;
9. narrative/UX/save;
10. QA e polimento final.
