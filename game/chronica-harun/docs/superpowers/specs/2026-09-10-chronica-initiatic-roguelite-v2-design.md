# CHRONICA HARUN · INICIÁTICO ROGUELITE v2

**Estado:** CANÔNICO PARA MUNDUS / CHRONICA HARUN  
**Data:** 2026-09-10  
**Autor real:** Frater Horus Phosphorus  
**Base técnica:** `feat/chronica-combat-definitive-v1`

## 1. Regra-mãe

A CHRONICA HARUN permanece um FPS roguelite narrativo em primeira pessoa. Esta revisão não apaga o prólogo, a história de Harun, Caim, Lilith, Sophia, Yaldabaoth, Nadir, escolhas, powers, kinesis, salas, inimigos, bosses, câmera nem o catálogo roguelite já existente. Ela reconcilia progressão, apresentação e presença sistêmica do conteúdo.

A progressão digital dramatiza a arquitetura iniciática, mas **não concede Grau institucional real**.

## 2. Cadeia canônica de entrada

A cadeia governante, conforme decisão humana mais recente, é:

**Portal 0 · Aspirante — Initiatio Luciferi → Estudante → I · Peregrinus Ignis**

### Portal 0 · Aspirante — Initiatio Luciferi · não é Grau

Portal preparatório anterior ao Estudante. Recebe os três Pergaminhos/Claves iniciais:

1. **Pergaminho I · O OLHO / Wedjat · Percepção**
2. **Pergaminho II · A CHAMA · Regência**
3. **Pergaminho III · A OBRA · Fundação**

O conteúdo narrativo já implementado para O Olho, A Chama e A Obra é preservado. A nomenclatura provisória **ACTUS INGRESSUS** fica superada como nome governante.

### ESTUDANTE · não é Grau

Recebe doze Pergaminhos, preservando o arco já escrito, numerados IV–XV:

IV Autoeleição; V Autorresponsabilidade; VI Verdadeira Vontade; VII Caráter; VIII Disciplina; IX Clareza; X Transmutação; XI Corpo e Energia; XII Obra; XIII Fortuna; XIV Influência; XV Legado.

A Câmara de Iniciação é o limiar entre ESTUDANTE e a progressão formal.

## 3. Os 33 Graus

O primeiro Grau é **I · Peregrinus Ignis**. Os 33 Graus permanecem organizados em três Árvores. Arbor Draconis permanece velada no menu e na Jornada até a conclusão do Grau XXII.

### Arbor Vitae · I–XI

I · Peregrinus Ignis  
II · Oculus Hori  
III · Architectus  
IV · Favilla Draconis  
V · Sol Internus  
VI · Lamina Voluntatis  
VII · Architectus Potestatis  
VIII · Clavis Potestatis  
IX · Horus Invictus  
X · Aurora Lux Ferre  
XI · Vigil Arcani

### Arbor Mortis · XII–XXII

XII · Lilith  
XIII · Gamaliel  
XIV · Samael  
XV · A'arab Zaraq  
XVI · Thagirion  
XVII · Golachab  
XVIII · Gha'agsheblah  
XIX · Satariel  
XX · Ghagiel  
XXI · Thaumiel  
XXII · Adamas Ater

### Arbor Draconis · XXIII–XXXIII · velada até XXII

XXIII · Coniunctio Arborum  
XXIV · Axis Serpentis  
XXV · Athanor Vivus  
XXVI · Verbum Operans  
XXVII · Porta Mentis  
XXVIII · Imperium Vocis  
XXIX · Clavis Commercii  
XXX · Aurum Potestatis  
XXXI · Architectus Imperii  
XXXII · Custos Operis  
XXXIII · Ipsissimus

## 4. Os 33 Pergaminhos

O corpus de jogo utiliza 33 Pergaminhos. I–III pertencem ao Portal 0 · Aspirante — Initiatio Luciferi; IV–XV pertencem ao ESTUDANTE; XVI–XXXIII aparecem como descobertas e integrações distribuídas ao longo dos 33 Graus, sem obrigar um Pergaminho em todo Grau.

Distribuição inicial de gameplay dos Pergaminhos XVI–XXXIII: Graus I, III, V, VII, IX, XI, XII, XIV, XVI, XVIII, XX, XXII, XXIII, XXV, XXVII, XXIX, XXXI e XXXIII.

## 5. Loop roguelite inspirado por princípios de Isaac, sem copiar conteúdo proprietário

Cada marco iniciático gera um andar/run com salas conectadas, combate, recompensa, ramificação, risco, segredo e boss. A inspiração é mecânica: legibilidade de salas, variedade de pickups, builds emergentes, salas secretas, itens ativos/passivos, consumíveis desconhecidos, sinergias e bosses. Arte, nomes, lore, UI e conteúdo permanecem Electorum.

Pools de run já existentes devem se tornar plenamente visíveis e jogáveis:

- Tarot de Thoth: usar **todo o catálogo presente em `tarot_thoth.json`**. O corpus documental registra 78 cartas autorais; o runtime não deve truncar o deck para satisfazer uma contagem informal.
- Pharmaka: consumíveis de efeito inicialmente desconhecido; o efeito é descoberto ao uso e registrado.
- Instrumenta: itens ativos com cargas.
- Relíquias: passivos acumuláveis.
- Talismãs: equipamentos limitados.
- Sigilla, Daimones, Blessings, Curses, Transformations e Powers: preservados e integrados ao build.
- Salas especiais: Arcana, Reliquary, Instrumentarium, Laboratorium, Bibliotheca, Pactos, Theophany, Historical Echo, Sacrifice e demais entradas já catalogadas.
- Salas secretas: `secret` e `super_secret` com telegraph, recompensa e registro claros; super-secret recebe apresentação de Câmara Velada.

A geração deve ser determinística por seed para QA.

## 6. Jornada, personagens e história

Harun continua protagonista padrão. O roster já existente não fica confinado ao JSON. Caim, Lilith, Nadir, Seth, Sabaoth, Sophia, Thoth, Hórus, Belial, Paimon e a Forma Baphomética podem aparecer conforme o cânone como encontro, mentor, eco, teofania, aliado, rival, boss especial ou personagem desbloqueável. A aparição depende de marco e rota, não de rotação aleatória sem contexto.

O prólogo e o Story Bible continuam fonte narrativa. O sistema de 33 Graus adiciona capítulos jogáveis sem reescrever eventos já aprovados.

## 7. Inimigos e bosses

Os inimigos e bosses já catalogados/modelados continuam sendo base. Cada família precisa de silhueta reconhecível, proporção própria, cabeça/coroa/membros/ornamentos distintos, materiais, emissivos, runas e leitura clara de ataque.

Famílias visuais do runtime: arcôntico cego; espectral/espelho; ígneo; pétreo/testemunha; escriba oco; serpentino; abissal; dracônico. Bosses recebem composição de múltiplas partes, aura/coroa e mudança visual por fase.

A dificuldade deve vir de padrões, telegraphs, posicionamento, janela de punição e pressão, nunca apenas de HP inflado.

## 8. UI e UX

### Escolhas narrativas

O modal não pode sobrepor texto. Prompt, opção, custo imediato e consequência são campos separados. O modal escurece o gameplay, pausa input de combate, suporta texto longo, teclado 1/2/3, mouse e controle. Em Web, restaura corretamente o pointer lock após a escolha.

### ESC

O menu de pausa deixa de ser placeholder. Deve oferecer:

Retomar; Jornada/Mapa; Build & Poderes; Tarot & Pharmaka; Codex; Personagens/Marcas; Controles; Configurações; Reiniciar Run; Voltar ao título.

O painel Jornada mostra **Portal 0 · Aspirante — Initiatio Luciferi**, **Estudante** e Graus liberados. Arbor Draconis não aparece antes da condição canônica.

## 9. Anti-regressão

Não quebrar: câmera Web; câmera 1ª/3ª pessoa; colisões de corredor; projétil/VFX primário; progressão de salas; save; kinesis; powers/mutações; combate; narrativa; export Web; página da Societas.

Testes novos devem cobrir: Portal 0 + 3 Pergaminhos; Estudante + 12 Pergaminhos; 33 Graus; nomes públicos canônicos; Draconis velada; corpus 33 Pergaminhos; escolha sem sobreposição; menu ESC; catálogo Tarot/Pharmaka; salas secretas/especiais; roster; variedade visual; export Web.

## 10. Critério de entrega

A frente é considerada pronta apenas quando a suíte completa, validadores, Godot import, boot, captura visual, export Web e deploy passarem em execução fresca e o link público da Societas servir a build nova.
