(function(root,factory){const api=factory();if(typeof module!=='undefined'&&module.exports)module.exports=api;if(root)root.CHRONICA_PERFORMANCE=api.createController({deviceMemory:root.navigator?.deviceMemory,hardwareConcurrency:root.navigator?.hardwareConcurrency});})(typeof globalThis!=='undefined'?globalThis:this,function(){'use strict';
const PROFILES=Object.freeze({
 high:{name:'high',dpr:1.15,aiHz:30,vfxBudget:26,lightBudget:16,motes:true,volumetrics:true,hitLights:true},
 medium:{name:'medium',dpr:1.0,aiHz:24,vfxBudget:18,lightBudget:11,motes:true,volumetrics:false,hitLights:true},
 low:{name:'low',dpr:.82,aiHz:18,vfxBudget:10,lightBudget:7,motes:false,volumetrics:false,hitLights:false}
});
function profile(name){return PROFILES[name]||PROFILES.medium}
function autoInitial(dm=8,hc=8){if(Number(dm)<=4||Number(hc)<=4)return'low';if(Number(dm)<=6||Number(hc)<=6)return'medium';return'high'}
function createController({deviceMemory=8,hardwareConcurrency=8,initial='auto'}={}){
 let tierName=initial==='auto'?autoInitial(deviceMemory,hardwareConcurrency):profile(initial).name,ema=16.7,slow=0,fast=0,lastChange=0,hidden=false;
 const listeners=new Set();
 function notify(){for(const fn of listeners){try{fn(snapshot())}catch{}}}
 function setTier(name,reason='manual'){const next=profile(name).name;if(next===tierName)return false;tierName=next;lastChange=Date.now();slow=fast=0;notify();return{tier:next,reason}}
 function observe(frameMs){const n=Math.max(1,Number(frameMs)||16.7);ema=ema*.88+n*.12;if(hidden)return tierName;if(n>30){slow++;fast=0}else if(n<18){fast++;slow=Math.max(0,slow-1)}else{slow=Math.max(0,slow-1);fast=Math.max(0,fast-1)}if(slow>=5){if(tierName==='high')setTier('medium','slow-frame');else if(tierName==='medium')setTier('low','slow-frame')}else if(fast>=18&&Date.now()-lastChange>8000){if(tierName==='low')setTier('medium','stable-fast');else if(tierName==='medium')setTier('high','stable-fast')}return tierName}
 function budget(kind){const p=profile(tierName);return kind in p?p[kind]:null}
 function roomActive(entityRoom,currentRoom,margin=0){return Math.abs(Number(entityRoom)-Number(currentRoom))<=Math.max(0,Number(margin)||0)}
 function scheduler(hz){let acc=0;const step=1/Math.max(1,Number(hz)||1);return dt=>{acc+=Math.max(0,Number(dt)||0);if(acc<step)return false;acc%=step;return true}}
 function setHidden(v){hidden=!!v}
 function onChange(fn){if(typeof fn==='function')listeners.add(fn);return()=>listeners.delete(fn)}
 function tier(){return tierName}
 function snapshot(){return{tier:tierName,ema:Math.round(ema*10)/10,profile:{...profile(tierName)},hidden,lastChange}}
 return{version:'1.0',tier,profile:()=>profile(tierName),budget,observe,setTier,roomActive,scheduler,setHidden,onChange,snapshot,validate}
}
function validate(){const errors=[],c=createController({initial:'high'});for(let i=0;i<6;i++)c.observe(35);if(c.tier()==='high')errors.push('slow frames did not degrade tier');const before=c.tier();for(let i=0;i<3;i++)c.observe(16);if(c.tier()!==before)errors.push('hysteresis flap');if(profile('low').aiHz>20||profile('low').dpr>1)errors.push('low profile budget invalid');return{ok:!errors.length,errors,profiles:Object.keys(PROFILES)}}
return{PROFILES,profile,createController,validate};});