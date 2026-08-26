import fs from 'node:fs';

const files=['dist/index.html','dist/oraculo.html'];

for(const file of files){
  let html=fs.readFileSync(file,'utf8');

  const legacyButton=`class="btn btn-primary \${isLive?'':'v11-checkout-disabled'}" \${isLive?'':'disabled'} onclick="completePayment()"`;
  const safeButton=`class="btn btn-primary" type="button" onclick="completePayment()"`;
  const legacyCount=html.split(legacyButton).length-1;
  if(legacyCount<2)throw new Error(`V12 checkout fix: markup legado do botão não encontrado em ${file}`);
  html=html.replaceAll(legacyButton,safeButton);

  const oldRuntime="var st=document.createElement('div');st.id='v12CheckoutStatus';st.className='v12-checkout-status';button.insertAdjacentElement('afterend',st);if(s.v12CheckoutPending){button.disabled=true;button.textContent='ABRINDO CHECKOUT SEGURO…';setStatus('Criando uma sessão protegida na Stripe.')}}";
  const newRuntime="var st=document.createElement('div');st.id='v12CheckoutStatus';st.className='v12-checkout-status';button.insertAdjacentElement('afterend',st);button.id='v12CheckoutButton';button.type='button';button.disabled=false;button.removeAttribute('disabled');button.classList.remove('v11-checkout-disabled');button.removeAttribute('onclick');button.addEventListener('click',startCheckout);if(s.v12CheckoutPending){button.disabled=true;button.textContent='ABRINDO CHECKOUT SEGURO…';setStatus('Criando uma sessão protegida na Stripe.')}else{button.disabled=false;button.textContent='IR PARA O PAGAMENTO SEGURO'}}";
  if(!html.includes(oldRuntime))throw new Error(`V12 checkout fix: runtime alvo não encontrado em ${file}`);
  html=html.replace(oldRuntime,newRuntime);

  const oldStart="var button=document.querySelector('button[onclick*=\"completePayment\"]');if(button){button.disabled=true;button.textContent='ABRINDO CHECKOUT SEGURO…'}";
  const newStart="var button=document.getElementById('v12CheckoutButton')||document.querySelector('button[onclick*=\"completePayment\"]');if(button){button.disabled=true;button.textContent='ABRINDO CHECKOUT SEGURO…'}";
  if(!html.includes(oldStart))throw new Error(`V12 checkout fix: seletor de início não encontrado em ${file}`);
  html=html.replace(oldStart,newStart);

  const oldError="var b=document.querySelector('button[onclick*=\"completePayment\"]');if(b){b.disabled=false;b.textContent='IR PARA O PAGAMENTO SEGURO'}";
  const newError="var b=document.getElementById('v12CheckoutButton')||document.querySelector('button[onclick*=\"completePayment\"]');if(b){b.disabled=false;b.textContent='IR PARA O PAGAMENTO SEGURO'}";
  if(!html.includes(oldError))throw new Error(`V12 checkout fix: seletor de recuperação não encontrado em ${file}`);
  html=html.replace(oldError,newError);

  html=html.replaceAll('Integração Stripe preparada','Checkout Stripe seguro');
  html=html.replaceAll('As quatro combinações deste plano já estão mapeadas para os preços reais. O botão só será habilitado quando existir um Payment Link real desta combinação.','O pagamento é criado de forma segura pela Stripe no domínio oficial da Societas Electorum. O valor é validado no servidor antes da abertura do checkout.');
  html=html.replaceAll('CHECKOUT AGUARDANDO LIBERAÇÃO DA STRIPE','IR PARA O PAGAMENTO SEGURO');

  if(html.includes(legacyButton))throw new Error(`V12 checkout fix: botão ainda depende do bloqueio legado em ${file}`);
  if(!html.includes("button.addEventListener('click',startCheckout)"))throw new Error(`V12 checkout fix: clique direto não foi ligado em ${file}`);
  if(!html.includes("button.classList.remove('v11-checkout-disabled')"))throw new Error(`V12 checkout fix: classe legada não é removida em ${file}`);
  if(html.includes('CHECKOUT AGUARDANDO LIBERAÇÃO DA STRIPE'))throw new Error(`V12 checkout fix: copy antiga permaneceu em ${file}`);

  fs.writeFileSync(file,html);
}

console.log('V12 checkout button rendered active and bound directly to secure checkout runtime');
