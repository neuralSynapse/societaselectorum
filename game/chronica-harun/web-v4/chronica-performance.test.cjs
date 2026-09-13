const assert=require('node:assert/strict');
const perf=require('./chronica-performance.js');
assert.equal(typeof perf.allowDynamicLight,'function');
assert.equal(perf.allowDynamicLight('enemyCore',{combatRoom:true,tier:'high',hitLights:true}),false);
assert.equal(perf.allowDynamicLight('hitImpact',{combatRoom:true,tier:'high',hitLights:true}),false);
assert.equal(perf.allowDynamicLight('roomKey',{combatRoom:true,tier:'high',hitLights:true}),true);
assert.equal(perf.allowDynamicLight('hitImpact',{combatRoom:false,tier:'high',hitLights:true}),true);
assert.equal(perf.validate().ok,true);
console.log('chronica-performance OK');
