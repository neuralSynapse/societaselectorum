# CHRONICA HARUN Production Art v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: execute task-by-task with TDD and verification before completion.

**Goal:** elevar a camada visual 3D para procedural production candidates reprodutíveis sem alterar gameplay, preservando 82 enemy paths e 16 boss paths.

**Architecture:** manter `tools/generate_models.py` como gerador determinístico e expandi-lo com builders de silhueta, materiais PBR controlados, manifests de QA e contratos de animação. A validação ocorre por testes Python, geração integral dos 98 GLBs, validadores existentes e Godot 4.3 headless em CI.

**Tech Stack:** Python 3.12, NumPy, trimesh, pytest, Godot 4.3 headless, GitHub Actions.

**Spec:** `game/chronica-harun/docs/superpowers/specs/2026-09-07-production-art-v1-design.md`

## Global Constraints

- Branch exclusiva: `feat/chronica-production-art-v1`.
- Base exata: `4342dcdaf154de952620208ca36f1ab0e76b228e`.
- Não fazer merge em `main` nem `integration/chronica-final-v1`.
- Não alterar narrativa, combate, progressão ou backend.
- Não alterar timing mecânico do AttackStateMachine.
- Blender ausente implica classificação `procedural_production_candidate`, nunca `final art`.
- Paths `res://art/generated/enemies/<id>.glb` e `res://art/generated/bosses/<id>.glb` permanecem estáveis.

---

### Task 1: Contratos de QA visual em teste

**Files:**
- Create: `game/chronica-harun/tests/test_production_art_contract.py`

**Interfaces:**
- Consumes: funções públicas de `tools/generate_models.py`.
- Produces: contrato executável para materiais, builders arcônticos, bosses prioritários, bounds e classificação de manifesto.

- [ ] Escrever testes que exijam builders distintos `ram_archon`, `asinine_archon`, `hyena_archon`, `seven_head_serpent`, `draconic_archon`, `simian_archon`, `fire_face`.
- [ ] Exigir `PRODUCTION_CLASS == "procedural_production_candidate"`.
- [ ] Exigir material sem emissão geral e `emissiveFactor` focal <= 0.18 quando houver.
- [ ] Exigir bounds normalizados: base próxima de Y=0 e altura de enemy <= 4.5; boss <= 7.0.
- [ ] Exigir que `blind_observer`, `impulse_archon` e `inert_stone_guardian` usem builders dedicados.
- [ ] Rodar a suíte e confirmar RED contra o gerador antigo.

### Task 2: Biblioteca visual e formas arcônticas

**Files:**
- Modify: `game/chronica-harun/tools/generate_models.py`

**Interfaces:**
- Produces: `enemy_scene(row) -> trimesh.Scene`, `boss_scene(row) -> trimesh.Scene`, `scene_metrics(scene) -> dict` e registries de builders.

- [ ] Criar materiais PBR `charcoal`, `burnt_gold`, `ritual_red`, `burnt_stone`, `copper`, `heated_metal` com roughness alto e metallic controlado.
- [ ] Criar primitivas auxiliares para chifres, focinho, mandíbulas, garras, placas, costelas, caudas e coroas.
- [ ] Implementar sete builders arcônticos distintos, priorizando perfil frontal/lateral reconhecível.
- [ ] Implementar leitura de windup por geometria estática dedicada, sem alterar ataque mecânico.
- [ ] Manter origem no chão e pivô central estável.
- [ ] Rodar testes focados até GREEN.

### Task 3: O OLHO, A CHAMA e A FUNDAÇÃO

**Files:**
- Modify: `game/chronica-harun/tools/generate_models.py`

**Interfaces:**
- Consumes: registries de builders.
- Produces: variação por `stage_id`, `role`, `family` e seed determinística.

- [ ] O OLHO recebe foco em olhos, coroas cegas, cabeças animais e leitura de sete autoridades.
- [ ] A CHAMA recebe materiais aquecidos não-emissivos ou emissão focal mínima e silhuetas assimétricas.
- [ ] A FUNDAÇÃO recebe placas de pedra, contrafortes, pesos inferiores e negativos arquitetônicos.
- [ ] Elites ganham massa/proporção próprias sem apenas aplicar escala uniforme.
- [ ] Rodar geração integral e validar 82 enemy GLBs.

### Task 4: Três bosses prioritários e bosses restantes

**Files:**
- Modify: `game/chronica-harun/tools/generate_models.py`

**Interfaces:**
- Consumes: `silhouette` do catálogo de bosses.
- Produces: 16 GLBs únicos e métricas individuais.

- [ ] `blind_observer`: olho central não esférico, órbitas quebradas, coroa de sete eyelets e apêndices de sustentação.
- [ ] `impulse_archon`: corpo de chama material, chifres, caixa torácica exposta e braços/laminas de ataque.
- [ ] `inert_stone_guardian`: colosso pétreo com cabeça baixa, ombros de contraforte, braços pesados e fissuras geométricas.
- [ ] Enriquecer builders restantes para evitar “esfera grande” e repetir proporções.
- [ ] Rodar geração integral e validar 16 boss GLBs.

### Task 5: Manifesto, animação e viewmodel contract

**Files:**
- Create: `game/chronica-harun/art/production/production_art_manifest.json`
- Create: `game/chronica-harun/art/production/animation_contracts.json`
- Create: `game/chronica-harun/art/production/fps_viewmodel_contract.json`
- Modify: `game/chronica-harun/tools/generate_models.py`

**Interfaces:**
- Manifesto registra classe, builder, prioridade, bounds, materiais, SHA-256 e status de substituição.

- [ ] Registrar 98 assets a partir dos catálogos na geração.
- [ ] Distinguir `priority_candidate`, `general_candidate` e `residual_placeholder` quando aplicável.
- [ ] Declarar `blender_used: false` enquanto Blender não estiver disponível.
- [ ] Declarar contratos de animação sem timestamps mecânicos.
- [ ] Declarar viewmodel com duas mãos/antebraços, escala, orientação e sockets, sem anexar visual à câmera mundial.

### Task 6: Validador de produção e CI da branch

**Files:**
- Create: `game/chronica-harun/tools/validate_production_art.py`
- Create: `.github/workflows/chronica-production-art-v1.yml`

**Interfaces:**
- `validate_production_art.py` retorna exit code 0 somente com contratos visuais satisfeitos.

- [ ] Validar contagem 82/16 e resolução de todos os paths.
- [ ] Carregar cada GLB com trimesh e validar geometria, bounds, materiais e ausência de escala absurda.
- [ ] Validar que manifestos não chamam candidatos de final.
- [ ] Rodar `pytest`, `validate_complete_game.py`, `validate_story_canon.py`, `validate_production_art.py`.
- [ ] Instalar Godot 4.3 e executar import headless estrito.
- [ ] Publicar manifests e provas de render como artifact de CI quando disponíveis.

### Task 7: Provas visuais reprodutíveis

**Files:**
- Create: `game/chronica-harun/tools/render_production_art_proofs.py`

**Interfaces:**
- Consumes GLBs gerados.
- Produces PNGs ortográficos simples e um índice JSON, sem depender de Blender/OpenGL.

- [ ] Gerar vistas frontal/lateral/top de assets prioritários por projeção de triângulos.
- [ ] Produzir contact sheet dos sete arcônticos e dos três primeiros bosses.
- [ ] Incluir os PNGs como artifact do workflow.

### Task 8: Verificação final e commit de fechamento

- [ ] Confirmar todos os testes e validadores verdes no CI da branch.
- [ ] Confirmar Godot 4.3 import verde.
- [ ] Confirmar que nenhum merge foi realizado.
- [ ] Atualizar manifesto de entrega com HEAD, assets substituídos, placeholders residuais, Blender=false, rigs/animações como contratos, provas e limitações.
- [ ] Commitar somente em `feat/chronica-production-art-v1`.
