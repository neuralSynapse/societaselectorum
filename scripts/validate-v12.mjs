import fs from 'node:fs';
import vm from 'node:vm';

const html=fs.readFileSync('dist/oraculo.html','utf8');
const required=[
  '<title>Oráculo Financeiro de THOTH · Societas Electorum</title>',
  'id="h93-v12-runtime"',
  'window.__H93_GET_STATE=()=>state',
  "PARENT_ORIGIN='https://www.sociedadedoseleitos.com'",
  "type:'H93_CHECKOUT_REQUEST'",
  'consultation_id:s.consultation_id',
  'context_json:JSON.stringify(context(s))',
  'v12CheckoutConsent',
  'Entrega automática e privada.',
  'MÉTODOS DISPONÍVEIS',
  'window.quickCheckout=quick',
  'window.completePayment=startCheckout',
  "button.id='v12CheckoutButton'",
  "button.classList.remove('v11-checkout-disabled')",
  "button.removeAttribute('disabled')",
  "button.removeAttribute('onclick')",
  "button.addEventListener('click',startCheckout)",
  "document.getElementById('v12CheckoutButton')||document.querySelector('button[onclick*=\"completePayment\"]')",
  'leitura privada escrita e individual',
  'leitura privada aprofundada',
  'Ferramenta de Integração personalizada',
  'cdn.websitepublisher.ai/js/sapi-client.js',
  "form_name:'oraculo_financeiro_thoth'",
  "quickCheckout('${x.id}','none')",
  "quickCheckout('${x.id}','pdf')",
  "quickCheckout('${x.id}','extra')",
  "quickCheckout('${x.id}','pdf_extra')",
  'sete práticas guiadas escritas',
  'DISPONÍVEL NA ÁREA PRIVADA',
  'Nenhuma aquisição foi registrada nesta tela.'
];
for(const token of required)if(!html.includes(token))throw new Error(`V12 sem marcador obrigatório: ${token}`);
const forbidden=[
  'áudio ou vídeo objetivo',
  'áudio ou vídeo aprofundado',
  'Ferramenta Gravada de Integração personalizada',
  'O checkout Stripe está em ativação. Nenhuma cobrança foi realizada.',
  'Ainda não quero uma consulta conduzida por Frater Hórus L93',
  'Esta alternativa é mais simples e não substitui uma consulta conduzida por Frater Hórus L93.',
  'sete áudios de hipnose',
  'SEGUIR SEM OS ÁUDIOS',
  'a edição foi preparada na quinta-feira',
  'state.upsells.push(id)',
  'ciclos e tendências materiais',
  'quando aplicável, o agendamento',
  `class="btn btn-primary \${isLive?'':'v11-checkout-disabled'}" \${isLive?'':'disabled'} onclick="completePayment()"`,
  'CHECKOUT AGUARDANDO LIBERAÇÃO DA STRIPE'
];
for(const token of forbidden)if(html.includes(token))throw new Error(`V12 contém promessa ou fluxo legado: ${token}`);
const start=html.indexOf("window.parent.postMessage({type:'H93_CHECKOUT_REQUEST'");
if(start<0)throw new Error('V12 sem postMessage de checkout');
const end=html.indexOf('},PARENT_ORIGIN)',start);
if(end<0)throw new Error('V12 postMessage sem destino de origem explícito');
const request=html.slice(start,end);
if(/\bamount\b|\bprice(?:_id)?\b|unit_amount/i.test(request))throw new Error('V12 envia preço pelo navegador; servidor deve ser autoridade');
if(!request.includes('offer:id')||!request.includes('combo:combo(s)'))throw new Error('V12 não envia offer/combo esperados');
if(!/event\.origin!==PARENT_ORIGIN\|\|event\.source!==window\.parent/.test(html))throw new Error('V12 não valida origem/source das mensagens');
if(!/window\.parent===window/.test(html))throw new Error('V12 não bloqueia checkout direto fora do domínio oficial');
const scripts=[...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)].map(x=>x[1]).filter(Boolean);
for(let i=0;i<scripts.length;i++)new vm.Script(scripts[i],{filename:`H93-v12-inline-${i}.js`});
console.log(`V12 OK: ${html.length} caracteres; botão ativo com binding direto, checkout parent-bridged, preço server-side, consentimento, entrega privada e pós-compras legados neutralizados.`);
