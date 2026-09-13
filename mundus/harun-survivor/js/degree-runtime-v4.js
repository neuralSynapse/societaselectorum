(function(){
'use strict';
const Core=window.HarunSurvivorDebug,P=window.HarunCanonicalProgression;if(!Core||!P)return;
const $=s=>document.querySelector(s),frame=$('.frame');
let activeSig='',lastBoss=null,orderTimer=0,lastPlayerHp=0;
const bossNames={
 blind_observer:'OBSERVADOR CEGO',impulse_archon:'ARCONTE DO IMPULSO',inert_stone_guardian:'GUARDIÃO DA PEDRA INERTE',seal_of_no:'SELO DO NÃO',mask_collector:'COLETOR DE MÁSCARAS',false_daimon:'FALSO DAIMON',stone_witness:'TESTEMUNHA DE PEDRA',rhythm_devourer:'DEVORADOR DO RITMO',clouding_one:'O OFUSCADOR',slag_dragon:'DRAGÃO DE ESCÓRIA',exhaustion_tyrant:'TIRANO DA EXAUSTÃO',blind_architect:'ARQUITETO CEGO',archontic_banker:'BANQUEIRO ARCÔNTICO',approval_chorus:'CORO DA APROVAÇÃO',durable_name_guardian:'GUARDIÃO DO NOME DURÁVEL',initiation_throne:'TRONO DO ACTUS INGRESSUS'
};
const studentBoss={xi1:'PROVA · PERCEPÇÃO I',xi2:'PROVA · PERCEPÇÃO II',xi3:'PROVA · PERCEPÇÃO III',period1:'GUARDIÃO · PERÍODO I',xi4:'PROVA · REGÊNCIA I',xi5:'PROVA · REGÊNCIA II',xi6:'PROVA · REGÊNCIA III',period2:'GUARDIÃO · PERÍODO II',xi7:'PROVA · OBRA I',xi8:'PROVA · OBRA II',xi9:'PROVA · OBRA III',period3:'GUARDIÃO · PERÍODO III',regencia:'GATE · REGÊNCIA',dossie:'GUARDIÃO DO DOSSIÊ',exame:'EXAME · PEREGRINUS'};
function ensureBadge(){let b=$('#degreeRuntimeBadge');if(!b){b=document.createElement('div');b.id='degreeRuntimeBadge';b.className='degree-runtime-badge';b.hidden=true;frame.appendChild(b)}return b}
const badge=ensureBadge();
function degreeOf(ctx){return ctx&&ctx.phase==='degrees'?P.degrees[(ctx.degree||1)-1]:null}
function signature(ctx){return ctx?`${ctx.phase}:${ctx.degree||0}:${ctx.index}:${ctx.node&&ctx.node.id}`:''}
function orderKey(g,ctx){if(g)return g.number<=11?'vitae':g.number<=22?'mortis':'draconis';return ctx&&ctx.phase==='student'?'student':'ingressus'}
function difficulty(g,ctx){if(!g){if(ctx&&ctx.phase==='student')return 1.08+Math.min(.16,(ctx.index||0)*.01);return 1+Math.min(.12,(ctx&&ctx.index||0)*.0075)}if(g.number<=11)return 1.05+g.number*.018;if(g.number<=22)return 1.27+(g.number-12)*.028;return 1.58+(g.number-23)*.032}
function applyRunIdentity(run,ctx){
 const g=degreeOf(ctx),key=orderKey(g,ctx),sig=signature(ctx),mult=difficulty(g,ctx);run.degreeRuntime={sig,key,degree:g?g.number:0,difficulty:mult,node:ctx.node&&ctx.node.id||''};
 frame.dataset.order=key;frame.dataset.phase=ctx.phase;orderTimer=0;lastPlayerHp=run.player.hp;
 if(g){const n=g.number,boon=Math.min(.32,.025+n*.008);run.player.damage*=1+boon;run.player.maxHp*=1+Math.min(.18,n*.004);run.player.hp=run.player.maxHp;if(n<=11){run.player.pickup+=3+n*.8;run.player.dodge+=.004*n}else if(n<=22){run.player.crit+=.02+.002*(n-11);run.player.speed+=Math.min(18,(n-11)*1.5)}else{run.player.damage*=1.08;run.player.dodge+=.015;run.player.fireRate=Math.max(.17,run.player.fireRate*.94)}}else if(ctx.phase==='student'){run.player.pickup+=8;run.player.crit+=.015}
 badge.hidden=false;badge.innerHTML=g?`<small>${g.order}</small><b>GRAU ${g.roman}</b><span>${g.public?g.name:'CONTEÚDO RESERVADO'}</span>`:`<small>${ctx.phase==='student'?'ETAPA FORMATIVA':'INGRESSUS · CIDADELA'}</small><b>${ctx.phase==='student'?'ESTUDANTE':'INGRESSUS'}</b><span>${ctx.node.name}</span>`;
}
function scaleEnemy(e,run){const rt=run.degreeRuntime;if(!rt||e._degreeSig===rt.sig)return;e._degreeSig=rt.sig;const mult=rt.difficulty;e.hp*=mult;e.maxHp*=mult;e.damage*=.92+mult*.16;e.speed*=Math.min(1.22,.98+(mult-1)*.085);if(rt.key==='mortis'){e.damage*=1.08;e.speed*=1.035}else if(rt.key==='draconis'){e.hp*=1.08;e.maxHp*=1.08;e.damage*=1.1}if(e.kind==='boss'){e.hp*=1.18;e.maxHp*=1.18}}
function nameBoss(run,ctx){if(!run.boss||run.boss===lastBoss)return;lastBoss=run.boss;const g=degreeOf(ctx),node=ctx.node||{};if(ctx.phase==='ingressus')run.boss.name=bossNames[node.bossId]||`GUARDIÃO · ${String(node.name||'INGRESSUS').toUpperCase()}`;else if(ctx.phase==='student')run.boss.name=studentBoss[node.id]||`PROVA · ${String(node.name||'ESTUDANTE').toUpperCase()}`;else if(g){if(g.number===33)run.boss.name='LIMIAR · IPSISSIMUS';else if(g.public)run.boss.name=`PROVA · ${g.name.toUpperCase()}`;else run.boss.name=`GUARDIÃO · GRAU ${g.roman}`}
 if(node.kind==='gate'||node.kind==='rite'){run.boss.hp*=1.22;run.boss.maxHp*=1.22;run.boss.damage*=1.08}
}
function orderTick(run,dt){const rt=run.degreeRuntime;if(!rt)return;orderTimer+=dt;if(rt.key==='vitae'&&orderTimer>=9){orderTimer=0;run.player.hp=Math.min(run.player.maxHp,run.player.hp+run.player.maxHp*.035)}else if(rt.key==='mortis'&&orderTimer>=7){orderTimer=0;for(const e of run.enemies)if(e.kind!=='boss')e.speed*=1.025}else if(rt.key==='draconis'&&orderTimer>=6){orderTimer=0;run.player.crit=Math.min(.65,run.player.crit+.002);for(const e of run.enemies)if(e.kind!=='boss')e.damage*=1.012}else if(rt.key==='student'&&orderTimer>=10){orderTimer=0;run.player.hp=Math.min(run.player.maxHp,run.player.hp+.15)}lastPlayerHp=run.player.hp}
let last=performance.now();function loop(now){const dt=Math.min(.05,Math.max(0,(now-last)/1000));last=now;const st=Core.getState(),run=st.run;if(st.state==='run'&&run&&run.progressionContext){const ctx=run.progressionContext,sig=signature(ctx);if(sig&&sig!==activeSig){activeSig=sig;applyRunIdentity(run,ctx)}for(const e of run.enemies)scaleEnemy(e,run);nameBoss(run,ctx);orderTick(run,dt)}else if(st.state==='menu'){activeSig='';lastBoss=null;badge.hidden=true;delete frame.dataset.order;delete frame.dataset.phase}requestAnimationFrame(loop)}
window.HarunDegreeRuntime=Object.freeze({difficultyFor:n=>difficulty(P.degrees[Math.max(0,Math.min(32,n-1))],{phase:'degrees'}),active:()=>{const st=Core.getState();return st.run&&st.run.degreeRuntime?{...st.run.degreeRuntime}:null},bossNames:Object.freeze({...bossNames})});
requestAnimationFrame(loop);
})();