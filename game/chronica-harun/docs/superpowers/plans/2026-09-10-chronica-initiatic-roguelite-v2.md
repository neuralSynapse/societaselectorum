# Plano de Implementação · CHRONICA HARUN · INICIÁTICO ROGUELITE v2

## Meta

Implementar a arquitetura aprovada sem regressão do runtime atual e publicar uma build Web jogável no domínio da Societas.

## Sequência

1. **Teste de contrato V2 primeiro**
   - Criar `tests/test_initiatic_roguelite_v2_contract.py`.
   - Exigir ACTUS INGRESSUS + 3 Claves, ESTUDANTE + 12 Pergaminhos, 33 Graus, Draconis velada, 33 Pergaminhos, catálogos roguelite, modal responsivo e menu ESC expandido.
   - Rodar CI e confirmar RED antes da implementação.

2. **Fonte única de progressão**
   - Criar `data/progression/initiatic_path.json`.
   - Criar `scripts/progression/InitiaticProgressionService.gd`.
   - Registrar catálogo no ContentRegistry.
   - Migrar GameState com compatibilidade de saves antigos.

3. **Integração StageDirector**
   - Reutilizar as 15 etapas narrativas existentes para ACTUS INGRESSUS + ESTUDANTE.
   - Após Câmara de Iniciação, gerar as etapas de Grau data-driven usando template de sala/inimigo/boss já existente.
   - Persistir fase, Grau e Pergaminho liberado.

4. **Escolha narrativa e Web input**
   - Atualizar NarrativeChoiceDirector para passar payload estruturado.
   - Atualizar HUDController/HUD para modal grande, layout vertical, custo/consequência separados e input 1/2.
   - Pausar combate durante escolha e restaurar pointer lock de forma segura em Web.

5. **Menu ESC completo**
   - Substituir placeholder por navegação funcional: Retomar, Jornada, Build, Inventário, Codex, Personagens, Controles, Configurações, Reiniciar Run e Título.
   - Expor estado atual e Draconis somente após Grau XXII.

6. **Roguelite presente em jogo**
   - Integrar Tarot, Pharmaka, Instrumenta, Relíquias, Talismãs, Sigilla, Daimones, Blessings/Curses e Powers às recompensas por sala.
   - Garantir Secret e Super Secret com recompensas e telegraph.
   - Preservar seed determinística e pools existentes.

7. **Personagens e encontros**
   - Criar diretor de encontros narrativos data-driven usando `playable_roster.json`.
   - Aparições dependem do marco e da rota; não usar rotação aleatória sem contexto.

8. **Elevação visual de inimigos e bosses**
   - Melhorar geradores de production art com famílias de silhueta, partes secundárias, emissivos e fase visual de boss.
   - Manter orçamento Web e contratos de modelo.

9. **Validação**
   - Pytest completo + validadores.
   - Godot 4.3 import estrito.
   - Main boot smoke.
   - Captura visual específica do modal/menu e gameplay.
   - Export Web.
   - Deploy Pages.
   - Verificar página da Societas apontando para build atual.

10. **Checkpoint e Drive**
   - Atualizar `docs/CHECKPOINT_MASTER.md`.
   - Criar documento de checkpoint no Drive na pasta CHRONICA HARUN.
   - Registrar commit final, run CI, estado dos catálogos e link jogável.

## Estratégia TDD

O contrato V2 entra primeiro e precisa falhar na branch antes das mudanças funcionais. Depois cada subsistema deve satisfazer o contrato e a suíte histórica. Nenhum teste histórico será apagado para produzir verde.

## Critério de conclusão

Não declarar pronto antes de uma execução fresca que demonstre testes + import + boot + captura + export + deploy verdes e antes de confirmar que o link público está servindo a nova build.