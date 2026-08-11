/* H93-OF-001 V9.3 — correções resilientes de estado e navegação */
(function(){
  'use strict';
  window.applyH93V9StateFixes=function(html){
    html=html.replace(/<title>[^<]*Oráculo Financeiro de THOTH[^<]*<\/title>/i,'<title>Oráculo Financeiro de THOTH — V9.3</title>');

    /*
      Chave nova para curar automaticamente estados produzidos pelas V9/V9.2.
      O fluxo real tem 28 telas, indexadas de 0 a 27.
    */
    const stateBlock=/const (?:STATE_KEY='H93_OF_001_V9(?:_2)?_STATE';[\s\S]*?)?initial=\(\)=>\(\{(?:version:(?:9|'9\.2'),)?step:0[\s\S]*?function reset\(\)\{[\s\S]*?render\(\)\}/;
    const stateReplacement=`const STATE_KEY='H93_OF_001_V9_3_STATE';
const OLD_STATE_KEYS=['H93_OF_001_V9_2_STATE','H93_OF_001_V9_STATE','h93of001v8','h93of001v7','h93of001','H93_OF_001_STATE'];
const initial=()=>({version:'9.3',step:0,answers:{},spread:[],card:null,lead:{},product:null,bumps:[],payment:null,upsells:[],downsell:false,postStage:'magnet',utm:{}});
let state=initial();
function validStep(n){return Number.isInteger(n)&&n>=0&&n<STEPS.length}
function normalizeState(x){
  const next={...initial(),...(x||{}),version:'9.3',bumps:x?.bumps||[],upsells:x?.upsells||[]};
  if(!validStep(next.step))next.step=0;
  if(!Array.isArray(next.spread))next.spread=[];
  if(next.card&&(!next.spread.length||!next.spread.some(c=>c&&c.id===next.card.id)))next.card=null;
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
    else if(!html.includes('H93_OF_001_V9_3_STATE')) console.warn('[H93 V9.3] bloco de estado não localizado');

    /*
      IMPORTANTE: substituir SOMENTE a função jump antiga.
      A versão anterior usava um regex amplo que atravessava funções seguintes
      até encontrar outro window.scrollTo e removia profile(), answer(),
      qScreen(), chooseCard() e outras funções essenciais.
    */
    const oldJump="function jump(n){state.step=Math.max(0,Math.min(STEPS.length-1,Number(n)||0));if(state.step>=26&&!state.product)state.product=PRODUCTS[recommendation()];if(state.step>=21&&!state.card)state.card=state.spread[0]||CARDS[0];render()}";
    const safeJump="function jump(n){n=Number(n);if(!Number.isFinite(n))n=0;n=Math.max(0,Math.min(Math.trunc(n),STEPS.length-1));state.step=n;if(state.step>=17)ensureSpread();if(state.step>=8&&!state.card){const review=new URLSearchParams(location.search).has('step');if(review){state.card=state.spread[0]||CARDS[0]}else{state.step=7;save();render();return}}if(state.step>=26&&!state.product){state.step=25;save();render();return}save();render();window.scrollTo({top:0,behavior:'smooth'})}";
    if(html.includes(oldJump)) html=html.replace(oldJump,safeJump);
    else if(!html.includes('Math.min(Math.trunc(n),STEPS.length-1)')) console.warn('[H93 V9.3] jump antigo não localizado');

    /* Defesa final: um estado corrompido nunca deve produzir painel vazio. */
    const renderOld="function render(){ensureSpread();updatePhase();const p=profile();const rec=recommendation();let h='';";
    const renderSafe="function render(){if(!validStep(state.step)){state=initial();ensureSpread();save()}if(state.step>=8&&!state.card)state.step=7;if(state.step>=26&&!state.product)state.step=25;ensureSpread();updatePhase();const p=profile();const rec=recommendation();let h='';";
    if(html.includes(renderOld)) html=html.replace(renderOld,renderSafe);

    return html;
  };
})();
