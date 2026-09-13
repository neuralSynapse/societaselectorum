(function(root,factory){
  const api=factory();
  if(typeof module!=='undefined'&&module.exports)module.exports=api;
  if(root)root.CHRONICA_ENCOUNTER_DIRECTOR=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const PHASES=Object.freeze(['manifest','read','chase','windup','telegraph','release','travel','impact','recovery']);
  function ms(value,fallback){const n=Number(value);return Number.isFinite(n)&&n>=0?n:fallback}
  function pacingFor(stagePacing={}){const grace=ms(stagePacing.spawnGraceMs,1200);return{
    manifestMs:Math.max(500,Math.round(grace*.66)),
    readMs:Math.max(260,Math.round(grace*.34)),
    attackDelayMs:Math.max(280,Math.round(grace*.28)),
    maxSimultaneous:Math.max(1,Math.floor(Number(stagePacing.maxSimultaneous)||1))
  }}
  function createManifestState(manifestMs=1200,readMs=300,attackDelayMs=300,kind='enemy'){
    return{phase:'manifest',kind,manifestMs:ms(manifestMs,1200),readMs:ms(readMs,300),attackDelayMs:ms(attackDelayMs,300),ageMs:0,activeMs:0}
  }
  function createState({kind='enemy',pacing={}}={}){const p=pacingFor(pacing);return createManifestState(p.manifestMs,p.readMs,p.attackDelayMs,kind)}
  function stepEncounterState(input,dtSeconds){
    const s={...input};let delta=Math.max(0,Number(dtSeconds)||0)*1000;s.ageMs=ms(s.ageMs,0)+delta;
    if(s.phase==='manifest'){
      const remain=Math.max(0,ms(s.manifestMs,0));
      if(delta<remain){s.manifestMs=remain-delta;return s}
      delta-=remain;s.manifestMs=0;s.phase='read';
    }
    if(s.phase==='read'){
      const remain=Math.max(0,ms(s.readMs,0));
      if(delta<remain){s.readMs=remain-delta;return s}
      delta-=remain;s.readMs=0;s.phase='chase';
    }
    if(s.phase==='chase'){
      s.activeMs=ms(s.activeMs,0)+delta;
      if(s.attackDelayMs>0)s.attackDelayMs=Math.max(0,s.attackDelayMs-delta);
    }
    return s
  }
  function spawnGate(s){const move=!!s&&s.phase==='chase';const attack=move&&ms(s.attackDelayMs,0)<=0;return{move,attack,damage:attack}}
  function canMove(s){return spawnGate(s).move}
  function canAttack(s){return spawnGate(s).attack}
  function canDamage(s){return spawnGate(s).damage}
  function isManifesting(s){return!!s&&(s.phase==='manifest'||s.phase==='read')}
  function validate(){
    const errors=[];
    let s=createManifestState(1000,300,250);
    if(canMove(s)||canAttack(s)||canDamage(s))errors.push('manifest gate leak');
    s=stepEncounterState(s,1.05);
    if(s.phase!=='read'||canMove(s)||canAttack(s))errors.push('read gate leak');
    s=stepEncounterState(s,.30);
    if(s.phase!=='chase'||!canMove(s)||canAttack(s))errors.push('chase attack delay broken');
    s=stepEncounterState(s,.25);
    if(!canAttack(s)||!canDamage(s))errors.push('attack did not unlock after delay');
    const boss=createState({kind:'boss',pacing:{spawnGraceMs:1200}});
    if(boss.phase!=='manifest'||boss.kind!=='boss')errors.push('boss gate invalid');
    return{ok:errors.length===0,errors,phases:PHASES.slice()}
  }
  return{version:'2.0',PHASES,createManifestState,createState,stepEncounterState,spawnGate,canMove,canAttack,canDamage,isManifesting,pacingFor,validate};
});