import WORLD from './manifest.js?v=20260905-canonical-v1';
import { worldStorageKey } from '../../js/platform/world-registry.js?v=20260905-canonical-v1';

const $=(s,r=document)=>r.querySelector(s), $$=(s,r=document)=>[...r.querySelectorAll(s)];
const state={selected:null,mode:'mapa',lens:null,compare:[],visited:new Set(),started:false};
const MEMBER_BRIDGE=(window.__MUNDUS_MEMBER_BRIDGE&&typeof window.__MUNDUS_MEMBER_BRIDGE==='object')?window.__MUNDUS_MEMBER_BRIDGE:null;
const CHRONICA_KEY=worldStorageKey('societas','chronica-v1');
const START_KEY=worldStorageKey('societas','entered-v1');
const nodeMap=new Map(WORLD.nodes.map(n=>[n.id,n]));
const positions={
  'societas-electorum':[50,20],
  'arbor-vitae':[24,10],'arbor-draconis':[50,7],'arbor-electorum':[76,10],
  'biblioteca':[18,29],'jornada':[50,30],'pergaminho':[82,29],
  'estudante':[50,41],
  'periodo-1':[23,51],'periodo-2':[50,51],'periodo-3':[77,51],
  'clavis-1':[23,61],'clavis-2':[50,61],'clavis-3':[77,61],
  'xi-1':[13,70],'xi-2':[23,73],'xi-3':[33,70],
  'xi-4':[40,70],'xi-5':[50,73],'xi-6':[60,70],
  'xi-7':[67,70],'xi-8':[77,73],'xi-9':[87,70],
  'lm-001':[28,82],'na-001':[40,84],'an-001':[52,82],
  'exame-peregrinus':[66,84],'peregrinus-ignis':[79,83],
  'pergaminho-1':[88,78],'pergaminho-2':[91,72],'pergaminho-3':[93,65],'pergaminho-4':[94,57],
  'pergaminho-5':[93,49],'pergaminho-6':[91,42],'pergaminho-7':[88,36],'pergaminho-8':[84,32],
  'pergaminho-9':[80,35],'pergaminho-10':[78,41],'pergaminho-11':[77,47],'pergaminho-12':[80,54]
};

function esc(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
function kindLabel(n){return ({institution:'INSTITUIÇÃO',tree:'ÁRVORE',stage:'ETAPA',period:'PERÍODO',clavis:'CLAVIS DO UMBRAL',cycle:'CICLO XI',degree:'GRAU',system:'SISTEMA',work:'OBRA TRANSVERSAL',gate:'PORTÃO DE PASSAGEM',competency:'COMPETÊNCIA',module:'MÓDULO',pergaminho_maior:'PERGAMINHO MAIOR'})[n.kind]||String(n.kind||'NÓ').toUpperCase();}
function statusLabel(n){if(n.status==='veiled')return 'VELADA · ESPECTRAL';if(n.status==='preparatory')return 'PREPARATÓRIA · NÃO É GRAU';if(n.status==='degree_1')return 'GRAU I';if(n.status==='present')return 'PRESENTE NA UX';if(n.status==='student')return 'ETAPA DO ESTUDANTE';if(n.status==='transversal')return 'TRANSVERSAL';if(n.status==='peregrinus')return 'PEREGRINUS IGNIS';return String(n.status||'CANÔNICO').replaceAll('_',' ').toUpperCase();}
function chronica(){try{return JSON.parse(localStorage.getItem(CHRONICA_KEY)||'[]')}catch{return []}}
function writeChronica(entry){const rows=chronica();rows.unshift({at:Date.now(),...entry});if(rows.length>120)rows.length=120;localStorage.setItem(CHRONICA_KEY,JSON.stringify(rows));}
function recordVisit(node){if(state.visited.has(node.id))return;state.visited.add(node.id);writeChronica({type:'focus',nodeId:node.id,text:`Foco aberto: ${node.title}.`});updateStatus();}
function relationsFor(id){return WORLD.relations.filter(r=>r.from===id||r.to===id);}
function relatedNodes(id){return relationsFor(id).map(r=>({relation:r,node:nodeMap.get(r.from===id?r.to:r.from),direction:r.from===id?'out':'in'})).filter(x=>x.node);}

function buildShell(){
  document.body.innerHTML=`<main class="sw-shell" id="sw-shell">
    <header class="sw-top"><a class="sw-brand" href="${esc(MEMBER_BRIDGE?.backHref||'/mundus.html')}" aria-label="${esc(MEMBER_BRIDGE?'Voltar à Comunidade Electorum':'Voltar ao MUNDUS')}"><span class="sw-mark"></span><span><b>MUNDUS</b><small>${esc(MEMBER_BRIDGE?'SOCIETAS · SESSÃO VERIFICADA':'CORE · MULTIWORLD')}</small></span></a><div class="sw-world-label"><small>WORLD PACKAGE</small><b>SOCIETAS ELECTORUM</b></div><div class="sw-top-actions">${MEMBER_BRIDGE?`<a class="sw-icon-btn" href="${esc(MEMBER_BRIDGE.backHref||'/comunidade/app.html')}" aria-label="Voltar à Comunidade" style="display:grid;place-items:center;text-decoration:none">↩</a>`:''}<button class="sw-icon-btn" id="sw-search-toggle" aria-label="Pesquisar">⌕</button><button class="sw-icon-btn" id="sw-home" aria-label="Recentrar">◎</button></div></header>
    <div class="sw-search" id="sw-search"><input id="sw-search-input" placeholder="Localizar Árvore, etapa, Grau ou Pergaminho…" autocomplete="off"><div class="sw-search-results" id="sw-search-results"></div></div>
    <section class="sw-stage"><div class="sw-map" id="sw-map"><svg class="sw-lines" id="sw-lines" aria-hidden="true"></svg><div id="sw-nodes"></div></div></section>
    <div class="sw-lens-banner" id="sw-lens-banner"></div>
    <footer class="sw-bottom"><div class="sw-lenses" id="sw-lenses"><button class="sw-chip" data-lens="assiah">ASSIAH</button><button class="sw-chip" data-lens="yetzirah">YETZIRAH</button><button class="sw-chip" data-lens="briah">BRIAH</button><button class="sw-chip" data-lens="atziluth">ATZILUTH</button></div><nav class="sw-modes" id="sw-modes"><button class="sw-mode active" data-mode="mapa">MAPA</button><button class="sw-mode" data-mode="foco">FOCO</button><button class="sw-mode" data-mode="caminho">CAMINHO</button><button class="sw-mode" data-mode="comparacao">COMPARAÇÃO</button><button class="sw-mode" data-mode="comunhao">COMUNHÃO</button><button class="sw-mode" data-mode="praxis">PRAXIS</button><button class="sw-mode" data-mode="chronica">CHRONICA</button></nav><div class="sw-status"><b id="sw-status">0 NÓS VISITADOS</b><small>progressão iniciática não é gamificada</small></div></footer>
    <aside class="sw-panel" id="sw-panel" aria-hidden="true"><header class="sw-panel-head"><div><small id="sw-panel-kind">NÓ CANÔNICO</small><h2 id="sw-panel-title">SOCIETAS ELECTORUM</h2></div><button class="sw-close" id="sw-panel-close" aria-label="Fechar">×</button></header><div class="sw-panel-body" id="sw-panel-body"></div></aside>
    <div class="sw-modal" id="sw-modal"><section class="sw-modal-card"><header><div><small id="sw-modal-kicker">MUNDUS · SOCIETAS</small><h2 id="sw-modal-title"></h2></div><button class="sw-close" id="sw-modal-close">×</button></header><div id="sw-modal-body"></div></section></div>
    <div class="sw-onboarding" id="sw-onboarding"><section class="sw-onboarding-card"><small>${esc(MEMBER_BRIDGE?'MUNDUS · SOCIETAS · SESSÃO VERIFICADA':'MUNDUS · SEGUNDO MUNDO')}</small><h1>SOCIETAS</h1><p>A SOCIETAS ELECTORUM não aparece aqui como menu ou apostila. Ela aparece como arquitetura: Árvores, etapas, Graus, Pergaminhos, fontes, relações e práticas ocupam um território que pode ser navegado e reconstruído.${MEMBER_BRIDGE?` Sua posição autenticada permanece vinculada à Jornada real; explorar este mundo não altera Grau nem substitui seus gates.`:''}</p><button class="sw-enter" id="sw-enter">ENTRAR NA ARQUITETURA</button></section></div>
  </main>`;
}

function renderNodes(){
  const host=$('#sw-nodes');
  host.innerHTML=WORLD.nodes.filter(n=>!n.hiddenByDefault).map(n=>{
    const p=positions[n.id]||[50,50];
    return `<button class="sw-node ${esc(n.kind)} ${n.status==='veiled'?'veiled':''}" style="left:${p[0]}%;top:${p[1]}%" data-node="${esc(n.id)}" aria-label="${esc(n.title)}"><span class="kind">${esc(kindLabel(n))}</span><b>${esc(n.title)}</b><span class="status">${esc(statusLabel(n))}</span></button>`;
  }).join('');
  $$('[data-node]').forEach(btn=>btn.addEventListener('click',()=>handleNodeClick(btn.dataset.node)));
  requestAnimationFrame(drawLines);
}
function drawLines(){
  const svg=$('#sw-lines'), map=$('#sw-map');if(!svg||!map)return;
  const mr=map.getBoundingClientRect();svg.setAttribute('viewBox',`0 0 ${mr.width} ${mr.height}`);
  svg.innerHTML=WORLD.relations.map(r=>{
    const a=$(`[data-node="${CSS.escape(r.from)}"]`),b=$(`[data-node="${CSS.escape(r.to)}"]`);if(!a||!b)return '';
    const ar=a.getBoundingClientRect(),br=b.getBoundingClientRect();
    const x1=ar.left+ar.width/2-mr.left,y1=ar.top+ar.height/2-mr.top,x2=br.left+br.width/2-mr.left,y2=br.top+br.height/2-mr.top;
    const active=state.selected&&(r.from===state.selected||r.to===state.selected);
    return `<line class="${active?'active':''}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" data-rel="${esc(r.type)}"/>`;
  }).join('');
}
function updateNodeStates(){
  $$('[data-node]').forEach(el=>{
    const id=el.dataset.node, linked=!state.selected||id===state.selected||relationsFor(state.selected).some(r=>r.from===id||r.to===id);
    el.classList.toggle('active',id===state.selected||state.compare.includes(id));
    el.classList.toggle('dim',state.mode==='caminho'&&state.selected&&!linked);
  });
  drawLines();
}
function handleNodeClick(id){
  const node=nodeMap.get(id);if(!node)return;
  if(state.mode==='comparacao')return toggleCompare(node);
  state.selected=id;recordVisit(node);openNode(node);updateNodeStates();
  if(state.mode==='comunhao')openCommunion(node);
  if(state.mode==='praxis')openPraxis(node);
}
function openNode(node){
  const panel=$('#sw-panel');$('#sw-panel-kind').textContent=`${kindLabel(node)} · ${statusLabel(node)}`;$('#sw-panel-title').textContent=node.title;
  const rels=relatedNodes(node.id);
  const veiled=node.status==='veiled';
  const lens=state.lens?WORLD.fourWorlds.find(x=>x.id===state.lens):null;
  $('#sw-panel-body').innerHTML=`
    <p>${esc(veiled?'Esta presença existe desde o início como camada velada, espectral e progressivamente revelada. O MUNDUS localiza sua relação sem fabricar conteúdo para preencher o que o cânone ainda mantém fechado.':node.summary)}</p>
    <div class="sw-meta"><div><span>STATUS CANÔNICO</span><b>${esc(statusLabel(node))}</b></div><div><span>WORLD PACKAGE</span><b>SOCIETAS · v${esc(WORLD.canon.version)}</b></div>${MEMBER_BRIDGE?`<div><span>SUA ETAPA</span><b>${esc(MEMBER_BRIDGE.currentStage||'estado autenticado')}</b></div><div><span>JORNADA</span><b>${esc(Number.isFinite(Number(MEMBER_BRIDGE.journeyPercent))?Math.round(Number(MEMBER_BRIDGE.journeyPercent))+'%':'estado sincronizado')}</b></div>`:''}</div>
    ${lens?`<section class="sw-section"><h3>LENTE ATIVA · ${esc(lens.title)}</h3><div class="sw-callout">Observe este nó pela dimensão de ${esc(lens.meaning)}. A lente muda a pergunta feita ao objeto, não reescreve seu cânone.</div></section>`:''}
    <section class="sw-section"><h3>RELAÇÕES</h3><div class="sw-rel">${rels.length?rels.map(x=>`<button data-related="${esc(x.node.id)}"><b>${esc(x.direction==='out'?'→':'←')} ${esc(x.node.title)}</b><br><small>${esc(x.relation.type.replaceAll('_',' '))}</small></button>`).join(''):'<div class="sw-empty">Nenhuma relação adicional registrada nesta camada.</div>'}</div></section>
    <section class="sw-section"><h3>PROVENIÊNCIA</h3><div class="sw-callout">Fonte governante desta foundation: CURRÍCULO VIVO DO ESTUDANTE v2.13, de 05/09/2026, em conjunto com a precedência digital vigente. Método de apresentação: MET-MUNDUS-001. O mundo deriva da fonte; não a substitui e não inventa lacunas.</div></section>
    ${node.id==='estudante'?`<section class="sw-section"><h3>REGRA DE PROGRESSÃO</h3><div class="sw-callout">Estudante é etapa preparatória, não Grau. O mínimo temporal não promove ninguém sozinho. Progressão depende de competência e evidência verificável.</div></section>`:''}
    ${node.kind==='degree'?`<section class="sw-section"><h3>REGRA DE GRAU</h3><div class="sw-callout">XP, nível de interface, streak, clique, compra ou tempo de tela não promovem Grau.</div></section>`:''}`;
  $$('[data-related]').forEach(b=>b.onclick=()=>{const n=nodeMap.get(b.dataset.related);state.selected=n.id;recordVisit(n);openNode(n);updateNodeStates();});
  panel.classList.add('open');panel.setAttribute('aria-hidden','false');
}
function closePanel(){const p=$('#sw-panel');p.classList.remove('open');p.setAttribute('aria-hidden','true');}

function setMode(mode){
  state.mode=mode;state.compare=[];$$('[data-mode]').forEach(b=>b.classList.toggle('active',b.dataset.mode===mode));
  if(mode==='mapa'){state.selected=null;closePanel();}
  if(mode==='chronica')openChronica();
  if(mode==='caminho')openStudentPath();
  if(mode==='comparacao')showModal('COMPARAÇÃO','Escolha dois nós','<p>Toque em dois elementos do mapa. O MUNDUS colocará as funções, status e relações lado a lado sem fingir equivalência entre coisas diferentes.</p>');
  if(mode==='comunhao'&&!state.selected)showModal('COMUNHÃO','Selecione um interlocutor','<p>Escolha um nó do mundo. A Comunhão desta foundation responde a partir do manifest canônico do próprio nó, não de improvisação livre.</p>');
  if(mode==='praxis'&&!state.selected)showModal('PRAXIS','Selecione um objeto de prática','<p>A exploração do mundo nunca conclui uma etapa sozinha. Selecione um nó para ver o vínculo entre compreensão, prática, registro e evidência.</p>');
  updateNodeStates();
}
function openStudentPath(){
  showModal('CAMINHO','ESTUDANTE → PEREGRINUS IGNIS',`<div class="sw-callout">O caminho mostra ordem e portões. Ele não executa promoção automática.</div><section class="sw-section"><h3>ETAPA DO ESTUDANTE · MÍNIMO ESTRUTURAL</h3><p>99 dias mínimos → 3 Períodos de 33 → 9 Ciclos XI de 11. O tempo isolado nunca aprova.</p></section><section class="sw-section"><h3>VER → GOVERNAR → FAZER</h3><div class="sw-rel"><button data-path-node="clavis-1"><b>CLAVIS I · O OLHO</b><br><small>Período I · REGÊNCIA · XI·1–XI·3</small></button><button data-path-node="clavis-2"><b>CLAVIS II · A CHAMA</b><br><small>Período II · DISCERNIMENTO · XI·4–XI·6</small></button><button data-path-node="clavis-3"><b>CLAVIS III · A OBRA</b><br><small>Período III · OBRA · XI·7–XI·9</small></button><button data-path-node="exame-peregrinus"><b>EXAME DE PASSAGEM</b><br><small>competência, autoria, ética e evidência</small></button><button data-path-node="peregrinus-ignis"><b>PEREGRINUS IGNIS</b><br><small>Grau I · somente após decisão de passagem documentada</small></button></div></section><section class="sw-section"><h3>QUATRO CLASSES DE EVIDÊNCIA</h3><p>RECUPERAÇÃO → DISCRIMINAÇÃO → TRANSFERÊNCIA → OBRA.</p></section>`);
  $$('[data-path-node]').forEach(b=>b.onclick=()=>{closeModal();handleNodeClick(b.dataset.pathNode);});
}

function toggleCompare(node){
  const i=state.compare.indexOf(node.id);if(i>=0)state.compare.splice(i,1);else if(state.compare.length<2)state.compare.push(node.id);else state.compare=[state.compare[1],node.id];
  updateNodeStates();
  if(state.compare.length===2)openComparison(state.compare.map(id=>nodeMap.get(id)));
}
function openComparison([a,b]){
  const row=n=>`<div><h3>${esc(n.title)}</h3><p>${esc(n.status==='veiled'?'Conteúdo velado; somente função geral autorizada.':n.summary)}</p><div class="sw-meta"><div><span>TIPO</span><b>${esc(kindLabel(n))}</b></div><div><span>STATUS</span><b>${esc(statusLabel(n))}</b></div></div></div>`;
  showModal('COMPARAÇÃO','Dois objetos, duas funções',`<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:18px;margin-top:16px">${row(a)}${row(b)}</div><div class="sw-callout" style="margin-top:16px">Comparar não significa fundir. O objetivo é distinguir função, posição e relação no sistema maior.</div>`);
  writeChronica({type:'comparison',text:`Comparação aberta: ${a.title} ↔ ${b.title}.`});
}
function setLens(id){
  state.lens=state.lens===id?null:id;$$('[data-lens]').forEach(b=>b.classList.toggle('active',b.dataset.lens===state.lens));
  const banner=$('#sw-lens-banner');if(!state.lens){banner.classList.remove('show');banner.textContent='';}
  else{const w=WORLD.fourWorlds.find(x=>x.id===state.lens);banner.textContent=`${w.title} · ${w.meaning}`;banner.classList.add('show');writeChronica({type:'lens',text:`Lente transversal ativada: ${w.title}.`});}
  if(state.selected)openNode(nodeMap.get(state.selected));
}
function openCommunion(node){
  const body=`<p>Interlocutor: <b>${esc(node.title)}</b></p><div class="sw-callout">${esc(node.status==='veiled'?'Minha presença pode ser localizada, mas meu conteúdo permanece velado nesta camada. O silêncio canônico vale mais que uma resposta inventada.':node.summary)}</div><section class="sw-section"><h3>PERGUNTA DISPONÍVEL NESTA FOUNDATION</h3><div class="sw-rel"><button id="comm-role">QUAL É A SUA FUNÇÃO?</button><button id="comm-rel">COM O QUE VOCÊ SE RELACIONA?</button><button id="comm-proof">COMO ISSO SE VERIFICA?</button></div><div id="comm-answer" style="margin-top:12px"></div></section>`;
  showModal('COMUNHÃO',node.title,body);
  const answer=$('#comm-answer');$('#comm-role').onclick=()=>answer.innerHTML=`<div class="sw-callout">${esc(node.status==='veiled'?'Sou uma presença velada da arquitetura digital vigente. Minha função detalhada não é preenchida por inferência enquanto a fonte não a autorizar.':node.summary)}</div>`;
  $('#comm-rel').onclick=()=>answer.innerHTML=`<div class="sw-callout">${relatedNodes(node.id).map(x=>`${x.direction==='out'?'→':'←'} ${x.node.title}: ${x.relation.type.replaceAll('_',' ')}`).join('<br>')||'Nenhuma relação adicional registrada nesta camada.'}</div>`;
  $('#comm-proof').onclick=()=>answer.innerHTML='<div class="sw-callout">No MÉTODO MUNDUS, ver não basta. A verificação exige reconstrução conceitual, transferência para um caso, praxis correspondente e evidência registrada quando o currículo exigir.</div>';
  writeChronica({type:'communion',nodeId:node.id,text:`Comunhão aberta com ${node.title}.`});
}
function openPraxis(node){
  showModal('PRAXIS',`Prática · ${node.title}`,`<p>${esc(node.status==='veiled'?'Nenhuma prática velada é exposta por este world package.':'O objeto foi compreendido em modo navegável. Agora ele deve sair da tela e entrar em ação verificável.')}</p><div class="sw-callout">Explorar, assistir, clicar ou permanecer tempo suficiente aqui <b>não conclui</b> etapa, Pergaminho ou Grau. A conclusão real pertence ao currículo vigente e às evidências exigidas pela SOCIETAS.</div><section class="sw-section"><h3>CICLO MUNDUS</h3><p>Praxis → Registro → Integração → Verificação → Continuidade.</p></section>`);
  writeChronica({type:'praxis',nodeId:node.id,text:`Camada de Praxis consultada para ${node.title}.`});
}
function openChronica(){
  const rows=chronica();
  showModal('CHRONICA','Seu percurso neste mundo',`<div class="sw-chronica">${rows.length?rows.map(r=>`<article><time>${new Date(r.at).toLocaleString('pt-BR')}</time><p>${esc(r.text)}</p></article>`).join(''):'<div class="sw-empty">A Chronica ainda está vazia. Ela registra navegação, lentes, comparações, Comunhão e Praxis, mas não converte essas ações em promoção iniciática.</div>'}</div>`);
}
function showModal(kicker,title,body){$('#sw-modal-kicker').textContent=kicker;$('#sw-modal-title').textContent=title;$('#sw-modal-body').innerHTML=body;$('#sw-modal').classList.add('open');}
function closeModal(){$('#sw-modal').classList.remove('open');}
function updateStatus(){$('#sw-status').textContent=`${state.visited.size} ${state.visited.size===1?'NÓ VISITADO':'NÓS VISITADOS'}`;}
function recenter(){state.selected=null;state.compare=[];closePanel();$('#sw-map').style.transform='';updateNodeStates();}
function search(q){q=String(q||'').trim().toLowerCase();const box=$('#sw-search-results');if(!q){box.classList.remove('show');box.innerHTML='';return;}const rows=WORLD.nodes.filter(n=>`${n.title} ${n.kind} ${n.summary}`.toLowerCase().includes(q)).slice(0,8);box.innerHTML=rows.map(n=>`<button data-search-node="${esc(n.id)}"><b>${esc(n.title)}</b><small>${esc(kindLabel(n))} · ${esc(statusLabel(n))}</small></button>`).join('');box.classList.toggle('show',!!rows.length);$$('[data-search-node]').forEach(b=>b.onclick=()=>{box.classList.remove('show');const n=nodeMap.get(b.dataset.searchNode);state.selected=n.id;recordVisit(n);openNode(n);updateNodeStates();});}
function bind(){
  $('#sw-panel-close').onclick=closePanel;$('#sw-modal-close').onclick=closeModal;$('#sw-modal').addEventListener('click',e=>{if(e.target.id==='sw-modal')closeModal();});
  $$('[data-mode]').forEach(b=>b.onclick=()=>setMode(b.dataset.mode));$$('[data-lens]').forEach(b=>b.onclick=()=>setLens(b.dataset.lens));
  $('#sw-home').onclick=recenter;$('#sw-search-toggle').onclick=()=>$('#sw-search-input').focus();$('#sw-search-input').addEventListener('input',e=>search(e.target.value));
  $('#sw-enter').onclick=()=>{state.started=true;localStorage.setItem(START_KEY,'1');$('#sw-onboarding').classList.add('hidden');writeChronica({type:'entry',text:'Entrada no MUNDUS · SOCIETAS.'});};
  if(localStorage.getItem(START_KEY)==='1')$('#sw-onboarding').classList.add('hidden');
  window.addEventListener('resize',()=>requestAnimationFrame(drawLines));
  window.addEventListener('keydown',e=>{if(e.key==='Escape'){closeModal();closePanel();}});
}

buildShell();renderNodes();bind();updateStatus();
window.MUNDUS_WORLD={manifest:WORLD,memberBridge:MEMBER_BRIDGE,getState:()=>({selected:state.selected,mode:state.mode,lens:state.lens,visited:[...state.visited]}),focus:(id)=>handleNodeClick(id),setMode,setLens};
