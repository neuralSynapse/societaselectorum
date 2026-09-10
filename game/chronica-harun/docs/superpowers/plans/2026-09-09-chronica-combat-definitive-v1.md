# CHRONICA HARUN · COMBAT DEFINITIVE V1 — IMPLEMENTATION PLAN

> **Required sub-skill:** use `superpowers:test-driven-development` for each behavior change and `superpowers:verification-before-completion` before declaring completion.

**Goal:** elevar o runtime Godot para reproduzir a hierarquia visual e funcional do mock aprovado: HUD ritual premium, inimigos com nome/vida, chefe com nível/fase, Harun com vida/foco/poderes, aquisição visível de poderes, narração no alto e combate com dodge real.

**Architecture:** preservar `StageDirector` como orquestrador; `HUDController` assume apresentação e tracking de marcadores; `EnemyBrain`/`DataBossController` expõem estado de combate; `PlayerController` ganha dodge e invulnerabilidade; `StageDirector` conecta aquisição/recompensas ao HUD. Nenhuma lógica narrativa canônica é reescrita.

**Tech:** Godot 4.3, GDScript, cenas `.tscn`, testes Python estáticos existentes, GitHub Actions para validação.

**Spec:** `docs/superpowers/specs/2026-09-09-chronica-combat-definitive-v1-design.md`

**Global constraints:** branch isolada `feat/chronica-combat-definitive-v1`; base `integration/chronica-final-v1@60ed7e03775515ae0c2bfd31a0aef831638fe232`; sem merge automático; preservar assets/model paths e sistemas já verdes; nenhuma dependência binária nova obrigatória para boot.

---

### Task 1: Contrato anti-regressão do Combat Definitive

**Files:**
- Create: `tests/test_combat_definitive_visual_contract.py`

**Steps:**
1. Criar testes que exigem os nós e métodos definitivos do HUD, tracking de inimigos, aquisição de poder, dodge/invulnerabilidade e level metadata de boss/enemy.
2. Confirmar que o teste é vermelho contra a implementação atual pelo conteúdo esperado ausente.
3. Commitar o teste antes das mudanças de produção.

### Task 2: HUD ritual responsivo e hierarquia idêntica à referência

**Files:**
- Modify: `scenes/ui/HUD.tscn`
- Modify: `scripts/ui/HUDController.gd`

**Steps:**
1. Substituir offsets frágeis por anchors/layouts compatíveis com 16:9 e escaláveis.
2. Criar painel HARUN inferior esquerdo, números de vida/foco, level badge e Essência.
3. Criar boss panel topo-central com nível, fase e barra dominante.
4. Mover `Message` para topo-centro, acima do boss, com fundo translúcido.
5. Criar `EnemyMarkers`, `RewardFeed`, `PowerSlots` e `PowerAcquiredPanel`.
6. Implementar `track_enemy`, `untrack_enemy`, projeção de marcadores 3D→2D, `push_reward`, `show_power_acquired`, cooldown/estado de slots e atualização numérica do player.

### Task 3: Estado de inimigo e chefe exposto ao HUD

**Files:**
- Modify: `scripts/ai/EnemyBrain.gd`
- Modify: `scripts/ai/DataEnemy.gd`
- Modify: `scripts/bosses/DataBossController.gd`

**Steps:**
1. Adicionar `combat_level` e helpers de razão de vida/estado.
2. Emitir atualização de status em dano, identificação e morte.
3. Derivar nível de dados quando disponível e fallback determinístico baseado na progressão.
4. Expor ataque atual/fase do chefe sem duplicar lógica.
5. Preservar famílias e modelos existentes.

### Task 4: Dodge real de Harun e dificuldade justa

**Files:**
- Modify: `project.godot`
- Modify: `scripts/player/PlayerController.gd`

**Steps:**
1. Adicionar input `dodge` com teclado/controller sem conflitar com inputs existentes.
2. Implementar burst direcional com stamina, cooldown e janela curta de invulnerabilidade.
3. Detectar perfect dodge quando um dano chega na janela de precisão.
4. Chamar `PowerMutationRuntime.on_dodge` e aplicar stamina/efeitos devolvidos.
5. Emitir sinais para HUD/VFX/SFX e manter física/câmera estáveis.

### Task 5: Wiring em StageDirector, aquisição visível e primeira luta informativa

**Files:**
- Modify: `scripts/progression/StageDirector.gd`

**Steps:**
1. Registrar cada inimigo no HUD ao spawn e removê-lo na morte.
2. Registrar boss e fornecer nível/fase ao painel.
3. Atualizar PowerSlots com poder da etapa e Kinesis real.
4. Em pickups de categoria `powers` ou aquisição/mutação, mostrar cartão `PODER ADQUIRIDO` e feed de recompensa.
5. Após elite/combate-chave, oferecer escolha de poderes quando houver opções válidas, incorporando a escolha na build sem substituir o sistema roguelite existente.
6. Aplicar VFX/SFX no uso de poderes e dodge usando diretores já existentes.

### Task 6: Acabamento audiovisual via sistemas existentes

**Files:**
- Modify if needed: `autoload/VFXDirector.gd`
- Modify if needed: `autoload/AudioDirector.gd`
- Modify if needed: `scenes/rooms/RoomShell.tscn`

**Steps:**
1. Auditar os eventos existentes para dodge, power reveal, boss phase, enemy windup e hit.
2. Adicionar fallback seguro apenas para eventos ausentes.
3. Elevar emissão, luz curta de impacto e contraste ritual sem introduzir dependência que impeça boot.
4. Preservar assets reais e `model_path` sempre que válidos.

### Task 7: Verificação e handoff

**Files:**
- Update: `docs/CHECKPOINT_MASTER.md` somente se a implementação estiver verde.

**Steps:**
1. Rodar/verificar GitHub Actions aplicáveis ao branch e inspecionar falhas.
2. Comparar branch com base e revisar regressões acidentais.
3. Confirmar contrato novo, testes existentes e boot/release workflows quando disponíveis.
4. Abrir PR para `integration/chronica-final-v1` somente após verificação, sem merge automático.
5. Entregar SHA final e prompt de integração para o coordenador principal.