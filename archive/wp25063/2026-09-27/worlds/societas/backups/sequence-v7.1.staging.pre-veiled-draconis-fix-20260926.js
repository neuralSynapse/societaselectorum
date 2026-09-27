export const SOCIETAS_SEQUENCE = Object.freeze([
  {
    id:'t0', code:'T0', title:'ANTES DA ARQUITETURA', duration:12,
    reveal:[], focus:null, camera:'void',
    narration:'Antes de qualquer mapa, há apenas a pergunta: o que é a SOCIETAS ELECTORUM, e como suas partes se relacionam sem serem confundidas?',
    caption:'O mundo começa vazio. Nenhuma geometria é tratada como cânone antes de sua manifestação.'
  },
  {
    id:'nucleus', code:'T1', title:'MANIFESTAÇÃO DO NÚCLEO', duration:18,
    reveal:['societas-electorum'], focus:'societas-electorum', camera:'nucleus',
    narration:'A SOCIETAS ELECTORUM manifesta-se primeiro como núcleo institucional. Biblioteca, Jornada, Pergaminho, Árvores, formação e evidência só adquirem sentido quando suas funções são distinguidas.',
    caption:'Núcleo institucional. Relações vêm depois da identidade.'
  },
  {
    id:'vitae-root', code:'T2A', title:'ARBOR VITAE · A RAIZ', duration:16,
    reveal:['arbor-vitae'], focus:'arbor-vitae', camera:'vitaeSeed', treeProgress:[0,.24],
    narration:'Antes de ensinar posições, a Árvore precisa existir. A Arbor Vitae surge primeiro como raiz e eixo vivo: uma estrutura de ascensão, relação e ordem, não um diagrama solto sobre a tela.',
    caption:'A forma nasce de baixo para cima. O território precede os rótulos.'
  },
  {
    id:'vitae-form', code:'T2B', title:'ARBOR VITAE · A FORMA', duration:18,
    reveal:['arbor-vitae'], focus:'arbor-vitae', camera:'vitaeForm', treeProgress:[.24,.46],
    narration:'O tronco se divide. Ramos laterais estabelecem os pilares e o eixo central. A geometria da Árvore da Vida começa a aparecer como uma arquitetura habitável.',
    caption:'Eixo central, pilares e ramificações emergem como um único organismo.'
  },
  {
    id:'vitae-sephirot', code:'T2C', title:'AS DEZ SEFIROT', duration:24,
    reveal:['arbor-vitae'], focus:'arbor-vitae', camera:'vitaeCrown', treeProgress:[.46,.72],
    narration:'As dez sefirot se manifestam em posições reconhecíveis da Árvore: Keter, Chokmah, Binah, Chesed, Gevurah, Tiferet, Netzach, Hod, Yesod e Malkuth. Cada esfera é um ponto de relação, não uma ilha.',
    caption:'De Keter a Malkuth, a estrutura deixa de ser abstrata e ganha lugares navegáveis.'
  },
  {
    id:'vitae-paths', code:'T2D', title:'OS CAMINHOS SE ACENDEM', duration:24,
    reveal:['arbor-vitae'], focus:'arbor-vitae', camera:'vitaePaths', treeProgress:[.72,.9],
    narration:'Quando os pontos existem, os caminhos podem surgir. As conexões se acendem entre as sefirot para mostrar que a Árvore é feita de relações, travessias e tensões organizadas.',
    caption:'Primeiro os lugares. Depois as relações. O caminho só aparece quando seus extremos existem.'
  },
  {
    id:'vitae-student', code:'T2E', title:'O ESTUDANTE DIANTE DA ÁRVORE', duration:22,
    reveal:['arbor-vitae'], focus:'arbor-vitae', camera:'vitaeStudent', treeProgress:[.9,1],
    narration:'O Estudante aparece abaixo de Malkuth, ainda no limiar. Ele pode contemplar toda a arquitetura, mas contemplar não é possuir Grau. A Árvore mostra o território que será aprendido, atravessado e demonstrado.',
    caption:'ESTUDANTE · limiar do percurso formal. Ver o mapa não equivale a ocupar seus Graus nem a ter atravessado suas Câmaras.'
  },
  {
    id:'trees', code:'T3A', title:'ARBORES GEMINAE E O VÉU', duration:24,
    reveal:['societas-electorum','arbor-vitae','arbor-draconis','arbor-electorum'], focus:null, camera:'trees', treeProgress:[1,1],
    narration:'Depois de compreender a Árvore da Vida como linguagem da potência ordenada, a arquitetura revela o método vigente: Camera Lucis sob Collegium Lucis e Camera Noctis sob Aurea Serpens são atravessadas dentro de cada Grau pertinente; Rectificatio reconcilia ambas antes do Transitus. A Tertia Arbor permanece velada. O que está velado não recebe conteúdo inventado.',
    caption:'CAMERA LUCIS + CAMERA NOCTIS → RECTIFICATIO. A Tertia Arbor permanece velada; não constitui terceira carreira revelada.'
  },
  {
    id:'systems', code:'T3B', title:'ORIENTAÇÃO E OPERAÇÃO', duration:22,
    reveal:['societas-electorum','arbor-vitae','arbor-draconis','arbor-electorum','biblioteca','jornada','pergaminho'], focus:null, camera:'systems',
    narration:'Biblioteca, Jornada e Pergaminho não são três nomes para a mesma coisa. Biblioteca é o acervo único. Jornada situa o percurso. Pergaminho é o núcleo operacional de leitura, prática, registro, integração e evidência.',
    caption:'Um acervo, uma orientação de percurso e um núcleo operacional distinto.'
  },
  {
    id:'student', code:'T4', title:'A ETAPA DO ESTUDANTE', duration:24,
    reveal:['societas-electorum','arbor-vitae','arbor-draconis','arbor-electorum','biblioteca','jornada','pergaminho','estudante'], focus:'estudante', camera:'student',
    narration:'Estudante é etapa preparatória, não Grau. Há um mínimo estrutural de noventa e nove dias, mas tempo isolado nunca promove ninguém. Competência, prática, registro e evidência governam a passagem.',
    caption:'99 dias mínimos. Progressão por competência e evidência, nunca por engajamento de interface.'
  },
  {
    id:'periods', code:'T5', title:'VER · GOVERNAR · FAZER', duration:28,
    reveal:['societas-electorum','arbor-vitae','arbor-draconis','arbor-electorum','biblioteca','jornada','pergaminho','estudante','periodo-1','periodo-2','periodo-3','clavis-1','clavis-2','clavis-3'], focus:null, camera:'periods',
    narration:'Três Períodos de trinta e três dias organizam a etapa. Clavis I, O Olho, serve a VER. Clavis II, A Chama, serve a GOVERNAR. Clavis III, A Obra, serve a FAZER. As Claves atravessam os Períodos sem substituí-los.',
    caption:'Período I · REGÊNCIA ↔ O OLHO. Período II · DISCERNIMENTO ↔ A CHAMA. Período III · OBRA ↔ A OBRA.'
  },
  {
    id:'cycles', code:'T6', title:'NOVE CICLOS XI', duration:32,
    reveal:['societas-electorum','arbor-vitae','arbor-draconis','arbor-electorum','biblioteca','jornada','pergaminho','estudante','periodo-1','periodo-2','periodo-3','clavis-1','clavis-2','clavis-3','xi-1','xi-2','xi-3','xi-4','xi-5','xi-6','xi-7','xi-8','xi-9'], focus:null, camera:'cycles',
    narration:'Os três Períodos contêm nove Ciclos XI de onze dias. O percurso avança de autogoverno e método para discernimento crítico e, por fim, síntese, autoria e Obra.',
    caption:'XI·1–XI·3 · Regência. XI·4–XI·6 · Discernimento. XI·7–XI·9 · Obra.'
  },
  {
    id:'evidence', code:'T7', title:'OBRAS E PROVAÇÃO', duration:28,
    reveal:['societas-electorum','arbor-vitae','arbor-draconis','arbor-electorum','biblioteca','jornada','pergaminho','estudante','periodo-1','periodo-2','periodo-3','clavis-1','clavis-2','clavis-3','xi-1','xi-2','xi-3','xi-4','xi-5','xi-6','xi-7','xi-8','xi-9','lm-001','na-001','an-001','exame-peregrinus'], focus:'exame-peregrinus', camera:'evidence',
    narration:'O percurso não termina quando o conteúdo foi visto. Obras transversais, autoria, defesa e exame de passagem exigem evidência. Recuperação, discriminação, transferência e Obra formam o eixo de verificação.',
    caption:'VER NÃO É CONCLUIR. NAVEGAR NÃO É INCORPORAR. ENTENDER NÃO É AINDA DEMONSTRAR.'
  },
  {
    id:'degree1', code:'T8', title:'PEREGRINUS IGNIS', duration:22,
    reveal:['societas-electorum','arbor-vitae','arbor-draconis','arbor-electorum','biblioteca','jornada','pergaminho','estudante','periodo-1','periodo-2','periodo-3','clavis-1','clavis-2','clavis-3','xi-1','xi-2','xi-3','xi-4','xi-5','xi-6','xi-7','xi-8','xi-9','lm-001','na-001','an-001','exame-peregrinus','peregrinus-ignis'], focus:'peregrinus-ignis', camera:'degree',
    narration:'Peregrinus Ignis é o Grau I. A passagem reconhece competência demonstrada e decisão documentada. XP, streak, clique, compra, tempo de tela e mero decurso temporal não concedem Grau.',
    caption:'Grau I. Passagem humana e documentada após competência verificável.'
  },
  {
    id:'major-scrolls', code:'T9', title:'OS DOZE PERGAMINHOS MAIORES', duration:34,
    reveal:['societas-electorum','arbor-vitae','arbor-draconis','arbor-electorum','biblioteca','jornada','pergaminho','estudante','periodo-1','periodo-2','periodo-3','clavis-1','clavis-2','clavis-3','xi-1','xi-2','xi-3','xi-4','xi-5','xi-6','xi-7','xi-8','xi-9','lm-001','na-001','an-001','exame-peregrinus','peregrinus-ignis','pergaminho-1','pergaminho-2','pergaminho-3','pergaminho-4','pergaminho-5','pergaminho-6','pergaminho-7','pergaminho-8','pergaminho-9','pergaminho-10','pergaminho-11','pergaminho-12'], focus:'peregrinus-ignis', camera:'scrolls',
    narration:'No Grau I, doze Pergaminhos Maiores formam uma nova órbita de trabalho: Autoeleição, Autorresponsabilidade, Verdadeira Vontade, Caráter, Disciplina, Clareza, Transmutação, Corpo e Energia, Obra, Fortuna, Influência e Legado.',
    caption:'Doze Pergaminhos Maiores pertencem ao Peregrinus Ignis, não à Etapa do Estudante.'
  },
  {
    id:'integration', code:'T10', title:'ARQUITETURA INTEGRADA', duration:36,
    reveal:'all', focus:'societas-electorum', camera:'integration',
    narration:'A arquitetura agora pode ser observada como um todo. O MUNDUS não transforma doutrina em decoração. Ele torna relações habitáveis para que o estudante possa reconstruí-las, interrogá-las, praticá-las e demonstrar compreensão fora da interface.',
    caption:'Praxis → Registro → Integração → Verificação → Continuidade.'
  }
]);

export function sequenceVisibleIds(index, manifest){
  const phase=SOCIETAS_SEQUENCE[Math.max(0,Math.min(SOCIETAS_SEQUENCE.length-1,index))];
  if(phase.reveal==='all') return manifest.nodes.filter(n=>!n.hiddenByDefault).map(n=>n.id);
  return [...phase.reveal];
}

export default SOCIETAS_SEQUENCE;
