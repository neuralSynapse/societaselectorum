# CHRONICA HARUN — CHECKPOINT MESTRE DE CONTINUIDADE

Data do checkpoint: 2026-09-07
Projeto: MUNDUS · CHRONICA HARUN
Direção: FPS roguelite em primeira pessoa, com progressão iniciática ficcional/canônica e sistemas autorais inspirados em profundidade de roguelites como Binding of Isaac, sem copiar identidade, assets, personagens, nomes ou conteúdo protegido.

## 1. ENDEREÇOS E IDENTIFICADORES IMPORTANTES

Jogo público atual:
https://www.sociedadedoseleitos.com/mundus/chronica-harun.html

WebsitePublisher principal:
Project ID 25063

Repositório principal do site:
https://github.com/neuralSynapse/societaselectorum

Backend dedicado:
https://github.com/neuralSynapse/chronica-harun-backend

Backend Vercel:
https://chronica-harun-backend.vercel.app

Health:
https://chronica-harun-backend.vercel.app/api/health

Status público backend:
https://www.sociedadedoseleitos.com/mundus/chronica-backend-status.html

Neon PROD:
Project ID small-glitter-64386115
Nome MUNDUS — CHRONICA HARUN Backend PROD
Região aws-sa-east-1
Banco chronica_harun
Branch principal conhecida br-fancy-wave-ac0gr9pi

Documento mestre de infraestrutura já existente no Drive:
https://docs.google.com/document/d/18NukP-Ujl0CwPwNk29vWIWnc5_YKGJOuYErfkd1X_gQ/edit
Título: CHRONICA HARUN — PLANO MESTRE DE EVOLUÇÃO · GAME SYSTEMS + INFRAESTRUTURA v1.0 — 2026-09-06

## 2. PRINCÍPIO VISUAL E DE GAMEPLAY

- O jogo permanece em PRIMEIRA PESSOA.
- Nunca voltar ao modo tático/top-down.
- Câmera, arma, mãos, inimigos, projéteis e mundo precisam obedecer a world-space real.
- Inimigos não podem deslocar junto com o movimento da câmera.
- Mouse/câmera não pode permanecer invertido.
- Projéteis inimigos precisam ser visíveis, telegráficos e legíveis.
- O jogador precisa identificar imediatamente o que cada criatura é, o que ela está fazendo e qual ataque está prestes a executar.
- Reduzir bloom/emissão exagerada. Brilho deve ser seletivo e funcional, não um véu amarelo sobre tudo.
- Alvo visual final: arte 3D de produção, alta definição, materiais e luz cinematográficos, substituindo placeholders procedurais por modelos esculpidos/rigados 1:1 quando o pipeline Blender/Godot estiver disponível.

## 3. JORNADA CANÔNICA DO ESTUDANTE

Regra canônica do jogo:
- 15 subetapas da Jornada do Estudante.
- Em seguida Câmara de Iniciação.
- A conclusão narrativa leva ao estado de jogo PEREGRINUS_IGNIS_GAME.
- Isso é progressão narrativa do videogame. Não equivale nem escreve Grau institucional real.

As 15 subetapas foram tratadas como provas temáticas com inimigos, elites, boss, poder e linguagem próprios.

## 4. ESTADO DA MIGRAÇÃO GODOT DECLARADO NO CHECKPOINT ANTERIOR

A execução anterior construiu uma migração Godot 4 data-driven com os seguintes blocos:

### Bestiário
- 82 inimigos individuais da Jornada.
- IDs únicos.
- HP, velocidade, função, comportamento e ataque por criatura.
- telegraph/windup/active/recovery.
- Codex e proveniência por criatura.
- 82 GLBs procedurais individuais e determinísticos.
- famílias geométricas separadas, incluindo crawler, eye, shade, ritualist, chain, beast, winged, construct, chorus, serpent, fire etc.
- linhagem arcôntica inicial específica para Athoth, Eloaios, Astaphaios, Yao, Adonin, Sabbataios e Sabaoth.

### Bosses
Foram estruturados 16 bosses de 3 fases:
1. Observador Cego
2. Arconte do Impulso
3. Guardião da Pedra Inerte
4. Selo do Não
5. Cobrador de Máscaras
6. Falso Daimon
7. Testemunha de Pedra
8. Devorador de Ritmo
9. Nublador
10. Dragão da Escória
11. Tirano da Exaustão
12. Arquiteto Cego
13. Banqueiro Arcôntico
14. Coral da Aprovação
15. Guardião do Nome Durável
16. Trono da Iniciação

Cada um com:
- GLB próprio;
- reward_id próprio;
- 3 fases;
- ataques próprios por fase;
- controller data-driven.

### Salas e geração
Foi criada arquitetura de geração genérica por estágio em vez de depender apenas de OOlhoFloor.tscn:
- threshold;
- combat;
- reward;
- sanctuary;
- trial/elite;
- boss;
- secret rooms;
- room themes por estágio;
- orçamento de inimigos crescente por ciclo.

### Progressão/save
GameState foi ampliado para:
- current_stage_id;
- stage_index;
- cycle;
- journey_state;
- completion_marks;
- run_stats;
- run_build;
- retries sem pular estágio;
- carregamento de campanha existente no boot;
- transição final para PEREGRINUS_IGNIS_GAME.

### Narrativa/Codex
Foram estruturados beats por estágio:
- threshold;
- first family;
- elite;
- secret;
- boss intro;
- phase 2;
- phase 3;
- completion.

Codex foi preparado para cobrir etapas, inimigos e bosses com proveniência explícita.

## 5. CATÁLOGOS ROGUELITE JÁ ESTRUTURADOS NO CHECKPOINT ANTERIOR

Contagens definidas:
- Tarot de Thoth: 78 = 22 Atu + 56 Menores.
- Sigilla Goetica: 72.
- Pharmaka Hermetica: 21 = 3 princípios alquímicos × 7 planetas clássicos.
- Talismãs decânicos: 36 = 12 signos × 3 decanatos.
- Instrumenta: 32.
- Poderes-Matriz: 15.
- Mutações: 45 = 3 por Poder-Matriz.
- Daimones: 7.
- Relíquias iniciais: 9+.
- Transformações: 10+.
- Maldições: 8.
- Bênçãos: 6.
- Rotas: 8.
- Teofanias: 18+.
- Ecos históricos/tradicionais: 6+.

## 6. 32 INSTRUMENTA E FUNÇÕES

Entre os instrumenta já definidos:
- Bastão Ígneo: cone_fire.
- Vara Serpentina: chain_strike.
- Cetro Solar: solar_burst.
- Bastão de Mercúrio: tempo_shift.
- Vara de Marte: dash_break.
- Bastão da Chama Negra: black_flame.
- Cálice Lunar: focus_well.
- Taça do Véu: phase.
- Copa de Vênus: heal_link.
- Cratera de Sophia: transmute_hurt.
- Cálice de Água Negra: curse_cleanse.
- Taça do Retorno: return.
- Lâmina de Ruptura: armor_break.
- Athame de Thoth: mark_reveal.
- Espada Solar: line_beam.
- Faca do Verbum: silence.
- Lâmina de Saturno: slow_cut.
- Espada do Limiar: door_cut.
- Disco de Saturno: fortify.
- Pentáculo Solar: ward.
- Disco de Fortuna: reroll.
- Selo de Terra: anchor.
- Moeda de Júpiter: multiply_essence.
- Placa de Belial: grounding.
- Espelho de Sophia: reflect.
- Lâmpada de Phosphoros: reveal_all.
- Livro do Verbum: command_wave.
- Ampulheta de Kairos: time_stop.
- Máscara de Paimon: dominate.
- Olho de Hórus: precision.
- Tabuleta de Thoth: echo_card.
- Chave Dracônica: red_path.

O checkpoint anterior declarou dispatch runtime individual para os 32 efeitos.

## 7. 22 ATU — EFEITOS DE GAMEPLAY AUTORAIS

Efeitos declarados no runtime:
threshold_reset
echo_instrument
secret_sight
fecundity
command
tradition
syzygy
chariot
adjustment
hermit
fortune
lust
suspension
death
art
devil
tower
star
moon
sun
aeon
universe

Os nomes e estrutura do Tarot pertencem à tradição Thoth; os efeitos de jogo são dramatização autoral Electorum.

## 8. 45 MUTAÇÕES E HOOKS

O checkpoint anterior criou PowerMutationRuntime com hooks para:
- modify_damage;
- on_player_damaged;
- on_room_cleared;
- on_dodge;
- on_enemy_killed;
- on_projectile_about_to_hit;
- passive_flags.

Exemplos de comportamento:
- crit contra revelados;
- visão de projéteis;
- cadáver-brasa;
- dano recebido alimenta Chama;
- chain flame;
- quebra de armadura;
- HP → Foco;
- esquiva contra projéteis;
- execução de HP baixo;
- carga por perfect dodge;
- cura ao limpar sala;
- maldição → buff;
- excesso → Essência;
- silence ranged;
- dominate temporário;
- first card free;
- memória de carga/build.

## 9. 7 DAIMONES

- Daimon Lampadário: revelar segredo.
- Daimon Serpentino: execução/mordida.
- Daimon Escriba: eco de Arcano.
- Daimon Specular: eco de ataque.
- Daimon Funerário: essência de cadáveres.
- Daimon Saturnino: interceptar projétil.
- Daimon Solar: purga de maldição.

## 10. SISTEMAS AINDA PENDENTES DA MIGRAÇÃO GODOT

A próxima execução deve continuar exatamente daqui. Pendências principais:

1. Integrar fisicamente as categorias de salas especiais no StageFloorBuilder/StageDirector.
2. Implementar pós-boss Angel/Demon/Pact com exclusividade e condições de run.
3. Implementar VisionDirector para teofanias e ecos históricos.
4. Implementar MetaRunDirector para rotas, blessings, curses, completion marks por personagem e meta-progression.
5. Implementar Gauntlets.
6. Implementar manifestação visual das transformações.
7. Integrar pickups e recompensas reais das 78 cartas, 72 sigilla, 21 pharmaka, 36 talismãs, 32 instrumenta e relíquias às salas.
8. Conectar PowerMutationRuntime e DaimonRuntime ao combate real do Player/Enemy/Projectile/Room clear.
9. Implementar room routing e special-room eligibility em padrão roguelite: salas secretas e super-secretas, comércio, pacto, teofania, biblioteca, laboratório, instrumentarium, sigillar etc.
10. Garantir que inimigos não apareçam todos numa mesma sala nem em excesso no início; usar budget por sala e progressão de densidade.
11. Garantir inimigos com ataques visíveis e diferenciáveis.
12. Substituir arte procedural por pipeline Blender/GLTF de produção, mantendo IDs e contratos de gameplay.
13. Implementar áudio/impacto/VFX em Godot sem bloom excessivo.
14. Implementar HUD final para Arcana, Pharmakon, Instrumentum, Sigillum, Daimon e route state.
15. Implementar export presets Windows/Linux e release manifest.
16. Criar validador global do jogo completo.
17. Rodar full pytest.
18. Rodar Godot headless/import/scene tests quando o binário Godot 4 estiver disponível.
19. Rodar teste jogável real, incluindo câmera, mouse look, colisão, room transitions, attacks, bosses, saves e performance.
20. Depois disso, empacotar e publicar nova build; não declarar produção final antes de QA real.

## 11. SALAS ESPECIAIS APROVADAS/DESEJADAS

O projeto deve modelar, de forma própria e coerente:
- Arcana;
- Reliquary;
- Instrumentarium;
- Laboratorium;
- Sigillar;
- Market/Rito de Troca;
- Bibliotheca;
- Speculum;
- Planetary;
- Trial;
- Cursed;
- Secret;
- Super Secret;
- Archon;
- Theophany;
- Historical Echo;
- Initiation;
- Angel-equivalent autoral;
- Demon/Pact-equivalent autoral.

Sala secreta deve exigir recurso/condição própria, incluindo uso de bomba/carga de ruptura quando aplicável. Não copiar layout/arte/nomenclatura de Isaac.

## 12. REFERÊNCIAS NARRATIVAS E CANÔNICAS

O jogo deve integrar de forma contextual e não aleatória:
- Yaldabaoth;
- Sophia;
- Sabaoth;
- linhagens arcônticas;
- Hórus;
- Thoth;
- Lúcifer/Phosphoros;
- Belial;
- Paimon;
- Lilith;
- Seth;
- Samael;
- Baphomet;
- Mammon;
- Agares;
- Sitri;
- Rá;
- Vishnu;
- Ganesh;
- figuras históricas como Aleister Crowley, Michael W. Ford, Paracelso, Éliphas Lévi e Giordano Bruno.

Regra: teofanias e figuras históricas NÃO são automaticamente inimigos genéricos. Podem surgir como visão, patrono, juiz, bênção, pacto, eco narrativo ou encontro especial conforme o cânone.

## 13. PROVENIÊNCIA E RIGOR

Manter separação explícita:
- FONTE;
- TRADIÇÃO;
- INTERPRETAÇÃO;
- DRAMATIZAÇÃO ELECTORUM.

O Liber Yaldabaoth fornecido ao projeto insiste nessa disciplina: o material antigo não deve ser fundido como se houvesse um sistema único e os sete/doze/365 arcontes variam por testemunho. O jogo pode criar uma síntese Electorum, mas deve rotulá-la como síntese/dramatização e preservar a proveniência no Codex.

## 14. INFRAESTRUTURA/BACKEND — NÃO REGREDIR

Estado esperado do backend já auditado em frente separada:
- Neon schema esperado 1.5.0.
- JWT/Neon Auth.
- save_campaign, campaign_snapshot, start_run, append_run_event, finish_run, Speculi, Codex, world state, relic, telemetry.
- cross-user isolation.
- real_progress_gate sem escrita client-side.
- frontend sem chave privilegiada.
- DATABASE_URL somente server-side.
- Vercel /api/health server-side.

A migração Godot NÃO pode quebrar esses contratos. Se a nova build desktop precisar de API, usar a camada server-side existente e nunca incorporar DATABASE_URL/segredos no executável.

## 15. REFERÊNCIAS DE TESTE ISAAC ENVIADAS PELO USUÁRIO

Arquivos fornecidos como referência de ritmo/sistemas:
- Binding of Isaac_ Afterbirth+ 2026-09-06 15-49-32.mp4
- Binding of Isaac_ Afterbirth+ 2026-09-06 15-51-52.mp4

Usar para estudar:
- cadência de sala;
- quantidade de inimigos por estágio;
- progressão de risco;
- leitura de projéteis;
- recompensa;
- segredos;
- pacing de boss;
- variedade sistêmica.

Não copiar literalmente personagens, layouts, itens, nomes, arte, sprites, músicas ou identidade visual.

## 16. TESTES DECLARADOS NO CHECKPOINT ANTERIOR

Antes da expansão roguelite final, a suíte da Jornada havia chegado a 36/36 testes verdes e o validador reportou:
- 16 journey entries;
- 82+ individual enemy forms;
- 16 bosses / 3 phases each;
- unique GLBs and canonical chain;
- no institutional progression writes.

Depois foram declarados testes verdes dos catálogos e runtimes parciais.

IMPORTANTE PARA A PRÓXIMA INSTÂNCIA:
Não confie cegamente nesses números. Rode fresh validation no repositório/branch real recuperado. O runtime local da conversa anterior não está montado neste checkpoint atual. Localize o repositório real no GitHub/Drive/workspace antes de afirmar que os commits existem remotamente.

## 17. COMMITS DECLARADOS NO CHECKPOINT ANTERIOR

Commits locais declarados na sessão anterior:
ed9570e  complete Student enemy catalog + factory
62be8b4  82 individual enemy GLBs
c229ccd  16 bosses + individual GLBs
9a418c3  generic Student floors/encounters
e01f1dc  canonical progression/save/initiation
94ed311  Student narrative + Codex
e3b38a9  Student validation
5259c0b  complete roguelite catalogs
52a2295  roguelite inventory runtime/build resolver

Branch declarado:
feat/godot-o-olho

ATENÇÃO: confirmar no GitHub/Drive se estes commits foram realmente persistidos/pushed. Se não estiverem, use este documento como especificação de reconstrução e não invente que o código existe.

## 18. PLANO DE CONTINUIDADE

Plano declarado anteriormente:
docs/superpowers/plans/2026-09-07-chronica-harun-godot-roguelite-systems.md

Próxima tarefa canônica:
TASK 4 — SPECIAL ROOMS AND ROUTE STATE

Depois:
TASK 5 — THEOPHANIES, HISTORICAL ECHOES AND CODEX PROVENANCE
TASK 6 — COMPLETION MARKS, ROUTES, CURSES/BLESSINGS AND GAUNTLETS
TASK 7 — DESKTOP DISTRIBUTION CONTRACT
TASK 8 — FULL STATIC QA

## 19. REGRA DE EXECUÇÃO PARA A PRÓXIMA ABA

A próxima instância deve:
1. Revalidar o estado REAL do código.
2. Recuperar repo/branch antes de editar.
3. Rodar testes antes da primeira mudança.
4. Continuar da Task 4 se Tasks 1-3 estiverem realmente presentes.
5. Se não estiverem, reconstruir exatamente com base neste checkpoint e validar.
6. Trabalhar por commits pequenos e verificáveis.
7. Não declarar “implementado” por existir JSON ou design. Exigir integração runtime.
8. Não declarar arte final 8K quando ainda for placeholder procedural.
9. Não publicar a build pública Canvas velha por cima da migração Godot.
10. Manter FPS em primeira pessoa e preservar câmera/world-space.

