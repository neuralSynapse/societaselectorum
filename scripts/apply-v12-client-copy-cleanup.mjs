import fs from 'node:fs';

const files=['dist/index.html','dist/oraculo.html'];

function clean(html){
  const replacements=[
    ['A tiragem começa por esta questão central e vai afinando a leitura a partir das escolhas principais que você fizer ao longo do percurso.','Escolha com sinceridade o que mais se aproxima da sua experiência financeira atual.'],
    ['O que você já tentou para mudar esse ponto da sua pergunta?','O que você já tentou para mudar essa situação?'],
    ['O que ainda faria esta leitura parecer insuficiente para a sua questão?','O que ainda falta para esta leitura ser realmente útil para você?'],
    ['Quanto aprofundamento a sua pergunta realmente pede?','Até onde você quer aprofundar esta leitura?'],
    ['Sua pergunta já deixou de ser abstrata.','O padrão começa a ganhar forma.'],
    ['Abra a carta para a questão que você realmente trouxe.','Escolha a carta que mais chama sua atenção.'],
    ['Qual posição chama você quando pensa nesta pergunta?','Em qual posição sua atenção pousa primeiro?'],
    [' foi aberta para a sua questão.',' ocupa o centro da sua leitura.'],
    [' agora precisa conversar com a sua pergunta.',' revela um ponto que merece atenção na sua vida financeira.'],
    ['O padrão mais provável precisa ser testado contra a sua pergunta.','O padrão dominante começa a aparecer.'],
    ["Uma pergunta sobre '+c.subject+' pede contexto, não palavra-chave.","Em '+c.subject+', o contexto muda o significado do que aparece."],
    ['Os relatos agora entram pelo mesmo filtro da sua pergunta.','Observe apenas o que nesses relatos realmente se aproxima da sua experiência.'],
    ['Sua pergunta passa por várias linguagens antes de virar interpretação.','O mesmo padrão pode aparecer em decisões, emoções e comportamento financeiro.'],
    ['Conecte seus dados à questão central da tiragem.','Complete seus dados para personalizar sua leitura.'],
    ['A síntese está sendo construída para a questão central da tiragem.','Seu padrão financeiro central começa a se revelar.'],
    ['Sua cartografia precisa responder ao problema identificado nas suas escolhas.','Aqui está o eixo central da sua Cartografia Financeira.'],
    ['Sua cartografia precisa responder ao problema que você escreveu.','Aqui está o eixo central da sua Cartografia Financeira.'],
    ['O primeiro teste precisa responder à sua pergunta no mundo real.','Leve esta leitura para uma ação concreta nas próximas 72 horas.'],
    ['Seu plano agora responde ao problema identificado nas suas escolhas no início.','Seu primeiro plano de ação começa pelo padrão que apareceu com mais força.'],
    ['Seu plano agora responde ao problema que você escreveu no início.','Seu primeiro plano de ação começa pelo padrão que apareceu com mais força.'],
    ['A prova social agora é filtrada pelo eixo da sua pergunta.','Compare histórias sem transformar a experiência de outra pessoa em promessa.'],
    ['A profundidade recomendada parte da sua pergunta e do percurso.','Escolha o nível de aprofundamento que faz sentido para o seu momento.'],
    ['Sua seleção preserva a pergunta que será levada ao atendimento.','O eixo central da sua consulta já está definido.'],
    ['A continuidade mantém o mesmo eixo da pergunta inicial.','A partir daqui, transforme percepção em mudança sustentada.'],
    ['O percurso vai observar exatamente onde <b>','Quando <b>'],
    ['</b>, em vez de empurrar sua questão para uma resposta genérica.</p><p>Suas próximas escolhas separam sintoma, reação emocional e mecanismo de repetição.</p><div class="article-quote">Objetivo desta análise: ','</b>, o dinheiro tende a perder força antes de virar margem, previsibilidade ou capacidade de escolha.</p><p>Observe a diferença entre uma reação pontual e um padrão que se repete.</p><div class="article-quote">Direção inicial: '],
    ["Pergunta, respostas, carta e escolhas principais estão sendo relacionados para localizar onde <b>'+esc(c.tension)+'</b> e qual movimento favorece <b>'+esc(c.build)+'</b>.","<b>Ponto crítico:</b> '+esc(c.tension)+'. <b>Direção:</b> '+esc(c.build)+'."],
    ["A recomendação considera sua pergunta, duração do ciclo, respostas, carta e profundidade escolhida. O objetivo é aprofundar <b>'+esc(c.subject)+'</b> sem perder o problema original.","Para <b>'+esc(c.subject)+'</b>, aprofundar significa transformar percepção em decisão, estrutura e acompanhamento."],
    ['A questão central já está definida. Agora os seus dados conectam a tiragem ao diagnóstico final.','Informe seus dados para personalizar sua leitura e calcular sua numerologia financeira.'],
    ['PROCESSAR MEU DIAGNÓSTICO','VER MEU DIAGNÓSTICO'],
    ['Dados registrados. Seu diagnóstico está sendo organizado.','Dados registrados. Continuando sua leitura.'],
    ['Somente para maiores de 18 anos. Nome e nascimento também compõem uma camada numerológica financeira simbólica da leitura.','Somente para maiores de 18 anos. Nome e nascimento são usados para calcular sua leitura numerológica financeira simbólica.'],
    ['Camada numerológica financeira integrada','Seu eixo numerológico financeiro'],
    [". Esta camada será cruzada com o Tarot e suas respostas, sem tratar numerologia como previsão financeira.</span>",". Em termos simbólicos, esse conjunto destaca '+String(n.financial_axis)+'. Use esta leitura como reflexão, não como previsão financeira.</span>"]
  ];

  for(const [from,to] of replacements)html=html.replaceAll(from,to);

  // Resíduos de copy de engenharia que podem sobreviver a versões anteriores.
  html=html.replaceAll('Esta escolha afina uma parte da sua pergunta','Escolha o que mais se aproxima da sua experiência');
  html=html.replaceAll('Questão que organiza esta etapa','Ponto central');
  html=html.replaceAll('Pergunta preservada nesta seleção','Eixo central');
  html=html.replaceAll('Pergunta de partida','Ponto de partida');
  html=html.replaceAll('problema identificado nas suas escolhas','padrão que apareceu com mais força');
  html=html.replaceAll('problema que você escreveu','padrão que apareceu com mais força');
  html=html.replaceAll('processamento final','leitura');
  html=html.replaceAll('o sistema organiza uma pergunta mais precisa para você aprovar ou manter como escreveu','você transforma a situação em uma pergunta mais clara antes da tiragem');
  html=html.replaceAll('O percurso cruza suas respostas e a tiragem para localizar o eixo principal sem exigir que você saiba formular o problema agora.','Escolha esta opção se você sente o padrão, mas ainda não consegue nomeá-lo com clareza.');

  return html;
}

for(const file of files){
  let html=fs.readFileSync(file,'utf8');
  html=clean(html);
  fs.writeFileSync(file,html);
}

console.log('H93 client-facing copy cleanup applied');
