# CHRONICA HĀRŪN · Bolso Ritual, Arcana e Pharmaka — Design

**Estado:** aprovado pelo fundador em 2026-09-12.

## Objetivo
Elevar a versão web de CHRONICA HĀRŪN para uma profundidade roguelite inspirada na variedade, descoberta, risco/recompensa e build emergente de Binding of Isaac, sem copiar nomes, sprites, layouts ou assets proprietários.

## Regra canônica crítica
Caim é personagem iniciático de CHRONICA HĀRŪN e não pode ser usado como inimigo genérico. Referências gnósticas a um homônimo/figura chamada Cain devem aparecer apenas no Livro Negro com contexto explícito e separado do Caim iniciador.

## Sistemas
1. **Bolso Ritual**: um único slot de consumível carregado. Arcana e Pharmaka disputam o mesmo slot. Coletar com slot ocupado oferece troca; usar consome o objeto.
2. **Arcana Thoth**: 78 cartas, nomes exibidos em PT-BR, cada uma com efeito individual de gameplay definido pelo catálogo canônico. A carta ativa aparece no HUD e pode ser consultada na coleção.
3. **Pharmaka Hermetica**: 21 fórmulas consumíveis. Cada uma tem princípio, planeta, benefício, efeito colateral e magnitude próprios. Na jornada, fórmulas podem começar não identificadas; após o primeiro uso, sua identidade fica conhecida na run.
4. **Coleção / descoberta**: memória da run e memória persistente separadas. O arquivo persistente mostra tudo já encontrado em partidas anteriores; itens nunca vistos permanecem ocultos.
5. **Arte**: o runtime usa um manifesto `id -> asset`. Quando houver arte autorizada do Tarot de Thoth, exibe a arte correspondente em proporção real de carta. Sem asset autorizado confirmado, usar verso/placeholder claramente marcado, nunca uma imitação apresentada como carta real.
6. **Português primeiro**: toda UI, nome e descrição de gameplay é PT-BR por padrão; inglês é idioma opcional.
7. **Livro Negro**: cada Arcana/Pharmakon descoberto recebe ficha com identidade tradicional/interpretativa separada do efeito autoral de gameplay.

## Fluxo
Drop/sala/recompensa -> pickup -> Bolso Ritual -> HUD -> uso -> efeito -> consumo -> descoberta/identificação -> Livro Negro/Coleção -> persistência.

## Anti-regressão
- O OLHO permanece percepção, nunca projétil.
- Combate, primeira pessoa, pulo, Kinesis, câmera e progressão atuais são preservados.
- Caim não entra em rosters inimigos.
- Catálogos em JSON não contam como funcionalidade até existir caminho real de runtime.
- Sem copiar assets de Binding of Isaac.
