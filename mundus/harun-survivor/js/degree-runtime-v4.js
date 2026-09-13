(function(){
'use strict';
const Core=window.HarunSurvivorDebug,P=window.HarunCanonicalProgression;if(!Core||!P)return;
const $=s=>document.querySelector(s),frame=$('.frame');
let activeSig='',lastBoss=null;
function ensureBadge(){let b=$('#degreeRuntimeBadge');if(!b){b=document.createElement('div');b.id='degreeRuntimeBadge';b.className='degree-runtime-badge';b.hidden=true;frame.appendChild(b)}return b}
const badge=ensureBadge();
function degreeOf(ctx){return ctx&&ctx.phase==='degrees'?P.degrees[(ctx.degree||1)-1]:null}
function signature(ctx){return ctx?`${ctx.phase}:${ctx.degree||0}:${ctx.index}:${ctx.node&&ctx.node.id}`:''}
function orderKey(g){if(!g)return'pre';return g.number<=11?'vitae':g.number<=22?'mortis':'draconis'}
function difficulty(g){if(!g)return 1;if(g.number<=11)return 1.05+g.number*.018;if(g.number<=22)return 1.27+(g.number-12)*.028;return 1.58+(g.number-23)*.032}
function applyRunIdentity(run,ctx){
 const g=degreeOf(ctx),key=orderKey(g),sig=signature(ctx);run.degreeRuntime={sig,key,degree:g?g.number:0,difficulty:difficulty(g)};
 frame.dataset.order=key;frame.dataset.phase=ctx.phase;
 if(g){const n=g.number,boon=Math.min(.32,.025+n*.008);run.player.damage*=1+boon;run.player.maxHp*=1+Math.min(.18,n*.004);run.player.hp=run.player.maxHp;if(n<=11)run.player.pickup+=3+n*.8;else if(n<=22){run.player.crit+=.02;run.player.speed+=Math.min(18,(n-11)*1.5)}else{run.player.damage*=1.08;run.player.dodge+=.015}}
 badge.hidden=false;badge.innerHTML=g?`<small>${g.order}</small><b>GRAU ${g.roman}</b><span>${g.public?g.name:'CONTEÚDO RESERVADO'}</span>`:`<small>${ctx.phase==='student'?'ETAPA FORMATIVA':'JORNADA INICIAL'}</small><b>${ctx.phase==='student'?'ESTUDANTE':'INGRESSUS'}</b><span>${ctx.node.name}</span>`;
}
function scaleEnemy(e,run){const rt=run.degreeRuntime;if(!rt||e._degreeSig===rt.sig)return;e._degreeSig=rt.sig;const mult=rt.difficulty;e.hp*=mult;e.maxHp*=mult;e.damage*=.92+mult*.16;e.speed*=Math.min(1.2,.98+(mult-1)*.08);if(e.kind==='boss'){e.hp*=1.18;e.maxHp*=1.18}}
function nameBoss(run,ctx){if(!run.boss||run.boss===lastBoss)return;lastBoss=run.boss;const g=degreeOf(ctx);if(!g)return;if(g.number===33)run.boss.name='LIMIAR · IPSISSIMUS';else if(g.public)run.boss.name=`PROVA · ${g.name.toUpperCase()}`;else run.boss.name=`GUARDIÃO · GRAU ${g.roman}`;if(ctx.node&&ctx.node.kind==='gate'){run.boss.hp*=1.2;run.boss.maxHp*=1.2}}
function loop(){const st=Core.getState(),run=st.run;if(st.state==='run'&&run&&run.progressionContext){const ctx=run.progressionContext,sig=signature(ctx);if(sig&&sig!==activeSig){activeSig=sig;applyRunIdentity(run,ctx)}for(const e of run.enemies)scaleEnemy(e,run);nameBoss(run,ctx)}else if(st.state==='menu'){activeSig='';lastBoss=null;badge.hidden=true;delete frame.dataset.order;delete frame.dataset.phase}requestAnimationFrame(loop)}
window.HarunDegreeRuntime=Object.freeze({difficultyFor:n=>difficulty(P.degrees[Math.max(0,Math.min(32,n-1))]),active:()=>{const st=Core.getState();return st.run&&st.run.degreeRuntime?{...st.run.degreeRuntime}:null}});
requestAnimationFrame(loop);
})();