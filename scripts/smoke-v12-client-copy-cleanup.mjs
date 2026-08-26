import fs from 'node:fs';

const files=['dist/index.html','dist/oraculo.html'];
const forbidden=[
  'precisa responder ao problema',
  'problema identificado nas suas escolhas',
  'está sendo construída para',
  'é filtrada pelo eixo',
  'será levada ao atendimento',
  'preserva a pergunta',
  'questão que organiza esta etapa',
  'esta escolha afina',
  'o percurso vai observar',
  'objetivo desta análise',
  'estão sendo relacionados para localizar',
  'a recomendação considera',
  'será cruzada com o tarot',
  'camada numerológica financeira integrada',
  'o sistema organiza uma pergunta',
  'percurso cruza suas respostas',
  'passa por várias linguagens antes de virar interpretação',
  'processamento final',
  'entram pelo mesmo filtro da sua pergunta',
  'profundidade recomendada parte da sua pergunta',
  'precisa ser testado contra a sua pergunta',
  'precisa conversar com a sua pergunta'
];

const required=[
  'Aqui está o eixo central da sua Cartografia Financeira.',
  'Seu eixo numerológico financeiro',
  'Escolha com sinceridade o que mais se aproxima da sua experiência financeira atual.',
  'Leve esta leitura para uma ação concreta nas próximas 72 horas.',
  'VER MEU DIAGNÓSTICO'
];

for(const file of files){
  const html=fs.readFileSync(file,'utf8');
  const lower=html.toLowerCase();
  for(const phrase of forbidden){
    if(lower.includes(phrase.toLowerCase()))throw new Error(`${file}: linguagem interna exposta: ${phrase}`);
  }
  for(const phrase of required){
    if(!html.includes(phrase))throw new Error(`${file}: copy pública esperada ausente: ${phrase}`);
  }
}

console.log('H93 client-copy smoke OK: nenhuma linguagem interna bloqueada ficou exposta');
