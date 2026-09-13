(function(){
'use strict';
const A=window.HarunSurvivorArt;if(!A)return;const TAU=Math.PI*2;
function path(ctx,pts,fill,stroke=null,w=1){ctx.beginPath();ctx.moveTo(pts[0][0],pts[0][1]);for(let i=1;i<pts.length;i++)ctx.lineTo(pts[i][0],pts[i][1]);ctx.closePath();ctx.fillStyle=fill;ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=w;ctx.stroke()}}
function oval(ctx,x,y,rx,ry,fill,a=1){ctx.save();ctx.globalAlpha=a;ctx.fillStyle=fill;ctx.beginPath();ctx.ellipse(x,y,rx,ry,0,0,TAU);ctx.fill();ctx.restore()}
function glow(ctx,x,y,r,color,a=.25){ctx.save();ctx.globalAlpha=a;ctx.shadowColor=color;ctx.shadowBlur=r*.85;ctx.fillStyle=color;ctx.beginPath();ctx.arc(x,y,r*.42,0,TAU);ctx.fill();ctx.restore()}
function drawHarun(ctx,p,t){const x=p.x,y=p.y,bob=Math.sin(t*7.5)*1.1,walk=Math.sin((p.walk||0)*1.8+t*10)*2.2,aim=p.aim||-Math.PI/2;
  ctx.save();ctx.translate(x,y+bob);if(p.hitFlash>0)ctx.globalAlpha=.7;
  oval(ctx,0,29,28,10,'#020507',.38);glow(ctx,0,1,40,'#d9b35f',.10);
  // flowing mantle and robe: broad cloth silhouette, no armor blocks.
  const rg=ctx.createLinearGradient(-18,-8,20,37);rg.addColorStop(0,'#23222b');rg.addColorStop(.48,'#12151b');rg.addColorStop(1,'#05070a');
  path(ctx,[[-17,-8],[-25,8],[-22,28],[-11,38],[0,42],[12,38],[23,27],[25,8],[16,-8]],rg,'#090b0e',2);
  // asymmetric crimson shoulder mantle.
  const cg=ctx.createLinearGradient(-20,-9,12,26);cg.addColorStop(0,'#7c2a32');cg.addColorStop(1,'#2d111a');path(ctx,[[-18,-8],[-25,8],[-15,24],[-3,18],[5,-5]],cg,'#241016',1.6);
  // linen sash and solar seal.
  ctx.strokeStyle='#c99e55';ctx.lineWidth=4;ctx.beginPath();ctx.moveTo(-13,7);ctx.lineTo(13,18);ctx.stroke();ctx.fillStyle='#f2d27d';ctx.beginPath();ctx.arc(3,10,4.2,0,TAU);ctx.fill();ctx.strokeStyle='#6f5425';ctx.lineWidth=1.2;ctx.stroke();ctx.fillStyle='#201a10';ctx.beginPath();ctx.arc(3,10,1.5,0,TAU);ctx.fill();
  // legs under robe, light and narrow.
  ctx.strokeStyle='#151a20';ctx.lineCap='round';ctx.lineWidth=7;ctx.beginPath();ctx.moveTo(-7,26);ctx.lineTo(-10+walk,38);ctx.moveTo(7,26);ctx.lineTo(10-walk,38);ctx.stroke();
  // hands and forearms, cloth sleeves rather than pauldrons.
  ctx.strokeStyle='#1b2027';ctx.lineWidth=7;ctx.beginPath();ctx.moveTo(-13,-2);ctx.lineTo(-20,11);ctx.moveTo(13,-2);ctx.lineTo(20,10);ctx.stroke();oval(ctx,-20,12,4.2,4.8,'#d8ac8d');oval(ctx,20,11,4.2,4.8,'#d8ac8d');
  // human head with ritual headband and swept hair.
  const skin=ctx.createRadialGradient(-5,-29,2,0,-24,18);skin.addColorStop(0,'#ffe6c5');skin.addColorStop(.58,'#d5a281');skin.addColorStop(1,'#8e5f54');ctx.fillStyle=skin;ctx.strokeStyle='#2c2021';ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,-26,16,0,TAU);ctx.fill();ctx.stroke();
  ctx.fillStyle='#101318';ctx.beginPath();ctx.arc(0,-31,16,Math.PI,TAU);ctx.quadraticCurveTo(12,-30,14,-24);ctx.quadraticCurveTo(5,-29,-2,-27);ctx.quadraticCurveTo(-9,-31,-15,-24);ctx.closePath();ctx.fill();
  // thin golden initiatic band.
  ctx.strokeStyle='#d6ad57';ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,-26,14.5,3.55,5.88);ctx.stroke();ctx.fillStyle='#e7c36c';ctx.beginPath();ctx.arc(0,-39,2.6,0,TAU);ctx.fill();
  oval(ctx,-5.3,-26.8,1.8,2.2,'#11161a');oval(ctx,5.3,-26.8,1.8,2.2,'#11161a');ctx.strokeStyle='#754d45';ctx.lineWidth=1.2;ctx.beginPath();ctx.arc(0,-20,4.4,.25,Math.PI-.25);ctx.stroke();
  // ritual blade/wand follows aim but reads ceremonial, not rifle/soldier.
  ctx.save();ctx.rotate(aim+Math.PI/2);ctx.strokeStyle='#6f4b2d';ctx.lineWidth=5;ctx.beginPath();ctx.moveTo(6,-4);ctx.lineTo(6,-16);ctx.stroke();ctx.strokeStyle='#d8bd79';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(1,-7);ctx.lineTo(1,-34);ctx.stroke();ctx.strokeStyle='#fff0bd';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(0,-8);ctx.lineTo(0,-35);ctx.stroke();path(ctx,[[-3,-34],[1,-42],[5,-34]],'#ecd786','#6d5831',1);ctx.restore();
  // subtle Eye/solar arc rather than armor halo.
  ctx.strokeStyle='rgba(231,195,108,.62)';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(0,-26,20,-2.5,-.55);ctx.stroke();ctx.restore();
}
A.drawHero=drawHarun;
window.HarunV5Art=Object.freeze({version:'5.1.0',style:'ritual-initiatic-procedural',drawHero:drawHarun});
})();