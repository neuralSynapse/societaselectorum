(function(){
'use strict';
const A=window.HarunSurvivorArt;
if(!A) throw new Error('V4 art requires HarunSurvivorArt');
const old={hero:A.drawHero.bind(A),enemy:A.drawEnemy.bind(A),boss:A.drawBoss.bind(A),projectile:A.drawProjectile.bind(A),gem:A.drawGem.bind(A),pulse:A.drawPulse.bind(A)};
const TAU=Math.PI*2,cache=new Map();
A.v4={version:'4.1.0',arenaTheme:'moonlit-courtyard',combatScale:'reference-compact'};
function rr(ctx,x,y,w,h,r,fill,stroke=null,lw=1){ctx.beginPath();ctx.roundRect(x,y,w,h,r);ctx.fillStyle=fill;ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=lw;ctx.stroke()}}
function oval(ctx,x,y,rx,ry,fill,a=1){ctx.save();ctx.globalAlpha=a;ctx.fillStyle=fill;ctx.beginPath();ctx.ellipse(x,y,rx,ry,0,0,TAU);ctx.fill();ctx.restore()}
function flower(ctx,x,y,c='#f86c8e'){ctx.save();ctx.translate(x,y);ctx.fillStyle=c;for(let i=0;i<5;i++){const a=i*TAU/5;ctx.beginPath();ctx.arc(Math.cos(a)*3.2,Math.sin(a)*3.2,2.2,0,TAU);ctx.fill()}ctx.fillStyle='#ffe06b';ctx.beginPath();ctx.arc(0,0,1.5,0,TAU);ctx.fill();ctx.restore()}
function renderArena(act){const c=document.createElement('canvas');c.width=540;c.height=960;const x=c.getContext('2d');const accent=act.accent||'#6ee7d5';let g=x.createLinearGradient(0,0,0,960);g.addColorStop(0,'#132f4d');g.addColorStop(.13,'#243761');g.addColorStop(.58,'#454777');g.addColorStop(1,'#3f456d');x.fillStyle=g;x.fillRect(0,0,540,960);
// luminous water / garden strips on both sides
for(const side of [0,1]){const sx=side?500:0;let wg=x.createLinearGradient(sx,0,side?sx-42:sx+42,0);wg.addColorStop(0,'#2fd6d2');wg.addColorStop(.35,'#187b9a');wg.addColorStop(1,'#1e465e');x.fillStyle=wg;x.fillRect(side?498:0,0,42,960);for(let i=0;i<13;i++){const yy=50+i*76+(i%2)*15;oval(x,side?520:20,yy,18,10,i%3?'#25745f':'#3b8a70',.85);oval(x,side?514:26,yy-3,8,4,'#7dbb81',.32)}}
// raised top gate and glowing pools
x.fillStyle='#17253e';x.fillRect(42,0,456,105);for(let i=0;i<6;i++){const px=52+i*76;rr(x,px,28,66,60,9,i%2?'#334a6c':'#2b4163','#172c4b',2);x.fillStyle='rgba(135,232,255,.12)';x.fillRect(px+8,34,50,4)}
for(const px of [84,456]){const pg=x.createRadialGradient(px,30,2,px,30,32);pg.addColorStop(0,'#84ffff');pg.addColorStop(.35,'#27bcd4');pg.addColorStop(1,'rgba(22,74,102,0)');x.fillStyle=pg;x.beginPath();x.arc(px,30,31,0,TAU);x.fill()}
// main moonlit floor with large subtle slabs
const floor=x.createLinearGradient(42,100,498,900);floor.addColorStop(0,'#4a4d82');floor.addColorStop(.55,'#424574');floor.addColorStop(1,'#3b4168');x.fillStyle=floor;x.fillRect(42,100,456,790);x.strokeStyle='rgba(18,29,58,.38)';x.lineWidth=2;for(let row=0;row<8;row++){const y=105+row*100;const off=row%2?44:0;for(let col=-1;col<5;col++){const xx=44+col*112+off;rr(x,xx,y,108,96,7,'rgba(255,255,255,.018)','rgba(21,31,61,.32)',1.5)}}
// center sigil/worn moss mark
x.save();x.globalAlpha=.22;x.strokeStyle='#1a8a69';x.lineWidth=7;x.beginPath();x.arc(270,455,42,0,TAU);x.stroke();x.lineWidth=3;x.beginPath();x.arc(270,455,25,0,TAU);x.stroke();x.beginPath();for(let i=0;i<6;i++){const a=i*TAU/6;x.moveTo(270+Math.cos(a)*18,455+Math.sin(a)*18);x.lineTo(270+Math.cos(a)*36,455+Math.sin(a)*36)}x.stroke();x.restore();
// edge grass, bricks and flowers
x.fillStyle='#1a5c48';x.fillRect(42,865,456,40);x.fillStyle='#2c7859';x.fillRect(42,865,456,10);for(let i=0;i<11;i++){const bx=44+i*44;rr(x,bx,883,40,23,5,i%2?'#8f5477':'#a25d7b','#5e3857',1)}for(let i=0;i<18;i++){const fx=55+(i*71)%425,fy=118+(i*131)%720;flower(x,fx,fy,i%3===0?'#ff6e91':i%3===1?'#66e8c7':'#b982ff')}
// luminous runes / dust
for(let i=0;i<22;i++){const px=55+(i*83)%430,py=120+(i*157)%720;const rg=x.createRadialGradient(px,py,0,px,py,9);rg.addColorStop(0,i%2?'rgba(105,255,221,.65)':'rgba(255,224,103,.55)');rg.addColorStop(1,'rgba(0,0,0,0)');x.fillStyle=rg;x.beginPath();x.arc(px,py,9,0,TAU);x.fill()}
// bottom vignette for depth
const vg=x.createLinearGradient(0,770,0,960);vg.addColorStop(0,'rgba(0,0,0,0)');vg.addColorStop(1,'rgba(3,16,24,.45)');x.fillStyle=vg;x.fillRect(0,760,540,200);
return c}
A.drawArena=function(ctx,act,t){let c=cache.get(act.id);if(!c){c=renderArena(act);cache.set(act.id,c)}ctx.drawImage(c,0,0);ctx.save();ctx.globalCompositeOperation='screen';for(let i=0;i<8;i++){const px=58+((i*97+t*20)%424),py=115+((i*151+t*11)%730);ctx.globalAlpha=.12+.12*(.5+.5*Math.sin(t*2+i));ctx.fillStyle=i%2?'#5ff7df':'#ffdf68';ctx.beginPath();ctx.arc(px,py,1.8+(i%3)*.5,0,TAU);ctx.fill()}ctx.restore()};
A.drawHero=function(ctx,p,t){ctx.save();ctx.translate(p.x,p.y);ctx.scale(.72,.72);const q={...p,x:0,y:0};old.hero(ctx,q,t);ctx.restore();ctx.save();ctx.globalAlpha=.22;ctx.strokeStyle='#69f3d5';ctx.lineWidth=2;ctx.beginPath();ctx.arc(p.x,p.y+8,22+Math.sin(t*4)*2,0,TAU);ctx.stroke();ctx.restore()};
A.drawEnemy=function(ctx,e,t){ctx.save();ctx.translate(e.x,e.y);ctx.scale(.76,.76);const q={...e,x:0,y:0};old.enemy(ctx,q,t);ctx.restore()};
A.drawBoss=function(ctx,e,t){ctx.save();ctx.globalAlpha=.24;ctx.strokeStyle=e.bossPhase===2?'#ff6b68':'#ffce68';ctx.lineWidth=3;ctx.beginPath();ctx.arc(e.x,e.y,e.r*1.35+Math.sin(t*5)*4,0,TAU);ctx.stroke();ctx.globalAlpha=.11;ctx.lineWidth=9;ctx.beginPath();ctx.arc(e.x,e.y,e.r*1.65+Math.sin(t*4)*6,0,TAU);ctx.stroke();ctx.restore();ctx.save();ctx.translate(e.x,e.y);ctx.scale(.88,.88);old.boss(ctx,{...e,x:0,y:0},t);ctx.restore()};
A.drawProjectile=function(ctx,p){ctx.save();const a=p.a!=null?p.a:Math.atan2(p.vy||0,p.vx||1);ctx.strokeStyle=p.enemy?'rgba(255,86,114,.5)':'rgba(103,245,231,.58)';ctx.lineWidth=p.enemy?3:5;ctx.lineCap='round';ctx.beginPath();ctx.moveTo(p.x-Math.cos(a)*(p.enemy?12:30),p.y-Math.sin(a)*(p.enemy?12:30));ctx.lineTo(p.x,p.y);ctx.stroke();ctx.restore();old.projectile(ctx,p)};
A.drawGem=function(ctx,g){ctx.save();ctx.shadowColor=g.big?'#ffe36a':'#55dcff';ctx.shadowBlur=12;old.gem(ctx,g);ctx.restore()};
A.drawPulse=function(ctx,x,y,r,a,color){ctx.save();ctx.globalCompositeOperation='screen';old.pulse(ctx,x,y,r,a,color);ctx.restore()};
})();