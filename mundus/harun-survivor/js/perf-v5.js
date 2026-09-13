(function(){
'use strict';
const Core=window.HarunSurvivorDebug;if(!Core)return;
function rescale(sel,scale){const c=document.querySelector(sel);if(!c)return null;c.width=Math.round(540*scale);c.height=Math.round(960*scale);const x=c.getContext('2d');x.setTransform(scale,0,0,scale,0,0);x.imageSmoothingEnabled=true;return x}
const gameScale=.76,fxScale=.44,worldScale=.72;rescale('#game',gameScale);rescale('#v4fx',fxScale);const c=document.querySelector('#v5WorldFx'),ctx=rescale('#v5WorldFx',worldScale);if(!c||!ctx)return;
const dense=()=>((Core.getState().run?.enemies?.length||0)>16);
for(const name of ['save','restore','beginPath','arc','stroke','fill','translate','rotate','fillText']){const original=ctx[name].bind(ctx);ctx[name]=function(){if(dense())return;return original(...arguments)}}
let lowFx=false,last=performance.now(),frames=0,acc=0;
function monitor(now){frames++;if(now-last>=1000){const fps=frames/((now-last)/1000);frames=0;last=now;acc=fps;lowFx=fps<48;c.dataset.lowFx=lowFx?'1':'0';c.style.opacity=dense()?'.12':'1'}requestAnimationFrame(monitor)}
window.HarunV5Perf=Object.freeze({version:'5.0.2',gameScale,fxScale,worldScale,lowFx:()=>lowFx,lastFps:()=>acc,dense});requestAnimationFrame(monitor);
})();