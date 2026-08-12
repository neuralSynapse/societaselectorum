import fs from 'node:fs';

let html=fs.readFileSync('dist/index.html','utf8');

// Identidade pública canônica.
html=html.replaceAll('SOCIEDADE DOS ELEITOS','SOCIETAS ELECTORUM');
html=html.replaceAll('Sociedade dos Eleitos','Societas Electorum');

// Remove qualquer rótulo legado de versão interna que tenha escapado para o público.
const footer='Societas Electorum · Oráculo Financeiro de THOTH · Leitura simbólica e reflexiva. Não substitui orientação financeira, jurídica, contábil ou de investimentos e não garante resultados.';
html=html.replace(/V8 Consolidado funcional para aprovação\.[^<]*/g,footer);
html=html.replace(/V8 Consolidado[^<]*/g,footer);

// A URL pública é estável. Números internos de build não aparecem para o visitante.
html=html.replace(/<title>Oráculo Financeiro de THOTH[^<]*<\/title>/,'<title>Oráculo Financeiro de THOTH · Societas Electorum</title>');

// SAPI oficial do WebsitePublisher para captura real de lead quando a build roda diretamente no domínio oficial.
if(!html.includes('cdn.websitepublisher.ai/js/sapi-client.js')){
  html=html.replace('</head>','<script src="https://cdn.websitepublisher.ai/js/sapi-client.js"></script>\n</head>');
}

// Campos obrigatórios e consentimento explícito. Isso é validação de dados, não uma micropergunta do percurso.
html=html.replace('<input id="name" value="${esc(state.lead.name||\'\')}">','<input id="name" required autocomplete="name" value="${esc(state.lead.name||\'\')}">');
html=html.replace('<input id="email" type="email" autocomplete="email"','<input id="email" type="email" required autocomplete="email"');
html=html.replace('<input id="birth" type="date"','<input id="birth" type="date" required');
const leadButton='<button class="btn btn-primary" onclick="saveLead()">PROCESSAR MEU DIAGNÓSTICO</button>';
const leadBlock='<div class="lead-consent"><label><input id="leadConsent" type="checkbox"> <span>Concordo com o uso destes dados para gerar, registrar e entregar minha leitura.</span></label></div><div id="leadStatus" class="lead-status" role="status" aria-live="polite"></div><button id="leadSubmit" class="btn btn-primary" onclick="saveLead()">PROCESSAR MEU DIAGNÓSTICO</button>';
if(!html.includes(leadButton))throw new Error('Botão de lead não localizado na finalização');
html=html.replace(leadButton,leadBlock);

const leadCss=`\n.lead-consent{margin:18px 0 10px;padding:14px 16px;border:1px solid rgba(65,207,206,.24);border-radius:14px;background:rgba(65,207,206,.05);color:var(--muted);font-size:13px;line-height:1.5}.lead-consent label{display:flex;gap:10px;align-items:flex-start;cursor:pointer}.lead-consent input{width:18px;height:18px;margin-top:2px;accent-color:#2fc3c0;flex:0 0 auto}.lead-status{min-height:20px;margin:0 0 10px;color:#bde7e3;font-size:13px}.lead-status.error{color:#f1a2a2}.lead-status.ok{color:#b9e8c7}\n`;
html=html.replace('</style>',leadCss+'</style>');

// Captura real: direta quando hospedada no domínio oficial e por ponte postMessage quando a build GitHub está embutida na página oficial.
const saveLeadRe=/function saveLead\(\)\{[\s\S]*?save\(\);next\(\)\}/;
if(!saveLeadRe.test(html))throw new Error('saveLead não localizado na finalização');
const saveLead=`async function saveLead(){
  const name=(document.getElementById('name')?.value||'').trim();
  const email=(document.getElementById('email')?.value||'').trim();
  const birth=document.getElementById('birth')?.value||'';
  const time=document.getElementById('time')?.value||'';
  const consent=Boolean(document.getElementById('leadConsent')?.checked);
  const status=document.getElementById('leadStatus');
  const button=document.getElementById('leadSubmit');
  const message=(text,type='error')=>{if(status){status.className='lead-status '+type;status.textContent=text}};
  if(!name||!email||!birth){message('Preencha nome, e-mail e data de nascimento para gerar o diagnóstico.');return}
  if(!/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(email)){message('Confira o e-mail informado.');return}
  if(!consent){message('Confirme o consentimento para registrar e entregar sua leitura.');return}
  state.lead={name,email,birth,time,question:activeQuestion()};save();
  const payload={name,email,birth,time,question:activeQuestion(),axis:state.questionAxis||'entrada e permanência',card:state.card?.name||'',source:'oraculo_financeiro_thoth'};
  const host=String(location.hostname||'').toLowerCase();
  const official=host==='sociedadedoseleitos.com'||host.endsWith('.sociedadedoseleitos.com');
  const inFrame=typeof window.parent!=='undefined'&&window.parent&&window.parent!==window;
  if(button){button.disabled=true;button.textContent='REGISTRANDO SUA LEITURA…'}
  try{
    if(official){
      if(!window.WP?.sapi)throw new Error('Canal de registro indisponível. Recarregue a página e tente novamente.');
      const sapi=window.WP.sapi(25063);
      const result=await sapi.submitForm({form_name:'oraculo_financeiro_thoth',form_data:payload});
      if(result&&result.ok===false)throw new Error(result.message||'Não foi possível registrar seus dados agora.');
      message('Dados registrados. Seu diagnóstico está sendo organizado.','ok');
    }else if(inFrame&&typeof window.addEventListener==='function'){
      const requestId='h93_'+Date.now()+'_'+Math.random().toString(36).slice(2);
      await new Promise((resolve,reject)=>{
        let timer;
        const onMessage=(event)=>{const data=event?.data||{};if(data.type!=='H93_LEAD_RESULT'||data.requestId!==requestId)return;clearTimeout(timer);window.removeEventListener('message',onMessage);data.ok?resolve(data):reject(new Error(data.message||'Não foi possível registrar seus dados agora.'))};
        window.addEventListener('message',onMessage);
        timer=setTimeout(()=>{window.removeEventListener('message',onMessage);reject(new Error('O registro demorou mais que o esperado. Tente novamente.'))},10000);
        window.parent.postMessage({type:'H93_LEAD_SUBMIT',requestId,form_name:'oraculo_financeiro_thoth',form_data:payload},'*');
      });
      message('Dados registrados. Seu diagnóstico está sendo organizado.','ok');
    }
    next();
  }catch(err){
    message(err?.message||'Não foi possível registrar seus dados agora. Tente novamente.');
    if(button){button.disabled=false;button.textContent='PROCESSAR MEU DIAGNÓSTICO'}
  }
}`;
html=html.replace(saveLeadRe,saveLead);

fs.writeFileSync('dist/index.html',html);
fs.writeFileSync('dist/oraculo.html',html);
console.log('Finalização pública aplicada:',html.length,'caracteres');
