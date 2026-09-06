(function(root,factory){
  const api=factory();
  if(typeof module==='object'&&module.exports)module.exports=api;
  else root.CHRONICA_CLOUD_SYNC_FACTORY=api;
})(typeof globalThis!=='undefined'?globalThis:this,function(){
  'use strict';
  const SAVE_KEYS=['chronica_harun_v06_save','chronica_harun_v03_save','chronica_harun_v02_save','chronica_harun_v0_save'];
  function stableStringify(value){if(value===null||typeof value!=='object')return JSON.stringify(value);if(Array.isArray(value))return '['+value.map(stableStringify).join(',')+']';return '{'+Object.keys(value).sort().map(k=>JSON.stringify(k)+':'+stableStringify(value[k])).join(',')+'}';}
  function checksum(value){const text=stableStringify(value);let h=0x811c9dc5;for(let i=0;i<text.length;i++){h^=text.charCodeAt(i);h=Math.imul(h,0x01000193)>>>0;}return h.toString(16).padStart(8,'0');}
  function unwrapSnapshot(value){if(value&&typeof value==='object'&&value.save!==undefined)return value;if(Array.isArray(value)&&value.length===1)return unwrapSnapshot(value[0]);if(value&&typeof value==='object')for(const k of ['data','result','body'])if(value[k]!=null){const x=unwrapSnapshot(value[k]);if(x)return x;}return value||{};}
  function createCloudSync({bridge,storage,onState,gameBridge}){
    if(!bridge||typeof bridge.campaignSnapshot!=='function'||typeof bridge.saveCampaign!=='function')throw new TypeError('backend bridge is required');
    storage=storage||((typeof localStorage!=='undefined')?localStorage:null);if(!storage)throw new TypeError('storage is required');
    let current={mode:'unknown',hasLocal:false,hasRemote:false,localChecksum:null,remoteChecksum:null,error:null,checkedAt:null};
    function emit(next){current=Object.freeze(Object.assign({},current,next||{},{checkedAt:new Date().toISOString()}));if(typeof onState==='function')try{onState(current)}catch(_){}return current;}
    function readLocal(){for(const key of SAVE_KEYS){try{const raw=storage.getItem(key);if(raw){const state=JSON.parse(raw);return{key,state,checksum:checksum(state)}}}catch(_){}}return null;}
    async function remoteSnapshot(){return unwrapSnapshot(await bridge.campaignSnapshot(1));}
    async function inspect(){try{const local=readLocal(),snap=await remoteSnapshot(),remote=snap&&snap.save&&snap.save.state?{state:snap.save.state,checksum:snap.save.checksum||checksum(snap.save.state)}:null;let mode='empty';if(local&&remote)mode=local.checksum===remote.checksum?'ready':'conflict';else if(local)mode='local-only';else if(remote)mode='remote-only';return emit({mode,hasLocal:!!local,hasRemote:!!remote,localChecksum:local&&local.checksum||null,remoteChecksum:remote&&remote.checksum||null,error:null});}catch(error){emit({mode:'error',error:error&&error.message?error.message:String(error)});throw error;}}
    async function uploadLocal(){if(gameBridge&&typeof gameBridge.saveGame==='function')try{gameBridge.saveGame(true)}catch(_){}const local=readLocal();if(!local)throw new Error('Nenhum save local encontrado.');await bridge.saveCampaign(1,local.state,local.checksum);if(typeof bridge.recordTelemetry==='function')Promise.resolve(bridge.recordTelemetry(null,'cloud_save_uploaded','backend-sync-v1',{checksum:local.checksum})).catch(()=>{});return emit({mode:'ready',hasLocal:true,hasRemote:true,localChecksum:local.checksum,remoteChecksum:local.checksum,error:null});}
    async function downloadRemote(){const snap=await remoteSnapshot(),remote=snap&&snap.save&&snap.save.state?snap.save:null;if(!remote)throw new Error('Nenhum save remoto encontrado.');storage.setItem('chronica_harun_v06_save',JSON.stringify(remote.state));if(remote.state&&remote.state.meta)storage.setItem('chronica_harun_v06_meta',JSON.stringify(remote.state.meta));const c=remote.checksum||checksum(remote.state);if(typeof bridge.recordTelemetry==='function')Promise.resolve(bridge.recordTelemetry(null,'cloud_save_downloaded','backend-sync-v1',{checksum:c})).catch(()=>{});return emit({mode:'ready',hasLocal:true,hasRemote:true,localChecksum:c,remoteChecksum:c,error:null,downloaded:true});}
    return Object.freeze({inspect,uploadLocal,downloadRemote,readLocal,state:()=>current,checksum});
  }
  return {createCloudSync,checksum,unwrapSnapshot};
});
