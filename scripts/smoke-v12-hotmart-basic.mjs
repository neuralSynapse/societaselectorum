import fs from 'node:fs';

const html=fs.readFileSync('dist/oraculo.html','utf8');
const checks=[
  ["function combo(s){var pdf=(s.bumps||[]).includes('pdf'),extra=(s.bumps||[]).includes('extra');return pdf&&extra?'pdf_extra':pdf?'pdf':extra?'extra':'none'}",'full combo logic'],
  ["combo:combo(s),name:name,email:email",'checkout request preserves combo'],
  ["s.bumps=c==='pdf_extra'?['pdf','extra']:c==='pdf'?['pdf']:c==='extra'?['extra']:[];",'quick checkout preserves bumps'],
  ["badges.innerHTML='<span>WIX</span><span>PAGAMENTO SEGURO</span><span>MÉTODOS DISPONÍVEIS</span>'",'Wix badge'],
  ['Depois que o Wix confirmar o pagamento','Wix delivery copy'],
  ['Preparando seu checkout seguro no Wix.','Wix status copy']
];
for(const [needle,label] of checks)if(!html.includes(needle))throw new Error(`Smoke Wix checkout falhou: ${label}`);
for(const forbidden of ["function combo(){return 'none'}","combo:'none',name:name,email:email","s.bumps=[];",'Depois que a Hotmart confirmar o pagamento','Abrindo o checkout seguro da Hotmart.','Checkout Stripe seguro'])if(html.includes(forbidden))throw new Error(`Smoke Wix checkout: trecho legado ainda ativo: ${forbidden}`);
console.log('Smoke H93 Wix checkout OK: planos, bumps e combos preservados.');
