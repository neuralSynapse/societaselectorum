(function(){
'use strict';
const frame=document.querySelector('.frame');
if(!frame)return;
const style=document.createElement('style');
style.textContent='.v6-meta-nav[hidden]{display:none!important}';
document.head.appendChild(style);
function hideMeta(){
  const meta=document.querySelector('#v6Meta');
  const nav=document.querySelector('#v6MetaNav');
  if(meta)meta.hidden=true;
  if(nav)nav.hidden=true;
}
function choiceOwnsScreen(){
  return !!document.querySelector('#v4Glory:not([hidden]),#v4Event:not([hidden]),#v5Choice:not([hidden]),#upgrade:not([hidden]),#event:not([hidden]),#v6Pause:not([hidden])');
}
frame.addEventListener('click',event=>{
  const play=event.target.closest('[data-action="play"]');
  if(!play)return;
  hideMeta();
},{capture:true});
function guard(){
  if(choiceOwnsScreen())hideMeta();
  requestAnimationFrame(guard);
}
window.HarunV6MetaTransition=Object.freeze({version:'6.0.3',hideMeta});
requestAnimationFrame(guard);
})();