# CHRONICA HARUN · INICIÁTICO ROGUELITE v2

**Estado:** CANÔNICO PARA MUNDUS / CHRONICA HARUN
**Data:** 2026-09-10
**Autor real:** Frater Horus Phosphorus
**Base técnica:** `feat/chronica-combat-definitive-v1`

## 1. Regra-mãe

A CHRONICA HARUN permanece um FPS roguelite narrativo em primeira pessoa. Esta revisão não apaga o prólogo, a história de Harun, Caim, Lilith, Sophia, Yaldabaoth, Nadir, escolhas, powers, kinesis, salas, inimigos, bosses, sistema de câmera nem o catálogo roguelite já existente. Ela reconcilia progressão, apresentação e presença sistêmica do conteúdo.

Progressão de jogo não concede Grau institucional real. O jogo dramatiza a arquitetura iniciática; a progressão institucional permanece separada.

## 2. Progressão canônica

### ACTUS INGRESSUS · não é Grau

Etapa imediatamente anterior a ESTUDANTE. Possui três Claves/Pergaminhos do Umbral:

1. **Pergaminho I · Clavis I · O OLHO / Wedjat · Percepção**
2. **Pergaminho II · Clavis II · A CHAMA · Regência**
3. **Pergaminho III · Clavis III · A OBRA · Fundação**

O conteúdo narrativo já implementado para O Olho, A Chama e A Obra é preservado, apenas reclassificado de forma correta.

### ESTUDANTE · não é Grau

Possui doze Pergaminhos, preservando o arco já escrito, agora numerados IV–XV:

IV Autoeleição; V Autorresponsabilidade; VI Verdadeira Vontade; VII Caráter; VIII Disciplina; IX Clareza; X Transmutação; XI Corpo e Energia; XII Obra; XIII Fortuna; XIV Influência; XV Legado.

A Câmara de Iniciação torna-se o limiar entre ESTUDANTE e a progressão formal.

### GRAUS I–XXXIII

A progressão formal possui 33 Graus, distribuídos por Arbor Vitae, Arbor Mortis e Arbor Draconis. **Arbor Draconis permanece velada no menu e na Jornada até conclusão do Grau XXII.** Dados podem existir internamente, mas nomes, mapa e recompensas Draconis não são revelados antecipadamente.

Grau I preserva **Peregrinus Ignis** como estado/título iniciático e recebe o nome estrutural **INCEPTIO** no sistema de árvore.

**Arbor Vitae I–XI:** INCEPTIO, DISCIPLINA, PURIFICATIO, ORDO INTERIOR, DOMINIUM MENTIS, CORPUS ET VIS, OPUS PERSONALE, VOCATIO, CONSOLIDATIO, ARCHITECTURA VITAE, ADEPTUS VITAE.

**Arbor Mortis XII–XXII:** LIMEN UMBRAE, SPECULUM NIGRUM, VULNERA, METUS ET FAMES, POTESTAS OCCULTA, NOX INTERIOR, DESOLUTIO, MORS SYMBOLICA, TRANSFORMATIO, REINTEGRATIO, ADEPTUS MORTIS.

**Arbor Draconis XXIII–XXXIII, velada até XXII:** IGNITIO DRACONIS, VOLUNTAS IGNEA, FERRUM ET IGNIS, IMPERIUM INTERIUS, AURUM NIGRUM, CORPUS GLORIAE, ACTUS CREATOR, IMPERIUM EXTERIUS, ELIXIR, OPUS MAGNUM, ADEPTUS DRACONIS.

## 3. Os 33 Pergaminhos

O corpus de jogo utiliza 33 Pergaminhos. I–III pertencem ao ACTUS INGRESSUS; IV–XV pertencem ao ESTUDANTE; XVI–XXXIII aparecem como descobertas e integrações distribuídas ao longo dos 33 Graus, não um Pergaminho obrigatório em todo Grau.

Distribuição inicial de gameplay dos Pergaminhos XVI–XXXIII: Graus I, III, V, VII, IX, XI, XII, XIV, XVI, XVIII, XX, XXII, XXIII, XXV, XXVII, XXIX, XXXI e XXXIII. Essa distribuição cria respiração entre grandes revelações e permite que Graus sem Pergaminho tenham missões, personagens, bosses e transformação próprios.

## 4. Loop roguelite inspirado por princípios de Isaac, sem copiar conteúdo proprietário

Cada marco iniciático gera um andar/run com salas conectadas, combate, recompensa, ramificação, risco, segredo e boss. A inspiração é mecânica: legibilidade de salas, variedade de pickups, builds emergentes, salas secretas, itens ativos/passivos e sinergias. Arte, nomes, lore, UI e conteúdo permanecem Electorum.

Pools de run já existentes tornam-se plenamente visíveis e jogáveis:

- Tarot de Thoth: todo o catálogo presente em `tarot_thoth.json`, com slot de Arcano e efeitos próprios.
- Pharmaka: função análoga a consumíveis de efeito parcialmente desconhecido; efeito é descoberto ao uso e registrado.
- Instrumenta: itens ativos com cargas.
- Relíquias: passivos acumuláveis.
- Talismãs: equipamentos limitados.
- Sigilla, Daimones, Blessings, Curses, Transformations e Powers: preservados e integrados ao build.
- Salas especiais: Arcana, Reliquary, Instrumentarium, Laboratorium, Bibliotheca, Pactos, Theophany, Historical Echo, Sacrifice e demais entradas já catalogadas.
- Salas secretas: `secret` e `super_secret` passam a ter telegraph, recompensa e registro claros; super-secret recebe apresentação de Câmara Velada.

A geração deve ser determinística por seed para QA.

## 5. Jornada, personagens e história

Harun continua protagonista padrão. O roster já existente não fica confinado ao JSON. Caim, Lilith, Nadir, Seth, Sabaoth, Sophia, Thoth, Hórus, Belial, Paimon e a Forma Baphomética podem aparecer conforme o cânone como encontro, mentor, eco, teofania, aliado, rival, boss especial ou personagem desbloqueável. A aparição depende de marco e rota, não de rotação aleatória sem contexto.

O prólogo e o Story Bible continuam fonte narrativa. O sistema de 33 Graus adiciona capítulos jogáveis sem reescrever os eventos já aprovados.

## 6. Inimigos e bosses

Os 82 inimigos e 16 bosses já catalogados/modelados continuam sendo base. O objetivo visual não é apenas aumentar polígonos: cada família precisa de silhueta reconhecível, proporção própria, cabeça/coroa/membros/ornamentos distintos, materiais, emissivos, runas e leitura de ataque.

Famílias visuais do runtime: arcôntico cego; espectral/espelho; ígneo; pétreo/testemunha; escriba oco; serpentino; abissal; dracônico. Bosses recebem composição de múltiplas partes, aura/coroa e mudança visual por fase.

O comportamento mantém telegraph, dodge, janela de punição e dificuldade justa. Nenhum aumento de dificuldade baseado apenas em HP inflado.

## 7. UI e UX

### Escolhas narrativas

O modal não pode sobrepor texto. Prompt, opção, custo imediato e consequência são campos separados. O modal escurece o gameplay, pausa input de combate, suporta texto longo, teclado 1/2, mouse e controle. Em Web, restaura corretamente o pointer lock após a escolha.

### ESC

O menu de pausa deixa de ser placeholder. Deve oferecer:

Retomar; Jornada/Mapa; Build & Poderes; Tarot & Pharmaka; Codex; Personagens/Marcas; Controles; Configurações; Reiniciar Run; Voltar ao título.

O painel Jornada mostra ACTUS INGRESSUS, ESTUDANTE e Graus liberados. Arbor Draconis não aparece antes da condição canônica.

## 8. Anti-regressão

Não quebrar: câmera Web; câmera 1ª/3ª pessoa; colisões de corredor; projétil/VFX primário; progressão de salas; save; kinesis; powers/mutações; combate; narrativa; export Web; página da Societas.

Testes novos devem cobrir: estrutura 3 + 12 + 33; nome ACTUS INGRESSUS; 33 Graus e árvores; Draconis velada; corpus 33 Pergaminhos; escolha sem altura fixa de 54px; menu ESC; catálogo Tarot/Pharmaka; salas secretas/especiais; roster; variedade visual; export Web.

## 9. Critério de entrega

A entrega desta frente é considerada pronta apenas quando a suíte completa, validadores, Godot import, boot, captura visual, export Web e deploy passarem em execução fresca e o link público da Societas servir a build nova.