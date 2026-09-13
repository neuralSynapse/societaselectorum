(function(root){'use strict';
const state={errors:[],warnings:[],checks:{},ready:false,lastCheck:0,release:'FUSÃO V4.2'};
function push(kind,msg,detail){const row={at:Date.now(),message:String(msg||kind),detail:detail?String(detail):''};state[kind].push(row);if(state[kind].length>24)state[kind].shift();render()}
function normalize(r){return typeof r==='object'&&r!==null&&'ok'in r?r:{ok:!!r}}
function check(name,fn){try{const r=normalize(fn());state.checks[name]={ok:!!r.ok,result:r};if(!r.ok)push('warnings',`CHECK ${name} FALHOU`,JSON.stringify(r));return !!r.ok}catch(e){state.checks[name]={ok:false,error:String(e?.message||e)};push('errors',`CHECK ${name} ERRO`,e?.stack||e);return false}}
function validate(){state.lastCheck=Date.now();state.checks={};
 check('progression',()=>root.CHRONICA_PROGRESSION?.validate?.()||{ok:false,reason:'módulo ausente'});
 check('angelic_host',()=>root.CHRONICA_ANGELIC_HOST?.validate?.()||{ok:false,reason:'módulo ausente'});
 check('encounter_canon',()=>root.CHRONICA_ENCOUNTER_CANON?.validate?.()||{ok:false,reason:'módulo ausente'});
 check('encounter_director',()=>root.CHRONICA_ENCOUNTER_DIRECTOR?.validate?.()||{ok:false,reason:'módulo ausente'});
 check('cain_rite',()=>root.CHRONICA_CAIN_RITE?.validate?.()||{ok:false,reason:'cain rite ausente'});
 check('encounter_manifest_gate',()=>{const d=root.CHRONICA_ENCOUNTER_DIRECTOR;if(!d)return{ok:false,reason:'director ausente'};let s=d.createManifestState?.(900,300,250,'qa');const a={manifest:{move:d.canMove(s),attack:d.canAttack(s),damage:d.canDamage?.(s)}};s=d.stepEncounterState(s,.95);a.read={phase:s.phase,move:d.canMove(s),attack:d.canAttack(s)};s=d.stepEncounterState(s,.25);a.chase={phase:s.phase,move:d.canMove(s),attack:d.canAttack(s)};return{ok:!a.manifest.move&&!a.manifest.attack&&!a.manifest.damage&&a.read.phase==='read'&&!a.read.move&&!a.read.attack&&a.chase.phase==='chase'&&a.chase.move&&!a.chase.attack,states:a}});
 check('performance',()=>root.CHRONICA_PERFORMANCE?.validate?.()||{ok:false,reason:'performance module ausente'});
 check('performance_live',()=>{const p=root.CHRONICA_PERFORMANCE;const s=p?.snapshot?.();return{ok:!!s&&['high','medium','low'].includes(s.tier)&&Number(s.profile?.aiHz)>0,snapshot:s}});
 check('performance_combat_lights',()=>root.CHRONICA_DIAGNOSTIC_POLICY?.validateCombatLightPolicy?.(root.CHRONICA_PERFORMANCE)||{ok:false,reason:'diagnostic light policy ausente'});
 check('traditional_rosters',()=>root.CHRONICA_TRADITIONAL_ROSTERS?.validate?.()||{ok:false,reason:'módulo ausente'});
 check('kinesis_initial',()=>{const k=root.CHRONICA_PARITY?.state?.kinesis||[];return{ok:k.length===3&&!k.filter(Boolean).length,value:k}});
 check('goetia_allied',()=>{const ids=root.CHRONICA_TRADITIONAL_ROSTERS?.goetiaAllies||[],bad=ids.filter(id=>root.CHRONICA_CANON?.entries?.[id]?.combatEligible!==false);return{ok:ids.length===72&&!bad.length,count:ids.length,bad}});
 check('cain_non_hostile',()=>{const a=root.CHRONICA_CANON?.entries?.cain_initiator;return{ok:!!a&&a.combatEligible===false&&a.alignment==='initiator'}});
 check('sabaoth_non_hostile',()=>{const a=root.CHRONICA_CANON?.entries?.sabaoth;return{ok:!!a&&a.combatEligible===false&&a.alignment==='allied_rebel'}});
 check('runtime_ready',()=>({ok:root.__chronicaReady===true,bootErrors:(root.__chronicaBootErrors||[]).slice(-5)}));
 state.ready=Object.values(state.checks).every(x=>x.ok);render();return snapshot()}
function snapshot(){return JSON.parse(JSON.stringify(state))}
function ensureUi(){let el=document.getElementById('chronicaDiag');if(el)return el;el=document.createElement('div');el.id='chronicaDiag';el.hidden=true;el.innerHTML='<div class="cd-head"><b>DIAGNÓSTICO CHRONICA · V4.2</b><button type="button">×</button></div><div class="cd-body"></div>';document.body.appendChild(el);el.querySelector('button').onclick=()=>el.hidden=true;return el}
function render(){if(!document?.body)return;const el=ensureUi(),body=el.querySelector('.cd-body');if(!body)return;const checks=Object.entries(state.checks).map(([k,v])=>`<div class="cd-check ${v.ok?'ok':'bad'}"><i></i><span>${k.replace(/_/g,' ')}</span><b>${v.ok?'OK':'FALHA'}</b></div>`).join('');const perf=root.CHRONICA_PERFORMANCE?.snapshot?.();const perfLine=perf?`<div class="cd-perf">TIER <b>${String(perf.tier).toUpperCase()}</b> · EMA ${perf.ema}ms · AI ${perf.profile?.aiHz||'?'}Hz · VFX ${perf.profile?.vfxBudget||'?'}</div>`:'';const errors=state.errors.slice(-5).map(e=>`<div class="cd-error"><b>${e.message}</b><small>${e.detail||''}</small></div>`).join('');const warnings=state.warnings.slice(-4).map(e=>`<div class="cd-warn"><b>${e.message}</b><small>${e.detail||''}</small></div>`).join('');body.innerHTML=`<div class="cd-state ${state.ready?'ok':'bad'}">${state.ready?'NÚCLEO V4 ÍNTEGRO':'VERIFICAÇÃO PENDENTE / FALHA'}</div>${perfLine}${checks}${errors}${warnings}`}
root.addEventListener('error',e=>push('errors',e.message,e.error?.stack||`${e.filename||''}:${e.lineno||''}`));root.addEventListener('unhandledrejection',e=>push('errors','PROMISE REJEITADA',e.reason?.stack||e.reason));
document.addEventListener('keydown',e=>{if(e.code==='F2'){e.preventDefault();const el=ensureUi();el.hidden=!el.hidden;if(!el.hidden)validate()}});
root.CHRONICA_DIAGNOSTICS={state,validate,snapshot,show(){const el=ensureUi();el.hidden=false;return validate()},hide(){ensureUi().hidden=true}};
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>setTimeout(validate,1800),{once:true});else setTimeout(validate,1800);
})(typeof globalThis!=='undefined'?globalThis:this);