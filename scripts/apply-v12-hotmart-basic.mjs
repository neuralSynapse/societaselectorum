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

  // Defesa final contra resíduos visuais de versões anteriores do checkout.
  html=html.replaceAll('<span>STRIPE</span>','<span>WIX</span>');
  html=html.replaceAll('O checkout está temporariamente indisponível enquanto o provedor conclui a ativação da conta. Nenhuma cobrança foi realizada.','O checkout Wix está ativo. Sua seleção permanece salva até a abertura do pagamento. A leitura só é liberada após a confirmação real do pagamento.');
  html=html.replaceAll('O checkout está temporariamente indisponível enquanto o provedor conclui a ativação da conta.','O checkout Wix está ativo e pronto para abrir o pagamento seguro.');

  must('var installed=false,observer=null;','var installed=false,observer=null,checkoutWindow=null;','checkout window state');
  must("s.v12CheckoutPending=true;s.v12CheckoutRequestId=uuid();save();decorate();", "checkoutWindow=window.open('about:blank','h93_wix_checkout');if(checkoutWindow){try{checkoutWindow.document.title='Pagamento seguro · Wix';checkoutWindow.document.body.innerHTML='<p style=\"font-family:system-ui;padding:24px\">Preparando seu checkout seguro…</p>'}catch(_){}}s.v12CheckoutPending=true;s.v12CheckoutRequestId=uuid();save();decorate();",'reserve checkout window');
  must("if(data.ok){setStatus('Checkout validado. Abrindo o Wix…');return}", "if(data.ok){var checkoutUrl=String(data.checkout_url||'');if(!checkoutUrl.startsWith('https://menussienterprises.wixsite.com/sociedade-dos-eleito/_paylink/')){s.v12CheckoutPending=false;s.v12CheckoutRequestId='';save();if(checkoutWindow&&!checkoutWindow.closed)checkoutWindow.close();setStatus('O Wix não retornou um checkout válido.','error');return}if(checkoutWindow&&!checkoutWindow.closed){checkoutWindow.location.replace(checkoutUrl);window.parent.postMessage({type:'H93_CHECKOUT_OPENED',requestId:s.v12CheckoutRequestId},PARENT_ORIGIN)}else{window.parent.postMessage({type:'H93_CHECKOUT_FALLBACK',requestId:s.v12CheckoutRequestId,url:checkoutUrl},PARENT_ORIGIN)}setStatus('Checkout Wix aberto. A confirmação da compra será acompanhada automaticamente.');return}",'open reserved checkout');

  if(html.includes('<span>STRIPE</span>'))throw new Error(`Wix checkout: selo STRIPE residual em ${path}`);
  if(html.includes('O checkout está temporariamente indisponível enquanto o provedor conclui a ativação da conta'))throw new Error(`Wix checkout: aviso de provedor inativo residual em ${path}`);
  if(!html.includes("checkoutUrl.startsWith('https://menussienterprises.wixsite.com/sociedade-dos-eleito/_paylink/')"))throw new Error(`Wix checkout: validação segura do Pay Link não aplicada em ${path}`);

  fs.writeFileSync(path,html);
}
console.log('H93 Wix checkout aplicado: matriz completa, bumps preservados, resíduos Stripe removidos e aba reservada antes da validação.');
