import fs from 'node:fs';

const files=['dist/index.html','dist/oraculo.html'];

for(const file of files){
  let html=fs.readFileSync(file,'utf8');

  const oldRuntime="var st=document.createElement('div');st.id='v12CheckoutStatus';st.className='v12-checkout-status';button.insertAdjacentElement('afterend',st);if(s.v12CheckoutPending){button.disabled=true;button.textContent='ABRINDO CHECKOUT SEGURO…';setStatus('Criando uma sessão protegida na Stripe.')}}";
  const newRuntime="var st=document.createElement('div');st.id='v12CheckoutStatus';st.className='v12-checkout-status';button.insertAdjacentElement('afterend',st);if(s.v12CheckoutPending){button.disabled=true;button.textContent='ABRINDO CHECKOUT SEGURO…';setStatus('Criando uma sessão protegida na Stripe.')}else{button.disabled=false;button.textContent='IR PARA O PAGAMENTO SEGURO'}}";
  if(!html.includes(oldRuntime))throw new Error(`V12 checkout fix: runtime alvo não encontrado em ${file}`);
  html=html.replace(oldRuntime,newRuntime);

  html=html.replaceAll('Integração Stripe preparada','Checkout Stripe seguro');
  html=html.replaceAll('As quatro combinações deste plano já estão mapeadas para os preços reais. O botão só será habilitado quando existir um Payment Link real desta combinação.','O pagamento é criado de forma segura pela Stripe no domínio oficial da Societas Electorum. O valor é validado no servidor antes da abertura do checkout.');
  html=html.replaceAll('CHECKOUT AGUARDANDO LIBERAÇÃO DA STRIPE','IR PARA O PAGAMENTO SEGURO');

  if(!html.includes("else{button.disabled=false;button.textContent='IR PARA O PAGAMENTO SEGURO'}"))throw new Error(`V12 checkout fix: botão não foi habilitado em ${file}`);
  if(html.includes('CHECKOUT AGUARDANDO LIBERAÇÃO DA STRIPE'))throw new Error(`V12 checkout fix: copy antiga permaneceu em ${file}`);

  fs.writeFileSync(file,html);
}

console.log('V12 checkout button enabled and stale Stripe lock copy removed');
