/* H93-OF-001 V9.5 — estado, DOM, navegação e tiragem de cartas resilientes */
(function(){
  'use strict';
  window.applyH93V9StateFixes=function(html){
    html=html.replace(/<title>[^<]*Oráculo Financeiro de THOTH[^<]*<\/title>/i,'<title>Oráculo Financeiro de THOTH — V9.5</title>');

    const stateBlock=/const (?:STATE_KEY='H93_OF_001_V9(?:_[234])?_STATE';[\s\S]*?)?initial=\(\)=>\(\{(?:version:(?:9|'9\.[234]'),)?step:0[\s\S]*?function reset\(\)\{[\s\S]*?render\(\)\}/;
    const stateReplacement=`const STATE_KEY='H93_OF_001_V9_5_STATE';
const OLD_STATE_KEYS=['H93_OF_001_V9_4_STATE','H93_OF_001_V9_3_STATE','H93_OF_001_V9_2_STATE','H93_OF_001_V9_STATE','h93of001v8','h93of001v7','h93of001','H93_OF_001_STATE'];
const initial=()=>({version:'9.5',step:0,answers:{},spread:[],card:null,cardPos:null,lead:{},product:null,bumps:[],payment:null,upsells:[],downsell:false,postStage:'magnet',utm:{}});
let state=initial();
const app=document.getElementById('app'),progress=document.getElementById('progress'),phase=document.getElementById('phase');
function validStep(n){return Number.isInteger(n)&&n>=0&&n<STEPS.length}
function normalizeState(x){
  const next={...initial(),...(x||{}),version:'9.5',bumps:x?.bumps||[],upsells:x?.upsells||[]};
  if(!validStep(next.step))next.step=0;
  if(!Array.isArray(next.spread))next.spread=[];
  if(next.card&&(!next.spread.length||!next.spread.some(c=>c&&c.id===next.card.id)))next.card=null;
  if(next.step===7){next.card=null;next.cardPos=null;}
  if(next.step>=8&&!next.card)next.step=7;
  if(next.step>=26&&!next.product)next.step=25;
  return next;
}
function save(){try{localStorage.setItem(STATE_KEY,JSON.stringify(state))}catch(e){}}
function restore(){
  try{
    const raw=localStorage.getItem(STATE_KEY);
    if(!raw){OLD_STATE_KEYS.forEach(k=>localStorage.removeItem(k));state=initial();return}
    state=normalizeState(JSON.parse(raw));
    save();
  }catch(e){state=initial();save()}
}
function reset(){[STATE_KEY,...OLD_STATE_KEYS].forEach(k=>localStorage.removeItem(k));state=initial();ensureSpread();save();render()}`;
    if(stateBlock.test(html)) html=html.replace(stateBlock,stateReplacement);
    else if(!html.includes('H93_OF_001_V9_5_STATE')) console.warn('[H93 V9.5] bloco de estado não localizado');

    const oldEnsure="function ensureSpread(){if(!state.spread.length)state.spread=[...CARDS].sort(()=>Math.random()-.5).slice(0,3)}";
    const cardRuntime=`function freshSpread(){
  const pool=[...CARDS];
  for(let i=pool.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[pool[i],pool[j]]=[pool[j],pool[i]]}
  state.spread=pool.slice(0,3);state.card=null;state.cardPos=null;
}
function ensureSpread(){
  const valid=Array.isArray(state.spread)&&state.spread.length===3&&new Set(state.spread.map(c=>c&&c.id)).size===3&&state.spread.every(c=>c&&CARDS.some(k=>k.id===c.id));
  if(!valid)freshSpread();
}
function beginCardSelection(){freshSpread();state.step=7;save();render();window.scrollTo({top:0,behavior:'smooth'})}`;
    if(html.includes(oldEnsure)) html=html.replace(oldEnsure,cardRuntime);
    else if(!html.includes('function beginCardSelection(){')) console.warn('[H93 V9.5] ensureSpread antigo não localizado');

    const oldChoose=/function chooseCard\(id,pos\)\{\s*if\(state\.card\)return;\s*state\.card=CARDS\.find\(c=>c\.id===id\);\s*state\.cardPos=pos;\s*save\(\);\s*const cards=\[\.\.\.document\.querySelectorAll\('\.flip-card'\)\];\s*cards\.forEach\(\(el,i\)=>i===pos\?el\.classList\.add\('selected'\):el\.classList\.add\('dim'\)\);\s*setTimeout\(\(\)=>next\(\),900\);\s*\}/;
    const safeChoose=`function chooseCard(id,pos){
  pos=Number(pos);
  if(state.step!==7||state.card||!Number.isInteger(pos)||pos<0||pos>=state.spread.length)return;
  const chosen=state.spread[pos];
  if(!chosen||chosen.id!==id)return;
  state.card=chosen;state.cardPos=pos;save();
  const cards=[...document.querySelectorAll('.flip-card')];
  cards.forEach((el,i)=>{el.disabled=true;if(i===pos)el.classList.add('selected');else el.classList.add('dim')});
  setTimeout(()=>{
    if(state.step===7&&state.card&&state.card.id===id){state.step=8;save();render();window.scrollTo({top:0,behavior:'smooth'})}
  },950);
}`;
    if(oldChoose.test(html)) html=html.replace(oldChoose,safeChoose);
    else if(!html.includes("state.step===7&&state.card&&state.card.id===id")) console.warn('[H93 V9.5] chooseCard antigo não localizado');

    html=html.replace('onclick="next()">ESCOLHER ENTRE AS TRÊS CARTAS</button>','onclick="beginCardSelection()">ESCOLHER ENTRE AS TRÊS CARTAS</button>');
    html=html.replace('window.next=next;','window.next=next;window.beginCardSelection=beginCardSelection;');

    const oldJump="function jump(n){state.step=Math.max(0,Math.min(STEPS.length-1,Number(n)||0));if(state.step>=26&&!state.product)state.product=PRODUCTS[recommendation()];if(state.step>=21&&!state.card)state.card=state.spread[0]||CARDS[0];render()}";
    const safeJump="function jump(n){n=Number(n);if(!Number.isFinite(n))n=0;n=Math.max(0,Math.min(Math.trunc(n),STEPS.length-1));state.step=n;if(state.step>=17)ensureSpread();if(state.step===7){state.card=null;state.cardPos=null}if(state.step>=8&&!state.card){const review=new URLSearchParams(location.search).has('step');if(review){state.card=state.spread[0]||CARDS[0]}else{state.step=7;save();render();return}}if(state.step>=26&&!state.product){state.step=25;save();render();return}save();render();window.scrollTo({top:0,behavior:'smooth'})}";
    if(html.includes(oldJump)) html=html.replace(oldJump,safeJump);
    else if(!html.includes('if(state.step===7){state.card=null;state.cardPos=null}')) console.warn('[H93 V9.5] jump antigo não localizado');

    const renderOld="function render(){ensureSpread();updatePhase();const p=profile();const rec=recommendation();let h='';";
    const renderSafe="function render(){if(!validStep(state.step)){state=initial();ensureSpread();save()}if(state.step>=8&&!state.card)state.step=7;if(state.step>=26&&!state.product)state.step=25;ensureSpread();updatePhase();const p=profile();const rec=recommendation();let h='';";
    if(html.includes(renderOld)) html=html.replace(renderOld,renderSafe);

    const cardCss=`\n/* V9.5 · estabilidade de virada no Chromium/Opera e toque */\n.flip-card{touch-action:manipulation;-webkit-tap-highlight-color:transparent}\n.flip-card-inner{-webkit-transform-style:preserve-3d;transform-style:preserve-3d}\n.flip-face{-webkit-backface-visibility:hidden;backface-visibility:hidden}\n.flip-card.selected .flip-card-inner{-webkit-transform:rotateY(180deg);transform:rotateY(180deg)}\n.flip-card:disabled{cursor:default}\n`;
    html=html.replace('</style>',cardCss+'</style>');

    return html;
  };
})();
