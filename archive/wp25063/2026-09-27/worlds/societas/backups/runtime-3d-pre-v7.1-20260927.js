import WORLD from './manifest.js?v=20260905-canonical-v1';
import { SOCIETAS_SEQUENCE, sequenceVisibleIds } from './sequence.js?v=20260905-canonical-v1';
import { SocietasRenderer3D } from './renderer-3d.js?v=20260905-canonical-v1';
import { worldStorageKey } from '../../js/platform/world-registry.js?v=20260905-canonical-v1';

const $=(s,r=document)=>r.querySelector(s), $$=(s,r=document)=>[...r.querySelectorAll(s)];
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const nodeMap=new Map(WORLD.nodes.map(n=>[n.id,n]));
const MEMBER_BRIDGE=(window.__MUNDUS_MEMBER_BRIDGE&&typeof window.__MUNDUS_MEMBER_BRIDGE==='object')?window.__MUNDUS_MEMBER_BRIDGE:null;
const CHRONICA_KEY=worldStorageKey('societas','chronica-v2');
const LEGACY_CHRONICA_KEY=worldStorageKey('societas','chronica-v1');
const STATE_KEY=worldStorageKey('societas','cinematic-semantic-v2');
const START_KEY=worldStorageKey('societas','entered-semantic-v2');

const state={
  guided:true,phase:0,phaseElapsed:0,playing:false,speed:1,mode:'mapa',lens:null,
  selected:null,compare:[],visited:new Set(),cameraMode:'auto',audio:true,narration:true,
  lastTick:performance.now(),started:false
};

function supportsWebGL(){try{const c=document.createElement('canvas');return !!(window.WebGLRenderingContext&&(c.getContext('webgl2')||c.getContext('webgl')));}catch{return false;}}
function validateWorldPackage(){
  const errors=[];
  const required=['societas-electorum','arbor-vitae','arbor-draconis','arbor-electorum','biblioteca','jornada','pergaminho','estudante','peregrinus-ignis'];
  required.forEach(id=>{if(!nodeMap.has(id))errors.push(`Nó obrigatório ausente: ${id}`);});
  const electorum=nodeMap.get('arbor-electorum');if(electorum&&electorum.status!=='veiled')errors.push('Arbor Electorum precisa permanecer velada nesta versão.');
  const estudante=nodeMap.get('estudante');if(estudante&&estudante.kind==='degree')errors.push('Estudante não pode ser tipado como Grau.');
  const peregrinus=nodeMap.get('peregrinus-ignis');if(peregrinus&&peregrinus.kind!=='degree')errors.push('Peregrinus Ignis precisa permanecer tipado como Grau.');
  const majors=WORLD.nodes.filter(n=>n.kind==='pergaminho_maior');if(majors.length!==12)errors.push(`Esperados 12 Pergaminhos Maiores; encontrados ${majors.length}.`);
  WORLD.relations.forEach((r,i)=>{if(!nodeMap.has(r.from)||!nodeMap.has(r.to))errors.push(`Relação ${i} aponta para nó inexistente.`);});
  SOCIETAS_SEQUENCE.forEach((p,i)=>{const ids=p.reveal==='all'?[]:p.reveal||[];ids.forEach(id=>{if(!nodeMap.has(id))errors.push(`Fase ${p.code||i} referencia nó inexistente: ${id}`);});if(p.focus&&!nodeMap.has(p.focus))errors.push(`Fase ${p.code||i} foca nó inexistente: ${p.focus}`);});
  ['assiah','yetzirah','briah','atziluth'].forEach(id=>{if(!WORLD.fourWorlds?.some(w=>w.id===id))errors.push(`Lente ausente: ${id}`);});
  return {ok:errors.length===0,errors,checkedAt:new Date().toISOString(),technicalVersion:WORLD.technical?.version||'unknown'};
}
function renderFatal(errors){
  document.body.innerHTML=`<main style="min-height:100vh;display:grid;place-items:center;background:#05070b;color:#e9edf5;font-family:'IBM Plex Sans',sans-serif;padding:24px"><section style="max-width:680px;border:1px solid rgba(240,207,131,.25);padding:24px;border-radius:16px;background:#080b11"><small style="color:#c7a96b;letter-spacing:.16em">MUNDUS · SOCIETAS · SELF-CHECK</small><h1 style="font-family:'Space Grotesk',sans-serif">O mundo recusou uma versão incoerente.</h1><p style="color:#aeb8c4;line-height:1.6">Nenhum renderer deve esconder um erro de cânone. A versão permaneceu fechada até correção.</p><pre style="white-space:pre-wrap;color:#f0cf83;font-size:11px">${esc(errors.join('\n'))}</pre></section></main>`;
}
function kindLabel(n){return ({institution:'INSTITUIÇÃO',tree:'ÁRVORE',stage:'ETAPA',period:'PERÍODO',clavis:'CLAVIS DO UMBRAL',cycle:'CICLO XI',degree:'GRAU',system:'SISTEMA',work:'OBRA TRANSVERSAL',gate:'PORTÃO DE PASSAGEM',competency:'COMPETÊNCIA',module:'MÓDULO',pergaminho_maior:'PERGAMINHO MAIOR'})[n.kind]||String(n.kind||'NÓ').toUpperCase();}
function statusLabel(n){if(n.status==='veiled')return 'VELADA · ESPECTRAL';if(n.status==='preparatory')return 'PREPARATÓRIA · NÃO É GRAU';if(n.status==='degree_1')return 'GRAU I';if(n.status==='present')return 'PRESENTE NA UX';if(n.status==='student')return 'ETAPA DO ESTUDANTE';if(n.status==='transversal')return 'TRANSVERSAL';if(n.status==='peregrinus')return 'PEREGRINUS IGNIS';return String(n.status||'CANÔNICO').replaceAll('_',' ').toUpperCase();}
function relatedNodes(id){return WORLD.relations.filter(r=>r.from===id||r.to===id).map(r=>({relation:r,node:nodeMap.get(r.from===id?r.to:r.from),direction:r.from===id?'out':'in'})).filter(x=>x.node);}
function currentPhase(){return SOCIETAS_SEQUENCE[state.phase]||SOCIETAS_SEQUENCE[0];}

function readChronica(){
  try{
    const current=JSON.parse(localStorage.getItem(CHRONICA_KEY)||'[]');
    if(current.length)return current;
    const legacy=JSON.parse(localStorage.getItem(LEGACY_CHRONICA_KEY)||'[]');
    return Array.isArray(legacy)?legacy:[];
  }catch{return []}
}
function writeChronica(entry){const rows=readChronica();rows.unshift({at:Date.now(),world:'societas',...entry});if(rows.length>180)rows.length=180;localStorage.setItem(CHRONICA_KEY,JSON.stringify(rows));}
function persist(){
  try{localStorage.setItem(STATE_KEY,JSON.stringify({guided:state.guided,phase:state.phase,mode:state.mode,lens:state.lens,selected:state.selected,visited:[...state.visited],cameraMode:state.cameraMode,audio:state.audio,narration:state.narration}));}catch{}
}
function restore(){try{const x=JSON.parse(localStorage.getItem(STATE_KEY)||'null');if(!x)return;state.guided=x.guided!==false;state.phase=Math.max(0,Math.min(SOCIETAS_SEQUENCE.length-1,Number(x.phase)||0));state.mode=WORLD.modes?.includes(x.mode)?x.mode:'mapa';state.lens=WORLD.fourWorlds?.some(w=>w.id===x.lens)?x.lens:null;state.selected=nodeMap.has(x.selected)?x.selected:null;state.visited=new Set((Array.isArray(x.visited)?x.visited:[]).filter(id=>nodeMap.has(id)));state.cameraMode=['auto','orbit','free'].includes(x.cameraMode)?x.cameraMode:'auto';state.audio=x.audio!==false;state.narration=x.narration!==false;}catch{}}

class Atmosphere{
  constructor(){this.ctx=null;this.master=null;this.started=false;}
  async start(){if(this.started)return;try{this.ctx=new (window.AudioContext||window.webkitAudioContext)();this.master=this.ctx.createGain();this.master.gain.value=.018;this.master.connect(this.ctx.destination);const filter=this.ctx.createBiquadFilter();filter.type='lowpass';filter.frequency.value=360;filter.Q.value=.7;filter.connect(this.master);this.oscs=[55,82.5,110].map((f,i)=>{const o=this.ctx.createOscillator(),g=this.ctx.createGain();o.type=i===0?'sine':'triangle';o.frequency.value=f;g.gain.value=i===0?.34:.09;o.connect(g);g.connect(filter);o.start();return {o,g};});this.started=true;}catch{this.started=false;}}
  setLens(id){if(!this.started)return;const base={assiah:48,yetzirah:61,briah:73,atziluth:88}[id]||55;this.oscs.forEach((x,i)=>x.o.frequency.setTargetAtTime(base*(i===0?1:i===1?1.5:2),this.ctx.currentTime,.8));}
  setEnabled(on){if(this.master)this.master.gain.setTargetAtTime(on?.018:0,this.ctx.currentTime,.25);}
}
const atmosphere=new Atmosphere();

function speak(text){
  if(!state.narration||!('speechSynthesis' in window)||!text)return;
  speechSynthesis.cancel();const u=new SpeechSynthesisUtterance(text);u.lang='pt-BR';u.rate=.9;u.pitch=.88;u.volume=.82;
  const voices=speechSynthesis.getVoices();const pt=voices.find(v=>/^pt-BR/i.test(v.lang))||voices.find(v=>/^pt/i.test(v.lang));if(pt)u.voice=pt;speechSynthesis.speak(u);
}
function stopSpeak(){if('speechSynthesis' in window)speechSynthesis.cancel();}

function buildShell(){
  const back=MEMBER_BRIDGE?.backHref||'/mundus.html';
  document.body.innerHTML=`<main class="sw3d-shell" id="sw3d-shell">
    <section class="sw3d-world" id="sw3d-world" aria-label="Mundo tridimensional da SOCIETAS ELECTORUM"></section>
    <header class="sw3d-top">
      <a class="sw3d-brand" href="${esc(back)}"><span class="sw3d-sigil"></span><span><b>MUNDUS</b><small>${esc(MEMBER_BRIDGE?'SOCIETAS · SESSÃO VERIFICADA':'WORLD 02 · SOCIETAS')}</small></span></a>
      <div class="sw3d-phase"><small id="phase-code">T0 · GUIADO</small><b id="phase-title">ANTES DA ARQUITETURA</b></div>
      <div class="sw3d-tools"><button id="search-toggle" aria-label="Pesquisar">⌕</button><button id="audio-toggle" aria-label="Áudio">◉</button><button id="home-btn" aria-label="Visão geral">◎</button></div>
    </header>
    <div class="sw3d-search" id="search-box"><input id="search-input" placeholder="Localizar Árvore, etapa, Grau ou Pergaminho…" autocomplete="off"><div id="search-results"></div></div>
    <aside class="sw3d-story" id="story-card"><small id="story-kicker">MUNDUS · SOCIETAS</small><h1 id="story-title">ANTES DA ARQUITETURA</h1><p id="story-caption"></p><button id="story-min" aria-label="Recolher narrativa">−</button></aside>
    <aside class="sw3d-panel" id="node-panel" aria-hidden="true"><header><div><small id="panel-kind">NÓ CANÔNICO</small><h2 id="panel-title"></h2></div><button id="panel-close" aria-label="Fechar">×</button></header><div id="panel-body"></div></aside>
    <section class="sw3d-timeline" aria-label="Linha temporal do mundo">
      <div class="sw3d-play"><button id="prev-phase" aria-label="Anterior">‹</button><button id="play-btn" aria-label="Reproduzir ou pausar">▶</button><button id="next-phase" aria-label="Próximo">›</button></div>
      <input id="phase-range" type="range" min="0" max="${SOCIETAS_SEQUENCE.length-1}" value="0" step="1" aria-label="Fase do mundo">
      <div class="sw3d-speed"><button data-speed="1" class="active">1×</button><button data-speed="3">3×</button><button data-speed="8">8×</button></div>
    </section>
    <footer class="sw3d-bottom">
      <div class="sw3d-lenses"><button data-lens="assiah">ASSIAH</button><button data-lens="yetzirah">YETZIRAH</button><button data-lens="briah">BRIAH</button><button data-lens="atziluth">ATZILUTH</button></div>
      <nav class="sw3d-modes"><button data-mode="mapa">MAPA</button><button data-mode="orbita">ÓRBITA</button><button data-mode="foco">FOCO</button><button data-mode="caminho">CAMINHO</button><button data-mode="comparacao">COMPARAÇÃO</button><button data-mode="comunhao">COMUNHÃO</button><button data-mode="praxis">PRAXIS</button><button data-mode="chronica">CHRONICA</button></nav>
      <div class="sw3d-cameras"><button data-camera="auto">AUTO</button><button data-camera="orbit">ÓRBITA</button><button data-camera="free">LIVRE</button></div>
    </footer>
    <div class="sw3d-lens-note" id="lens-note"></div>
    <div class="sw3d-modal" id="modal"><section><header><div><small id="modal-kicker">MUNDUS · SOCIETAS</small><h2 id="modal-title"></h2></div><button id="modal-close">×</button></header><div id="modal-body"></div></section></div>
    <div class="sw3d-onboarding" id="onboarding"><div class="sw3d-onboarding-core"><small>${esc(MEMBER_BRIDGE?'MUNDUS · SOCIETAS · SESSÃO VERIFICADA':'MUNDUS · WORLD 02')}</small><h1>ENTRE NA<br><span>ARQUITETURA.</span></h1><p>A SOCIETAS ELECTORUM será manifestada como território tridimensional, sequência causal e sistema interrogável. O mundo ensina relações; a passagem real continua pertencendo ao currículo, à prática e à evidência.</p><div class="sw3d-enter-actions"><button id="enter-guided">PERCURSO GUIADO</button><button id="enter-free">EXPLORAR LIVREMENTE</button></div><div class="sw3d-onboard-rule"><b>REGRA</b> · ver não é concluir · navegar não é incorporar · compreender ainda precisa ser demonstrado</div></div></div>
    <div class="sw3d-loading" id="loading"><b>MUNDUS · SOCIETAS</b><span>Inicializando World Package 3D · MET-MUNDUS-001</span></div>
  </main>`;
}

let renderer;
function boot(){
  restore();buildShell();
  renderer=new SocietasRenderer3D($('#sw3d-world'),{onSelect:selectNode});renderer.setManifest(WORLD);renderer.setCameraMode(state.cameraMode);renderer.setLens(state.lens);
  bind();applyPhase(state.phase,{narrate:false,record:false});setMode(state.mode,{silent:true});setLens(state.lens,{silent:true});updateStatusUI();
  if(localStorage.getItem(START_KEY)==='1'){state.started=true;$('#onboarding').classList.add('hidden');}
  requestAnimationFrame(()=>$('#loading').classList.add('hidden'));
  requestAnimationFrame(tick);
  window.MUNDUS_WORLD={manifest:WORLD,sequence:SOCIETAS_SEQUENCE,renderer,getState:()=>({...state,visited:[...state.visited]}),focus:selectNode,setMode,setLens,setPhase:i=>applyPhase(i),selfTest:validateWorldPackage};
}

function visibleForCurrent(){return state.guided?sequenceVisibleIds(state.phase,WORLD):WORLD.nodes.filter(n=>!n.hiddenByDefault).map(n=>n.id);}
function applyPhase(index,{narrate=true,record=true}={}){
  state.phase=Math.max(0,Math.min(SOCIETAS_SEQUENCE.length-1,Number(index)||0));state.phaseElapsed=0;const p=currentPhase();
  renderer.setVisible(visibleForCurrent());renderer.setCameraPreset(p.camera);const initialTreeProgress=Array.isArray(p.treeProgress)?p.treeProgress[0]:null;renderer.setCinematicPhase?.(p.id,0,initialTreeProgress);if(p.focus&&!String(p.id).startsWith('vitae-'))renderer.focus(p.focus,{distance:p.id==='degree1'?8:7});else renderer.setSelected(null);
  $('#phase-range').value=String(state.phase);$('#phase-code').textContent=`${p.code} · ${state.guided?'GUIADO':'LIVRE'}`;$('#phase-title').textContent=p.title;$('#story-title').textContent=p.title;$('#story-caption').textContent=p.caption;
  if(narrate)speak(p.narration);if(record)writeChronica({type:'phase',phase:p.id,text:`Fase manifestada: ${p.code} · ${p.title}.`});persist();
}
const THREE_CLAMP=v=>Math.max(0,Math.min(1,Number(v)||0));
function tick(now){const dt=Math.min(.1,(now-state.lastTick)/1000);state.lastTick=now;if(state.playing&&state.guided){state.phaseElapsed+=dt*state.speed;const p=currentPhase();const q=THREE_CLAMP(state.phaseElapsed/Math.max(.001,p.duration));let treeP=null;if(Array.isArray(p.treeProgress)){treeP=p.treeProgress[0]+(p.treeProgress[1]-p.treeProgress[0])*q;}renderer.setCinematicPhase?.(p.id,q,treeP);if(state.phaseElapsed>=p.duration){if(state.phase<SOCIETAS_SEQUENCE.length-1)applyPhase(state.phase+1);else{state.playing=false;$('#play-btn').textContent='▶';}}}requestAnimationFrame(tick);}
function togglePlay(){state.playing=!state.playing;if(state.playing&&!state.guided){state.guided=true;applyPhase(state.phase,{narrate:false});}$('#play-btn').textContent=state.playing?'Ⅱ':'▶';if(state.playing)speak(currentPhase().narration);else stopSpeak();persist();}

function recordVisit(n){if(state.visited.has(n.id))return;state.visited.add(n.id);writeChronica({type:'focus',nodeId:n.id,text:`Foco aberto: ${n.title}.`});persist();}
function selectNode(id){const n=nodeMap.get(id);if(!n)return;if(state.mode==='comparacao')return toggleCompare(n);state.selected=id;recordVisit(n);renderer.setSelected(id);renderer.focus(id,{distance:n.kind==='institution'?8:n.kind==='pergaminho_maior'?5.5:6.5});openPanel(n);if(state.mode==='comunhao')openCommunion(n);if(state.mode==='praxis')openPraxis(n);persist();}
function openPanel(n){
  const lens=state.lens?WORLD.fourWorlds.find(x=>x.id===state.lens):null,rels=relatedNodes(n.id),veiled=n.status==='veiled';
  $('#panel-kind').textContent=`${kindLabel(n)} · ${statusLabel(n)}`;$('#panel-title').textContent=n.title;
  $('#panel-body').innerHTML=`<p>${esc(veiled?'Esta presença é localizada sem fabricar o que a fonte ainda mantém velado. O silêncio canônico é informação.':n.summary)}</p>
  <div class="sw3d-meta"><div><span>STATUS</span><b>${esc(statusLabel(n))}</b></div><div><span>FONTE GOVERNANTE</span><b>Currículo Vivo v2.13</b></div>${MEMBER_BRIDGE?`<div><span>SUA ETAPA</span><b>${esc(MEMBER_BRIDGE.currentStage||'estado autenticado')}</b></div><div><span>JORNADA</span><b>${esc(Number.isFinite(Number(MEMBER_BRIDGE.journeyPercent))?Math.round(Number(MEMBER_BRIDGE.journeyPercent))+'%':'sincronizada')}</b></div>`:''}</div>
  ${lens?`<section><h3>LENTE · ${esc(lens.title)}</h3><div class="sw3d-callout">Observe por ${esc(lens.meaning)}. A lente muda a pergunta, nunca o cânone.</div></section>`:''}
  <section><h3>RELAÇÕES</h3><div class="sw3d-relations">${rels.length?rels.map(x=>`<button data-related="${esc(x.node.id)}"><b>${x.direction==='out'?'→':'←'} ${esc(x.node.title)}</b><small>${esc(x.relation.type.replaceAll('_',' '))}</small></button>`).join(''):'<div class="sw3d-empty">Nenhuma relação adicional registrada nesta camada.</div>'}</div></section>
  <section><h3>PROVENIÊNCIA</h3><div class="sw3d-callout">World Package SOCIETAS · MET-MUNDUS-001 · fonte curricular v2.13 + precedência multi-mundos vigente. O renderer não pode completar lacunas doutrinárias por conveniência visual.</div></section>
  ${n.id==='estudante'?'<section><h3>REGRA DE PROGRESSÃO</h3><div class="sw3d-callout">Estudante é etapa preparatória. 99 dias é mínimo estrutural, não promoção automática. Eixo de evidência: RECUPERAÇÃO → DISCRIMINAÇÃO → TRANSFERÊNCIA → OBRA.</div></section>':''}
  ${n.kind==='degree'?'<section><h3>REGRA DE GRAU</h3><div class="sw3d-callout">XP, streak, clique, compra, posse de conta, tempo de tela ou exploração integral deste mundo não promovem Grau.</div></section>':''}`;
  $$('[data-related]').forEach(b=>b.onclick=()=>selectNode(b.dataset.related));$('#node-panel').classList.add('open');$('#node-panel').setAttribute('aria-hidden','false');
}
function closePanel(){$('#node-panel').classList.remove('open');$('#node-panel').setAttribute('aria-hidden','true');}

function setMode(mode,{silent=false}={}){
  state.mode=mode||'mapa';$$('[data-mode]').forEach(b=>b.classList.toggle('active',b.dataset.mode===state.mode));renderer.setComparison([]);
  if(state.mode==='orbita')renderer.setCameraMode('orbit');else if(state.cameraMode!=='orbit')renderer.setCameraMode(state.cameraMode);
  if(state.mode==='mapa'){closePanel();renderer.setSelected(null);state.selected=null;}
  if(state.mode==='caminho')openPath();
  if(state.mode==='comparacao'&&!silent)showModal('COMPARAÇÃO','DISTINGUIR SEM FUNDIR','<p>Selecione dois elementos no mundo. O MUNDUS colocará função, status e relações lado a lado sem fingir equivalência.</p>');
  if(state.mode==='comunhao'&&!state.selected&&!silent)showModal('COMUNHÃO','ESCOLHA UM INTERLOCUTOR','<p>Selecione um nó. Nesta implementação, a resposta permanece ligada ao manifest canônico local e declara limites em vez de improvisar autoridade.</p>');
  if(state.mode==='praxis'&&!state.selected&&!silent)showModal('PRAXIS','ESCOLHA UM OBJETO','<p>Selecione um nó para atravessar da compreensão visual para prática, registro, integração e verificação.</p>');
  if(state.mode==='chronica')openChronica();persist();
}
function openPath(){
  const ids=['estudante','periodo-1','clavis-1','xi-1','xi-2','xi-3','periodo-2','clavis-2','xi-4','xi-5','xi-6','periodo-3','clavis-3','xi-7','xi-8','xi-9','exame-peregrinus','peregrinus-ignis'];renderer.setVisible(ids.filter(id=>nodeMap.has(id)));renderer.setCameraPreset('periods');
  showModal('CAMINHO','ESTUDANTE → PEREGRINUS IGNIS','<div class="sw3d-callout">O caminho mostra ordem e portões. Ele não executa promoção automática.</div><div class="sw3d-path"><b>PERÍODO I · REGÊNCIA</b><span>XI·1–XI·3 ↔ CLAVIS I · O OLHO · VER</span><b>PERÍODO II · DISCERNIMENTO</b><span>XI·4–XI·6 ↔ CLAVIS II · A CHAMA · GOVERNAR</span><b>PERÍODO III · OBRA</b><span>XI·7–XI·9 ↔ CLAVIS III · A OBRA · FAZER</span><b>EXAME DE PASSAGEM</b><span>competência + autoria + ética + evidência</span><b>PEREGRINUS IGNIS</b><span>Grau I após decisão documentada</span></div>');
}

function toggleCompare(n){const i=state.compare.indexOf(n.id);if(i>=0)state.compare.splice(i,1);else if(state.compare.length<2)state.compare.push(n.id);else state.compare=[state.compare[1],n.id];renderer.setComparison(state.compare);if(state.compare.length===2)openComparison(state.compare.map(id=>nodeMap.get(id)));}
function openComparison([a,b]){const col=n=>`<article><small>${esc(kindLabel(n))}</small><h3>${esc(n.title)}</h3><p>${esc(n.status==='veiled'?'Conteúdo velado; somente posição e função autorizadas.':n.summary)}</p><div class="sw3d-meta"><div><span>STATUS</span><b>${esc(statusLabel(n))}</b></div><div><span>RELAÇÕES</span><b>${relatedNodes(n.id).length}</b></div></div></article>`;showModal('COMPARAÇÃO','DOIS OBJETOS · DUAS FUNÇÕES',`<div class="sw3d-compare">${col(a)}${col(b)}</div><div class="sw3d-callout">Comparar não significa fundir. A diferença é parte da arquitetura.</div>`);writeChronica({type:'comparison',text:`Comparação: ${a.title} ↔ ${b.title}.`});}

function setLens(id,{silent=false}={}){state.lens=state.lens===id&&!silent?null:id;renderer.setLens(state.lens);atmosphere.setLens(state.lens);$$('[data-lens]').forEach(b=>b.classList.toggle('active',b.dataset.lens===state.lens));const note=$('#lens-note');if(state.lens){const w=WORLD.fourWorlds.find(x=>x.id===state.lens);note.textContent=`${w.title} · ${w.meaning}`;note.classList.add('show');if(!silent)writeChronica({type:'lens',text:`Lente ativada: ${w.title}.`});}else{note.textContent='';note.classList.remove('show');}if(state.selected)openPanel(nodeMap.get(state.selected));persist();}

function openCommunion(n){showModal('COMUNHÃO',n.title,`<p>${esc(n.status==='veiled'?'Minha presença pode ser localizada, mas meu conteúdo permanece velado nesta camada. O silêncio canônico vale mais que uma resposta inventada.':n.summary)}</p><div class="sw3d-questions"><button data-q="role">QUAL É A SUA FUNÇÃO?</button><button data-q="rel">COM O QUE VOCÊ SE RELACIONA?</button><button data-q="proof">COMO ISSO SE VERIFICA?</button><button data-q="limit">O QUE VOCÊ NÃO PODE AFIRMAR?</button></div><div id="communion-answer"></div>`);$$('[data-q]').forEach(b=>b.onclick=()=>answerCommunion(n,b.dataset.q));writeChronica({type:'communion',nodeId:n.id,text:`Comunhão aberta com ${n.title}.`});}
function answerCommunion(n,q){const rel=relatedNodes(n.id);let text='';if(q==='role')text=n.status==='veiled'?'Sou uma presença velada. Minha posição pode ser ensinada, mas meu conteúdo detalhado não é preenchido por inferência.':n.summary;if(q==='rel')text=rel.map(x=>`${x.direction==='out'?'→':'←'} ${x.node.title}: ${x.relation.type.replaceAll('_',' ')}`).join('\n')||'Nenhuma relação adicional registrada.';if(q==='proof')text='No Método MUNDUS, ver não basta. Verificação exige reconstrução conceitual, discriminação, transferência, praxis e evidência quando a fonte curricular exigir.';if(q==='limit')text='Não posso converter hipótese em cânone, preencher o que está velado, fundir tradições silenciosamente nem conceder Grau por atividade de interface.';$('#communion-answer').innerHTML=`<div class="sw3d-callout">${esc(text).replaceAll('\n','<br>')}</div>`;}
function openPraxis(n){showModal('PRAXIS',`PRÁTICA · ${n.title}`,`<p>${esc(n.status==='veiled'?'Nenhuma prática velada é exposta por este World Package.':'A compreensão do objeto precisa atravessar a tela e adquirir consequência verificável.')}</p><div class="sw3d-callout"><b>Explorar, assistir, clicar ou permanecer aqui não conclui etapa, Pergaminho ou Grau.</b></div><div class="sw3d-praxis"><span>1</span><b>PRAXIS</b><p>execute a ação correspondente no currículo real</p><span>2</span><b>REGISTRO</b><p>produza memória auditável e proveniência</p><span>3</span><b>INTEGRAÇÃO</b><p>reconstrua relações sem depender da interface</p><span>4</span><b>VERIFICAÇÃO</b><p>demonstre recuperação, discriminação, transferência e Obra</p><span>5</span><b>CONTINUIDADE</b><p>retome do contexto preservado</p></div>`);writeChronica({type:'praxis',nodeId:n.id,text:`Praxis consultada para ${n.title}.`});}
function openChronica(){const rows=readChronica();showModal('CHRONICA','PERCURSO NESTE MUNDO',`<div class="sw3d-chronica">${rows.length?rows.map(r=>`<article><time>${new Date(r.at).toLocaleString('pt-BR')}</time><p>${esc(r.text)}</p></article>`).join(''):'<div class="sw3d-empty">A Chronica ainda está vazia. Ela registra o percurso, não transforma interface em iniciação.</div>'}</div>`);}

function showModal(k,t,b){$('#modal-kicker').textContent=k;$('#modal-title').textContent=t;$('#modal-body').innerHTML=b;$('#modal').classList.add('open');}
function closeModal(){$('#modal').classList.remove('open');if(state.mode==='caminho')renderer.setVisible(visibleForCurrent());}
function search(q){q=String(q||'').trim().toLowerCase();const box=$('#search-results');if(!q){box.classList.remove('show');box.innerHTML='';return;}const rows=WORLD.nodes.filter(n=>!n.hiddenByDefault&&`${n.title} ${n.kind} ${n.summary}`.toLowerCase().includes(q)).slice(0,9);box.innerHTML=rows.map(n=>`<button data-search-node="${esc(n.id)}"><b>${esc(n.title)}</b><small>${esc(kindLabel(n))} · ${esc(statusLabel(n))}</small></button>`).join('');box.classList.toggle('show',!!rows.length);$$('[data-search-node]').forEach(b=>b.onclick=()=>{box.classList.remove('show');selectNode(b.dataset.searchNode);});}

function setCamera(mode){state.cameraMode=mode;renderer.setCameraMode(mode);$$('[data-camera]').forEach(b=>b.classList.toggle('active',b.dataset.camera===mode));persist();}
function recenter(){renderer.setVisible(visibleForCurrent());renderer.setSelected(null);renderer.setComparison([]);renderer.setCameraPreset(state.guided?currentPhase().camera:'integration');state.selected=null;state.compare=[];closePanel();}
function updateStatusUI(){$$('[data-mode]').forEach(b=>b.classList.toggle('active',b.dataset.mode===state.mode));$$('[data-camera]').forEach(b=>b.classList.toggle('active',b.dataset.camera===state.cameraMode));$$('[data-lens]').forEach(b=>b.classList.toggle('active',b.dataset.lens===state.lens));}

async function enter(guided){state.started=true;state.guided=guided;localStorage.setItem(START_KEY,'1');$('#onboarding').classList.add('hidden');await atmosphere.start();atmosphere.setEnabled(state.audio);if(guided){state.phase=0;state.playing=true;applyPhase(0,{narrate:true});$('#play-btn').textContent='Ⅱ';writeChronica({type:'entry',text:'Entrada no percurso guiado 3D do MUNDUS · SOCIETAS.'});}else{state.phase=SOCIETAS_SEQUENCE.length-1;state.playing=false;applyPhase(state.phase,{narrate:false});renderer.setCameraPreset('integration');writeChronica({type:'entry',text:'Entrada em exploração livre 3D do MUNDUS · SOCIETAS.'});}persist();}
function toggleAudio(){state.audio=!state.audio;atmosphere.start().then(()=>atmosphere.setEnabled(state.audio));state.narration=state.audio;$('#audio-toggle').classList.toggle('active',state.audio);if(!state.audio)stopSpeak();persist();}

function bind(){
  $('#panel-close').onclick=closePanel;$('#modal-close').onclick=closeModal;$('#modal').onclick=e=>{if(e.target.id==='modal')closeModal();};
  $('#enter-guided').onclick=()=>enter(true);$('#enter-free').onclick=()=>enter(false);
  $('#play-btn').onclick=togglePlay;$('#prev-phase').onclick=()=>applyPhase(state.phase-1);$('#next-phase').onclick=()=>applyPhase(state.phase+1);$('#phase-range').oninput=e=>applyPhase(Number(e.target.value));
  $$('[data-speed]').forEach(b=>b.onclick=()=>{state.speed=Number(b.dataset.speed);$$('[data-speed]').forEach(x=>x.classList.toggle('active',x===b));});
  $$('[data-mode]').forEach(b=>b.onclick=()=>setMode(b.dataset.mode));$$('[data-lens]').forEach(b=>b.onclick=()=>setLens(b.dataset.lens));$$('[data-camera]').forEach(b=>b.onclick=()=>setCamera(b.dataset.camera));
  $('#home-btn').onclick=recenter;$('#audio-toggle').onclick=toggleAudio;$('#audio-toggle').classList.toggle('active',state.audio);
  $('#search-toggle').onclick=()=>{const box=$('#search-box');box.classList.toggle('open');if(box.classList.contains('open'))$('#search-input').focus();};$('#search-input').oninput=e=>search(e.target.value);
  $('#story-min').onclick=()=>$('#story-card').classList.toggle('min');
  window.addEventListener('keydown',e=>{if(e.target.matches('input,textarea'))return;if(e.key==='Escape'){closeModal();closePanel();}if(e.key===' '){e.preventDefault();togglePlay();}if(e.key==='ArrowRight')applyPhase(state.phase+1);if(e.key==='ArrowLeft')applyPhase(state.phase-1);});
  document.addEventListener('visibilitychange',()=>{if(document.hidden)persist();});window.addEventListener('beforeunload',persist);
}

const WORLD_CHECK=validateWorldPackage();
if(!WORLD_CHECK.ok){
  console.error('[MUNDUS · SOCIETAS] world package recusado',WORLD_CHECK.errors);
  renderFatal(WORLD_CHECK.errors);
}else if(window.MUNDUS_SOCIETAS_DISABLE_3D){
  console.warn('[MUNDUS · SOCIETAS] boot 3D cancelado pelo watchdog; aguardando runtime compatível.');
}else if(!supportsWebGL()){
  document.body.innerHTML='<div style="min-height:100vh;display:grid;place-items:center;background:#05070b;color:#e9edf5;font-family:IBM Plex Sans,sans-serif;padding:24px;text-align:center"><div><b>MUNDUS · SOCIETAS</b><p>O dispositivo não expôs WebGL. Carregando a representação compatível.</p></div></div>';
  import('./runtime.js?v=20260905-canonical-v1');
}else{
  boot();
}
