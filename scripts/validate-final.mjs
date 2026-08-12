import fs from 'node:fs';
import vm from 'node:vm';

const html=fs.readFileSync('dist/index.html','utf8');
const required=[
  '<title>Oráculo Financeiro de THOTH · Societas Electorum</title>',
  'SOCIETAS ELECTORUM',
  'Societas Electorum',
  'O que está impedindo o dinheiro de <span class="accent">entrar ou permanecer na sua vida?</span>',
  'INICIAR MINHA TIRAGEM',
  "const CARDS=[...MAJORS,...MINORS];",
  'tarot-thoth-full/',
  'v10-system-icon',
  'window.__H93_FRATER_PHOTO',
  "quickCheckout('${x.id}','none')",
  "quickCheckout('${x.id}','pdf')",
  "quickCheckout('${x.id}','extra')",
  "quickCheckout('${x.id}','pdf_extra')",
  'depoimento-02-meta-300-mil.png',
  'depoimento-03-abertura-possibilidades.png',
  'depoimento-04-orientacoes.png',
  'depoimento-05-captacao-comissoes.png',
  'cdn.websitepublisher.ai/js/sapi-client.js',
  "window.WP.sapi(25063)",
  "form_name:'oraculo_financeiro_thoth'",
  'id="leadConsent"',
  'id="leadStatus"',
  'id="leadSubmit"'
];
for(const token of required)if(!html.includes(token))throw new Error(`Final sem marcador obrigatório: ${token}`);
const forbidden=[
  'Sociedade dos Eleitos',
  'SOCIEDADE DOS ELEITOS',
  'V8 Consolidado',
  '<title>Oráculo Financeiro de THOTH — V10</title>',
  '<title>Oráculo Financeiro de THOTH · V11.2</title>',
  'JÁ TENHO UMA QUESTÃO ESPECÍFICA',
  '<textarea id="entryQuestion"',
  'ORGANIZAR MINHA PERGUNTA',
  'const microBlock=microPromptHtml(state.step)',
  'Pessoas que chegaram com dores semelhantes'
];
for(const token of forbidden)if(html.includes(token))throw new Error(`Final contém regressão pública: ${token}`);
if(!/\.flip-front img\{[^}]*object-fit:contain!important/i.test(html))throw new Error('Carta pode ser recortada');
if(!/async function saveLead\(\)/.test(html))throw new Error('saveLead final não é assíncrono');
const scripts=[...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)].map(x=>x[1]);
const runtime=scripts.find(x=>x.includes("H93_OF_001_V11_2_STATE"));
if(!runtime)throw new Error('Runtime final não localizado');
new vm.Script(runtime,{filename:'H93-final-runtime.js'});
console.log(`Final OK: ${html.length} caracteres; identidade, UX, THOTH, autoridade, provas, ofertas e captura real de lead preservados.`);
