# CHRONICA HARUN · Roguelite Depth — Design

Data: 2026-09-07
Branch: `feat/chronica-roguelite-depth`
Escopo: Frente Paralela C — sistemas roguelite, salas especiais e buildcraft.

## 1. Estado recuperado

A fonte Godot declarada no checkpoint anterior não está persistida no GitHub conectado: não existe `feat/godot-o-olho`, os commits locais declarados não resolvem no remoto e a branch remota `chronica/godot-engine-v1` não contém `project.godot`. Conforme a regra do checkpoint, esta frente reconstrói a fundação necessária sem alterar a camada web/backend existente.

O projeto Godot reconstruído vive em `game/chronica-harun/`. Nenhum arquivo em `mundus/chronica-harun/backend/` será modificado.

## 2. Invariantes

- FPS em primeira pessoa permanece a identidade do jogo.
- Esta frente não reescreve combate, inimigos ou narrativa cinematográfica.
- Gameplay nunca escreve Grau institucional real nem `real_progress_gate`.
- Todos os catálogos são data-driven, mas JSON isolado não conta como implementação.
- Cada registro chega ao runtime por `RogueliteContentService` e produz efeitos/ações por `BuildResolver`, `SpecialRoomDirector`, `SpecialRoomRuntime` ou `MetaRunDirector`.
- Proveniência distingue `fonte`, `tradicao`, `interpretacao` e `dramatizacao_electorum`.
- Binding of Isaac é referência apenas de princípios de design. Nenhum nome, layout, sprite, item ou efeito específico é reproduzido.

## 3. Arquitetura

### 3.1 Conteúdo

`game/chronica-harun/data/roguelite/` contém:

- `tarot.json` — 78 cartas, 22 Atu e 56 Menores;
- `sigilla.json` — 72 Sigilla;
- `pharmaka.json` — 21 Pharmaka;
- `talismans.json` — 36 Talismãs decânicos;
- `instrumenta.json` — 32 Instrumenta;
- `powers.json` — 15 Poderes-Matriz;
- `mutations.json` — 45 Mutações;
- `daimones.json` — 7 Daimones;
- `relics.json` — 9 relíquias canônicas iniciais;
- `transformations.json` — 12 transformações autorais;
- `curses.json` — 8 maldições;
- `blessings.json` — 6 bênçãos;
- `routes.json` — 8 rotas;
- `special_rooms.json` — 20 tipos, incluindo as 17 câmaras canônicas e três opções pós-chefe autorais.

Todo item usa o contrato comum: `id`, `name`, `rarity`, `pool`, `eligibility`, `effect`, `cost`, `duration`, `stacking`, `synergies`, `exclusions`, `vfx_hook`, `sfx_hook`, `save_state`, `codex`, `provenance`.

### 3.2 Runtime

- `autoload/GameState.gd`: estado local serializável da run, inventário/build, salas descobertas, rota, maldições, bênçãos, transformações e completion marks. Não contém bridge de escrita institucional.
- `autoload/RogueliteContentService.gd`: carrega todos os catálogos, indexa por ID/pool e filtra elegibilidade.
- `scripts/content/BuildResolver.gd`: resolve stacking, exclusões, tags de sinergia e transforma cada efeito em mudança de estado ou evento de gameplay.
- `scripts/generation/SpecialRoomDirector.gd`: calcula elegibilidade/peso, limita segredos, escolhe salas e opções pós-chefe.
- `scripts/rooms/SpecialRoomRuntime.gd`: executa entrada, custo, risco, recompensa e persistência da sala.
- `scripts/progression/MetaRunDirector.gd`: gerencia rotas, curses, blessings, transformations, gauntlets e completion marks.
- `scripts/content/GameplayEffectBus.gd`: barramento de eventos para efeitos que precisam ser consumidos por sistemas de combate/visual de outras frentes sem acoplá-los aqui.

## 4. Tarot

Os 22 Atu usam as funções já declaradas no checkpoint: `threshold_reset`, `echo_instrument`, `secret_sight`, `fecundity`, `command`, `tradition`, `syzygy`, `chariot`, `adjustment`, `hermit`, `fortune`, `lust`, `suspension`, `death`, `art`, `devil`, `tower`, `star`, `moon`, `sun`, `aeon`, `universe`.

Os 56 Menores não são meros incrementos numéricos. Cada naipe possui gramática mecânica própria:

- Bastões: ataque, vontade, velocidade e overdrive;
- Copas: foco, recuperação, vínculo e conversão;
- Espadas: precisão, ruptura, revelação e risco técnico;
- Discos: defesa, economia, matéria e ancoragem.

As cartas numeradas usam dez arquétipos funcionais distintos por naipe: semente, escolha, formação, postura, risco, ressonância, limiar, motor, culminação e transbordamento. Princess, Prince, Queen e Knight possuem manifestações próprias e interagem com tags de Instrumenta, Poderes, Mutações, Sigilla, Daimones e Relíquias.

## 5. Segredos

Cada andar pode receber no máximo duas salas secretas se `layout_secret_capacity >= 2`. Nenhuma porta textual denuncia o segredo. O acesso físico usa tags de abertura: `ritual_bomb`, `rupture_charge`, `wall_break` ou efeito canônico equivalente. Efeitos de revelação podem indicar uma parede candidata, mas não substituem automaticamente o ato físico de abertura, salvo quando o próprio efeito declarar `opens_secret=true`.

## 6. Salas especiais

Cada sala define elegibilidade, condição de spawn, peso, entrada, custo, risco, recompensa, evento runtime, estado persistente, ícone/mapa e feedback de descoberta.

Tipos: Câmara do Arcano, Reliquarium, Instrumentarium, Laboratorium, Câmara Sigillar, Mercado de Essência, Bibliotheca, Speculum, Câmara Planetária, Câmara de Provação, Câmara Maldita, Sala Secreta, Sala Duplamente Secreta, Câmara do Arconte, Câmara Teofânica, Câmara Histórica, Câmara de Iniciação, Câmara Pneumática, Câmara Ctônica e Mesa do Pacto.

As três últimas são dramatizações Electorum próprias para decisões pós-chefe. São mutuamente exclusivas por encontro e condicionadas ao estado da run.

## 7. Buildcraft

A build usa tags e eventos, não cadeias rígidas de itens. Sinergias podem alterar multiplicador, trigger, alcance, custo, duração, conversão de recurso ou evento emitido. Exclusões bloqueiam combinações contraditórias. Stacking aceita `none`, `refresh`, `additive`, `multiplicative`, `charges` e `unique_transform`.

O resolver devolve um resultado determinístico e serializável com `state_changes`, `events`, `synergies_triggered`, `blocked_by` e `consumed`.

## 8. Metarun

As oito rotas, nomes de maldições/bênçãos e transformações que não possuem nomes fixados nas fontes serão explicitamente marcadas como `dramatizacao_electorum`. O runtime mantém escolha, condições, modificadores e persistência local. Completion marks são por personagem e desafio. Gauntlets são conjuntos de modificadores/condições, sem alterar a Jornada canônica.

## 9. Testes e definição de pronto desta frente

A frente é considerada implementada quando os validadores confirmarem todas as contagens, campos obrigatórios, IDs únicos, referências de sinergia/exclusão válidas, 78 cartas realmente despacháveis, 72 Sigilla despacháveis, salas especiais executáveis pelo runtime, no máximo duas salas secretas, abertura física validada, pós-chefe exclusivo, rotas/curses/blessings/transformations serializáveis e ausência de qualquer escrita institucional.

A validação estática é executada por `pytest`. Um smoke scene Godot será incluído para validação headless futura. Como o binário Godot e a fonte anterior não estão montados nesta interface, nenhum resultado de execução Godot será alegado sem evidência real.