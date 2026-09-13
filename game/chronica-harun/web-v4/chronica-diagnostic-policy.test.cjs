const assert=require('node:assert/strict');
const perf=require('./chronica-performance.js');
const policy=require('./chronica-diagnostic-policy.js');
const result=policy.validateCombatLightPolicy(perf);
assert.equal(result.ok,true,JSON.stringify(result));
assert.equal(result.checks.enemyCoreCombatDisabled,true);
assert.equal(result.checks.hitImpactCombatDisabled,true);
assert.equal(result.checks.roomKeyCombatAllowed,true);
console.log('chronica-diagnostic-policy OK');
