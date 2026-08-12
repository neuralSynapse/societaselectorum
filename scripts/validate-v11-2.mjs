import fs from 'node:fs';
import vm from 'node:vm';

const html=fs.readFileSync('dist/index.html','utf8');
const required=[
  'H93_OF_001_V11_2_STATE',
  'O que está impedindo o dinheiro de <span class="accent">entrar ou permanecer na sua vida?</span>',
  'INICIAR MINHA TIRAGEM',
  "function qthread(){return''}",
  "const CARDS=[...MAJORS,...MINORS];",
  'images/tarot-thoth-full/back-thoth-lamen.png',
  "quickCheckout('${x.id}','none')",
  "quickCheckout('${x.id}','pdf')",
  "quickCheckout('${x.id}','extra')",
  "quickCheckout('${x.id}','pdf_extra')",
  'v10-system-icon',
  'window.__H93_FRATER_PHOTO'
];
for(const token of required)if(!html.includes(token))throw new Error(`V11.2 sem marcador obrigatório: ${token}`);

const forbidden=[
  'JÁ TENHO UMA QUESTÃO ESPECÍFICA',
  '<textarea id="entryQuestion"',
  'ORGANIZAR MINHA PERGUNTA',
  'USAR ESTA PERGUNTA',
  'MANTER A MINHA',
  'const microBlock=microPromptHtml(state.step)',
  '${qthread(\'Esta escolha afina uma parte da sua pergunta\')}',
  '<div class="question-echo"><span>Sua pergunta</span>',
  '<div class="question-echo light"><span>Pergunta que orienta esta leitura</span>',
  '<label>Sua pergunta para a tiragem</label>',
  'problema que você escreveu',
  'microescolhas'
];
for(const token of forbidden)if(html.includes(token))throw new Error(`V11.2 contém elemento removido: ${token}`);

if(!/function next\(\)\{if\(state\.step===0&&!state\.entryQuestion\)\{startGuidedQuestion\(\);return\}if\(state\.step<STEPS\.length-1\)/.test(html))throw new Error('next ainda depende das microperguntas');
if(!/function activeQuestion\(\)\{return DEFAULT_ENTRY_QUESTION\}/.test(html))throw new Error('Pergunta central não ficou fixa');
if(!/\.flip-front img\{[^}]*object-fit:contain!important/i.test(html))throw new Error('Cartas podem voltar a ser cortadas');
if(!/const CARDS=\[\.\.\.MAJORS,\.\.\.MINORS\];/.test(html))throw new Error('Deck integral não está montado por Maiores + Menores');

const scripts=[...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)].map(x=>x[1]);
const runtime=scripts.find(x=>x.includes("const STATE_KEY='H93_OF_001_V11_2_STATE'"));
if(!runtime)throw new Error('Runtime V11.2 não encontrado');
new vm.Script(runtime,{filename:'H93-V11.2-runtime.js'});
console.log(`V11.2 validada: ${html.length} caracteres; entrada simplificada, microperguntas removidas e runtime compilando.`);
