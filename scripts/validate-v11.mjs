import fs from 'node:fs';
import vm from 'node:vm';

const html=fs.readFileSync('dist/index.html','utf8');
const required=[
  'H93_OF_001_V11_STATE',
  'O que está impedindo o dinheiro de <span class="accent">entrar ou permanecer na sua vida?</span>',
  'Já tenho uma questão específica',
  'Formulação sugerida para aprofundar a leitura',
  "const CARDS=[...MAJORS,...MINORS];",
  '78 CARTAS · 22 ATUS · 56 ARCANOS MENORES',
  'images/tarot-thoth-full/back-thoth-lamen.png',
  'const microBlock=microPromptHtml(state.step)',
  "quickCheckout('${x.id}','none')",
  "quickCheckout('${x.id}','pdf')",
  "quickCheckout('${x.id}','extra')",
  "quickCheckout('${x.id}','pdf_extra')",
  'CHECKOUT AGUARDANDO LIBERAÇÃO DA STRIPE',
  'v11-checkout-disabled',
  'v10-system-icon',
  'depoimento-02-meta-300-mil.png',
  'depoimento-03-abertura-possibilidades.png',
  'depoimento-04-orientacoes.png',
  'depoimento-05-captacao-comissoes.png',
  'window.__H93_FRATER_PHOTO'
];
for(const token of required)if(!html.includes(token))throw new Error(`V11 sem marcador obrigatório: ${token}`);
const forbidden=[
  'Verso THOTH da simulação',
  'O valor desta leitura está no cruzamento',
  'Pessoas que chegaram com dores semelhantes',
  "alert('O checkout Stripe está em ativação"
];
for(const token of forbidden)if(html.includes(token))throw new Error(`V11 contém regressão proibida: ${token}`);
if(!/\.flip-front img\{[^}]*object-fit:contain!important/i.test(html))throw new Error('Carta fechada/revelada ainda pode ser cortada');
if(!/\.authority-photo img\{[^}]*object-fit:cover/i.test(html))throw new Error('Foto de autoridade perdeu o enquadramento próprio');
const scripts=[...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)].map(x=>x[1]);
const runtime=scripts.find(x=>x.includes("const STATE_KEY='H93_OF_001_V11_STATE'"));
if(!runtime)throw new Error('Runtime V11 não encontrado');
new vm.Script(runtime,{filename:'H93-V11-runtime.js'});
console.log(`V11 validada: ${html.length} caracteres; runtime compila, deck integral, UX, contraste e checkout matricial presentes.`);
