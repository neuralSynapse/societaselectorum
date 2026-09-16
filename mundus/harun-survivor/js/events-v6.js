(function(){
'use strict';
const frame=document.querySelector('.frame');let revealCount=0;
const watched=new WeakSet(),queued=new WeakMap();
function decorate(root){
  if(!root||root.hidden)return;
  root.classList.add('v6-event-surface');
  const cards=[...root.querySelectorAll('.skill-card,.v4-choice,.v5-tarot,.v5-system-card,[data-v5-glory]')];
  cards.forEach((card,i)=>{card.style.setProperty('--i',i);card.classList.add('v6-reveal-card')});
  if(cards.length){revealCount++;try{window.MUNDUSAudio?.sfx?.('book',{gain:.8})}catch(_){}}
  let fx=root.querySelector('.v6-event-rays');
  if(!fx){fx=document.createElement('div');fx.className='v6-event-rays';fx.innerHTML='<i></i><i></i><i></i><i></i>';root.appendChild(fx)}
}
function queue(el){
  if(!el||el.hidden)return;
  clearTimeout(queued.get(el));
  queued.set(el,setTimeout(()=>{queued.delete(el);decorate(el)},24));
}
function watch(el){
  if(!el||watched.has(el))return;
  watched.add(el);
  new MutationObserver(()=>queue(el)).observe(el,{attributes:true,attributeFilter:['hidden'],childList:true,subtree:false});
  queue(el);
}
function discover(){for(const sel of ['#upgrade','#event','#v4Glory','#v4Event','#v5Choice'])watch(document.querySelector(sel))}
discover();
if(frame)new MutationObserver(()=>discover()).observe(frame,{childList:true,subtree:false});
const style=document.createElement('style');style.textContent='.v6-event-surface{overflow:hidden}.v6-reveal-card{animation:v6cardreveal .45s cubic-bezier(.18,.75,.2,1) both;animation-delay:calc(var(--i,0)*70ms)}.v6-event-rays{position:absolute;z-index:-1;inset:0;pointer-events:none}.v6-event-rays i{position:absolute;left:50%;top:50%;width:5px;height:62%;transform-origin:50% 0;background:linear-gradient(#ffe6a0aa,transparent);filter:blur(.4px);animation:v6rayflash .9s ease-out both}.v6-event-rays i:nth-child(1){transform:rotate(28deg)}.v6-event-rays i:nth-child(2){transform:rotate(112deg)}.v6-event-rays i:nth-child(3){transform:rotate(208deg)}.v6-event-rays i:nth-child(4){transform:rotate(296deg)}@keyframes v6cardreveal{from{opacity:0;transform:translateY(34px) scale(.9);filter:brightness(2)}to{opacity:1;transform:none;filter:none}}@keyframes v6rayflash{from{opacity:0;height:0}30%{opacity:1}to{opacity:0;height:80%}}';document.head.appendChild(style);
window.HarunV6Events=Object.freeze({version:'6.0.2',decorate,revealCount:()=>revealCount});
})();