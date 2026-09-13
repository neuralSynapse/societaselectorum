(function(){
'use strict';
const Core=window.HarunSurvivorDebug,c=document.querySelector('#v5WorldFx');if(!Core||!c)return;
const scale=.82;c.width=Math.round(540*scale);c.height=Math.round(960*scale);const ctx=c.getContext('2d');ctx.setTransform(scale,0,0,scale,0,0);
const dense=()=>((Core.getState().run?.enemies?.length||0)>16);
const noopWhenDense=['save','restore','beginPath','arc','stroke','fill','translate','rotate','fillText'];
for(const name of noopWhenDense){const original=ctx[name].bind(ctx);ctx[name]=function(){if(dense())return;return original(...arguments)}}
let lowFx=false,last=performance.now(),frames=0,acc=0;
function monitor(now){frames++;if(now-last>=1000){const fps=frames/((now-last)/1000);frames=0;last=now;acc=fps;lowFx=fps<48;c.dataset.lowFx=lowFx?'1':'0';c.style.opacity=dense()?'.18':'1'}requestAnimationFrame(monitor)}
window.HarunV5Perf=Object.freeze({version:'5.0.1',renderScale:scale,lowFx:()=>lowFx,lastFps:()=>acc,dense});requestAnimationFrame(monitor);
})();