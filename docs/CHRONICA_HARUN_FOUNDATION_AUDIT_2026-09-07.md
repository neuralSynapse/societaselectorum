# CHRONICA HARUN · FRENTE A
## Recuperação do projeto Godot + Fundação + QA

Data: 2026-09-07
Branch exclusiva: `feat/chronica-foundation-audit`
Base inicial: `d5c927ac9cc118278388c8b03f038675e300a191`
Regra: **não fazer merge em `main`** sem uma decisão explícita posterior.

## 1. Conclusão executiva

A auditoria separou três coisas que estavam sendo confundidas:

1. `main` / `chronica/godot-engine-v1`: não contêm a fonte Godot histórica esperada.
2. `feat/chronica-foundation-audit`: contém uma fundação mínima reconstruída e auditável, criada apenas para estabilizar contratos e QA. Ela **não é apresentada como a fonte histórica recuperada**.
3. `handoff/chronica-godot-real-source-2026-09-07`: contém documentação de uma recuperação local anterior e expõe `chronica-handoff/source/project.godot`, mas os dois pacotes Base64 persistidos no GitHub estão corrompidos/truncados e não restauram a árvore completa.

Consequência: a fundação desta branch está verde, porém a árvore Godot completa alegadamente recuperada em outro workspace ainda não está disponível de forma remota, íntegra e reproduzível.

## 2. Repositório auditado

`neuralSynapse/societaselectorum`

Remote confirmado:

```text
origin  https://github.com/neuralSynapse/societaselectorum (fetch)
origin  https://github.com/neuralSynapse/societaselectorum (push)
```

## 3. Branches e história

No run de auditoria com `fetch-depth: 0` e `git fetch --all --prune`, foram vistas, entre outras:

```text
origin/chronica/godot-engine-v1
origin/feat/chronica-combat-entities
origin/feat/chronica-foundation-audit
origin/feat/chronica-roguelite-depth
origin/handoff/chronica-godot-real-source-2026-09-07
origin/main
```

`chronica/godot-engine-v1` continua apontando para o mesmo commit-base conhecido de `main`:

`d5c927ac9cc118278388c8b03f038675e300a191`

A branch histórica declarada `feat/godot-o-olho` foi procurada diretamente e o resultado foi:

```text
feat_godot_o_olho: ABSENT
```

Os commits históricos declarados também foram testados com `git cat-file -e <sha>^{commit}` e todos ficaram ausentes:

```text
ed9570e ABSENT
62be8b4 ABSENT
c229ccd ABSENT
9a418c3 ABSENT
e01f1dc ABSENT
94ed311 ABSENT
e3b38a9 ABSENT
5259c0b ABSENT
52a2295 ABSENT
```

## 4. Fonte Godot recuperada: estado verificável

A branch `handoff/chronica-godot-real-source-2026-09-07` expõe diretamente:

`chronica-handoff/source/project.godot`

O manifesto exposto declara:

```text
config/name="CHRONICA HARUN"
run/main_scene="res://scenes/boot/Main.tscn"
config/features=PackedStringArray("4.3", "GL Compatibility")
```

Autoloads declarados no manifesto:

```text
GameState="*res://autoload/GameState.gd"
SaveService="*res://autoload/SaveService.gd"
ContentRegistry="*res://autoload/ContentRegistry.gd"
RogueliteContentService="*res://autoload/RogueliteContentService.gd"
AudioDirector="*res://autoload/AudioDirector.gd"
```

Porém a branch de handoff não expõe diretamente a árvore completa necessária para validar esses paths.

### 4.1 Pacote v1

Arquivo:

`chronica-handoff/CHRONICA_HARUN_FRONT_B_SOURCE_MIN_2026-09-07.tar.gz.b64`

Auditoria literal do blob persistido:

```text
compact_length: 20021
contains_ellipsis_marker: true
invalid_chars: [".", "[", "]"]
length_mod_4: 1
status: CORRUPT_NOT_VALID_BASE64
stored_bytes: 20023
stored_sha256: 6fb8a881652dc44aab6c8ccae36c6a5b42e26b3fef665beb7dcbade4c706b66e
```

### 4.2 Pacote v2

Arquivo:

`chronica-handoff/CHRONICA_HARUN_FRONT_B_SOURCE_MIN_v2_2026-09-07.tar.gz.b64`

Auditoria literal do blob persistido:

```text
compact_length: 18479
contains_ellipsis_marker: true
invalid_chars: [".", "[", "]"]
length_mod_4: 3
status: CORRUPT_NOT_VALID_BASE64
stored_bytes: 18481
stored_sha256: b057d950dfa9b7dc32bc775800d9e0df0b21651b2b9e6b74781ed4b4272ae442
```

Portanto, relatórios que dizem que o pacote local foi validado podem ser verdadeiros para o workspace local anterior, mas **não validam os blobs que acabaram persistidos no GitHub**. Os blobs remotos contêm marcador de elisão/truncamento e não são Base64 válidos.

## 5. Frente B observada durante a auditoria

A branch `feat/chronica-combat-entities` apareceu enquanto esta Frente A estava rodando.

Ela foi criada a partir do handoff, mas a auditoria de árvore encontrou apenas o `project.godot` exposto pelo handoff como hit do conjunto obrigatório, não a fonte completa.

O workflow `CHRONICA Front B Restore` falhou duas vezes. Na segunda tentativa, mesmo tentando tolerar wrapping/garbage, o passo de restauração terminou literalmente em:

```text
base64: invalid input
Process completed with exit code 1.
```

Os passos posteriores de verificar paths, persistir source e continuar a produção foram pulados.

Regra: `feat/chronica-combat-entities` não deve ser tratada como base restaurada até que a árvore real seja persistida e um restore/QA completo passe.

## 6. Fundação mínima reconstruída nesta branch

Como a fonte completa não estava acessível quando a Frente A começou, foi construída uma fundação mínima, explícita e auditável em:

`godot/chronica_harun/`

Ela valida contratos de fundação sem fingir recuperar conteúdo de combate ou arte.

Principais garantias cobertas:

- Godot abre/importa a fundação;
- boot headless não quebra;
- player é `CharacterBody3D` com `Camera3D` real;
- contrato FPS de primeira pessoa;
- 15 subetapas + Câmara de Iniciação;
- `PEREGRINUS_IGNIS_GAME` permanece estado narrativo;
- `real_progress_gate` não aparece como escrita de gameplay nos GDScripts auditados;
- save version consistente;
- save local usa `user://`;
- autoloads fundamentais existem;
- referências `res://` das cenas da fundação resolvem;
- catálogo/bestiário ausente é marcado como `not_recovered`, não fabricado;
- não há credenciais/backend secrets embutidos nos arquivos auditados;
- boot da fundação não depende do backend.

## 7. Testes finais da fundação

Run canônico após a limpeza dos probes temporários:

GitHub Actions: `CHRONICA Foundation Audit`.

`pytest -q`:

```text
....................                                                     [100%]
20 passed in 0.06s
```

Teste backend existente:

```text
# tests 4
# pass 4
# fail 0
# cancelled 0
# skipped 0
# todo 0
```

Godot detectado e executado:

```text
4.5.1.stable.official.f62fdbde1
```

Checksum do binário oficial baixado pelo CI:

```text
/tmp/godot.zip: OK
```

Import headless terminou com:

```text
[ DONE ] first_scan_filesystem
[ DONE ] update_scripts_classes
[ DONE ] loading_editor_layout
```

Boot smoke headless iniciou sem erro fatal reportado.

## 8. Arquivos alterados nesta branch

Comparação contra `main` antes deste relatório:

```text
.github/workflows/chronica-foundation-audit.yml
godot/chronica_harun/autoload/GameState.gd
godot/chronica_harun/autoload/RogueliteContentService.gd
godot/chronica_harun/autoload/SaveService.gd
godot/chronica_harun/data/bosses/student_bosses.json
godot/chronica_harun/data/enemies/student_enemies.json
godot/chronica_harun/data/game_contract.json
godot/chronica_harun/data/roguelite/catalog_manifest.json
godot/chronica_harun/data/stages/student_journey.json
godot/chronica_harun/project.godot
godot/chronica_harun/scenes/boot/Boot.tscn
godot/chronica_harun/scenes/player/Player.tscn
godot/chronica_harun/scripts/boot/Boot.gd
godot/chronica_harun/scripts/content/BuildResolver.gd
godot/chronica_harun/scripts/content/DaimonRuntime.gd
godot/chronica_harun/scripts/content/PowerMutationRuntime.gd
godot/chronica_harun/scripts/generation/StageFloorBuilder.gd
godot/chronica_harun/scripts/meta/MetaRunDirector.gd
godot/chronica_harun/scripts/player/PlayerController.gd
godot/chronica_harun/scripts/progression/StageDirector.gd
godot/chronica_harun/scripts/rooms/SpecialRoomDirector.gd
godot/chronica_harun/scripts/vision/VisionDirector.gd
godot/chronica_harun/tests/test_foundation_contract.py
```

Este relatório passa a ser mais um arquivo alterado.

Nenhum caminho de conflito da Frente B foi editado:

```text
scripts/combat/**
scripts/ai/**
scenes/enemies/**
scenes/bosses/**
scenes/vfx/**
audio/entities/**
```

## 9. Backend

Nenhuma implementação Neon/Vercel foi alterada nesta frente.

O contrato existente permanece tratado somente como contrato externo. A suíte existente de autenticação passou 4/4 no CI da Frente A.

## 10. Problemas ainda existentes

O bloqueio restante não é um parser ou bug da fundação desta branch. É **persistência incompleta da fonte recuperada completa**.

Para desbloquear as frentes que precisam de combate/assets reais, uma guia que ainda possua o workspace local recuperado deve persistir a árvore de source como arquivos Git normais ou como artefato binário real, sem passar um Base64 grande por uma interface que o trunca/elide.

Fonte local declarada pelo handoff anterior:

```text
/mnt/data/chronica-godot-recovered/.worktrees/narrative-integration/
```

Commits locais declarados no handoff anterior:

```text
82449af8f83c10b46b4e4d907e2f1aea39bdee48  estado completo recuperado/narrativa
f4647798046254baff3447d9e224dd4fdb52d548  base de gameplay recuperada
```

Esses SHAs não foram encontrados como objetos acessíveis no repositório remoto auditado. São referências de um workspace local anterior e não devem ser tratados como remotos existentes.

## 11. Condição para considerar a fonte real desbloqueada

Somente considerar desbloqueada quando houver, numa branch/repo acessível:

- `project.godot`;
- todos os autoloads e runtimes fundamentais;
- `data/enemies/student_enemies.json`;
- `data/bosses/student_bosses.json`;
- `data/roguelite/`;
- `scenes/player/`;
- `scenes/enemies/`;
- `scenes/bosses/`;
- `scripts/ai/`;
- `scripts/combat/`;
- geradores/validators quando necessários;
- `pytest -q` executado sobre essa árvore;
- Godot headless import executado sobre essa árvore;
- boot/scene smoke executado sobre essa árvore.

Até isso acontecer, a fundação desta branch é QA/scaffold e não substituto do source completo.

## 12. Estado final da Frente A

**Fundação/QA desta branch: verde nos testes executados.**

**Recuperação da árvore histórica/completa: bloqueada por ausência de uma cópia remota íntegra.**

A auditoria provou o bloqueio e removeu a ambiguidade. Não há base técnica para afirmar que a fonte completa já está restaurada no GitHub.
