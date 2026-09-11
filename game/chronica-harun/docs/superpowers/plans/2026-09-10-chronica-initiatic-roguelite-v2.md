# Plano de Implementação · CHRONICA HARUN · INICIÁTICO ROGUELITE v2

## Meta

Implementar a arquitetura aprovada sem regressão do runtime atual e publicar uma build Web jogável no domínio da Societas.

## Cadeia governante

**Portal 0 · Aspirante — Initiatio Luciferi → Estudante → I · Peregrinus Ignis**

Portal 0/Aspirante e Estudante não são Graus. O primeiro Grau é I · Peregrinus Ignis. A nomenclatura intermediária ACTUS INGRESSUS fica superada como nome governante, mas saves antigos devem ser migrados com segurança.

## Sequência

1. **Teste de contrato V2 primeiro**
   - Criar `tests/test_initiatic_roguelite_v2_contract.py`.
   - Exigir Portal 0 · Aspirante — Initiatio Luciferi + 3 Claves, ESTUDANTE + 12 Pergaminhos, 33 Graus com nomes públicos canônicos, Draconis velada, 33 Pergaminhos, catálogos roguelite, modal responsivo e menu ESC expandido.
   - Rodar CI e confirmar RED antes da implementação.

2. **Fonte única de progressão**
   - Criar `data/progression/initiatic_path.json`.
   - Criar `scripts/progression/InitiaticProgressionService.gd`.
   - Registrar catálogo no ContentRegistry.
   - Migrar GameState com compatibilidade de saves antigos, inclusive `ACTUS_INGRESSUS` e `PEREGRINUS_IGNIS_GAME`.

3. **Integração de runtime**
   - Reutilizar as 15 etapas narrativas existentes para Portal 0 + ESTUDANTE e preservar a Câmara de Iniciação como ponte.
   - Após a Câmara, gerar o Grau atual data-driven, começando em I · Peregrinus Ignis.
   - Persistir fase, Grau e Pergaminho liberado sem escrever progressão institucional real.
   - Manter compatibilidade com consumidores legados que ainda leem `stage_index`.

4. **Escolha narrativa e Web input**
   - Manter NarrativeChoiceDirector como fonte de consequência.
   - Atualizar NarrativePresentation para modal grande, layout vertical, opção/custo/consequência separados e input 1/2/3.
   - Pausar combate durante escolha e restaurar pointer lock de forma segura em Web.

5. **Menu ESC completo**
   - Substituir o placeholder por navegação funcional: Retomar, Jornada/Mapa, Build & Poderes, Tarot & Pharmaka, Codex, Personagens/Marcas, Controles, Configurações, Reiniciar Run e Voltar ao título.
   - Expor Portal 0, Estudante e Graus liberados.
   - Nunca revelar Arbor Draconis antes da conclusão do Grau XXII.

6. **Roguelite presente em jogo**
   - Integrar Tarot, Pharmaka, Instrumenta, Relíquias, Talismãs, Sigilla, Daimones, Blessings/Curses, Transformations e Powers às recompensas e superfícies de run.
   - Garantir Secret e Super Secret com recompensa, telegraph e persistência.
   - Preservar seed determinística e pools existentes.

7. **Personagens e encontros**
   - Criar diretor de encontros narrativos data-driven usando `playable_roster.json`.
   - Aparições dependem do marco e da rota; não usar rotação aleatória sem contexto.
   - Harun permanece protagonista padrão.

8. **Elevação visual de inimigos e bosses**
   - Adicionar famílias de silhueta, partes secundárias, emissivos, runas e fase visual de boss sem apagar modelos aprovados.
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
   - Salvar checkpoint com a cadeia Portal 0 · Aspirante — Initiatio Luciferi → Estudante → I · Peregrinus Ignis.
   - Tentar persistência no Drive. Se o provedor bloquear por quota/permissão, preservar o snapshot exato no repositório e registrar o bloqueio sem fingir sucesso.
   - Registrar commit final, run CI, estado dos catálogos e link jogável.

## Estratégia TDD

O contrato V2 entrou antes da implementação e produziu falhas esperadas. Mudanças de requisito canônico atualizam as expectativas históricas sem apagar testes: o objetivo dos testes de fundação continua sendo anti-regressão, agora alinhado à cadeia governante mais recente.

## Critério de conclusão

Não declarar pronto antes de uma execução fresca que demonstre testes + import + boot + captura + export + deploy verdes e antes de confirmar que o link público está servindo a nova build.
