(function(){
'use strict';
const A=window.HarunSurvivorArt,D=window.HarunSurvivorData;if(!A||!D)return;
const prevEnemy=A.drawEnemy.bind(A),prevArena=A.drawArena.bind(A),enemySprites=new Map(),arenaSprites=new Map();
function enemySprite(kind){if(enemySprites.has(kind))return enemySprites.get(kind);const d=D.enemyKinds[kind],c=document.createElement('canvas');c.width=84;c.height=84;const x=c.getContext('2d');prevEnemy(x,{kind,x:42,y:42,r:d.r,hp:d.hp,maxHp:d.hp,phase:0,hit:0},0);enemySprites.set(kind,c);return c}
function arenaSprite(act){if(arenaSprites.has(act.id))return arenaSprites.get(act.id);const c=document.createElement('canvas');c.width=540;c.height=960;prevArena(c.getContext('2d'),act,0);arenaSprites.set(act.id,c);return c}
for(const k of Object.keys(D.enemyKinds))enemySprite(k);
A.drawArena=function(ctx,act){ctx.drawImage(arenaSprite(act),0,0)};
A.drawEnemy=function(ctx,e){const c=enemySprite(e.kind);ctx.save();if(e.hit>0)ctx.globalAlpha=.62;ctx.drawImage(c,e.x-42,e.y-42);ctx.restore();if(e.hp<e.maxHp){const r=Math.max(8,e.r*.72),y=e.y-e.r*.78-9;ctx.fillStyle='#160d12cc';ctx.fillRect(e.x-r,y,r*2,3);ctx.fillStyle='#f05b63';ctx.fillRect(e.x-r,y,r*2*Math.max(0,e.hp/e.maxHp),3)}};
A.drawProjectile=function(ctx,p){const a=p.a!=null?p.a:Math.atan2(p.vy||0,p.vx||1),enemy=!!p.enemy,col=enemy?'#ff6678':'#72f3e2',core=enemy?'#ffd2d8':'#fff6ad',trail=enemy?13:27;ctx.save();ctx.lineCap='round';ctx.globalAlpha=.55;ctx.strokeStyle=col;ctx.lineWidth=enemy?3:4;ctx.beginPath();ctx.moveTo(p.x-Math.cos(a)*trail,p.y-Math.sin(a)*trail);ctx.lineTo(p.x,p.y);ctx.stroke();ctx.globalAlpha=1;ctx.fillStyle=core;ctx.beginPath();ctx.arc(p.x,p.y,enemy?5:6,0,Math.PI*2);ctx.fill();ctx.strokeStyle=col;ctx.lineWidth=2;ctx.stroke();ctx.restore()};
A.drawGem=function(ctx,g){ctx.save();ctx.translate(g.x,g.y);ctx.rotate(Math.PI/4);ctx.fillStyle=g.big?'#ffe36a':'#54dbff';ctx.fillRect(-5,-5,10,10);ctx.fillStyle='#fff9';ctx.fillRect(-3,-3,4,4);ctx.restore()};
const renderScale=.88;for(const sel of ['#game','#v4fx']){const c=document.querySelector(sel);if(!c)continue;c.width=Math.round(540*renderScale);c.height=Math.round(960*renderScale);const x=c.getContext('2d');x.setTransform(renderScale,0,0,renderScale,0,0)}
A.v4.performance='static-arena+enemy-sprite-cache+lite-projectiles+fillrate-88';A.v4.renderScale=renderScale;
})();