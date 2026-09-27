const THREE_RUNTIME='https://cdn.websitepublisher.ai/custom/wid25063/worlds/societas/runtime-3d.js?v=20260906-societas-final';
const FALLBACK_RUNTIME='https://cdn.websitepublisher.ai/custom/wid25063/worlds/societas/runtime.js?v=20260906-societas-final';
const BOOT_ID='mundus-societas-boot';
const delay=ms=>new Promise(r=>setTimeout(r,ms));
function importWithTimeout(url,ms,label){
  let timer;
  return Promise.race([
    import(url),
    new Promise((_,reject)=>{timer=setTimeout(()=>reject(new Error(`${label} excedeu ${ms}ms sem concluir o carregamento`)),ms);})
  ]).finally(()=>clearTimeout(timer));
}
function bootEl(){return document.getElementById(BOOT_ID)}
function setBoot(title,message,state='loading'){
  const el=bootEl(); if(!el)return;
  el.dataset.state=state;
  const t=el.querySelector('[data-boot-title]'); const m=el.querySelector('[data-boot-message]');
  if(t)t.textContent=title; if(m)m.textContent=message;
}
function hideBoot(){const el=bootEl();if(el){el.classList.add('hidden');setTimeout(()=>el.remove(),700)}}
function errorText(e){return String(e?.stack||e?.message||e||'erro desconhecido').slice(0,1200)}
async function tryFallback(reason){
  window.MUNDUS_SOCIETAS_DISABLE_3D=true;
  window.MUNDUS_SOCIETAS_BOOT_ERROR=reason;
  console.error('[MUNDUS · SOCIETAS] 3D boot failed; loading compatibility runtime',reason);
  setBoot('Ativando modo compatível.','O renderer 3D encontrou uma falha de inicialização. Seu conteúdo permanece acessível enquanto o modo 3D é reparado.','fallback');
  try{
    document.querySelector('.sw3d-shell')?.remove();
    await importWithTimeout(FALLBACK_RUNTIME,5000,'runtime compatível');
    await delay(120);
    if(!document.querySelector('.sw-shell'))throw new Error('runtime compatível carregou, mas não criou .sw-shell');
    hideBoot();
    window.MUNDUS_SOCIETAS_BOOT_MODE='fallback';
    return true;
  }catch(e){
    window.MUNDUS_SOCIETAS_FALLBACK_ERROR=errorText(e);
    console.error('[MUNDUS · SOCIETAS] fallback boot failed',e);
    setBoot('Falha de inicialização.','O MUNDUS não conseguiu abrir nem o renderer 3D nem o modo compatível. O erro foi preservado para diagnóstico.','error');
    const el=bootEl();
    if(el){const pre=el.querySelector('[data-boot-error]');if(pre){pre.hidden=false;pre.textContent=window.MUNDUS_SOCIETAS_FALLBACK_ERROR}}
    return false;
  }
}
export async function bootSocietas(){
  window.MUNDUS_SOCIETAS_DISABLE_3D=false;
  setBoot('Preparando a arquitetura.','Inicializando MUNDUS · SOCIETAS em modo tridimensional.','loading');
  let imported=false;
  try{
    await importWithTimeout(THREE_RUNTIME,6500,'runtime 3D');
    imported=true;
  }catch(e){
    return tryFallback(errorText(e));
  }
  for(let i=0;i<18;i++){
    if(document.querySelector('.sw3d-shell')){
      hideBoot();
      window.MUNDUS_SOCIETAS_BOOT_MODE='3d';
      return true;
    }
    await delay(100);
  }
  if(imported)return tryFallback('runtime-3d importado, mas .sw3d-shell não foi criado dentro do watchdog de boot');
}
window.addEventListener('error',e=>{window.MUNDUS_SOCIETAS_LAST_WINDOW_ERROR=errorText(e.error||e.message)});
window.addEventListener('unhandledrejection',e=>{window.MUNDUS_SOCIETAS_LAST_REJECTION=errorText(e.reason)});
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>bootSocietas(),{once:true});else bootSocietas();
export default bootSocietas;
