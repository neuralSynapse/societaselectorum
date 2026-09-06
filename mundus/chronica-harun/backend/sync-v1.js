/* CHRONICA HARUN · Persistent Cloud Sync v1.0
 * Isolated save/run lifecycle bridge. No real institutional progression writes.
 */
(function(global){
  'use strict';
  const BUILD='backend-sync-v1';
  const RUN_MAP_KEY='chronica_remote_runs_v1';
  let sync=null,authState={authenticated:false},autoBusy=false,lastRunKey=null,remoteRunId=null,runStartedAt=0,runFinished=false,lastRoomKey=null;
  const sleep=ms=>new Promise(r=>setTimeout(r,ms));
  async function waitFor(getter,timeout=25000){const start=Date.now();while(Date.now()-start<timeout){const v=getter();if(v)return v;await sleep(50)}return null;}
  function emit(s){try{global.dispatchEvent(new CustomEvent('chronica:cloud-sync-state',{detail:s}))}catch(_){}return s;}
  function currentGameBridge(){return global.__CHRONICA_BRIDGE__||null;}
  function saveLocalNow(){const B=currentGameBridge();if(B&&typeof B.saveGame==='function')try{B.saveGame(true)}catch(_){};}
  function readRunMap(){try{const x=JSON.parse(sessionStorage.getItem(RUN_MAP_KEY)||'{}');return x&&typeof x==='object'?x:{}}catch(_){return{}}}
  function writeRunMap(map){try{const entries=Object.entries(map).slice(-12);sessionStorage.setItem(RUN_MAP_KEY,JSON.stringify(Object.fromEntries(entries)))}catch(_){}}
  function runKey(run){if(!run)return null;return [run.seed,run.cycle,run.characterId||run.characterKey||'harun'].join(':');}
  function buildVersion(){return document.documentElement.dataset.chronicaNextLevelBuild||document.documentElement.dataset.chronicaReady||'live';}
  function roomKey(run){if(!run)return null;const v=run.roomIndex??run.currentRoomIndex??run.roomId??run.currentRoom??null;return v==null?null:String(v);}
  async function inspect(){if(!sync)throw new Error('Sincronização ainda não inicializada.');return sync.inspect();}
  async function uploadLocal(){if(!sync)throw new Error('Sincronização ainda não inicializada.');saveLocalNow();return sync.uploadLocal();}
  async function downloadRemote(){if(!sync)throw new Error('Sincronização ainda não inicializada.');return sync.downloadRemote();}
  async function reconcile(){if(!authState.authenticated||!sync)return;try{const s=await sync.inspect();if(s.mode==='local-only')await uploadLocal();}catch(e){console.warn('[CHRONICA SYNC] reconcile',e)}}
  async function autoSave(){if(autoBusy||!authState.authenticated||!sync)return;const s=sync.state();if(s.mode!=='ready'&&s.mode!=='local-only')return;const B=currentGameBridge();if(!B||!B.isPlaying||!B.isPlaying())return;autoBusy=true;try{saveLocalNow();await sync.uploadLocal()}catch(e){console.warn('[CHRONICA SYNC] autosave',e)}finally{autoBusy=false}}
  async function beginRemoteRun(run,key){const bridge=global.CHRONICA_BACKEND_BRIDGE;if(!bridge||!authState.authenticated)return;const map=readRunMap();if(map[key]){remoteRunId=map[key];return}try{const id=await bridge.startRun(String(run.seed||key),String(run.characterId||run.characterKey||'harun'),String(buildVersion()));remoteRunId=Array.isArray(id)?id[0]:id;if(remoteRunId){map[key]=remoteRunId;writeRunMap(map)}await bridge.recordTelemetry(null,'run_started',String(buildVersion()),{runKey:key,cycle:Number(run.cycle)||0}).catch(()=>{})}catch(e){console.warn('[CHRONICA SYNC] start_run',e)}}
  async function finishRemoteRun(result,run){if(runFinished||!remoteRunId)return;runFinished=true;const bridge=global.CHRONICA_BACKEND_BRIDGE;try{await bridge.finishRun(remoteRunId,result,Math.max(0,Date.now()-runStartedAt),{cycle:Number(run&&run.cycle)||0,characterKey:String(run&&(run.characterId||run.characterKey)||'harun')});await bridge.recordTelemetry(null,'run_ended',String(buildVersion()),{result,runId:remoteRunId}).catch(()=>{});saveLocalNow();await autoSave()}catch(e){runFinished=false;console.warn('[CHRONICA SYNC] finish_run',e)}}
  async function lifecycleTick(){if(!authState.authenticated)return;const B=currentGameBridge();if(!B||typeof B.getRun!=='function')return;const run=B.getRun(),key=runKey(run);if(B.isPlaying&&B.isPlaying()&&key){if(key!==lastRunKey){lastRunKey=key;remoteRunId=null;runStartedAt=Date.now();runFinished=false;lastRoomKey=null;await beginRemoteRun(run,key)}const rk=roomKey(run);if(remoteRunId&&rk!==null&&rk!==lastRoomKey){lastRoomKey=rk;global.CHRONICA_BACKEND_BRIDGE.appendRunEvent(remoteRunId,'room_entered',rk,{cycle:Number(run.cycle)||0}).catch(()=>{})}if(B.isDying&&B.isDying())await finishRemoteRun('death',run);else if(B.isEnding&&B.isEnding())await finishRemoteRun('ending',run)}}
  async function init(){const bridge=await waitFor(()=>global.CHRONICA_BACKEND_BRIDGE),factory=await waitFor(()=>global.CHRONICA_CLOUD_SYNC_FACTORY);if(!bridge||!factory){console.error('[CHRONICA SYNC] dependências ausentes');return}sync=factory.createCloudSync({bridge,storage:global.localStorage,onState:emit});global.CHRONICA_CLOUD_SYNC=Object.freeze({inspect,uploadLocal,downloadRemote,state:()=>sync.state(),checksum:sync.checksum});document.documentElement.dataset.chronicaCloudSync='v1';const saveBtn=document.getElementById('saveBtn');if(saveBtn)saveBtn.addEventListener('click',()=>setTimeout(()=>{if(authState.authenticated)uploadLocal().catch(()=>{})},450),true);const newBtn=document.getElementById('newGameBtn');if(newBtn)newBtn.addEventListener('click',()=>setTimeout(()=>{if(authState.authenticated)uploadLocal().catch(()=>{})},1600),false);setInterval(autoSave,30000);setInterval(()=>{lifecycleTick().catch(()=>{})},600);if(authState.authenticated)reconcile();}
  global.addEventListener('chronica:auth-state',e=>{authState=e&&e.detail||{authenticated:false};if(authState.authenticated)reconcile();});
  if(global.CHRONICA_AUTH&&typeof global.CHRONICA_AUTH.state==='function')authState=global.CHRONICA_AUTH.state();
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init,{once:true});else init();
})(window);
