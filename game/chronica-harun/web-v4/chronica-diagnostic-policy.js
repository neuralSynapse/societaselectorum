(function(root,factory){
  const api=factory();
  if(typeof module!=='undefined'&&module.exports)module.exports=api;
  if(root)root.CHRONICA_DIAGNOSTIC_POLICY=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  function validateCombatLightPolicy(perf){
    if(!perf||typeof perf.allowDynamicLight!=='function'){
      return {ok:false,reason:'performance light policy ausente',checks:{}};
    }
    const checks={
      enemyCoreCombatDisabled:perf.allowDynamicLight('enemyCore',{combatRoom:true})===false,
      hitImpactCombatDisabled:perf.allowDynamicLight('hitImpact',{combatRoom:true})===false,
      roomKeyCombatAllowed:perf.allowDynamicLight('roomKey',{combatRoom:true})===true
    };
    return {ok:Object.values(checks).every(Boolean),checks,performanceVersion:perf.version||null};
  }
  return {version:'1.0',validateCombatLightPolicy};
});