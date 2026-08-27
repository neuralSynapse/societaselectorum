import fs from 'node:fs';

const html=fs.readFileSync('dist/oraculo.html','utf8');
const checks=[
  ["function combo(){return 'none'}",'combo must be none'],
  ["combo:'none',name:name,email:email",'checkout request must force none'],
  ["s.bumps=[];",'quick checkout must clear bumps'],
  ["badges.innerHTML='<span>HOTMART</span><span>PAGAMENTO SEGURO</span><span>MÉTODOS DISPONÍVEIS</span>'",'Hotmart badge'],
  ['Depois que a Hotmart confirmar o pagamento','Hotmart delivery copy'],
  ['Abrindo o checkout seguro da Hotmart.','Hotmart status copy']
];
for(const [needle,label] of checks)if(!html.includes(needle))throw new Error(`Smoke Hotmart basic falhou: ${label}`);
for(const forbidden of ["combo:combo(s),name:name,email:email","Checkout Stripe seguro","Criando uma sessão protegida na Stripe.","Checkout criado. Abrindo a Stripe…"])if(html.includes(forbidden))throw new Error(`Smoke Hotmart basic: trecho legado ainda ativo: ${forbidden}`);
console.log('Smoke H93 Hotmart basic OK: somente ofertas principais e combo none.');
