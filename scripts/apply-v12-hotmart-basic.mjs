import fs from 'node:fs';

for (const path of ['dist/index.html','dist/oraculo.html']) {
  let html=fs.readFileSync(path,'utf8');
  const must=(from,to,label)=>{if(!html.includes(from))throw new Error(`Wix checkout: trecho não localizado (${label}) em ${path}`);html=html.replace(from,to)};

  if(!html.includes("function combo(s){var pdf=(s.bumps||[]).includes('pdf'),extra=(s.bumps||[]).includes('extra');return pdf&&extra?'pdf_extra':pdf?'pdf':extra?'extra':'none'}"))throw new Error(`Wix checkout: lógica completa de combo ausente em ${path}`);
  if(!html.includes("combo:combo(s),name:name,email:email"))throw new Error(`Wix checkout: checkout request não preserva combo em ${path}`);
  if(!html.includes("s.bumps=c==='pdf_extra'?['pdf','extra']:c==='pdf'?['pdf']:c==='extra'?['extra']:[];"))throw new Error(`Wix checkout: quick checkout não preserva bumps em ${path}`);

  html=html.replaceAll('Depois que a Stripe confirmar o pagamento','Depois que o Wix confirmar o pagamento');
  html=html.replaceAll("badges.innerHTML='<span>STRIPE</span><span>CARTÃO</span><span>MÉTODOS DISPONÍVEIS</span>'", "badges.innerHTML='<span>WIX</span><span>PAGAMENTO SEGURO</span><span>MÉTODOS DISPONÍVEIS</span>'");
  html=html.replaceAll('Criando uma sessão protegida na Stripe.','Preparando seu checkout seguro no Wix.');
  html=html.replaceAll('Checkout criado. Abrindo a Stripe…','Checkout validado. Abrindo o Wix…');
  html=html.replaceAll('Checkout Stripe seguro','Checkout Wix seguro');
  html=html.replaceAll('O pagamento é criado de forma segura pela Stripe no domínio oficial da Societas Electorum. O valor é validado no servidor antes da abertura do checkout.','O plano e os complementos escolhidos são validados antes da abertura do checkout seguro do Wix. A leitura só é liberada após a confirmação real do pagamento.');
  html=html.replaceAll('Stripe','Wix');

  fs.writeFileSync(path,html);
}
console.log('H93 Wix checkout aplicado: matriz completa de planos, bumps e combos preservada.');
