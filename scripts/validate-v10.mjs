import fs from 'node:fs';

const html=fs.readFileSync('dist/index.html','utf8');
const checkout=JSON.parse(fs.readFileSync('config/checkout.json','utf8'));

const mustContain=[
  'H93_OF_001_V10_2_STATE',
  'O que está impedindo o dinheiro de <span class="accent">entrar ou permanecer na sua vida?</span>',
  'JÁ TENHO UMA QUESTÃO ESPECÍFICA','ORGANIZAR MINHA PERGUNTA','Pergunta sugerida para a tiragem',
  'function startGuidedQuestion','function startCustomQuestion','function refineEntryQuestion','function acceptEntryQuestion',
  'Pergunta que orienta esta tiragem','Pergunta que organizou esta leitura','Pergunta da tiragem',
  'favicon-flame-v4.svg',
  'THOTH_BASE',
  'o-louco.jpg','o-eremita.jpg','o-mago.jpg','dois-de-copas.jpg','cinco-de-bastoes.jpg','tres-de-espadas.jpg',
  'frater-photo-small-01.js','frater-photo-small-02.js','frater-photo-small-03.js','frater-photo-small-04.js','__H93_FRATER_PHOTO',
  'MICRO_PROMPTS','function chooseMicro','micro-gain','v10-system-icon',
  'depoimento-02-meta-300-mil.png','depoimento-03-abertura-possibilidades.png','depoimento-04-orientacoes.png','depoimento-05-captacao-comissoes.png',
  'function proofIntro','function proofIds','function checkoutVariant','checkout-status',
  'Você marcou <b>','sua leitura está pedindo agora',
  'Sua leitura está sendo organizada'
];
for(const token of mustContain){if(!html.includes(token))throw new Error(`V10.2 sem marcador obrigatório: ${token}`)}

const forbidden=[
  'Pessoas que chegaram com dores semelhantes',
  'O valor desta leitura está no cruzamento',
  "alert('O checkout Stripe está em ativação",
  'hotmart.com',
  'CARDS.forEach(c=>c.img=cardSvg(c))'
];
for(const token of forbidden){if(html.toLowerCase().includes(token.toLowerCase()))throw new Error(`Regressão V10.2: ${token}`)}

const cases=[...html.matchAll(/case\s+(\d+)\s*:/g)].map(m=>Number(m[1]));
if(cases.length<28||Math.min(...cases)!==0||Math.max(...cases)!==27)throw new Error(`Fluxo inválido: ${cases.length} cases, faixa ${Math.min(...cases)}..${Math.max(...cases)}`);

const expected={
  essential:'price_1U2MJK2aHZ9yiNGq8qWD2nC8',
  deep:'price_1U2MJQ2aHZ9yiNGqKFQxHnFY',
  complete:'price_1U2MJW2aHZ9yiNGquVnBSuRd',
  horusai:'price_1U2MJe2aHZ9yiNGqIG82EJcZ'
};
for(const [id,price] of Object.entries(expected)){if(checkout.offers?.[id]?.price_id!==price)throw new Error(`Price divergente: ${id}`)}
if(checkout.provider!=='stripe'||checkout.mode!=='live')throw new Error('Configuração não está em Stripe live');
for(const id of ['essential','deep','complete']){
  const variants=checkout.payment_links?.[id];
  for(const v of ['none','pdf','extra','pdf_extra'])if(typeof variants?.[v]!=='string')throw new Error(`payment_links.${id}.${v} ausente`);
}
if(typeof checkout.payment_links?.horusai?.none!=='string')throw new Error('payment_links.horusai.none ausente');

console.log(`V10.2 validada: ${html.length} caracteres; abertura híbrida, pergunta personalizada, cartas THOTH, foto, microganhos, prova social e checkout preparados.`);
