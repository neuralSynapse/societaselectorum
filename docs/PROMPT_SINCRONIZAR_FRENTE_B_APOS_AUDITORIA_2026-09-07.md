# PROMPT · SINCRONIZAR FRENTE B APÓS AUDITORIA DA FONTE GODOT

Cole o bloco abaixo na outra guia responsável por **CHRONICA HARUN · FRENTE PARALELA B · COMBAT SYSTEM + ENEMY/BOSS PRODUCTION**.

```text
CHRONICA HARUN · ATUALIZAÇÃO CRÍTICA DA FRENTE A PARA A FRENTE B

Absorva este estado antes de continuar qualquer implementação de combate.

REPOSITÓRIO AUDITADO:
neuralSynapse/societaselectorum

FRENTE A:
branch: feat/chronica-foundation-audit
relatório persistido:
docs/CHRONICA_HARUN_FOUNDATION_AUDIT_2026-09-07.md

IMPORTANTE: NÃO use a fundação mínima de feat/chronica-foundation-audit como se fosse a fonte histórica/completa do gameplay. Ela é apenas scaffold de fundação + QA criado explicitamente durante a recuperação.

============================================================
FATOS JÁ VERIFICADOS PELA FRENTE A
============================================================

1. chronica/godot-engine-v1 NÃO é a fonte Godot real.
Ela continua no mesmo commit-base conhecido de main:
d5c927ac9cc118278388c8b03f038675e300a191

2. A branch histórica declarada:
feat/godot-o-olho
foi procurada diretamente no remoto e está ABSENT.

3. Os commits históricos declarados foram testados como objetos Git e TODOS estão ABSENT no remoto auditado:

ed9570e
62be8b4
c229ccd
9a418c3
e01f1dc
94ed311
e3b38a9
5259c0b
52a2295

Não os trate como existentes.

4. Existe a branch:
handoff/chronica-godot-real-source-2026-09-07

Ela documenta que em OUTRO workspace local houve uma recuperação mais completa, com referências:

feat/chronica-narrative-integration
HEAD local declarado: 82449af8f83c10b46b4e4d907e2f1aea39bdee48
base gameplay local declarada: f4647798046254baff3447d9e224dd4fdb52d548
workspace declarado:
/mnt/data/chronica-godot-recovered/.worktrees/narrative-integration/

Esses SHAs/local paths NÃO estão confirmados como objetos remotos disponíveis no repo atual.

5. O handoff expõe somente um manifesto direto:
chronica-handoff/source/project.godot

Ele declara projeto CHRONICA HARUN, main scene res://scenes/boot/Main.tscn, Godot 4.3/GL Compatibility e autoloads GameState, SaveService, ContentRegistry, RogueliteContentService e AudioDirector.

Isso NÃO basta para restaurar o jogo porque a árvore completa não está exposta diretamente nessa branch.

============================================================
OS DOIS PACOTES DE RESTORE NO GITHUB ESTÃO CORROMPIDOS
============================================================

A Frente A verificou os blobs REAIS persistidos no GitHub, não apenas o relatório que dizia que eles estavam bons localmente.

PACOTE V1:
chronica-handoff/CHRONICA_HARUN_FRONT_B_SOURCE_MIN_2026-09-07.tar.gz.b64

resultado literal:
compact_length: 20021
contains_ellipsis_marker: true
invalid_chars: [".", "[", "]"]
length_mod_4: 1
status: CORRUPT_NOT_VALID_BASE64
stored_sha256: 6fb8a881652dc44aab6c8ccae36c6a5b42e26b3fef665beb7dcbade4c706b66e

PACOTE V2:
chronica-handoff/CHRONICA_HARUN_FRONT_B_SOURCE_MIN_v2_2026-09-07.tar.gz.b64

resultado literal:
compact_length: 18479
contains_ellipsis_marker: true
invalid_chars: [".", "[", "]"]
length_mod_4: 3
status: CORRUPT_NOT_VALID_BASE64
stored_sha256: b057d950dfa9b7dc32bc775800d9e0df0b21651b2b9e6b74781ed4b4272ae442

Ou seja: houve elisão/truncamento no conteúdo persistido. Não existe comando mágico que recupere os bytes removidos. Remover os caracteres estranhos não reconstrói os dados perdidos.

6. A sua própria branch atual:
feat/chronica-combat-entities
foi criada a partir do handoff e tentou restaurar o pacote.

O workflow CHRONICA Front B Restore já falhou duas vezes.
Na segunda tentativa, mesmo tentando filtrar/wrapping, o restore terminou literalmente em:

base64: invalid input
Process completed with exit code 1.

Os passos de verificar paths/counts e persistir source foram pulados.

PORTANTO: não considere feat/chronica-combat-entities como source restaurado enquanto o restore não for realmente concluído e validado.

7. A branch feat/chronica-roguelite-depth também NÃO é a fonte histórica completa. É uma frente paralela parcial criada a partir de main, contendo apenas parte dos sistemas roguelite.

============================================================
O QUE VOCÊ DEVE FAZER AGORA
============================================================

PRIORIDADE 1: procure no SEU runtime atual se ainda existe o workspace local real:

/mnt/data/chronica-godot-recovered/.worktrees/narrative-integration/

ou qualquer clone/worktree equivalente contendo a árvore completa.

Se existir:

A. NÃO tente transferir a árvore completa como Base64 gigante por uma chamada que pode truncar texto.

B. Persista a fonte diretamente como arquivos Git normais em uma branch dedicada, por exemplo:

handoff/chronica-godot-source-tree-2026-09-07

ou em um repositório dedicado, se o tamanho exigir.

C. Para assets gerados muito grandes, prefira persistir os geradores + fontes mínimas necessárias e gerar os GLBs em CI, ou use mecanismo binário apropriado. Não invente Base64 truncado novamente.

D. Antes de chamar a fonte de recuperada, execute SOBRE A ÁRVORE PERSISTIDA:

git status
git branch -a
git log --oneline --decorate -30
pytest -q
Godot headless import
Godot boot/scene smoke

E valide obrigatoriamente:

project.godot
autoload/GameState.gd
autoload/SaveService.gd
autoload/RogueliteContentService.gd
scripts/progression/StageDirector.gd
scripts/generation/StageFloorBuilder.gd
scripts/content/BuildResolver.gd
scripts/content/PowerMutationRuntime.gd
scripts/content/DaimonRuntime.gd
scripts/rooms/SpecialRoomDirector.gd
scripts/vision/VisionDirector.gd
scripts/meta/MetaRunDirector.gd
data/stages/student_journey.json
data/enemies/student_enemies.json
data/bosses/student_bosses.json
data/roguelite/
scenes/player/
scenes/enemies/
scenes/bosses/
scripts/ai/
scripts/combat/

E. Verifique os contratos:
- FPS real em primeira pessoa;
- 15 subetapas + Câmara de Iniciação;
- PEREGRINUS_IGNIS_GAME apenas narrativo;
- gameplay jamais escreve real_progress_gate;
- 82+ inimigos e 16 bosses/3 fases somente se os catálogos/cenas reais sustentarem esses números;
- nenhum secret de backend embutido;
- save version consistente;
- recursos/cenas resolvem;
- boot passa.

F. Somente APÓS isso continue a Frente B no escopo de combate/entities.

Se o workspace local NÃO existir mais:

- declare a fonte completa como perdida/não persistida;
- não continue fingindo que o pacote GitHub restaura o jogo;
- use checkpoint/cânone + frentes parciais apenas como material de reconstrução deliberada;
- mantenha essa reconstrução explicitamente identificada como reconstrução, nunca recuperação dos objetos históricos.

============================================================
ANTI-CONFLITO
============================================================

Não mexa em main.
Não substitua Godot pelo projeto web/Canvas.
Não altere narrativa principal.
Não mexa no backend.
Não use feat/chronica-foundation-audit como base de combate.
Não use feat/chronica-roguelite-depth como se fosse a árvore completa recuperada.

A Frente A terminou com sua fundação/QA verde, mas a árvore Godot completa continua bloqueada até existir uma cópia remota íntegra.

Quando conseguir persistir a árvore REAL, informe de volta:
- repo/URL;
- branch;
- HEAD SHA completo;
- caminho de project.godot;
- resultado literal de pytest;
- versão Godot;
- resultado de import/boot;
- contagem real de enemy/boss catalogs/scenes;
- confirmação de que a branch contém source completo e não pacote truncado.

Não declare conclusão antes disso.
```
