# CHRONICA HARUN · COMBAT DEFINITIVE V1 — DESIGN APROVADO

**Data:** 2026-09-09  
**Referência visual aprovada:** composição em primeira pessoa gerada nesta sessão, com Harun em combate contra ARCONTE CEGO e SENTINELA ABISSAL.  
**Estado:** APROVADO pelo usuário. Esta especificação é o alvo visual e funcional, não uma sugestão.

## Direção visual bloqueada

A experiência deve reproduzir a composição aprovada o mais fielmente possível usando o runtime e os assets reais do projeto: primeira pessoa com mãos/poderes legíveis; arquitetura gótica/ocultista de alto contraste; metais escuros, ouro queimado, vermelho ritual e violeta; iluminação volumétrica dramática; partículas, emissivos e impactos fortes sem destruir a leitura da luta.

Os formatos/modelos previamente aprovados de personagens, inimigos e chefes são preservados. O acabamento deve elevar esses modelos, não substituí-los por formas genéricas.

## Composição de HUD

1. **Topo central:** narração curta, centralizada na faixa superior, sem ocupar o centro de mira. Duas ou três linhas no máximo, com placa translúcida e moldura discreta.
2. **Chefe:** nome, nível, vida e fase no topo central, abaixo da narração. A barra deve ser dominante e vermelha.
3. **Inimigos comuns e elites:** nome, nível e barra de vida projetados sobre cada inimigo relevante. Elites recebem leitura visual mais forte.
4. **Harun:** painel inferior esquerdo com nome HARUN, nível, vida numérica + barra vermelha, Foco/Volição numérico + barra violeta, Essência e feedback de ganhos.
5. **Poderes:** slots inferiores direitos, visual de losangos/placas rituais, com nome abreviado, tecla/controle e cooldown/estado de disponibilidade.
6. **Aquisição:** cartão inferior central `PODER ADQUIRIDO` com nome e descrição curta, aparecendo imediatamente após uma aquisição real.
7. **Feed de ganhos:** esquerda da tela, acima do painel do jogador, para Essência, fragmentos e recompensas.
8. **Mira:** pequena, dourada e discreta.

## Harun e progressão durante a luta

Harun começa com ferramentas básicas já existentes no projeto e pode adquirir poderes/mutações durante a run. Aquisições devem entrar imediatamente na build e refletir no HUD. Recompensas importantes oferecem escolha significativa, preferencialmente três opções quando o catálogo permitir.

Poderes adquiridos devem possuir feedback de VFX/SFX e cartão de aquisição. Mutação não pode existir apenas em dados invisíveis.

## Combate

A dificuldade deve vir de leitura, timing e pressão, não de inflar HP. O combate definitivo inclui:

- dodge com custo, cooldown e janela curta de invulnerabilidade;
- suporte a perfect dodge e integração com `PowerMutationRuntime.on_dodge`;
- telegraphs legíveis dos inimigos;
- ataques por família já existentes preservados;
- elites mais agressivas e identificáveis;
- chefes com múltiplas fases e padrão visual de fase;
- feedback audiovisual para dano, windup, ataque, dodge, fase e morte;
- hit feedback forte sem câmera caótica.

## Regras de anti-regressão

- Não reescrever cânone narrativo.
- Não remover câmera em primeira pessoa nem o toggle já existente.
- Não remover famílias/ataques diferenciados existentes.
- Não quebrar sistemas roguelite, kinesis, especiais, save/load, áudio/VFX e Windows release.
- Não substituir modelos aprovados por placeholders quando `model_path` válido existir.
- A UI deve ser responsiva por anchors e containers, evitando depender apenas de offsets fixos de 1920×1080.
- Nada de mock visual desconectado do runtime: toda barra deve refletir estado real e toda aquisição deve refletir build real.

## Critério de aceite visual

Ao entrar em combate, uma captura do runtime deve comunicar a mesma hierarquia da referência aprovada: Harun em primeira pessoa; ameaça principal central; nomes e vidas legíveis; narração no alto; jogador inferior esquerdo; poderes inferior direito; aquisição inferior central; vermelho/violeta/ouro como linguagem de combate; ambiente escuro e cinematográfico com leitura preservada.