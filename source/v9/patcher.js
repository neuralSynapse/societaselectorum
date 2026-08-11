/* H93-OF-001 — V9 patch layer
   Preserva integralmente source/v8/* como fonte canônica e aplica apenas divergências aprovadas.
*/
(function(){
  'use strict';

  const SEAL='https://cdn.websitepublisher.ai/custom/wid25063/images/horus-l93-selo-canonico.png';

  function one(html, pattern, replacement, label){
    const next=html.replace(pattern,replacement);
    if(next===html) console.warn('[H93 V9] patch não aplicado:',label);
    return next;
  }

  window.applyH93V9Patches=function(html){
    html=one(html,'<title>Oráculo Financeiro de THOTH</title>','<title>Oráculo Financeiro de THOTH — V9</title>','title');
    html=one(html,'portrait:\'\'','portrait:\''+SEAL+'\'','seal asset');
    html=one(html,'alt="Frater Hórus L93"','alt="Selo canônico de Frater Hórus L93"','authority alt');

    const css=`
/* ===== V9 · BLACK / VIOLET / ANTIQUE GOLD ===== */
:root{--bg:#07050d!important;--bg2:#100719!important;--panel:#150b20!important;--text:#f8efd9!important;--muted:#b9afc4!important;--copper:#9d3546!important;--gold:#d6b15a!important;--teal:#8056c7!important;--line:rgba(214,177,90,.22)!important}
body{background:radial-gradient(circle at 50% -10%,rgba(93,49,145,.19),transparent 36%),linear-gradient(180deg,#07050d 0%,#0b0611 48%,#060409 100%)!important}
.btn-primary{background:linear-gradient(180deg,#791f32,#571522)!important;border:1px solid #d6b15a!important;color:#fff7df!important;box-shadow:0 12px 32px rgba(74,15,33,.32),inset 0 0 0 1px rgba(255,226,154,.08)!important}
.btn-primary:hover{transform:translateY(-1px);filter:brightness(1.08)}
.flip-card .thoth-back,.mini-card{background:radial-gradient(circle at 50% 42%,rgba(128,86,199,.3),transparent 34%),linear-gradient(145deg,#160920,#07050d)!important;border-color:#d6b15a!important;box-shadow:0 18px 46px rgba(0,0,0,.42),inset 0 0 28px rgba(128,86,199,.1)!important}
.thoth-back-symbol{filter:sepia(1) saturate(.7) brightness(1.35)}
.v9-process{display:grid;gap:10px;margin:24px auto;max-width:720px;text-align:left}
.v9-process-item{display:grid;grid-template-columns:34px 1fr;gap:12px;align-items:center;padding:13px 14px;border:1px solid rgba(214,177,90,.18);background:rgba(255,255,255,.025);border-radius:14px;animation:v9Rise .55s both}
.v9-process-item:nth-child(2){animation-delay:.08s}.v9-process-item:nth-child(3){animation-delay:.16s}.v9-process-item:nth-child(4){animation-delay:.24s}.v9-process-item:nth-child(5){animation-delay:.32s}.v9-process-item:nth-child(6){animation-delay:.4s}
.v9-process-item i{font-style:normal;color:#d6b15a;font-weight:800}.v9-process-item b{display:block;color:#f8efd9}.v9-process-item small{display:block;color:#b9afc4;margin-top:2px;line-height:1.35}
.v9-diag{display:grid;gap:12px;margin:22px 0}.v9-diag>div{padding:18px;border:1px solid rgba(214,177,90,.18);border-radius:16px;background:linear-gradient(145deg,rgba(128,86,199,.08),rgba(255,255,255,.018))}.v9-diag span{display:block;color:#d6b15a;font-size:.75rem;letter-spacing:.12em;text-transform:uppercase;margin-bottom:7px}.v9-diag b{font-size:1.04rem}.v9-diag p{margin:7px 0 0;color:#d8cfdd;line-height:1.55}
.v9-pdf{margin-top:12px}.v9-local-note{max-width:760px;margin:12px auto 0;color:#9f95a8;font-size:.78rem;line-height:1.45}
@keyframes v9Rise{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}
@media(max-width:680px){.v9-process-item{padding:12px}.v9-diag>div{padding:15px}}
@media print{.topbar,.progress-wrap,.review-bar,.btn,.micro,.v9-local-note{display:none!important}body{background:#fff!important;color:#111!important}.content{max-width:none!important}.v9-diag>div,.insight,.notice{border:1px solid #bbb!important;background:#fff!important;color:#111!important}.v9-diag p,.lead{color:#222!important}}
`;
    html=one(html,'</style>',css+'</style>','v9 visual layer');

    html=one(html,
      /const initial=\(\)=>\(\{step:0,answers:\{\},spread:\[\],card:null,lead:\{\},product:null,bumps:\[\],payment:null,upsells:\[\],downsell:false,postStage:'magnet',utm:\{\}\}\);\nlet state=initial\(\);\nfunction save\(\)\{try\{localStorage\.setItem\('h93of001v8',JSON\.stringify\(state\)\)\}catch\(e\)\{\}\}\nfunction restore\(\)\{try\{const x=JSON\.parse\(localStorage\.getItem\('h93of001v8'\)\|\|'null'\);if\(x\)state=\{\.\.\.initial\(\),\.\.\.x,bumps:x\.bumps\|\|\[\],upsells:x\.upsells\|\|\[\]\}\}catch\(e\)\{\}\}\nfunction reset\(\)\{localStorage\.removeItem\('h93of001v8'\);state=initial\(\);ensureSpread\(\);render\(\)\}/,
      `const STATE_KEY='H93_OF_001_V9_STATE';
const OLD_STATE_KEYS=['h93of001v8','h93of001v7','h93of001','H93_OF_001_STATE'];
const initial=()=>({version:9,step:0,answers:{},spread:[],card:null,lead:{},product:null,bumps:[],payment:null,upsells:[],downsell:false,postStage:'magnet',utm:{}});
let state=initial();
function save(){try{localStorage.setItem(STATE_KEY,JSON.stringify(state))}catch(e){}}
function restore(){try{const raw=localStorage.getItem(STATE_KEY);if(!raw){OLD_STATE_KEYS.forEach(k=>localStorage.removeItem(k));state=initial();return}const x=JSON.parse(raw);state={...initial(),...x,version:9,bumps:x?.bumps||[],upsells:x?.upsells||[]};if(state.card&&!state.spread.some(c=>c&&c.id===state.card.id))state.card=null}catch(e){state=initial()}}
function reset(){[STATE_KEY,...OLD_STATE_KEYS].forEach(k=>localStorage.removeItem(k));state=initial();ensureSpread();render()}`,
      'versioned local state');

    html=one(html,
      /function jump\(n\)\{if\(n>28\)n=28;if\(n<0\)n=0;state\.step=n;if\(state\.step>=17\)ensureSpread\(\);if\(state\.step>=21&&!state\.card\)state\.card=state\.spread\[0\]\|\|CARDS\[0\];save\(\);render\(\);window\.scrollTo\(\{top:0,behavior:'smooth'\}\)\}/,
      `function jump(n){if(n>28)n=28;if(n<0)n=0;state.step=n;if(state.step>=17)ensureSpread();if(state.step>=21&&!state.card){const review=new URLSearchParams(location.search).has('step');if(review){state.card=state.spread[0]||CARDS[0]}else{alert('Escolha uma das três cartas antes de prosseguir.');state.step=7;save();render();return}}save();render();window.scrollTo({top:0,behavior:'smooth'})}`,
      'card state guard');

    html=one(html,
      /function proofIds\(stage\)\{[\s\S]*?\n\}/,
      `function proofIds(stage){const pain=state.answers.pain,emotion=state.answers.emotion,desired=state.answers.desired;const sets={pressure:['dep02','dep04','dep03'],cycle:['dep05','dep04','dep02'],potential:['dep03','dep05','dep02'],control:['dep04','dep02','dep05']};const axis=emotion==='fear'||desired==='relief'?'pressure':pain==='stuck'||desired==='stability'?'cycle':desired==='expansion'?'potential':'control';const list=sets[axis]||sets.control;return stage==='second'?[list[1],list[2],list[0]]:list}`,
      'real testimonial routing');

    html=one(html,
      /function saveLead\(\)\{state\.lead=\{name:document\.getElementById\('name'\)\.value\.trim\(\),birth:document\.getElementById\('birth'\)\.value,time:document\.getElementById\('time'\)\.value,question:document\.getElementById\('question'\)\.value\.trim\(\)\};if\(!state\.lead\.name\|\|!state\.lead\.birth\|\|!state\.lead\.question\)\{alert\('Preencha nome, nascimento e a questão principal para continuar\.'\);return\}save\(\);next\(\)\}/,
      `function saveLead(){state.lead={name:document.getElementById('name').value.trim(),email:document.getElementById('email').value.trim(),birth:document.getElementById('birth').value,time:document.getElementById('time').value,question:document.getElementById('question').value.trim()};if(!state.lead.name||!state.lead.birth||!state.lead.question){alert('Preencha nome, nascimento e a questão principal para continuar.');return}if(state.lead.email&&!/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(state.lead.email)){alert('Confira o e-mail informado.');return}save();next()}
function v9Model(){const p=profile(),a=state.answers||{},card=state.card||CARDS[0];const cost={fear:'A proteção excessiva consome margem de decisão e mantém a atenção presa à perda.',frustration:'A repetição cobra energia, tempo e confiança antes mesmo de cobrar dinheiro.',confusion:'A dispersão transforma opções em custo de oportunidade.'}[a.emotion]||'O padrão consome clareza e reduz a qualidade das próximas decisões.';const mechanism={recent:'O ciclo ainda é recente e pode ser interrompido antes de virar hábito.',months:'A repetição já ganhou força suficiente para parecer normal.',years:'O padrão atravessa fases e tende a ser confundido com identidade.'}[a.duration]||'A repetição ganha força quando passa sem revisão.';const truth={rush:'Velocidade sem critério não é decisão, é reação.',delay:'Esperar certeza total também é uma forma de escolher.',scatter:'Abrir novas frentes não compensa a falta de conclusão.'}[a.decision]||p.truth;const sustain={relief:'preservar margem antes de expandir compromisso',stability:'manter uma rotina simples de registro e revisão',expansion:'concentrar recursos na frente que possui melhor evidência'}[a.desired]||p.move;return{p,card,cost,mechanism,truth,sustain}}
function exportDiagnosisPDF(){const m=v9Model(),w=window.open('','_blank');if(!w)return;const clean=s=>String(s||'').replace(/[<>&]/g,ch=>({'<':'&lt;','>':'&gt;','&':'&amp;'}[ch]));w.document.write('<!doctype html><html><head><meta charset="utf-8"><title>Diagnóstico Financeiro THOTH</title><style>body{font-family:Georgia,serif;max-width:760px;margin:40px auto;padding:0 24px;color:#17121a;line-height:1.55}h1{font-size:28px}h2{font-size:18px;margin-top:26px}small{color:#666}.sig{margin-top:36px;border-top:1px solid #bbb;padding-top:14px}</style></head><body><small>SOCIETAS ELECTORUM · H93-OF-001</small><h1>Diagnóstico Financeiro de THOTH</h1><p><b>'+clean(state.lead.name||'Consulente')+'</b></p><h2>Padrão dominante</h2><p>'+clean(m.p.truth)+'</p><h2>Custo invisível</h2><p>'+clean(m.cost)+'</p><h2>Mecanismo de repetição</h2><p>'+clean(m.mechanism)+'</p><h2>Primeiro comando de correção</h2><p>'+clean(m.p.move)+'</p><h2>Carta escolhida · '+clean(m.card.name)+'</h2><p>'+clean(m.card.text)+'</p><h2>Verdade percebida ainda não executada</h2><p>'+clean(m.truth)+'</p><h2>Próximas 72 horas</h2><p>Interromper: '+clean(m.p.shadow)+'<br>Sustentar: '+clean(m.sustain)+'<br>Executar: '+clean(m.card.advice)+'</p><div class="sig">Leitura inicial simbólica. Não constitui aconselhamento financeiro, jurídico ou de investimento.</div><script>window.onload=()=>setTimeout(()=>window.print(),250)<\\/script></body></html>');w.document.close()}`,
      'lead + diagnostic helpers');

    html=one(html,
      /case 19:h=`[\s\S]*?`;break;\ncase 20:/,
      `case 19:h=\`<div class="content"><div class="eyebrow">Dados da consulta</div><h2>Agora organize sua questão principal.</h2><p class="lead">Nome, nascimento e contexto ajudam a conectar sua pergunta ao percurso já construído.</p><div class="form-grid"><div class="field"><label>Nome completo</label><input id="name" value="\${esc(state.lead.name||'')}"></div><div class="field"><label>E-mail</label><input id="email" type="email" autocomplete="email" placeholder="voce@exemplo.com" value="\${esc(state.lead.email||'')}"></div><div class="field"><label>Data de nascimento</label><input id="birth" type="date" value="\${esc(state.lead.birth||'')}"></div><div class="field"><label>Hora de nascimento, se souber</label><input id="time" type="time" value="\${esc(state.lead.time||'')}"></div><div class="field full"><label>Qual é a questão financeira que mais exige clareza?</label><textarea id="question" placeholder="Descreva a situação, a decisão ou o ciclo que deseja compreender.">\${esc(state.lead.question||'')}</textarea></div></div><button class="btn btn-primary" onclick="saveLead()">PROCESSAR MEU DIAGNÓSTICO</button><p class="v9-local-note">Seu diagnóstico é montado nesta sessão. O envio transacional por e-mail só é liberado quando o canal de saída estiver operacional.</p></div>\`;break;
case 20:`,
      'frame 19');

    html=one(html,
      /case 20:h=`[\s\S]*?`;break;\ncase 21:/,
      `case 20:h=\`<div class="content processing"><div><div class="eyebrow">Cruzamento interpretativo</div><h2>O THOTH não interpreta uma única linguagem.</h2><p class="lead center">A leitura relaciona sua carta, estilo de decisão e respostas em seis camadas complementares.</p><div class="v9-process"><div class="v9-process-item"><i>01</i><div><b>Linguagem</b><small>Como você descreve problema, risco e desejo.</small></div></div><div class="v9-process-item"><i>02</i><div><b>Arquétipos</b><small>Qual força a carta escolhida coloca no centro.</small></div></div><div class="v9-process-item"><i>03</i><div><b>Simbologia</b><small>Elementos, número, planeta e estrutura do Arcano.</small></div></div><div class="v9-process-item"><i>04</i><div><b>Padrões comportamentais</b><small>Como pressão e decisão se repetem no cotidiano.</small></div></div><div class="v9-process-item"><i>05</i><div><b>Ciclos</b><small>Há quanto tempo o padrão se repete e ganha força.</small></div></div><div class="v9-process-item"><i>06</i><div><b>Dinâmica financeira</b><small>O que entra, escapa, trava ou precisa virar estrutura.</small></div></div></div><button class="btn btn-primary" onclick="next()">VER MEU DIAGNÓSTICO</button></div></div>\`;break;
case 21:`,
      'frame 20');

    html=one(html,
      /case 21:h=`[\s\S]*?`;break;\ncase 22:/,
      `case 21:{const m=v9Model();h=\`<div class="content"><div class="eyebrow">Sua Cartografia Financeira Inicial</div><h2>\${m.p.name}</h2><p class="lead">O valor desta leitura está no cruzamento. Nenhuma resposta isolada determina o resultado.</p><div class="v9-diag"><div><span>01 · Padrão dominante</span><b>\${m.p.short}</b><p>\${m.p.truth}</p></div><div><span>02 · Custo invisível</span><b>O que o ciclo cobra antes de aparecer na conta</b><p>\${m.cost}</p></div><div><span>03 · Mecanismo de repetição</span><b>Como o padrão se mantém</b><p>\${m.mechanism}</p></div><div><span>04 · Primeiro comando de correção</span><b>O movimento que devolve direção</b><p>\${m.p.move}.</p></div><div><span>05 · \${m.card.name}</span><b>Leitura da carta aplicada à situação</b><p>\${m.card.text}</p></div><div><span>06 · Verdade percebida ainda não executada</span><b>O ponto que pede ação</b><p>\${m.truth}</p></div></div><button class="btn btn-primary" onclick="next()">RECEBER O CONSELHO DO ORÁCULO</button></div>\`;break}
case 22:`,
      'frame 21');

    html=one(html,
      /case 22:h=`[\s\S]*?`;break;\ncase 23:/,
      `case 22:{const m=v9Model();h=\`<div class="content"><div class="eyebrow">Conselho do Oráculo · próximas 72 horas</div><h2>Clareza sem comando vira apenas uma boa interpretação.</h2><div class="v9-diag"><div><span>Interromper</span><b>O comportamento que alimenta o retorno</b><p>\${m.p.shadow}</p></div><div><span>Sustentar</span><b>O que protege o novo eixo</b><p>\${m.sustain}.</p></div><div><span>Executar em até 72h</span><b>Um movimento observável</b><p>\${m.card.advice}</p></div></div><div class="notice"><b>Ponto de virada:</b> \${m.p.move}.</div><button class="btn btn-primary" onclick="next()">TRANSFORMAR ISSO EM PLANO</button></div>\`;break}
case 23:`,
      'frame 22');

    html=one(html,
      /case 23:h=`[\s\S]*?`;break;\ncase 24:/,
      `case 23:{const m=v9Model();h=\`<div class="content"><div class="eyebrow">Plano inicial de execução</div><h2>Agora a leitura recebe prazo, critério e sinal de progresso.</h2><div class="v9-diag"><div><span>Ação</span><b>Primeiro movimento</b><p>\${m.card.advice}</p></div><div><span>Risco de recaída</span><b>O padrão antigo tentando recuperar o comando</b><p>\${m.p.shadow}</p></div><div><span>Critério de execução</span><b>Como saber que você realmente agiu</b><p>Defina uma ação única, com prazo de até 72 horas, e registre a evidência objetiva de conclusão.</p></div><div><span>Sinal de progresso</span><b>O que observar depois</b><p>Mais margem de escolha, menos repetição automática e uma decisão financeira concluída sem abrir outra frente para compensar.</p></div><div><span>Aprofundamento correspondente</span><b>O que novas cartas investigam</b><p>Raiz, bloqueio, recurso, ação e tendência conforme o nível de profundidade escolhido.</p></div></div><button class="btn btn-secondary v9-pdf" onclick="exportDiagnosisPDF()">SALVAR MEU DIAGNÓSTICO EM PDF</button><button class="btn btn-primary" onclick="next()">VER EXPERIÊNCIAS E CONTINUIDADE</button></div>\`;break}
case 24:`,
      'frame 23');

    html=one(html,
      'window.saveLead=saveLead;window.reset=reset;window.jump=jump;',
      'window.saveLead=saveLead;window.exportDiagnosisPDF=exportDiagnosisPDF;window.reset=reset;window.jump=jump;',
      'pdf export exposure');

    html=html.replace('V8 FINAL','V9').replace('V8 Consolidado','V9');
    html=html.replace('<meta name="robots" content="index,follow">','<meta name="robots" content="noindex,nofollow">');
    return html;
  };
})();
