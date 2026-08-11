/* H93-OF-001 V9 — correções resilientes de estado e navegação */
(function(){
  'use strict';
  window.applyH93V9StateFixes=function(html){
    html=html.replace(/<title>[^<]*Oráculo Financeiro de THOTH[^<]*<\/title>/i,'<title>Oráculo Financeiro de THOTH — V9</title>');

    const stateBlock=/const initial=\(\)=>\(\{step:0[\s\S]*?function reset\(\)\{localStorage\.removeItem\('h93of001v8'\);state=initial\(\);ensureSpread\(\);render\(\)\}/;
    const stateReplacement=`const STATE_KEY='H93_OF_001_V9_STATE';
const OLD_STATE_KEYS=['h93of001v8','h93of001v7','h93of001','H93_OF_001_STATE'];
const initial=()=>({version:9,step:0,answers:{},spread:[],card:null,lead:{},product:null,bumps:[],payment:null,upsells:[],downsell:false,postStage:'magnet',utm:{}});
let state=initial();
function save(){try{localStorage.setItem(STATE_KEY,JSON.stringify(state))}catch(e){}}
function restore(){try{const raw=localStorage.getItem(STATE_KEY);if(!raw){OLD_STATE_KEYS.forEach(k=>localStorage.removeItem(k));state=initial();return}const x=JSON.parse(raw);state={...initial(),...x,version:9,bumps:x?.bumps||[],upsells:x?.upsells||[]};if(state.card&&!state.spread.some(c=>c&&c.id===state.card.id))state.card=null}catch(e){state=initial()}}
function reset(){[STATE_KEY,...OLD_STATE_KEYS].forEach(k=>localStorage.removeItem(k));state=initial();ensureSpread();render()}`;
    if(stateBlock.test(html)) html=html.replace(stateBlock,stateReplacement);
    else if(!html.includes('H93_OF_001_V9_STATE')) console.warn('[H93 V9] bloco de estado não localizado');

    const jumpBlock=/function jump\(n\)\{[\s\S]*?window\.scrollTo\(\{top:0,behavior:'smooth'\}\)\}/;
    const jumpReplacement=`function jump(n){if(n>28)n=28;if(n<0)n=0;state.step=n;if(state.step>=17)ensureSpread();if(state.step>=21&&!state.card){const review=new URLSearchParams(location.search).has('step');if(review){state.card=state.spread[0]||CARDS[0]}else{alert('Escolha uma das três cartas antes de prosseguir.');state.step=7;save();render();return}}save();render();window.scrollTo({top:0,behavior:'smooth'})}`;
    if(jumpBlock.test(html)) html=html.replace(jumpBlock,jumpReplacement);
    else if(html.includes("if(state.step>=21&&!state.card)state.card=state.spread[0]||CARDS[0]")) console.warn('[H93 V9] jump antigo ainda presente');

    return html;
  };
})();
