# CHRONICA HARUN · Production Art v1 · Design

## Escopo

Esta frente altera somente a camada visual 3D de `game/chronica-harun`. Não altera narrativa, progressão, IA, AttackStateMachine, dano, HP, tempos de ataque, backend ou contratos de save.

## Estado de partida

- Branch: `feat/chronica-production-art-v1`
- Base governante: `4342dcdaf154de952620208ca36f1ab0e76b228e`
- Os 82 inimigos e 16 bosses possuem `model_path` estável.
- Os GLBs são gerados por `tools/generate_models.py` e são placeholders procedurais.
- Blender não é requisito de runtime e o gerador precisa continuar executável em CI apenas com Python + NumPy + trimesh.

## Objetivo visual

Transformar os placeholders em **procedural production candidates**, mantendo-os explicitamente não-finais. A leitura deve funcionar por massa, perfil e gesto antes de detalhe fino.

Paleta governante:

- preto profundo e carvão;
- pedra e cinza queimado;
- ouro queimado;
- cobre oxidado/ritual;
- vermelho ritual escuro;
- emissivo apenas como detalhe focal e sempre limitado.

Evitar bloom geral, corpos compostos apenas por glow, proporções repetidas e bosses tratados como esferas grandes.

## Prioridades

1. O OLHO: sete formas arcônticas distinguíveis já na silhueta.
2. A CHAMA: assimetria, perfis agressivos, fogo tratado como matéria aquecida em vez de glow.
3. A FUNDAÇÃO / A OBRA: massa pétrea, placas, contrafortes e leitura arquitetônica.
4. Bosses `blind_observer`, `impulse_archon`, `inert_stone_guardian`.
5. Demais famílias e bosses preservando identidade individual.
6. FPS viewmodel com mãos/antebraços separados do mundo e contrato de encaixe documentado.

## Formas arcônticas preservadas

- Athoth -> ram
- Eloaios -> asinine
- Astaphaios -> hyena
- Yao -> seven-headed serpent
- Sabaoth -> draconic/serpentine
- Adonin -> simian
- Sabbataios -> fire-face

São dramatizações visuais inspiradas nas fontes, não alegações históricas absolutas.

## Arquitetura do pipeline

`generate_models.py` continua sendo a fonte reprodutível dos GLBs e passa a oferecer:

- biblioteca de materiais PBR sem texturas externas obrigatórias;
- primitivas reutilizáveis para placas, chifres, mandíbulas, costelas, garras, olhos, caudas e ornamentos;
- builders exclusivos para as sete formas arcônticas;
- builders de prioridade dedicados aos três primeiros bosses;
- builders gerais enriquecidos para as famílias restantes;
- normalização de origem no chão e limites de escala;
- manifestos com classificação `procedural_production_candidate`;
- métricas de bounds, vértices, faces, materiais, emissive factor e assinatura SHA-256.

Colisão permanece separada do visual. Nenhum script de gameplay é modificado.

## Animação

Sem Blender disponível, não será alegado rig final. O pipeline fornece `animation_contracts.json` com nomes e semântica esperados para:

- `idle`
- `locomotion`
- `windup`
- `attack`
- `recovery`
- `hit_reaction`
- `death`
- `phase_transition` para bosses

Os tempos mecânicos continuam governados pelos dados existentes. O contrato de animação não os altera.

## Validação

A frente é considerada verde quando:

- o gerador produz exatamente 82 enemy GLBs e 16 boss GLBs;
- todos os `model_path` dos catálogos resolvem após geração;
- nenhum GLB possui bounds absurdos ou geometria vazia;
- materiais mantêm roughness/metallic dentro dos limites definidos e emission focal abaixo do teto;
- as sete formas arcônticas usam builders distintos;
- os três primeiros bosses usam builders exclusivos;
- o manifesto classifica corretamente Blender vs procedural;
- testes existentes continuam verdes;
- `validate_complete_game.py` e `validate_story_canon.py` continuam verdes;
- Godot 4.3 importa o projeto sem `Parse Error`, `Failed loading resource` ou material quebrado.

## Estado de arte

Nada gerado por este pipeline deve ser rotulado como `final art`. Sem Blender, tudo o que for substituído nesta frente será reportado como `procedural production candidate`. Assets não priorizados que mantiverem builder genérico serão reportados como candidatos intermediários/placeholder residual conforme o manifesto.
