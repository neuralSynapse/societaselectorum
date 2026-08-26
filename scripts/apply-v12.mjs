import fs from 'node:fs';

let html=fs.readFileSync('dist/oraculo.html','utf8');

const expose='window.saveLead=saveLead;';
if(!html.includes(expose))throw new Error('V12: export saveLead não localizado');
html=html.replace(expose,expose+"window.__H93_GET_STATE=()=>state;window.__H93_SAVE_STATE=()=>save();window.__H93_RENDER=()=>render();");

const copyReplacements=[
  ['áudio ou vídeo objetivo','leitura privada escrita e individual'],
  ['áudio ou vídeo aprofundado','leitura privada aprofundada'],
  ['Ferramenta Gravada de Integração personalizada','Ferramenta de Integração personalizada'],
  ['Ainda não quero uma consulta conduzida por Frater Hórus L93','Ainda não quero aprofundar minha leitura agora'],
  ['Esta alternativa é mais simples e não substitui uma consulta conduzida por Frater Hórus L93.','Esta alternativa é mais simples e não substitui os formatos completos de aprofundamento.'],
  ['O checkout Stripe está em ativação. Nenhuma cobrança foi realizada.','O checkout seguro é criado pelo domínio oficial da Societas Electorum.']
];
for(const [from,to] of copyReplacements)html=html.replaceAll(from,to);

const css=`
/* H93 V12 · secure checkout bridge */
.v12-paid-context{margin:18px 0;padding:16px;border:1px solid rgba(214,177,90,.2);border-radius:14px;background:rgba(214,177,90,.045)}
.v12-paid-context b{color:#f8efd9}.v12-paid-context p{margin:6px 0 0;color:#b9afc4;line-height:1.55}
.v12-paid-questions{display:grid;gap:12px;margin:18px 0}.v12-paid-question{display:grid;gap:7px}.v12-paid-question label{font-size:12px;letter-spacing:.05em;color:#d6b15a}.v12-paid-question textarea{width:100%;min-height:92px;resize:vertical;box-sizing:border-box;border:1px solid rgba(214,177,90,.25);border-radius:12px;padding:13px;background:#09060d;color:#f8efd9;font:inherit;line-height:1.5}.v12-paid-question textarea:focus{outline:2px solid rgba(128,86,199,.34);border-color:#d6b15a}
.v12-checkout-consent{display:flex;gap:10px;align-items:flex-start;margin:18px 0;padding:14px;border:1px solid rgba(214,177,90,.2);border-radius:12px;color:#cfc4d2;font-size:13px;line-height:1.5}.v12-checkout-consent input{margin-top:3px;accent-color:#d6b15a}
.v12-delivery-note{margin:14px 0;padding:13px 14px;border-left:2px solid #8056c7;background:rgba(128,86,199,.07);color:#cfc4d2;font-size:13px;line-height:1.55}.v12-checkout-status{min-height:18px;margin-top:10px;color:#b9afc4;font-size:12px;text-align:center}.v12-checkout-status.error{color:#f1a2a2}.btn[disabled]{opacity:.56;cursor:not-allowed;transform:none!important}
@media(max-width:680px){.v12-paid-question textarea{min-height:82px}.v12-checkout-consent{font-size:12px}}
`;
html=html.replace('</style>',css+'</style>');

const runtime=`<script id="h93-v12-runtime">
(function(){
'use strict';
var PARENT_ORIGIN='https://www.sociedadedoseleitos.com';
var DEFAULT_Q='O que está impedindo o dinheiro de entrar ou permanecer na sua vida?';
var PRODUCTS={
 essential:{id:'essential',name:'Leitura Financeira Essencial',price:47,pdf:9.97,extra:17},
 deep:{id:'deep',name:'Leitura Financeira Profunda',price:97,pdf:14.97,extra:27},
 complete:{id:'complete',name:'Consulta Financeira Completa',price:147,pdf:17,extra:37},
 horusai:{id:'horusai',name:'Consulta Inicial com Hórus IA',price:17,pdf:0,extra:0}
};
var installed=false,observer=null;
function uuid(){if(globalThis.crypto&&typeof globalThis.crypto.randomUUID==='function')return globalThis.crypto.randomUUID();var b=new Uint8Array(16);if(globalThis.crypto&&globalThis.crypto.getRandomValues)globalThis.crypto.getRandomValues(b);else for(var i=0;i<16;i++)b[i]=Math.floor(Math.random()*256);b[6]=(b[6]&15)|64;b[8]=(b[8]&63)|128;var h=Array.from(b,function(x){return x.toString(16).padStart(2,'0')}).join('');return h.slice(0,8)+'-'+h.slice(8,12)+'-'+h.slice(12,16)+'-'+h.slice(16,20)+'-'+h.slice(20)}
function state(){return window.__H93_GET_STATE&&window.__H93_GET_STATE()}
function save(){if(window.__H93_SAVE_STATE)window.__H93_SAVE_STATE()}
function render(){if(window.__H93_RENDER)window.__H93_RENDER()}
function ensure(){var s=state();if(!s)return null;if(!/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(String(s.consultation_id||'')))s.consultation_id=uuid();if(!Array.isArray(s.v12Questions))s.v12Questions=[];if(typeof s.v12ExtraQuestion!=='string')s.v12ExtraQuestion='';if(typeof s.v12CheckoutConsent!=='boolean')s.v12CheckoutConsent=false;if(typeof s.v12CheckoutPending!=='boolean')s.v12CheckoutPending=false;if(typeof s.v12CheckoutRequestId!=='string')s.v12CheckoutRequestId='';save();return s}
function combo(s){var pdf=(s.bumps||[]).includes('pdf'),extra=(s.bumps||[]).includes('extra');return pdf&&extra?'pdf_extra':pdf?'pdf':extra?'extra':'none'}
function esc(v){return String(v==null?'':v).replace(/[&<>\"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',"'":'&#39;'}[c]})}
function mainQuestion(s){return String(s.lead&&s.lead.question||s.entryQuestion||s.questionSuggested||s.questionRaw||DEFAULT_Q).trim()||DEFAULT_Q}
function setStatus(text,type){var el=document.getElementById('v12CheckoutStatus');if(el){el.className='v12-checkout-status'+(type?' '+type:'');el.textContent=text||''}}
function relatedCount(s){return s.product&&s.product.id==='deep'?2:s.product&&s.product.id==='complete'?4:0}
function total(s){var p=s.product||{},n=Number(p.price||0);if((s.bumps||[]).includes('pdf'))n+=Number(p.pdf||0);if((s.bumps||[]).includes('extra'))n+=Number(p.extra||0);return n}
function decorate(){var s=ensure(),app=document.getElementById('app');if(!s||!app||Number(s.step)!==26)return;var checkout=app.querySelector('.checkout')||app.querySelector('.content');if(!checkout||checkout.dataset.v12==='1')return;checkout.dataset.v12='1';var summary=checkout.querySelector('.summary'),secure=checkout.querySelector('.secure-box'),button=checkout.querySelector('button[onclick*="completePayment"]');if(!button)return;var before=summary||secure||button,wrap=document.createElement('div');wrap.className='v12-paid-context';wrap.innerHTML='<b>Questão central preservada</b><p>'+esc(mainQuestion(s))+'</p>';before.parentNode.insertBefore(wrap,before);var count=relatedCount(s);if(count){var qbox=document.createElement('div');qbox.className='v12-paid-questions';var intro=document.createElement('p');intro.className='micro';intro.textContent='Este formato comporta até '+(count+1)+' perguntas relacionadas. Campos vazios não entram na leitura.';qbox.appendChild(intro);for(let i=0;i<count;i++){var item=document.createElement('div');item.className='v12-paid-question';item.innerHTML='<label>Pergunta relacionada '+(i+2)+' · opcional</label><textarea maxlength="1600" placeholder="Outro ponto conectado à questão principal.">'+esc(s.v12Questions[i]||'')+'</textarea>';var ta=item.querySelector('textarea');ta.addEventListener('input',function(){s.v12Questions[i]=ta.value.slice(0,1600);save()});qbox.appendChild(item)}before.parentNode.insertBefore(qbox,before)}if((s.bumps||[]).includes('extra')){var ex=document.createElement('div');ex.className='v12-paid-questions';ex.innerHTML='<div class="v12-paid-question"><label>Pergunta extra de confirmação · incluída</label><textarea id="v12ExtraQuestion" maxlength="1200" placeholder="Escreva uma pergunta objetiva que precisa ser esclarecida junto da leitura.">'+esc(s.v12ExtraQuestion||'')+'</textarea></div>';var eta=ex.querySelector('textarea');eta.addEventListener('input',function(){s.v12ExtraQuestion=eta.value.slice(0,1200);save()});before.parentNode.insertBefore(ex,before)}var note=document.createElement('div');note.className='v12-delivery-note';note.innerHTML='<b>Entrega automática e privada.</b> Depois que a Stripe confirmar o pagamento, o servidor abre novas cartas conforme o plano, gera a leitura individual, protege o resultado e envia o acesso ao e-mail informado. Nenhum resultado financeiro é prometido.';button.parentNode.insertBefore(note,button);var consent=document.createElement('label');consent.className='v12-checkout-consent';consent.innerHTML='<input id="v12CheckoutConsent" type="checkbox" '+(s.v12CheckoutConsent?'checked':'')+'><span>Autorizo o processamento das respostas e perguntas desta experiência para gerar e entregar minha consulta privada.</span>';var cb=consent.querySelector('input');cb.addEventListener('change',function(){s.v12CheckoutConsent=cb.checked;save()});button.parentNode.insertBefore(consent,button);var badges=checkout.querySelector('.payment-badges');if(badges)badges.innerHTML='<span>STRIPE</span><span>CARTÃO</span><span>MÉTODOS DISPONÍVEIS</span>';var micro=button.parentNode.querySelector('.micro.center');if(micro)micro.textContent='A leitura só é liberada depois da confirmação real da transação.';var st=document.createElement('div');st.id='v12CheckoutStatus';st.className='v12-checkout-status';button.insertAdjacentElement('afterend',st);if(s.v12CheckoutPending){button.disabled=true;button.textContent='ABRINDO CHECKOUT SEGURO…';setStatus('Criando uma sessão protegida na Stripe.')}}
function context(s){return {version:'h93-v12',consultation_id:s.consultation_id,identity:{name:String(s.lead&&s.lead.name||''),birth:String(s.lead&&s.lead.birth||''),time:String(s.lead&&s.lead.time||'')},main_question:mainQuestion(s),related_questions:(s.v12Questions||[]).map(function(v){return String(v||'').trim()}).filter(Boolean),extra_confirmation_question:(s.bumps||[]).includes('extra')?String(s.v12ExtraQuestion||'').trim():'',free_card:s.card?{id:s.card.id,name:s.card.name,meta:s.card.meta,position:Number.isInteger(s.cardPos)?s.cardPos:null}:null,funnel_answers:Object.assign({},s.answers||{}),question_axis:String(s.questionAxis||''),desired_depth:s.product&&s.product.id||''}}
function startCheckout(){var s=ensure();if(!s||s.v12CheckoutPending)return;var email=String(s.lead&&s.lead.email||'').trim().toLowerCase(),name=String(s.lead&&s.lead.name||'').trim();if(!name||!email||!mainQuestion(s)){alert('Complete seus dados antes de abrir o pagamento.');return}if(!/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(email)){alert('Confira o e-mail informado.');return}if((s.bumps||[]).includes('extra')&&String(s.v12ExtraQuestion||'').trim().length<8){alert('Escreva a pergunta extra de confirmação antes de continuar.');return}if(!s.v12CheckoutConsent){alert('Confirme a autorização de processamento e entrega antes de continuar.');return}if(window.parent===window){alert('Abra o Oráculo pelo domínio oficial da Societas Electorum para concluir o pagamento.');return}var id=s.product&&s.product.id;if(!PRODUCTS[id]){alert('Plano de consulta inválido.');return}s.v12CheckoutPending=true;s.v12CheckoutRequestId=uuid();save();decorate();var button=document.querySelector('button[onclick*="completePayment"]');if(button){button.disabled=true;button.textContent='ABRINDO CHECKOUT SEGURO…'}setStatus('Criando uma sessão protegida na Stripe.');window.parent.postMessage({type:'H93_CHECKOUT_REQUEST',requestId:s.v12CheckoutRequestId,offer:id,combo:combo(s),name:name,email:email,consultation_id:s.consultation_id,context_json:JSON.stringify(context(s)),consent:true},PARENT_ORIGIN)}
function quick(id,c){var s=ensure(),p=PRODUCTS[id];if(!s||!p)return;s.product=Object.assign({},p);s.bumps=c==='pdf_extra'?['pdf','extra']:c==='pdf'?['pdf']:c==='extra'?['extra']:[];s.downsell=false;s.step=26;s.v12CheckoutPending=false;s.v12CheckoutRequestId='';save();render();setTimeout(decorate,0);window.scrollTo({top:0,behavior:'smooth'})}
function onMessage(event){if(event.origin!==PARENT_ORIGIN||event.source!==window.parent)return;var data=event.data||{},s=ensure();if(!s)return;if(data.type==='H93_CHECKOUT_RESULT'&&data.requestId===s.v12CheckoutRequestId){if(data.ok){setStatus('Checkout criado. Abrindo a Stripe…');return}s.v12CheckoutPending=false;s.v12CheckoutRequestId='';save();var b=document.querySelector('button[onclick*="completePayment"]');if(b){b.disabled=false;b.textContent='IR PARA O PAGAMENTO SEGURO'}setStatus(data.message||'Não foi possível abrir o checkout agora.','error')}if(data.type==='H93_PAYMENT_CANCELLED'){s.v12CheckoutPending=false;s.v12CheckoutRequestId='';save();setTimeout(decorate,0)}if(data.type==='H93_PAYMENT_PROCESSING_ERROR'){s.v12CheckoutPending=false;save();setStatus(data.message||'O pagamento foi confirmado e a entrega continua em processamento.','error')}}
function install(){if(installed)return;if(typeof window.__H93_GET_STATE!=='function'||typeof window.__H93_RENDER!=='function'||typeof window.quickCheckout!=='function'||typeof window.completePayment!=='function')return;installed=true;window.quickCheckout=quick;window.completePayment=startCheckout;window.addEventListener('message',onMessage);observer=new MutationObserver(function(){decorate()});var app=document.getElementById('app');if(app)observer.observe(app,{childList:true,subtree:true});ensure();decorate()}
var tries=0,timer=setInterval(function(){install();tries++;if(installed||tries>200)clearInterval(timer)},50);
})();
</script>`;

if(!html.includes('</body>'))throw new Error('V12: body final não localizado');
html=html.replace('</body>',runtime+'\n</body>');

fs.writeFileSync('dist/index.html',html);
fs.writeFileSync('dist/oraculo.html',html);
console.log('V12 secure automation applied',html.length);
