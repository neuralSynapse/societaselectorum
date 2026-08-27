import fs from 'node:fs';

for (const path of ['dist/index.html','dist/oraculo.html']) {
  let html=fs.readFileSync(path,'utf8');
  const must=(from,to,label)=>{if(!html.includes(from))throw new Error(`Hotmart basic: trecho não localizado (${label}) em ${path}`);html=html.replace(from,to)};

  must("function combo(s){var pdf=(s.bumps||[]).includes('pdf'),extra=(s.bumps||[]).includes('extra');return pdf&&extra?'pdf_extra':pdf?'pdf':extra?'extra':'none'}","function combo(){return 'none'}",'combo');
  must("function total(s){var p=s.product||{},n=Number(p.price||0);if((s.bumps||[]).includes('pdf'))n+=Number(p.pdf||0);if((s.bumps||[]).includes('extra'))n+=Number(p.extra||0);return n}","function total(s){return Number(s.product&&s.product.price||0)}",'total');
  must("if(typeof s.v12CheckoutRequestId!=='string')s.v12CheckoutRequestId='';save();return s}","if(typeof s.v12CheckoutRequestId!=='string')s.v12CheckoutRequestId='';var hadBumps=Array.isArray(s.bumps)&&s.bumps.length>0;if(hadBumps)s.bumps=[];save();if(hadBumps&&Number(s.step)===26)setTimeout(render,0);return s}",'state bumps');
  must("checkout.dataset.v12='1';var summary=", "checkout.dataset.v12='1';checkout.querySelectorAll('input[type=checkbox]').forEach(function(input){var holder=input.closest('label')||input.parentElement,t=String(holder&&holder.textContent||'').toLowerCase();if(t.includes('dossiê')||t.includes('pergunta extra'))holder.style.display='none'});var summary=",'hide bump controls');
  html=html.replaceAll("if((s.bumps||[]).includes('extra')){var ex=", "if(false){var ex=");
  html=html.replaceAll("if((s.bumps||[]).includes('extra')&&String(s.v12ExtraQuestion||'').trim().length<8)", "if(false&&String(s.v12ExtraQuestion||'').trim().length<8)");
  html=html.replaceAll("extra_confirmation_question:(s.bumps||[]).includes('extra')?String(s.v12ExtraQuestion||'').trim():'',", "extra_confirmation_question:'',");
  must("combo:combo(s),name:name,email:email", "combo:'none',name:name,email:email",'postMessage combo');
  must("s.bumps=c==='pdf_extra'?['pdf','extra']:c==='pdf'?['pdf']:c==='extra'?['extra']:[];", "s.bumps=[];",'quick checkout bumps');

  html=html.replaceAll('Depois que a Stripe confirmar o pagamento','Depois que a Hotmart confirmar o pagamento');
  html=html.replaceAll("badges.innerHTML='<span>STRIPE</span><span>CARTÃO</span><span>MÉTODOS DISPONÍVEIS</span>'", "badges.innerHTML='<span>HOTMART</span><span>PAGAMENTO SEGURO</span><span>MÉTODOS DISPONÍVEIS</span>'");
  html=html.replaceAll('Criando uma sessão protegida na Stripe.','Abrindo o checkout seguro da Hotmart.');
  html=html.replaceAll('Checkout criado. Abrindo a Stripe…','Checkout validado. Abrindo a Hotmart…');
  html=html.replaceAll('Checkout Stripe seguro','Checkout Hotmart seguro');
  html=html.replaceAll('O pagamento é criado de forma segura pela Stripe no domínio oficial da Societas Electorum. O valor é validado no servidor antes da abertura do checkout.','Você seguirá para o checkout seguro da Hotmart com o plano escolhido. Nesta fase, os complementos ficam de fora para manter uma única compra simples.');

  fs.writeFileSync(path,html);
}
console.log('H93 Hotmart basic aplicado: somente planos principais, combo none e sem bumps no checkout.');
