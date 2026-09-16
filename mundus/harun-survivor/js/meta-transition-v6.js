(function(){
'use strict';
const frame=document.querySelector('.frame');
if(!frame)return;
frame.addEventListener('click',event=>{
  const play=event.target.closest('[data-action="play"]');
  if(!play)return;
  const meta=document.querySelector('#v6Meta');
  const nav=document.querySelector('#v6MetaNav');
  if(meta)meta.hidden=true;
  if(nav)nav.hidden=true;
},{capture:true});
window.HarunV6MetaTransition=Object.freeze({version:'6.0.1'});
})();