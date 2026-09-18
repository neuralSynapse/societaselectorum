
(function(){
'use strict';
const canvas=document.getElementById('game'),ctx=canvas.getContext('2d');
const VERSION='13.0.0-tycoon-reference-parity';
const BASE_W=540,TW=72,TH=36,TAU=Math.PI*2;
let W=540,H=960,viewportMode='mobile',sceneZoom=1.18;
const $=s=>document.querySelector(s);
const mobileInput=window.CHRONICA_MOBILE_INPUT||null;
const perf=window.CHRONICA_PERFORMANCE||null;
const reducedMotion=()=>window.matchMedia?.('(prefers-reduced-motion: reduce)')?.matches||false;
const runtimeErrors=[];
const captureError=(kind,e)=>{runtimeErrors.push({kind,message:String(e?.message||e?.reason||e||'erro'),at:Date.now()});if(runtimeErrors.length>20)runtimeErrors.shift()};
window.addEventListener('error',e=>captureError('error',e));
window.addEventListener('unhandledrejection',e=>captureError('promise',e));
const UI={resource:$('#resourceCount'),grain:$('#grainCount'),meat:$('#meatCount'),coin:$('#obolCount'),carry:$('#carryCount'),level:$('#levelCount'),phase:$('#phaseCount'),phaseName:$('#phaseName'),glory:$('#legacyGlory'),seal:$('#legacySeal'),eye:$('#legacyEye'),opus:$('#legacyOpus'),arcana:$('#legacyArcana'),objective:$('#objectiveText'),objectiveKicker:$('#objectiveKicker'),tip:$('#moveTip'),joy:$('#touchJoy'),knob:$('#touchJoy i'),pause:$('#pauseOverlay'),start:$('#startOverlay'),victory:$('#victoryOverlay'),pauseBtn:$('#pauseBtn'),resume:$('#resumeBtn'),restart:$('#restartBtn'),restartVictory:$('#restartVictory'),music:$('#musicVol'),sfx:$('#sfxVol'),musicVal:$('#musicVal'),sfxVal:$('#sfxVal')};
const perfProfile=perf?.profile?.()||{dpr:1.25};
const DPR=Math.min(Number(perfProfile.dpr)||1.25,window.devicePixelRatio||1.25);
function syncViewport(){
  const vh=Math.max(420,Math.round(window.visualViewport?.height||window.innerHeight||960));
  const vw=Math.max(320,Math.round(window.visualViewport?.width||window.innerWidth||540));
  document.documentElement.style.setProperty('--app-h',vh+'px');
  document.documentElement.style.setProperty('--app-w',vw+'px');
  const r=canvas.getBoundingClientRect(),rw=Math.max(1,r.width),rh=Math.max(1,r.height),aspect=rw/rh;
  const desktop=rw>=720&&aspect>=.78;
  let nextW,nextH;
  if(desktop){
    viewportMode='desktop';sceneZoom=aspect>1.9?1.5:1.42;
    nextH=900;
    nextW=Math.max(720,Math.min(1920,Math.round(nextH*aspect)));
  }else{
    viewportMode='mobile';sceneZoom=1.22;
    nextW=BASE_W;
    nextH=Math.max(820,Math.min(1280,Math.round(nextW/aspect)));
  }
  if(nextW!==W||nextH!==H||canvas.width!==Math.round(nextW*DPR)||canvas.height!==Math.round(nextH*DPR)){
    W=nextW;H=nextH;canvas.width=Math.round(W*DPR);canvas.height=Math.round(H*DPR);ctx.setTransform(DPR,0,0,DPR,0,0);
  }
  document.documentElement.dataset.viewportMode=viewportMode;
}
syncViewport();
const audio=window.MUNDUSAudio||null;
if(audio){audio.configure({game:'survivor',profile:{bpm:104,music:.47,sfx:.91,ui:.8,amb:.42}});audio.setState('menu',{intensity:.2})}
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const lerp=(a,b,t)=>a+(b-a)*t;
const dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
const hash=(x,y,k=0)=>{let n=Math.sin(x*127.1+y*311.7+k*74.7)*43758.5453;return n-Math.floor(n)};
const isoRaw=(x,y)=>({x:(x-y)*TW*.5,y:(x+y)*TH*.5});
let camera={x:0,y:0},shake=0,shakeX=0,shakeY=0,started=false,paused=false,last=performance.now(),time=0,idle=0,lastCombat=false;
let runState='menu',deathTimer=0,victoryTimer=0,frameEma=16.7;
let pointer={active:false,id:null,ox:0,oy:0,box:0,boy:0,x:0,y:0,vx:0,vy:0,strength:0,targetX:0,targetY:0,mode:'floating'};
let keys={};
const walkZones=[
 {x0:2.8,y0:11.0,x1:11.3,y1:19.4,type:'room'},
 {x0:10.0,y0:9.0,x1:18.6,y1:17.1,type:'room'},
 {x0:7.5,y0:6.7,x1:14.8,y1:13.1,type:'hall'},
 {x0:13.4,y0:5.6,x1:20.4,y1:11.9,type:'hall'},
 {x0:7.5,y0:-.2,x1:22.7,y1:9.3,type:'field'},
 {x0:.4,y0:18.2,x1:11.8,y1:24.2,type:'market'}
];
const floorCells=[];
for(let y=0;y<25;y++)for(let x=0;x<25;x++){
  const cx=x+.5,cy=y+.5,z=walkZones.find(q=>cx>=q.x0&&cx<=q.x1&&cy>=q.y0&&cy<=q.y1);
  if(z)floorCells.push({x,y,type:z.type});
}
floorCells.sort((a,b)=>(a.x+a.y)-(b.x+b.y));

function isWalkable(x,y){return walkZones.some(q=>x>=q.x0&&x<=q.x1&&y>=q.y0&&y<=q.y1)}
function isWalkableRadius(x,y,r=.16){return isWalkable(x-r,y)&&isWalkable(x+r,y)&&isWalkable(x,y-r)&&isWalkable(x,y+r)}
function typeAt(x,y){const z=walkZones.slice().reverse().find(q=>x>=q.x0&&x<=q.x1&&y>=q.y0&&y<=q.y1);return z?z.type:null}
function hasLineOfSight(a,b){for(let i=1;i<8;i++){const t=i/8;if(!isWalkable(lerp(a.x,b.x,t),lerp(a.y,b.y,t)))return false}return true}
function enemyCanWalk(e,x,y){const t=walkZones.slice().reverse().find(q=>x>=q.x0&&x<=q.x1&&y>=q.y0&&y<=q.y1)?.type;return t==='field'||t==='hall'||t==='market'}
function moveEnemy(e,dx,dy,dt){const nx=e.x+dx*e.speed*dt,ny=e.y+dy*e.speed*dt;if(enemyCanWalk(e,nx,e.y))e.x=nx;if(enemyCanWalk(e,e.x,ny))e.y=ny}
function project(x,y){const p=isoRaw(x,y);return{x:p.x-camera.x+W*.5+shakeX,y:p.y-camera.y+H*.56+shakeY}}
function rr(x,y,w,h,r,fill,stroke,lw=1){ctx.beginPath();ctx.roundRect(x,y,w,h,r);if(fill){ctx.fillStyle=fill;ctx.fill()}if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=lw;ctx.stroke()}}
function line(x1,y1,x2,y2,color,w=1,a=1){ctx.save();ctx.globalAlpha=a;ctx.strokeStyle=color;ctx.lineWidth=w;ctx.lineCap='round';ctx.beginPath();ctx.moveTo(x1,y1);ctx.lineTo(x2,y2);ctx.stroke();ctx.restore()}
function poly(pts,fill,stroke=null,lw=1){ctx.beginPath();ctx.moveTo(pts[0][0],pts[0][1]);for(let i=1;i<pts.length;i++)ctx.lineTo(pts[i][0],pts[i][1]);ctx.closePath();ctx.fillStyle=fill;ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=lw;ctx.stroke()}}
function ell(x,y,rx,ry,fill,a=1,rot=0){ctx.save();ctx.globalAlpha*=a;ctx.translate(x,y);ctx.rotate(rot);ctx.fillStyle=fill;ctx.beginPath();ctx.ellipse(0,0,rx,ry,0,0,TAU);ctx.fill();ctx.restore()}
function glow(x,y,r,color,a=.25){ctx.save();ctx.globalAlpha=a;ctx.shadowColor=color;ctx.shadowBlur=r;ctx.fillStyle=color;ctx.beginPath();ctx.arc(x,y,Math.max(2,r*.12),0,TAU);ctx.fill();ctx.restore()}
function diamond(x,y,fill,stroke='#332c25'){poly([[x,y-TH*.5],[x+TW*.5,y],[x,y+TH*.5],[x-TW*.5,y]],fill,stroke,.8)}
function floorColor(cell){
  const phase=(level-1)%4,n=hash(cell.x,cell.y,level);
  if(cell.type==='field'){const sets=[['#20342d','#1b3029'],['#26352b','#1e2c25'],['#1c3334','#172b2d'],['#2d3227','#242a22']],s=sets[phase];return n>.5?s[0]:s[1]}
  const sets=[['#3b3c3b','#343635','#2f3332'],['#403b38','#383532','#302f2d'],['#363b40','#30363b','#2b3035'],['#403d34','#38362f','#302f2a']],s=sets[phase];
  return n>.66?s[0]:n>.32?s[1]:s[2]
}
function isFieldPath(x,y){return Math.abs((x-y)-7)<1.35||Math.abs(x-15)<.82}
const fieldCrops=[];
for(const cell of floorCells){
  if(cell.type!=='field')continue;
  const cx=cell.x+.5,cy=cell.y+.5;
  if(isFieldPath(cx,cy))continue;
  const density=hash(cell.x,cell.y,17)>.23?2:1;
  for(let i=0;i<density;i++){
    const ox=(hash(cell.x,cell.y,i+31)-.5)*.48,oy=(hash(cell.x,cell.y,i+47)-.5)*.42;
    const max=1+Math.floor(hash(cell.x,cell.y,i+63)*3);
    fieldCrops.push({x:cx+ox,y:cy+oy,max,amount:max,cut:0,respawn:0,seed:cell.x*137+cell.y*29+i*911});
  }
}
function resetFieldCrops(){
  const bonus=Math.min(2,Math.floor((level-1)/4));
  for(const h of fieldCrops){h.max=Math.max(1,Math.min(4,h.max+bonus));h.amount=h.max;h.cut=0;h.respawn=0}
}
function drawFloor(){
  const phase=(level-1)%4,sky=['#06100d','#0a100d','#061013','#101008'][phase],g=ctx.createLinearGradient(0,0,0,H);
  g.addColorStop(0,sky);g.addColorStop(.62,'#07100d');g.addColorStop(1,'#030605');ctx.fillStyle=g;ctx.fillRect(0,0,W,H);
  for(const cell of floorCells){
    const p=project(cell.x+.5,cell.y+.5);
    if(p.x<-TW||p.x>W+TW||p.y<-TH||p.y>H+TH)continue;
    diamond(p.x,p.y,floorColor(cell),cell.type==='field'?'#29483c':'#4d4c47');
    if(cell.type!=='field'&&hash(cell.x,cell.y,9)>.78)line(p.x-TW*.18,p.y,p.x+TW*.18,p.y,'#ffffff10',1);
  }
}
function drawCrop(h){
  if(h.amount<=.02)return;
  const p=project(h.x,h.y);if(p.x<-55||p.x>W+55||p.y<-75||p.y>H+45)return;const ratio=clamp(h.amount/h.max,0,1),tier=perf?.tier?.()||'medium';
  const count=Math.max(2,Math.round((tier==='low'?4:tier==='high'?8:6)*(.42+.58*ratio)));
  const sway=Math.sin(time*2.6+h.seed)*1.4;
  for(let i=0;i<count;i++){
    const a=hash(h.seed,i,1),b=hash(h.seed,i,2),ox=(a-.5)*28,oy=(b-.5)*11,hh=13+hash(h.seed,i,3)*16;
    line(p.x+ox,p.y+oy,p.x+ox-2+sway*.28,p.y+oy-hh,'#8e7831',1.35,.92);
    line(p.x+ox-2+sway*.28,p.y+oy-hh,p.x+ox+4+sway*.4,p.y+oy-hh-3,'#d6ba50',1.2,.95);
    line(p.x+ox,p.y+oy-hh*.58,p.x+ox+4+sway*.3,p.y+oy-hh*.7,'#ad9439',1,.82);
  }
  if(h.cut>0){
    const q=clamp(h.cut,0,1);ctx.save();ctx.globalAlpha=.35+.45*q;ctx.strokeStyle='#e8efb5';ctx.lineWidth=2;ctx.beginPath();ctx.arc(p.x,p.y-5,17+q*7,-2.6,-.15);ctx.stroke();ctx.restore();
  }
}
const forest=[
 {x:7.1,y:-1.0,s:1.1},{x:9.1,y:-1.6,s:.9},{x:11.4,y:-1.2,s:1.25},{x:14.0,y:-1.8,s:1.0},{x:17.0,y:-1.4,s:1.2},{x:20.0,y:-1.1,s:1.0},{x:22.5,y:.2,s:1.2},
 {x:23.3,y:2.8,s:1.05},{x:23.7,y:5.1,s:1.25},{x:7.0,y:2.0,s:1.15},{x:6.7,y:4.6,s:.9},{x:6.9,y:7.0,s:1.2}
];
function drawTree(t){
  const p=project(t.x,t.y),s=t.s||1;ell(p.x,p.y+4,15*s,6*s,'#000',.28);
  line(p.x,p.y+4,p.x,p.y-25*s,'#171a15',4*s,.85);
  for(let i=0;i<3;i++){const yy=p.y-12*s-i*12*s,w=(20-i*4)*s;poly([[p.x,yy-25*s],[p.x-w,yy+9*s],[p.x+w,yy+9*s]],i%2?'#10261f':'#0d211b')}
}
function drawForest(){for(const t of forest)drawTree(t)}
function boundaryWallSegments(){
  const seg=[];
  const set=new Set(floorCells.filter(c=>c.type!=='field').map(c=>c.x+','+c.y));
  for(const c of floorCells){
    if(c.type==='field')continue;
    const dirs=[[1,0,'e'],[-1,0,'w'],[0,1,'s'],[0,-1,'n']];
    for(const d of dirs){
      const nx=c.x+d[0],ny=c.y+d[1];
      if(!set.has(nx+','+ny)){
        // omit some boundaries where room naturally opens into field/hall
        const mx=c.x+.5+d[0]*.5,my=c.y+.5+d[1]*.5;
        if(typeAt(mx,my)==='field')continue;
        seg.push({x:c.x,y:c.y,dir:d[2]});
      }
    }
  }return seg;
}
const wallSegs=boundaryWallSegments();
function drawWallSegment(s){
  const x=s.x,y=s.y,h=19;let a,b;
  if(s.dir==='n'){a=project(x,y);b=project(x+1,y)}
  else if(s.dir==='s'){a=project(x,y+1);b=project(x+1,y+1)}
  else if(s.dir==='w'){a=project(x,y);b=project(x,y+1)}
  else{a=project(x+1,y);b=project(x+1,y+1)}
  const topA=[a.x,a.y-h],topB=[b.x,b.y-h];
  poly([[a.x,a.y],[b.x,b.y],[topB[0],topB[1]],[topA[0],topA[1]]],s.dir==='n'||s.dir==='w'?'#33261d':'#251b17','#6b4d34',1);
  line(topA[0],topA[1],topB[0],topB[1],'#876144',4,.85);line(a.x,a.y,b.x,b.y,'#171210',2,.75);
  for(let t=.16;t<.95;t+=.22){const xx=lerp(topA[0],topB[0],t),yy=lerp(topA[1],topB[1],t);ell(xx,yy+1,2.1,1.2,'#b27645',.55)}
}
function drawWalls(){for(const s of wallSegs)drawWallSegment(s)}
const props=[
 {kind:'pedestal',x:4.4,y:12.2,icon:'⚔'},
 {kind:'pedestal',x:17.4,y:10.2,icon:'✦'},
 {kind:'bench',x:5.3,y:17.7},{kind:'bench',x:12.3,y:15.9},{kind:'sacks',x:8.1,y:18.0},{kind:'sacks',x:11.5,y:10.4},
 {kind:'torch',x:3.1,y:14.1},{kind:'torch',x:10.8,y:18.5},{kind:'torch',x:18.1,y:13.7},{kind:'rune',x:15.9,y:16.1}
];
const acolytes=[
 {x:9.3,y:17.2,homeX:9.3,homeY:17.2,rescued:false,follow:0,bubble:'☉'},
 {x:10.2,y:16.7,homeX:10.2,homeY:16.7,rescued:false,follow:1,bubble:'≡'},
 {x:11.2,y:16.3,homeX:11.2,homeY:16.3,rescued:false,follow:2,bubble:'△'},
 {x:12.2,y:15.8,homeX:12.2,homeY:15.8,rescued:false,ambient:true,bubble:'◌'},
 {x:13.0,y:15.3,homeX:13.0,homeY:15.3,rescued:false,ambient:true,bubble:'⚗'}
];
const depot={x:6.2,y:16.0,input:0,process:0,name:'MOINHO DO LIMIAR'};
const harvestNodes=fieldCrops;
const builds=[
 {id:'butcher',x:10.8,y:15.1,cost:28,invest:0,done:false,name:'AÇOUGUE DO LIMIAR',height:0,tier:0,product:'meat',process:0,input:0},
 {id:'scriptorium',x:13.0,y:13.2,cost:68,invest:0,done:false,name:'SCRIPTORIUM',height:0,tier:0,product:'scroll',process:0,input:0},
 {id:'library',x:16.0,y:11.1,cost:145,invest:0,done:false,name:'BIBLIOTHECA',height:0,tier:0,product:'book',process:0,input:0},
 {id:'relicary',x:18.0,y:8.0,cost:280,invest:0,done:false,name:'RELICÁRIO',height:0,tier:0,product:'relic',process:0,input:0}
];
const marketGate={x:1.2,y:23.0};
const marketStalls=[
 {x:4.6,y:20.7,label:'BANCA I'},{x:6.5,y:21.15,label:'BANCA II'},{x:8.4,y:20.7,label:'BANCA III'}
];
const goods={provision:0,meat:0,scroll:0,book:0,relic:0};
const upgrades=[
 {id:'scythe',x:3.0,y:22.0,name:'FOICE',icon:'☽',level:0,max:5,invest:0,base:18,desc:'CORTE MAIS RÁPIDO'},
 {id:'pack',x:4.6,y:22.55,name:'CARGA',icon:'▣',level:0,max:5,invest:0,base:22,desc:'MAIS CAPACIDADE'},
 {id:'farm',x:6.2,y:22.0,name:'CEIFEIRO',icon:'♟',level:0,max:5,invest:0,base:35,desc:'COLHEITA AUTOMÁTICA'},
 {id:'market',x:7.8,y:22.55,name:'PREGÃO',icon:'¤',level:0,max:5,invest:0,base:30,desc:'MAIS CLIENTES'},
 {id:'guard',x:9.4,y:22.0,name:'GUARDA',icon:'⚔',level:0,max:5,invest:0,base:38,desc:'DEFESA AUTOMÁTICA'},
 {id:'craft',x:10.6,y:20.7,name:'OFÍCIO',icon:'⚒',level:0,max:5,invest:0,base:44,desc:'PRODUÇÃO MAIS RÁPIDA'}
];
const automation={harvestCd:0,guardCd:0};
const metaLoot={glory:0,seal:0,eye:0,opus:0,arcana:0};
const PRODUCT={
 provision:{label:'PROVISÃO',icon:'◫',price:2},
 meat:{label:'CARNE',icon:'●',price:4},
 scroll:{label:'PERGAMINHO',icon:'≡',price:8},
 book:{label:'LIVRO',icon:'▤',price:14},
 relic:{label:'RELICÁRIO',icon:'✦',price:24}
};
let fx=[],drops=[],enemies=[],boss=null,customers=[],objective=0,kills=0,fieldKills=0,rescued=0,resource=0,grain=0,meat=0,coins=0,sales=0,salesLevel=0,level=1,bestLevel=1,levelTarget=6,levelTimer=0,waveTimer=0,customerTimer=0,harvestSfxCd=0,buildSfxCd=0,cutFxCd=0;
const player={x:5.2,y:15.2,hp:100,maxHp:100,speed:7.25,accel:44,decel:58,vx:0,vy:0,atkCd:0,hitCd:0,walk:0,moveBlend:0,angle:0,attackPulse:0,cutPulse:0,stepCd:0};
try{bestLevel=Math.max(1,Number(localStorage.getItem('harun-roomrun-best'))||1)}catch(_){}

function upgrade(id){return upgrades.find(u=>u.id===id)}
function upgradeCost(u){return Math.ceil(u.base*Math.pow(1.72,u.level))}
function carryCapacity(){return 24+rescued*4+Math.min(24,(level-1)*2)+metaLoot.seal*2+upgrade('pack').level*10}
function cutSpeed(){return 6.2*(1+upgrade('scythe').level*.34)}
function phaseNumber(){return Math.min(7,objective+1)}
function phaseName(){return ['COLHEITA','MERCADO','ACÓLITOS','DEFESA','EXPANSÃO','PROVA','ASCENSÃO'][Math.min(6,objective)]}
function combatUnlocked(){return builds[0].done||objective>=3||level>1}
function carryLoad(){return grain+meat}
function freeCarry(){return Math.max(0,carryCapacity()-carryLoad())}
function requiredBuildCount(){return level<=1?2:level===2?3:4}
function levelSalesTarget(){return 10+level*5}
function buildAvailable(b){
  if(b.done)return true;
  if(b.id==='butcher')return sales>=3;
  if(b.id==='scriptorium')return builds[0].done&&sales>=7;
  if(b.id==='library')return level>=2&&builds[1].done&&sales>=14;
  if(b.id==='relicary')return level>=3&&builds[2].done&&sales>=24;
  return false
}
function productAvailable(kind){
  if(kind==='provision')return true;
  const b=builds.find(x=>x.product===kind);return !!b?.done
}
function availableProducts(){return Object.keys(PRODUCT).filter(productAvailable)}
function goodsTotal(){return Object.values(goods).reduce((a,b)=>a+b,0)}
function resetRun(){
  player.x=5.2;player.y=15.2;player.vx=0;player.vy=0;player.hp=100;player.maxHp=100;player.atkCd=0;player.hitCd=0;player.walk=0;player.moveBlend=0;player.angle=0;player.attackPulse=0;player.cutPulse=0;player.stepCd=0;lastCombat=false;
  clearTimeout(deathTimer);clearTimeout(victoryTimer);deathTimer=victoryTimer=0;
  objective=0;kills=0;fieldKills=0;rescued=0;resource=0;grain=0;meat=0;coins=0;sales=0;salesLevel=0;level=1;levelTarget=6;levelTimer=0;waveTimer=2.5;customerTimer=.7;harvestSfxCd=0;buildSfxCd=0;cutFxCd=0;automation.harvestCd=0;automation.guardCd=0;
  fx=[];drops=[];enemies=[];customers=[];boss=null;depot.input=0;depot.process=0;
  Object.keys(goods).forEach(k=>goods[k]=0);Object.keys(metaLoot).forEach(k=>metaLoot[k]=0);
  resetFieldCrops();
  builds.forEach(b=>{b.invest=0;b.done=false;b.height=0;b.tier=0;b.process=0;b.input=0});upgrades.forEach(u=>{u.level=0;u.invest=0});
  acolytes.forEach(a=>{a.x=a.homeX??a.x;a.y=a.homeY??a.y;a.rescued=false;a.cool=0;a.workCd=0});
  updateHUD();
}
function spawnInitialEnemies(){
  if(objective<3&&level===1)return;
  const pts=[[14,4.6],[16.2,3.5],[18.2,5.4],[19.4,2.8],[12.8,2.8],[20.5,6.2],[11.2,4.2],[21.2,4.7],[15.2,6.0],[18.9,7.0]];
  const count=Math.min(pts.length,4+Math.floor(level/2));for(let i=0;i<count;i++){const p=pts[i];spawnEnemy(p[0],p[1],i%3===0?'hound':'shade',level%5===0&&i===count-1)}
}
function spawnEnemy(x,y,kind='shade',elite=false){
  const scale=1+(level-1)*.12,hp=Math.round((elite?70:kind==='hound'?28:22)*scale),speed=(kind==='hound'?2.35:1.7)*(1+Math.min(.28,(level-1)*.012));
  enemies.push({x,y,kind,hp,maxHp:hp,r:elite ? .42 : .27,speed,hit:0,dead:false,elite});
}
function spawnBoss(){
  if(boss&&!boss.dead)return;
  const scale=1+(level-1)*.18,bhp=Math.round(360*scale);
  enemies=enemies.filter(e=>e.dead);waveTimer=0;
  boss={x:18.3,y:3.3,hp:bhp,maxHp:bhp,r:.72,speed:1.18*(1+Math.min(.2,(level-1)*.01)),hit:0,dead:false,name:'OBSERVADOR CEGO',phase:0,specialCd:2.5,telegraph:0,struck:false};
  enemies.push(boss);objective=5;updateHUD();
  audio&&audio.setState('boss',{intensity:.95});audio&&audio.sfx('boss_windup',{gain:1});window.MUNDUSMusic?.sync?.();
}
function updateHUD(){
  if(UI.resource)UI.resource.textContent=Math.floor(resource);
  if(UI.grain)UI.grain.textContent=Math.floor(grain);
  if(UI.meat)UI.meat.textContent=Math.floor(meat);
  if(UI.coin)UI.coin.textContent=Math.floor(coins);
  if(UI.carry)UI.carry.textContent=Math.floor(carryLoad())+'/'+carryCapacity();
  if(UI.level)UI.level.textContent=String(level);if(UI.phase)UI.phase.textContent=phaseNumber()+'/7';if(UI.phaseName)UI.phaseName.textContent=phaseName();
  if(UI.glory)UI.glory.textContent=metaLoot.glory;if(UI.seal)UI.seal.textContent=metaLoot.seal;if(UI.eye)UI.eye.textContent=metaLoot.eye;if(UI.opus)UI.opus.textContent=metaLoot.opus;if(UI.arcana)UI.arcana.textContent=metaLoot.arcana;
  if(UI.objectiveKicker)UI.objectiveKicker.textContent='NÍVEL '+level+' · FASE '+phaseNumber()+'/7 · '+phaseName();
  let text='';
  if(objective===0)text='CORTE SEM PARAR · CARGA '+Math.floor(carryLoad())+'/'+carryCapacity()+' · PROVISÕES '+goods.provision;
  else if(objective===1)text='PEREGRINOS NO MERCADO EXTERNO · VENDAS '+sales+'/3 · ÓBOLOS '+Math.floor(coins);
  else if(objective===2)text='DESPERTE OS 3 ACÓLITOS · '+rescued+'/3';
  else if(objective===3){
    const b=builds[0];text=b.done?'DEFENDA O MERCADO · CARREGUE CARNE AO AÇOUGUE':'ERGA O AÇOUGUE · '+Math.ceil(Math.max(0,b.cost-b.invest))+' ÓBOLOS';
  }else if(objective===4){
    const next=builds.find(b=>!b.done&&buildAvailable(b)),up=upgrades.find(u=>u.level<u.max);text=next?'EXPANDA: '+next.name+' · '+Math.ceil(Math.max(0,next.cost-next.invest))+' ÓBOLOS':up?'EVOLUA/AUTOMATIZE NO MERCADO · '+up.name+' NV.'+up.level:'VENDAS DO DISTRITO '+salesLevel+'/'+levelSalesTarget();
  }else if(objective===5)text=boss?'OBSERVADOR CEGO · '+Math.ceil(Math.max(0,boss.hp))+'/'+boss.maxHp:'A PROVA SE APROXIMA';
  else text='A CIDADELA SE EXPANDE · PRÓXIMO NÍVEL';
  if(UI.objective)UI.objective.textContent=text;
}
function setObjective(n){if(objective===n)return;objective=n;updateHUD();fx.push({kind:'banner',text:UI.objective?.textContent||'',t:0,d:1.15});audio&&audio.sfx('special_room_activate',{gain:.72})}
function emit(kind,x,y,data={}){fx.push(Object.assign({kind,x,y,t:0,d:.65},data))}
function addSale(kind,c){
  const p=PRODUCT[kind],pay=p.price+Math.floor((level-1)*.7)+Math.floor(metaLoot.glory/10);coins+=pay;sales++;salesLevel++;
  emit('sale',c.x,c.y,{text:'+'+pay+' ÓB'});audio&&audio.sfx(kind==='scroll'||kind==='book'?'arcana':'pickup',{gain:.7,pitch:1.05});
  if(objective===0)setObjective(1);
  if(objective===1&&sales>=3)setObjective(rescued<3?2:3);
  updateHUD();
}
function pickupDrop(d){
  const room=freeCarry();if(room<=.01)return false;
  const got=Math.min(room,d.value);meat+=got;d.value-=got;
  emit('pickup',d.x,d.y,{text:'+'+Math.ceil(got)+' CARNE'});audio&&audio.sfx('pickup',{gain:.68,pitch:.9});try{navigator.vibrate?.(4)}catch(_){}
  if(d.value<=.05)d.dead=true;updateHUD();return true
}
function completeLevel(){
  if(runState!=='playing'||levelTimer>0)return;
  objective=6;levelTimer=1.25;resource+=3+Math.floor(level*.5);player.hp=Math.min(player.maxHp,player.hp+28);
  builds.filter(b=>b.done).forEach(b=>b.tier=(b.tier||0)+1);
  bestLevel=Math.max(bestLevel,level+1);metaLoot.glory+=5+level;if(level%2===0)metaLoot.seal++;if(level%3===0)metaLoot.eye++;if(level%4===0)metaLoot.opus++;if(level%5===0)metaLoot.arcana++;try{localStorage.setItem('harun-roomrun-best',String(bestLevel))}catch(_){}
  updateHUD();fx.push({kind:'banner',text:'DISTRITO '+level+' CONSOLIDADO · +'+(3+Math.floor(level*.5))+' ESSÊNCIAS',t:0,d:1.2});
  audio&&audio.setState('ritual',{intensity:.5});audio&&audio.sfx('level_up',{gain:1});window.MUNDUSMusic?.sync?.();try{navigator.vibrate?.([16,28,24])}catch(_){}
}
function beginNextLevel(){
  level++;levelTimer=0;objective=0;fieldKills=0;kills=0;boss=null;enemies=[];drops=[];customers=[];salesLevel=0;sales=0;waveTimer=2.5;customerTimer=.5;
  player.maxHp=Math.min(190,100+(level-1)*3);player.hp=player.maxHp;player.vx=player.vy=0;player.x=5.2;player.y=15.2;
  grain=Math.min(grain,Math.ceil(carryCapacity()*.35));meat=Math.min(meat,Math.ceil(carryCapacity()*.3));
  resetFieldCrops();
  if(level>1&&acolytes.filter(a=>a.rescued&&!a.ambient).length>=3)rescued=3;
  updateHUD();audio&&audio.setState('explore',{intensity:.4});fx.push({kind:'banner',text:'DISTRITO '+level+' · O MERCADO CRESCE',t:0,d:1.2});
}
function damageEnemy(e,dmg){
  if(e.dead||runState!=='playing')return;const power=1+(level-1)*.035+metaLoot.arcana*.05;e.hp=Math.max(0,e.hp-dmg*power);e.hit=.11;emit('damage',e.x,e.y,{text:String(Math.round(dmg*power)),crit:dmg>22});
  audio&&audio.sfx('impact',{gain:.45,pitch:e===boss ? .86 : 1});
  if(e.hp<=0){
    e.dead=true;kills++;if(e!==boss)fieldKills++;emit('burst',e.x,e.y,{big:e===boss});audio&&audio.sfx(e===boss?'boss_death':'enemy_death',{gain:e===boss ? 1 : .55});
    if(e===boss){resource+=2+Math.floor(level*.4);completeLevel()}
    else{const value=e.elite?9:e.kind==='hound'?6:4;drops.push({x:e.x,y:e.y,value,kind:'meat',dead:false,t:0})}
  }
}
function spawnFieldWave(){
  if(!combatUnlocked()||objective===5||levelTimer>0)return;
  const pts=[[10.2,4.8],[12.1,2.5],[14.4,4.1],[16.6,2.0],[18.9,4.8],[21.0,2.7],[20.7,6.5],[15.0,6.4],[9.0,6.8],[22.0,5.5]];
  const count=Math.min(10,3+Math.floor(level/2)+upgrade('guard').level);for(let i=0;i<count;i++){const p=pts[(i+level+fieldKills)%pts.length];spawnEnemy(p[0]+(Math.random()-.5)*.45,p[1]+(Math.random()-.5)*.35,i%3===0?'hound':'shade',level%4===0&&i===count-1)}
  audio&&audio.sfx('enemy_windup',{gain:.46});emit('banner',null,null,{text:'FERAS NO PERÍMETRO · CARNE DISPONÍVEL',d:.8});
}
function maintainEncounter(dt){
  if(!combatUnlocked()||objective===5||levelTimer>0)return;
  waveTimer-=dt;const alive=enemies.filter(e=>!e.dead&&e!==boss).length,minAlive=Math.min(7,2+Math.floor(level/2));
  if(alive<minAlive&&waveTimer<=0){waveTimer=Math.max(4.2,7.2-level*.12);spawnFieldWave()}
}
function customerTarget(kind,index=0){
  const stall=marketStalls[index%marketStalls.length],lane=Math.floor(index/marketStalls.length);
  return{x:stall.x+(lane%2?-.22:.22),y:stall.y+lane*.42}
}
function productForCustomer(){
  const pool=availableProducts();let weighted=[];
  for(const k of pool){const weight=k==='provision'?4:k==='meat'?3:k==='scroll'?2:k==='book'?1.5:1;for(let i=0;i<Math.ceil(weight);i++)weighted.push(k)}
  return weighted[Math.floor(Math.random()*weighted.length)]||'provision'
}
function spawnCustomer(){
  if(customers.length>=Math.min(10,5+Math.floor(level/2)))return;
  const want=productForCustomer(),q=customers.filter(c=>c.want===want&&c.state!=='leave').length,t=customerTarget(want,q);
  customers.push({x:marketGate.x+(Math.random()-.5)*.18,y:marketGate.y+(Math.random()-.5)*.16,want,state:'arrive',tx:t.x,ty:t.y,wait:0,buyFlash:0,speed:1.8+Math.random()*.28});
}
function moveNpcTo(n,tx,ty,dt){
  const dx=tx-n.x,dy=ty-n.y,m=Math.hypot(dx,dy);if(m<.04){n.x=tx;n.y=ty;return true}
  const d=Math.min(m,n.speed*dt);n.x+=dx/m*d;n.y+=dy/m*d;return false
}
function updateCustomers(dt){
  customerTimer-=dt;if(customerTimer<=0){customerTimer=Math.max(.38,1.85-level*.055-upgrade('market').level*.19);spawnCustomer()}
  for(const c of customers){
    c.buyFlash=Math.max(0,c.buyFlash-dt);
    if(c.state==='arrive'){if(moveNpcTo(c,c.tx,c.ty,dt)){c.state='wait';c.wait=0}}
    else if(c.state==='wait'){
      c.wait+=dt;if(goods[c.want]>0&&c.wait>.28){goods[c.want]-=1;addSale(c.want,c);c.state='leave';c.buyFlash=.6}
      else if(c.wait>12){c.state='leave'}
    }else if(c.state==='leave'){moveNpcTo(c,marketGate.x,marketGate.y,dt)}
  }
  customers=customers.filter(c=>!(c.state==='leave'&&Math.hypot(c.x-marketGate.x,c.y-marketGate.y)<.14));
}
function processBusiness(dt){
  const craftBoost=1+metaLoot.opus*.08;
  if(depot.input>=1){depot.process+=dt*(rescued>=1?2.3:1.7)*craftBoost;while(depot.process>=1&&depot.input>=1){depot.process-=1;depot.input-=1;goods.provision++;audio&&audio.sfx('pickup',{gain:.22,pitch:1.08})}}
  const butcher=builds[0],script=builds[1],library=builds[2],relic=builds[3];
  if(butcher.done&&butcher.input>=1){butcher.process+=dt*1.55*craftBoost;while(butcher.process>=1&&butcher.input>=1){butcher.process-=1;butcher.input-=1;goods.meat++}}
  if(script.done&&goods.provision>=2){script.process+=dt*(rescued>=2 ? .58 : .36)*craftBoost;if(script.process>=1){script.process-=1;goods.provision-=2;goods.scroll++;audio&&audio.sfx('arcana',{gain:.28})}}
  if(library.done&&goods.scroll>=2){library.process+=dt*.24*craftBoost;if(library.process>=1){library.process-=1;goods.scroll-=2;goods.book++;audio&&audio.sfx('arcana',{gain:.38})}}
  if(relic.done&&goods.book>=1&&goods.meat>=1){relic.process+=dt*.15*craftBoost;if(relic.process>=1){relic.process-=1;goods.book--;goods.meat--;goods.relic++;audio&&audio.sfx('ritual_seal',{gain:.32})}}
}
function checkBusinessProgress(){
  if(objective===1&&sales>=3)setObjective(rescued<3?2:3);
  if(objective===2&&rescued>=3)setObjective(3);
  if(objective===3&&builds[0].done)setObjective(4);
  const req=requiredBuildCount(),built=builds.slice(0,req).filter(b=>b.done).length;
  if(objective===4&&built>=req&&salesLevel>=levelSalesTarget()&&!boss)spawnBoss();
}
function interactionUpdate(dt){
  harvestSfxCd=Math.max(0,harvestSfxCd-dt);buildSfxCd=Math.max(0,buildSfxCd-dt);cutFxCd=Math.max(0,cutFxCd-dt);
  if(levelTimer>0){levelTimer-=dt;processBusiness(dt);updateCustomers(dt);if(levelTimer<=0)beginNextLevel();return}

  let cutTarget=null,cutDist=99;
  for(const h of harvestNodes){
    if(h.amount<=.02){
      h.cut=0;if(h.respawn>0){h.respawn-=dt;if(h.respawn<=0){h.amount=h.max;h.respawn=0}}
      continue;
    }
    const d=dist(player,h);
    if(d<.88&&d<cutDist&&freeCarry()>.05){cutTarget=h;cutDist=d}
    else h.cut=Math.max(0,(h.cut||0)-dt*3.2);
  }
  if(cutTarget){
    cutTarget.cut=(cutTarget.cut||0)+dt*6.2;
    player.cutPulse=.22;player.angle=Math.atan2(cutTarget.y-player.y,cutTarget.x-player.x);
    if(cutFxCd<=0){cutFxCd=.11;emit('cut',cutTarget.x,cutTarget.y,{angle:player.angle});audio&&audio.sfx('attack',{gain:.24,pitch:1.28+Math.random()*.08})}
    if(cutTarget.cut>=1){
      const yieldAmount=Math.min(cutTarget.amount,Math.max(.5,Math.floor(freeCarry())));
      if(yieldAmount>0){
        grain+=yieldAmount;cutTarget.amount-=yieldAmount;emit('pickup',cutTarget.x,cutTarget.y,{text:'+'+Math.ceil(yieldAmount)+' FEIXE'});
        audio&&audio.sfx('pickup',{gain:.42,pitch:1.14});try{navigator.vibrate?.(4)}catch(_){}
      }
      cutTarget.cut=0;
      if(cutTarget.amount<=.02){cutTarget.amount=0;cutTarget.respawn=7+Math.min(6,level*.3);audio&&audio.sfx('room_clear',{gain:.24,pitch:1.12})}
      updateHUD();
    }
  }

  if(dist(player,depot)<.92&&grain>.02){
    const take=Math.min(grain,dt*15);grain-=take;depot.input+=take;updateHUD();
    if(harvestSfxCd<=0){harvestSfxCd=.18;audio&&audio.sfx('pickup',{gain:.32,pitch:.98})}
  }
  if(builds[0].done&&dist(player,builds[0])<.92&&meat>.02){
    const take=Math.min(meat,dt*13);meat-=take;builds[0].input+=take;updateHUD();
    if(harvestSfxCd<=0){harvestSfxCd=.18;audio&&audio.sfx('pickup',{gain:.32,pitch:.82})}
  }

  for(const b of builds){
    if(b.done||!buildAvailable(b))continue;
    if(dist(player,b)<.92&&coins>.01){
      const take=Math.min(coins,b.cost-b.invest,dt*22);coins-=take;b.invest+=take;b.height=clamp(b.invest/b.cost,0,1);updateHUD();
      if(Math.random()<dt*10)emit('spark',b.x,b.y,{});
      if(buildSfxCd<=0){buildSfxCd=.22;audio&&audio.sfx('instrumenta',{gain:.34,pitch:.92+b.height*.2})}
      if(b.invest>=b.cost-.01){b.done=true;b.height=1;b.tier=1;audio&&audio.sfx('ritual_seal',{gain:.9});shake=4;try{navigator.vibrate?.([8,22,12])}catch(_){}
        if(b.id==='butcher'&&objective===3)setObjective(4);
      }
    }
  }

  if(objective===2){
    for(const a of acolytes){
      if(a.ambient||a.rescued)continue;
      if(dist(player,a)<.72){a.rescued=true;rescued++;audio&&audio.sfx('arcana',{gain:.6});emit('pickup',a.x,a.y,{text:'DESPERTO'});updateHUD()}
    }
  }

  processBusiness(dt);updateCustomers(dt);maintainEncounter(dt);checkBusinessProgress();
}
function inputVector(){
  let sx=0,sy=0;
  if(keys.w||keys.arrowup)sy-=1;if(keys.s||keys.arrowdown)sy+=1;if(keys.a||keys.arrowleft)sx-=1;if(keys.d||keys.arrowright)sx+=1;
  if(pointer.active){sx=pointer.vx;sy=pointer.vy}
  const m=Math.hypot(sx,sy);if(m<.03)return{x:0,y:0,mag:0,sx:0,sy:0};
  const mag=Math.min(1,m),nx=sx/m,ny=sy/m;
  let wx=nx/TW+ny/TH,wy=ny/TH-nx/TW;
  const wm=Math.hypot(wx,wy)||1;return{x:wx/wm,y:wy/wm,mag,sx:nx,sy:ny}
}
function approach(v,target,delta){return v<target?Math.min(target,v+delta):Math.max(target,v-delta)}
function movePlayer(dt){
  const v=inputVector(),moving=v.mag>.01;
  const targetVx=v.x*player.speed*v.mag,targetVy=v.y*player.speed*v.mag;
  const rate=moving?player.accel:player.decel;
  player.vx=approach(player.vx,targetVx,rate*dt);player.vy=approach(player.vy,targetVy,rate*dt);
  player.moveBlend=approach(player.moveBlend,moving?1:0,dt*(moving?10:14));
  if(moving){
    idle=0;UI.tip?.classList.add('hide');player.walk+=dt*(13+v.mag*8);player.angle=Math.atan2(player.vy,player.vx);
    player.stepCd-=dt;if(player.stepCd<=0){player.stepCd=.24;audio&&audio.sfx('footstep',{gain:.24,pitch:.92+Math.random()*.15})}
  }else{idle+=dt;player.stepCd=0}
  const steps=Math.max(1,Math.ceil(Math.hypot(player.vx,player.vy)*dt/.12)),sd=dt/steps;
  for(let i=0;i<steps;i++){
    const nx=player.x+player.vx*sd,ny=player.y+player.vy*sd;
    if(isWalkableRadius(nx,player.y))player.x=nx;else player.vx=0;
    if(isWalkableRadius(player.x,ny))player.y=ny;else player.vy=0;
  }
  if(idle>2.2&&!pointer.active&&started&&!paused)UI.tip?.classList.remove('hide');
}
function hurtPlayer(amount){
  if(player.hitCd>0||runState!=='playing')return false;
  player.hp=Math.max(0,player.hp-amount);player.hitCd=.48;shake=Math.max(shake,7);emit('hurt',player.x,player.y,{});audio&&audio.sfx('player_hurt',{gain:.9});
  if(player.hp<=0){restartAfterDeath();return true}return false
}
function updateBossSpecial(dt){
  if(!boss||boss.dead||objective!==5||runState!=='playing')return;
  if(boss.hp<boss.maxHp*.5&&boss.phase===0){boss.phase=1;boss.speed=1.45;boss.specialCd=Math.min(boss.specialCd,1.1);emit('banner',null,null,{text:'O OLHO SE ABRE',d:1.1});audio&&audio.sfx('boss_phase',{gain:.9})}
  if(boss.telegraph>0){
    boss.telegraph-=dt;
    if(boss.telegraph<=0&&!boss.struck){boss.struck=true;audio&&audio.sfx('boss_attack',{gain:1});shake=Math.max(shake,9);emit('bossPulse',boss.x,boss.y,{d:.45});
      if(dist(player,boss)<1.65)hurtPlayer(boss.phase?18:14);
      boss.specialCd=boss.phase?1.7:2.35;
    }
  }else{
    boss.specialCd-=dt;
    if(boss.specialCd<=0){boss.telegraph=boss.phase ? .52 : .68;boss.struck=false;audio&&audio.sfx('boss_windup',{gain:.9})}
  }
}
function separateEnemies(){
  for(let i=0;i<enemies.length;i++)for(let j=i+1;j<enemies.length;j++){
    const a=enemies[i],b=enemies[j];if(a.dead||b.dead)continue;let dx=a.x-b.x,dy=a.y-b.y,m=Math.hypot(dx,dy);const min=(a===boss||b===boss) ? .72 : .46;
    if(m>0&&m<min){const push=(min-m)*.16,ux=dx/m,uy=dy/m;const ax=a.x+ux*push,ay=a.y+uy*push,bx=b.x-ux*push,by=b.y-uy*push;if(enemyCanWalk(a,ax,ay)){a.x=ax;a.y=ay}if(enemyCanWalk(b,bx,by)){b.x=bx;b.y=by}}
  }
}
function combatUpdate(dt){
  if(runState!=='playing'||levelTimer>0||objective===6)return;
  player.atkCd-=dt;player.hitCd=Math.max(0,player.hitCd-dt);player.attackPulse=Math.max(0,player.attackPulse-dt*3);player.cutPulse=Math.max(0,player.cutPulse-dt*5.8);
  const live=enemies.filter(e=>!e.dead);
  let nearest=null,nd=99;
  for(const e of live){
    const d=dist(player,e);if(d<nd){nd=d;nearest=e}
    if(d<7.5&&objective>=3){
      const dx=player.x-e.x,dy=player.y-e.y,m=Math.hypot(dx,dy)||1;moveEnemy(e,dx/m,dy/m,dt);
      if(d<.62&&e!==boss&&hurtPlayer(6))return;
      if(d<.7&&e===boss&&boss.telegraph<=0&&hurtPlayer(7))return;
    }
    e.hit=Math.max(0,e.hit-dt);
  }
  separateEnemies();updateBossSpecial(dt);
  if(runState!=='playing')return;
  if(objective>=3&&nearest&&nd<2.85&&hasLineOfSight(player,nearest)&&player.atkCd<=0){
    player.atkCd=.29;player.attackPulse=1;audio&&audio.sfx('attack',{gain:.52,pitch:.95+Math.random()*.14});
    const dmg=nearest===boss?15:19;damageEnemy(nearest,dmg);
    for(const e of live)if(e!==nearest&&!e.dead&&dist(player,e)<1.18&&hasLineOfSight(player,e))damageEnemy(e,9);
    emit('slash',player.x,player.y,{angle:Math.atan2(nearest.y-player.y,nearest.x-player.x)});
  }
  if(objective>=3)acolytes.filter(a=>a.rescued&&!a.ambient&&a.role==='GUARDIÃO').forEach((a,i)=>{
    a.cool=(a.cool||0)-dt;const ad=nearest?dist(a,nearest):99;if(a.cool<=0&&nearest&&!nearest.dead&&ad<5.2){a.cool=.72+i*.08;damageEnemy(nearest,5.5);emit('bolt',a.x,a.y,{to:nearest})}
  });
  for(const d of drops){if(d.dead)continue;d.t+=dt;const di=dist(player,d);if(freeCarry()>.05&&di<2.15+metaLoot.eye*.22){const q=Math.min(1,dt*7);d.x=lerp(d.x,player.x,q);d.y=lerp(d.y,player.y,q)}if(di<.48&&freeCarry()>.05)pickupDrop(d)}
  enemies=enemies.filter(e=>!e.dead);drops=drops.filter(d=>!d.dead);
  const combat=enemies.some(e=>dist(player,e)<5.8);if(combat!==lastCombat&&objective!==5){lastCombat=combat;audio&&audio.setState(combat?'combat':'explore',{intensity:combat ? .72 : .38})}
}
function restartAfterDeath(){
  if(runState==='dead')return;
  runState='dead';paused=true;endPointer();fx.push({kind:'banner',text:'HĀRŪN CAIU · O MERCADO O REERGUERÁ',t:0,d:.9});audio&&audio.setState('menu',{intensity:.15});
  clearTimeout(deathTimer);deathTimer=setTimeout(()=>{
    if(runState!=='dead')return;
    grain=Math.floor(grain*.8);meat=Math.floor(meat*.8);coins=Math.floor(coins*.92);resource=Math.max(0,resource-1);
    player.x=5.2;player.y=15.2;player.vx=player.vy=0;player.hp=player.maxHp;player.hitCd=.8;
    enemies=[];boss=null;
    if(objective===5)objective=4;
    waveTimer=1.2;runState='playing';paused=false;last=performance.now();updateHUD();audio&&audio.setState('explore',{intensity:.38});
  },900)
}
function updateFollowers(dt){
  const rescuedList=acolytes.filter(a=>a.rescued&&!a.ambient);
  rescuedList.forEach((a,i)=>{
    let target;
    if(i===0){target={x:depot.x-.65,y:depot.y+.25};a.role='MOLEIRO'}
    else if(i===1&&builds[1].done){target={x:builds[1].x-.55,y:builds[1].y+.35};a.role='ESCRIBA'}
    else{const back=1.05+(i===2?0:.35),side=(i-1)*.38;target={x:player.x-Math.cos(player.angle)*back-Math.sin(player.angle)*side,y:player.y-Math.sin(player.angle)*back+Math.cos(player.angle)*side};a.role='GUARDIÃO'}
    const nx=lerp(a.x,target.x,Math.min(1,dt*4.8)),ny=lerp(a.y,target.y,Math.min(1,dt*4.8));if(isWalkable(nx,ny)){a.x=nx;a.y=ny}
  });
}
function update(dt){
  time+=dt;if(shake>0)shake=Math.max(0,shake-dt*34);
  movePlayer(dt);interactionUpdate(dt);combatUpdate(dt);updateFollowers(dt);
  for(const f of fx)f.t+=dt;fx=fx.filter(f=>f.t<f.d);
  const look=.13,pr=isoRaw(player.x+player.vx*look,player.y+player.vy*look);camera.x=lerp(camera.x,pr.x,1-Math.pow(.00045,dt));camera.y=lerp(camera.y,pr.y,1-Math.pow(.00045,dt));
}
function drawWallTorch(x,y){const p=project(x,y);glow(p.x,p.y-22,26,'#ff8b3e',.28);ell(p.x,p.y-24,3,9,'#ffb85b');ell(p.x,p.y-29,1.8,5,'#fff1a9')}
function drawProp(p){
  const s=project(p.x,p.y);
  if(p.kind==='bench'){poly([[s.x-24,s.y-5],[s.x+24,s.y-5],[s.x+19,s.y+5],[s.x-28,s.y+5]],'#38281f','#68462e');line(s.x-18,s.y+5,s.x-18,s.y+15,'#201813',3);line(s.x+15,s.y+4,s.x+15,s.y+14,'#201813',3)}
  else if(p.kind==='sacks'){for(let i=0;i<5;i++)ell(s.x+(i%3)*10-12,s.y-Math.floor(i/3)*6,8,5,i%2?'#6f342d':'#7c3d30',1,-.15)}
  else if(p.kind==='torch')drawWallTorch(p.x,p.y);
  else if(p.kind==='rune'){ctx.save();ctx.setLineDash([4,4]);ctx.strokeStyle='#c9ad7b99';ctx.lineWidth=1;ctx.beginPath();ctx.ellipse(s.x,s.y,28,13,0,0,TAU);ctx.stroke();ctx.restore();line(s.x-11,s.y,s.x+11,s.y,'#d0aa63',1.2,.6)}
  else if(p.kind==='pedestal'){poly([[s.x-14,s.y-2],[s.x,s.y-9],[s.x+14,s.y-2],[s.x,s.y+6]],'#171718','#55514a');poly([[s.x-8,s.y-8],[s.x,s.y-12],[s.x+8,s.y-8],[s.x,s.y-4]],'#303137','#786b58');drawBubble(s.x,s.y-44,p.icon,'#f9f8f3')}
}
function drawBubble(x,y,icon,color='#fff'){
  ctx.save();ctx.fillStyle='#f5f5f2';ctx.strokeStyle='#c8c8c1';ctx.lineWidth=1;ctx.beginPath();ctx.arc(x,y,13,0,TAU);ctx.fill();ctx.stroke();poly([[x-4,y+10],[x-1,y+20],[x+4,y+11]],'#f5f5f2');ctx.fillStyle=color==='#fff'?'#812b25':color;ctx.font='bold 12px serif';ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText(icon,x,y+1);ctx.restore()
}
function drawDepot(){
  const p=project(depot.x,depot.y),stock=goods.provision;
  ctx.save();ctx.setLineDash([5,5]);ctx.strokeStyle=grain>0?'#f2d66dcc':'#e9e6d888';ctx.lineWidth=1.2;ctx.beginPath();ctx.ellipse(p.x,p.y+4,31,14,0,0,TAU);ctx.stroke();ctx.restore();
  // mesa / moinho
  poly([[p.x-22,p.y-5],[p.x+22,p.y-5],[p.x+18,p.y+7],[p.x-25,p.y+7]],'#47372b','#8a6746',1);
  line(p.x-17,p.y+7,p.x-17,p.y+19,'#241a15',4);line(p.x+14,p.y+6,p.x+14,p.y+18,'#241a15',4);
  for(let i=0;i<Math.min(8,Math.ceil(depot.input));i++){const ox=(i%4)*7-11,oy=-Math.floor(i/4)*5;ell(p.x+ox,p.y-8+oy,5,2.4,'#d0ae49')}
  for(let i=0;i<Math.min(9,stock);i++){const ox=(i%3)*8+25,oy=-Math.floor(i/3)*5;ell(p.x+ox,p.y+2+oy,6,3,'#a55a2d');ell(p.x+ox,p.y+oy,4,1.6,'#dc9a49')}
  rr(p.x-28,p.y-42,56,15,7,'#080908dd','#8b744d');
  ctx.fillStyle='#f0d36b';ctx.font='800 6px Cinzel,serif';ctx.textAlign='center';ctx.fillText('MOINHO · ◫ '+stock,p.x,p.y-32);
}
function drawBuild(b){
  const p=project(b.x,b.y),done=b.done,prog=clamp(b.height||0,0,1),available=buildAvailable(b),active=!done&&available;
  ctx.save();ctx.setLineDash([4,4]);ctx.strokeStyle=done?'#6effb0aa':active?'#f5dc84dd':'#6d6d6880';ctx.lineWidth=active?1.8:1.1;ctx.beginPath();ctx.ellipse(p.x,p.y+3,30,13,0,0,TAU);ctx.stroke();ctx.restore();
  if(!done){
    poly([[p.x-18,p.y-3],[p.x,p.y-12],[p.x+18,p.y-3],[p.x,p.y+7]],available?'#24452c':'#222522',available?'#f0cc61':'#5c625c');
    rr(p.x-31,p.y-42,62,16,7,'#080908e8',available?'#8b744d':'#454844');
    ctx.fillStyle=available?'#f3d883':'#8d918c';ctx.font='800 5.8px Cinzel,serif';ctx.textAlign='center';
    ctx.fillText(available?'ÓBOLOS '+Math.ceil(Math.max(0,b.cost-b.invest)):'FECHADO',p.x,p.y-31);
    if(prog>0){const h=8+prog*55;poly([[p.x-10,p.y],[p.x-8,p.y-h],[p.x+8,p.y-h],[p.x+10,p.y]],'#704033','#c08455',1);ell(p.x,p.y-h,8,4,'#a36b44')}
    return;
  }
  // estação pronta
  poly([[p.x-24,p.y-4],[p.x+24,p.y-4],[p.x+20,p.y+8],[p.x-27,p.y+8]],'#3f2f27','#866143',1);
  line(p.x-18,p.y+8,p.x-18,p.y+20,'#241a15',4);line(p.x+16,p.y+7,p.x+16,p.y+19,'#241a15',4);
  const icon=PRODUCT[b.product]?.icon||'✦',count=goods[b.product]||0;
  if(b.id==='butcher'){for(let i=0;i<Math.min(5,Math.ceil(b.input));i++)ell(p.x-12+i*6,p.y-10,4,3,'#8d2f32')}
  else if(b.id==='scriptorium'){for(let i=0;i<Math.min(5,count);i++){const yy=p.y-8-i*3;rr(p.x-13,yy,26,4,1,'#d4b477','#6e5134')}}
  else if(b.id==='library'){for(let i=0;i<Math.min(4,count);i++){rr(p.x-15+i*8,p.y-15,7,14,1,i%2?'#69453b':'#4f3849','#b88d61')}}
  else if(b.id==='relicary'){glow(p.x,p.y-18,20,'#d9bc67',.2);ctx.fillStyle='#d8b85e';ctx.font='20px serif';ctx.textAlign='center';ctx.fillText('✦',p.x,p.y-9)}
  rr(p.x-31,p.y-46,62,16,7,'#080908e8','#8b744d');
  ctx.fillStyle='#f3dfa8';ctx.font='800 5.6px Cinzel,serif';ctx.textAlign='center';ctx.fillText(icon+' '+b.name+' · '+count,p.x,p.y-35);
}
function drawAcolyte(a){
  const p=project(a.x,a.y);ell(p.x,p.y+10,12,5,'#000',.35);ell(p.x,p.y-6,7,9,a.rescued?'#2f4157':'#4a3b56');ell(p.x,p.y-17,5.5,6,'#d2b89d');line(p.x-4,p.y+1,p.x-8,p.y+11,'#1f2026',3);line(p.x+4,p.y+1,p.x+8,p.y+11,'#1f2026',3);if(a.rescued)glow(p.x,p.y-4,18,'#7edfd0',.16);
  if(!a.rescued)drawBubble(p.x,p.y-43,a.bubble,a.ambient?'#7f6d5c':'#9b312c');
  else if(a.role){ctx.save();ctx.globalAlpha=.75;ctx.fillStyle='#d8c79d';ctx.font='700 5px Cinzel,serif';ctx.textAlign='center';ctx.fillText(a.role,p.x,p.y-31);ctx.restore()}
}
function drawCustomer(c){
  const p=project(c.x,c.y),walk=Math.sin(time*7+c.x*2)*1.2;
  ell(p.x,p.y+11,11,4,'#000',.3);
  const robe=c.want==='meat'?'#68403b':c.want==='scroll'?'#46536c':c.want==='book'?'#57445f':c.want==='relic'?'#6f5d39':'#56515f';
  ell(p.x,p.y-5+walk,6.5,9,robe);ell(p.x,p.y-16+walk,5,5.5,'#c8ad93');
  line(p.x-4,p.y+1,p.x-7,p.y+10,'#272427',2.5);line(p.x+4,p.y+1,p.x+7,p.y+10,'#272427',2.5);
  if(c.state==='wait')drawBubble(p.x,p.y-40,PRODUCT[c.want]?.icon||'?','#7d2b29');
  if(c.buyFlash>0){ctx.save();ctx.globalAlpha=c.buyFlash/.6;ctx.fillStyle='#ffd56d';ctx.font='900 10px Cinzel,serif';ctx.textAlign='center';ctx.fillText('ÓBOLOS',p.x,p.y-35-(1-c.buyFlash/.6)*12);ctx.restore()}
}
function drawCarryStack(p,bob,side=-1){
  const total=Math.floor(carryLoad());if(total<=0)return;
  const visible=Math.min(14,total),g=Math.min(visible,Math.ceil(grain)),m=Math.max(0,visible-g),sx=p.x+side*11;
  ctx.save();
  // wooden carrying frame, like the reference stack rig
  line(sx,p.y+7+bob,sx,p.y-8-visible*3.1+bob,'#4a3220',2.4,.95);
  line(sx-6,p.y+5+bob,sx+5,p.y+5+bob,'#5b3c24',2,.9);
  for(let i=0;i<g;i++){
    const y=p.y+2+bob-i*3.35,lean=(i%2?1:-1)*1.2;
    poly([[sx-8+lean,y],[sx-2+lean,y-3],[sx+7+lean,y-.5],[sx+1+lean,y+3]],'#a88b31','#e1c45d',.65);
    line(sx-6+lean,y-1,sx+5+lean,y,'#ebd56f',.8,.8);
  }
  for(let i=0;i<m;i++){
    const y=p.y+1+bob-(g+i)*3.6,lean=(i%2?1:-1);
    ell(sx+lean,y,5.3,3.2,'#8d3035');ell(sx+2+lean,y-1.1,2.3,1.4,'#dda08c');
  }
  if(total>14){rr(sx-11,p.y-48-visible*2.2,22,12,6,'#080908dd','#786341');ctx.fillStyle='#f4e4bb';ctx.font='800 6px Cinzel';ctx.textAlign='center';ctx.fillText('x'+total,sx,p.y-40-visible*2.2)}
  ctx.restore();
}
function heroFacing(){
  const wx=Math.cos(player.angle),wy=Math.sin(player.angle),sx=wx-wy,sy=(wx+wy)*.5;
  return{sx,sy,flip:sx<0,front:sy>.08};
}
function drawNativeHarun(p,bob){
  const face=heroFacing(),flip=face.flip? -1:1,walk=Math.sin(player.walk)*player.moveBlend,step=walk*3.1;
  ctx.save();ctx.translate(p.x,p.y+bob);ctx.scale(flip,1);
  // legs
  line(-4,8,-5+step,20,'#171619',4);line(4,8,5-step,20,'#171619',4);
  ell(-5+step,21,5,2.2,'#0b0b0d');ell(5-step,21,5,2.2,'#0b0b0d');
  // cloak / torso
  poly([[-8,-4],[-11,12],[-7,19],[0,16],[7,19],[11,12],[8,-4]],'#202126','#08090b',1.1);
  poly([[-7,-4],[0,12],[7,-4],[5,-11],[-5,-11]],'#3a2830','#171116',.8);
  // belt and small talisman
  line(-7,5,7,5,'#b58b4e',2.4);ell(0,6,2.2,2.2,'#d9b867');
  // arms
  const cut=player.cutPulse>0,attack=player.attackPulse>0;
  const swing=cut?Math.sin((.22-player.cutPulse)/.22*Math.PI)*1.0:attack?Math.sin((1-player.attackPulse)*Math.PI)*.9:0;
  ctx.save();ctx.translate(6,-1);ctx.rotate(-.35-swing);line(0,0,6,11,'#2c2225',4);ell(6,12,2.6,3,'#b7967d');ctx.restore();
  ctx.save();ctx.translate(-6,-1);ctx.rotate(.28+swing*.45);line(0,0,-5,10,'#2c2225',4);ell(-5,11,2.6,3,'#b7967d');ctx.restore();
  // head
  ell(0,-15,7.2,8.2,'#b89378');
  // hood/hair
  poly([[-8,-15],[-7,-24],[0,-29],[8,-23],[9,-14],[5,-18],[-4,-19]],'#090a0d','#27242a',.8);
  if(face.front){ell(-2.6,-15,1.05,1.2,'#241c1a');ell(2.6,-15,1.05,1.2,'#241c1a')}
  // tool: native sickle during harvest, blade/staff otherwise
  if(cut){
    ctx.save();ctx.translate(8,6);ctx.rotate(-1.0-swing*.9);line(0,0,0,-24,'#705237',2.2);ctx.strokeStyle='#d8d3c5';ctx.lineWidth=2.2;ctx.beginPath();ctx.arc(5,-23,8,2.7,5.2);ctx.stroke();ctx.restore();
  }else{
    ctx.save();ctx.translate(8,7);ctx.rotate(-.58-swing*.65);line(0,0,0,-25,'#83623b',2);line(0,-25,4,-31,'#e2d6b8',2.1);ctx.restore();
  }
  ctx.restore();
}
function drawHero(){
  const p=project(player.x,player.y);ell(p.x,p.y+18,17,5.5,'#000',.44);
  ctx.save();ctx.strokeStyle='#46f19a';ctx.lineWidth=2.5;ctx.beginPath();ctx.ellipse(p.x,p.y+15,20,7.5,0,0,TAU);ctx.stroke();ctx.restore();
  const bob=Math.sin(player.walk*1.7)*1.2*player.moveBlend,face=heroFacing();
  drawCarryStack(p,bob,face.flip?1:-1);
  drawNativeHarun(p,bob);
  if(player.attackPulse>0){ctx.save();ctx.globalAlpha=player.attackPulse;ctx.strokeStyle='#8ceaff';ctx.lineWidth=3.4;for(let i=0;i<2;i++){const a=time*7+i*Math.PI;ctx.beginPath();ctx.arc(p.x,p.y+4,23+i*3,a,a+.82);ctx.stroke()}ctx.restore()}
  rr(p.x-21,p.y-42,42,5,3,'#111');rr(p.x-21,p.y-42,42*(player.hp/player.maxHp),5,3,'#48e178');
  if(player.hp===player.maxHp){ctx.fillStyle='#effbe8';ctx.font='bold 6px Manrope';ctx.textAlign='center';ctx.fillText('MAX',p.x,p.y-46)}
}
function drawNativeShade(e,p,a){
  const pulse=Math.sin(time*5+e.x)*1.2;ctx.save();ctx.translate(p.x,p.y);ctx.globalAlpha=a;
  poly([[-10,10],[-9,-5],[0,-17-pulse],[9,-5],[11,10],[4,16],[0,12],[-4,16]],'#17131d','#3a2d43',1);
  poly([[-8,-7],[-3,-19],[0,-22],[4,-18],[8,-6]],'#241d2d');
  ell(-3,-8,1.6,1.8,'#e53f5a');ell(3,-8,1.6,1.8,'#e53f5a');glow(0,-8,12,'#d73555',.12);ctx.restore();
}
function drawNativeHound(e,p,a){
  const run=Math.sin(time*10+e.x*2)*2;ctx.save();ctx.translate(p.x,p.y);ctx.globalAlpha=a;
  ell(0,1,14,7.5,'#151821');ell(9,-3,8,6,'#1f222b');
  poly([[5,-7],[9,-18],[13,-7]],'#292c38');poly([[12,-7],[18,-16],[18,-4]],'#292c38');
  line(-8,5,-13,12+run,'#12141a',3);line(6,5,11,12-run,'#12141a',3);line(-4,5,-2,12-run,'#12141a',3);line(10,4,16,10+run,'#12141a',3);
  ell(12,-4,1.6,1.6,'#ff4658');line(-13,0,-19,-6,'#20242d',2.5);ctx.restore();
}
function drawNativeBoss(e,p,a){
  const pulse=.5+.5*Math.sin(time*3.2);ctx.save();ctx.translate(p.x,p.y);ctx.globalAlpha=a;
  glow(0,-9,44,'#a61f3b',.16+.08*pulse);
  // lower robe / body
  poly([[-25,20],[-20,-12],[-10,-31],[0,-38],[10,-31],[20,-12],[26,20],[10,29],[0,23],[-10,29]],'#17121d','#51243a',1.3);
  // crown/horns
  poly([[-17,-24],[-29,-45],[-11,-36]],'#3a1827','#7c3853',1);
  poly([[17,-24],[29,-45],[11,-36]],'#3a1827','#7c3853',1);
  ell(0,-17,18,15,'#211624');
  // central blind eye / sealed visor
  ell(0,-19,11,6,'#0b090d');line(-10,-19,10,-19,'#b73a52',2.3);ell(0,-19,2.5,2.5,'#ff4b66');glow(0,-19,18,'#ff3153',.18);
  // arms
  line(-18,-4,-31,10+Math.sin(time*4)*2,'#311a28',7);line(18,-4,31,10-Math.sin(time*4)*2,'#311a28',7);
  ctx.restore();
}
function drawEnemy(e){
  const p=project(e.x,e.y),hit=e.hit>0,a=hit ? .56 : 1;ell(p.x,p.y+12,e===boss?24:13,e===boss?8:5,'#000',.43);
  if(e===boss&&e.telegraph>0){const q=1-Math.max(0,Math.min(1,e.telegraph/(e.phase ? .52 : .68)));ctx.save();ctx.globalAlpha=.3+.5*q;ctx.strokeStyle='#ff5164';ctx.lineWidth=2.5;ctx.beginPath();ctx.ellipse(p.x,p.y+5,28+q*42,13+q*20,0,0,TAU);ctx.stroke();ctx.restore()}
  if(e===boss)drawNativeBoss(e,p,a);else if(e.kind==='hound')drawNativeHound(e,p,a);else drawNativeShade(e,p,a);
  const w=e===boss?82:32,y=p.y-(e===boss?55:31);rr(p.x-w/2,y,w,5,3,'#1b090d');rr(p.x-w/2,y,w*Math.max(0,e.hp/e.maxHp),5,3,e===boss?'#e92f4b':'#d3293b');
  if(e===boss){ctx.fillStyle='#f1d9c2';ctx.font='700 8px Cinzel,serif';ctx.textAlign='center';ctx.fillText(e.name,p.x,p.y-63)}
}
function drawDrop(d){
  const p=project(d.x,d.y),bob=Math.sin(d.t*7)*2;
  if(d.kind==='meat'){
    glow(p.x,p.y-6+bob,15,'#ff625d',.16);
    poly([[p.x-8,p.y-5+bob],[p.x-3,p.y-11+bob],[p.x+7,p.y-8+bob],[p.x+10,p.y-1+bob],[p.x+1,p.y+3+bob]],'#8d2f32','#e97970',1);
    ell(p.x+4,p.y-6+bob,2,2,'#f2a48d');
  }else if(d.kind==='grain'){
    glow(p.x,p.y-7+bob,14,'#f4d56b',.15);line(p.x,p.y+2+bob,p.x-2,p.y-12+bob,'#a88d36',2);ell(p.x+2,p.y-12+bob,5,2,'#e7cb5f');
  }else{
    glow(p.x,p.y-7+bob,18,'#6bffb2',.2);poly([[p.x-8,p.y-6+bob],[p.x,p.y-11+bob],[p.x+9,p.y-5+bob],[p.x,p.y+bob]],'#1e8a58','#7bffc0');
  }
}
function drawFx(){
  for(const f of fx){const q=f.t/f.d,a=1-q,p=f.x!=null?project(f.x,f.y):null;
    if(f.kind==='damage'){ctx.globalAlpha=a;ctx.fillStyle=f.crit?'#ffe26b':'#ffffff';ctx.font=(f.crit?'900 18px':'800 13px')+' Manrope';ctx.textAlign='center';ctx.fillText(f.text,p.x,p.y-35-q*28);ctx.globalAlpha=1}
    else if(f.kind==='pickup'){ctx.globalAlpha=a;ctx.fillStyle='#a5ffca';ctx.font='800 10px Manrope';ctx.textAlign='center';ctx.fillText(f.text,p.x,p.y-24-q*20);ctx.globalAlpha=1}
    else if(f.kind==='sale'){ctx.globalAlpha=a;ctx.fillStyle='#ffd46a';ctx.font='900 11px Cinzel,serif';ctx.textAlign='center';ctx.fillText(f.text,p.x,p.y-30-q*22);ctx.globalAlpha=1}
    else if(f.kind==='cut'){ctx.save();ctx.globalAlpha=a;ctx.strokeStyle='#d9efaf';ctx.lineWidth=3;ctx.beginPath();ctx.arc(p.x,p.y-8,20+q*8,-2.6,-.2);ctx.stroke();ctx.restore()}
    else if(f.kind==='spark'){for(let i=0;i<5;i++){const ang=i*1.7+f.t*5;ell(p.x+Math.cos(ang)*18*q,p.y-12+Math.sin(ang)*8*q,2,2,'#ffd66e',a)}}
    else if(f.kind==='burst'){for(let i=0;i<(f.big?18:8);i++){const ang=i*TAU/(f.big?18:8)+.4;ell(p.x+Math.cos(ang)*45*q,p.y+Math.sin(ang)*22*q,3,3,f.big?'#ff5672':'#a84d63',a)}}
    else if(f.kind==='hurt'){ctx.save();ctx.globalAlpha=a*.24;ctx.fillStyle='#d7253d';ctx.fillRect(0,0,W,H);ctx.restore()}
    else if(f.kind==='slash'){const s=project(f.x,f.y);ctx.save();ctx.globalAlpha=a;ctx.strokeStyle='#8ceaff';ctx.lineWidth=5;ctx.beginPath();ctx.arc(s.x,s.y,25+q*18,f.angle-.9,f.angle+.8);ctx.stroke();ctx.restore()}
    else if(f.kind==='bolt'&&f.to){const a1=project(f.x,f.y),a2=project(f.to.x,f.to.y);line(a1.x,a1.y-10,a2.x,a2.y-8,'#e8d47b',2,a)}
    else if(f.kind==='bossPulse'&&p){ctx.save();ctx.globalAlpha=a;ctx.strokeStyle='#ff5067';ctx.lineWidth=4;ctx.beginPath();ctx.ellipse(p.x,p.y,30+q*90,14+q*42,0,0,TAU);ctx.stroke();ctx.restore()}
    else if(f.kind==='banner'){ctx.save();ctx.globalAlpha=Math.sin(Math.min(1,q)*Math.PI);rr(72,H*.24,W-144,52,12,'#070806dd','#8c6c42');ctx.fillStyle='#f3dfb5';ctx.font='800 11px Cinzel,serif';ctx.textAlign='center';ctx.fillText(f.text,W/2,H*.24+31);ctx.restore()}
  }
}
function drawGuide(){
  if(!pointer.active)return;const h=project(player.x,player.y),x=pointer.x,y=pointer.y;
  ctx.save();ctx.fillStyle='#f6f6f0';for(let i=1;i<=8;i++){const t=i/9;ctx.globalAlpha=.25+.65*t;ctx.beginPath();ctx.arc(lerp(h.x,x,t),lerp(h.y,y,t),2.2,0,TAU);ctx.fill()}ctx.globalAlpha=.85;ctx.strokeStyle='#fff';ctx.lineWidth=1.4;ctx.beginPath();ctx.arc(x,y,12,0,TAU);ctx.stroke();ctx.restore()
}
function objectiveTarget(){
  if(objective===0){if(grain>0)return depot;const hs=harvestNodes.filter(h=>h.amount>0);return hs.sort((a,b)=>dist(player,a)-dist(player,b))[0]||depot}
  if(objective===1)return depot;
  if(objective===2)return acolytes.find(a=>!a.ambient&&!a.rescued)||null;
  if(objective===3)return builds[0].done?(enemies.find(e=>!e.dead)||{x:16,y:4}):builds[0];
  if(objective===4)return builds.find(b=>!b.done&&buildAvailable(b))||(enemies.find(e=>!e.dead)||depot);
  if(objective===5)return boss;return null
}
function drawObjectiveBeacon(){
  const t=objectiveTarget();if(!t)return;const p=project(t.x,t.y),margin=34;
  if(p.x>margin&&p.x<W-margin&&p.y>105&&p.y<H-margin){ctx.save();ctx.globalAlpha=.45+.2*Math.sin(time*4);ctx.strokeStyle='#e9c26c';ctx.lineWidth=1.5;ctx.beginPath();ctx.ellipse(p.x,p.y+4,24,11,0,0,TAU);ctx.stroke();ctx.restore();return}
  const cx=Math.max(margin,Math.min(W-margin,p.x)),cy=Math.max(112,Math.min(H-margin,p.y)),ang=Math.atan2(p.y-H*.5,p.x-W*.5);ctx.save();ctx.translate(cx,cy);ctx.rotate(ang);poly([[12,0],[-7,-6],[-4,0],[-7,6]],'#f0ca75');ctx.restore()
}
function drawScene(){
  drawFloor();drawForest();drawWalls();
  const drawables=[];
  fieldCrops.filter(h=>h.amount>.02).forEach(h=>drawables.push({d:h.x+h.y-.08,fn:()=>drawCrop(h)}));
  drawables.push({d:depot.x+depot.y,fn:drawDepot});
  builds.forEach(b=>drawables.push({d:b.x+b.y+.01,fn:()=>drawBuild(b)}));
  props.forEach(p=>drawables.push({d:p.x+p.y+.02,fn:()=>drawProp(p)}));
  acolytes.forEach(a=>drawables.push({d:a.x+a.y+.05,fn:()=>drawAcolyte(a)}));
  customers.forEach(q=>drawables.push({d:q.x+q.y+.06,fn:()=>drawCustomer(q)}));
  drops.forEach(d=>drawables.push({d:d.x+d.y+.08,fn:()=>drawDrop(d)}));
  enemies.filter(e=>!e.dead).forEach(e=>drawables.push({d:e.x+e.y+.12,fn:()=>drawEnemy(e)}));
  drawables.push({d:player.x+player.y+.14,fn:drawHero});
  drawables.sort((a,b)=>a.d-b.d).forEach(o=>o.fn());
  drawFx();drawObjectiveBeacon();drawGuide();
}
function loop(now){
  const raw=Math.max(0,now-last);const dt=Math.min(.033,raw/1000||0);last=now;frameEma=frameEma*.9+raw*.1;perf?.observe?.(raw||16.7);
  shakeX=shake&&!reducedMotion()?(Math.random()-.5)*shake:0;shakeY=shake&&!reducedMotion()?(Math.random()-.5)*shake:0;
  if(started&&!paused&&runState==='playing')update(dt);drawScene();requestAnimationFrame(loop)
}
function setJoy(e){
  const r=canvas.getBoundingClientRect(),x=(e.clientX-r.left)*W/r.width,y=(e.clientY-r.top)*H/r.height;
  if(pointer.box===0&&pointer.boy===0){
    pointer.ox=x;pointer.oy=y;pointer.box=e.clientX;pointer.boy=e.clientY;
    UI.joy.style.left=(e.clientX-r.left)+'px';UI.joy.style.top=(e.clientY-r.top)+'px';UI.joy.style.display='block';
  }
  let dx=e.clientX-pointer.box,dy=e.clientY-pointer.boy,m=Math.hypot(dx,dy),rad=54;
  if(m>rad*1.35){
    const shift=m-rad,ux=dx/m,uy=dy/m;pointer.box+=ux*shift;pointer.boy+=uy*shift;
    UI.joy.style.left=(pointer.box-r.left)+'px';UI.joy.style.top=(pointer.boy-r.top)+'px';
    dx=e.clientX-pointer.box;dy=e.clientY-pointer.boy;m=Math.hypot(dx,dy);
  }
  pointer.x=x;pointer.y=y;
  const dead=3.5,norm=m<=dead?0:Math.min(1,(m-dead)/(rad-dead)),ux=m?dx/m:0,uy=m?dy/m:0;
  pointer.vx=ux*norm;pointer.vy=uy*norm;pointer.strength=norm;
  UI.knob.style.transform='translate('+(ux*Math.min(rad,m)*.66)+'px,'+(uy*Math.min(rad,m)*.66)+'px)';
}
canvas.addEventListener('pointerdown',e=>{e.preventDefault();if(!started||paused||runState!=='playing'||pointer.active)return;pointer.active=true;pointer.id=e.pointerId;pointer.box=pointer.boy=0;try{canvas.setPointerCapture?.(e.pointerId)}catch(_){}setJoy(e);audio&&audio.unlock()},{passive:false});
canvas.addEventListener('pointermove',e=>{if(!pointer.active||e.pointerId!==pointer.id)return;e.preventDefault();setJoy(e)},{passive:false});
function endPointer(e){if(pointer.active&&(!e||e.pointerId===pointer.id)){const id=pointer.id;pointer.active=false;pointer.id=null;pointer.vx=pointer.vy=0;pointer.strength=0;pointer.box=pointer.boy=0;player.vx*=.18;player.vy*=.18;UI.joy.style.display='none';UI.knob.style.transform='translate(0,0)';try{if(id!=null&&canvas.hasPointerCapture?.(id))canvas.releasePointerCapture(id)}catch(_){}}}
canvas.addEventListener('pointerup',endPointer);canvas.addEventListener('pointercancel',endPointer);canvas.addEventListener('lostpointercapture',()=>endPointer());
window.addEventListener('keydown',e=>{if(/^(INPUT|TEXTAREA|SELECT)$/.test(e.target?.tagName||''))return;const k=e.key.toLowerCase();if(['w','a','s','d','arrowup','arrowdown','arrowleft','arrowright'].includes(k))e.preventDefault();keys[k]=true;if(e.key==='Escape'&&!e.repeat){e.preventDefault();togglePause()}},{passive:false});
window.addEventListener('keyup',e=>keys[e.key.toLowerCase()]=false);
window.addEventListener('blur',()=>{endPointer();keys={}});
document.addEventListener('visibilitychange',()=>{perf?.setHidden?.(document.hidden);if(document.hidden){endPointer();keys={};if(started&&!paused&&runState==='playing')togglePause()}else last=performance.now()});
window.addEventListener('pagehide',()=>{endPointer();keys={}});
window.addEventListener('resize',()=>{syncViewport();last=performance.now()},{passive:true});window.visualViewport?.addEventListener?.('resize',()=>{syncViewport();last=performance.now()},{passive:true});
document.addEventListener('gesturestart',e=>e.preventDefault(),{passive:false});
document.addEventListener('contextmenu',e=>e.preventDefault());
function startGame(){
  started=true;paused=false;runState='playing';UI.start.hidden=true;UI.pause.hidden=true;UI.victory.hidden=true;idle=0;last=performance.now();audio&&audio.unlock();window.MUNDUSMusic?.setAudible?.();audio&&audio.setState('explore',{intensity:.38});resetRun();
}
function togglePause(){
  if(!started||runState!=='playing'||!UI.victory.hidden)return;paused=!paused;UI.pause.hidden=!paused;last=performance.now();audio&&audio.setState(paused?'menu':(objective===5?'boss':'explore'),{intensity:paused ? .2 : .45});endPointer()
}
function restart(){clearTimeout(deathTimer);clearTimeout(victoryTimer);runState='playing';paused=false;UI.pause.hidden=true;UI.victory.hidden=true;last=performance.now();resetRun();window.MUNDUSMusic?.resume?.();audio&&audio.setState('explore',{intensity:.38})}
function showVictory(){if(runState==='dead')return;runState='victory';paused=true;endPointer();UI.pause.hidden=true;UI.victory.hidden=false;audio&&audio.setState('pleroma',{intensity:.4});audio&&audio.sfx('room_clear',{gain:1})}
$('#startBtn').addEventListener('click',startGame);UI.pauseBtn.addEventListener('click',togglePause);UI.resume.addEventListener('click',togglePause);UI.restart.addEventListener('click',restart);UI.restartVictory.addEventListener('click',restart);
function safeStore(k,v){try{localStorage.setItem(k,JSON.stringify(v))}catch(_){}}
function safeLoad(k,fallback){try{const raw=localStorage.getItem(k);if(raw==null)return fallback;const v=JSON.parse(raw);return v??fallback}catch(_){return fallback}}
function bindAudio(){
  const saved=safeLoad('harun-roomrun-audio',null),m=saved?.master??audio?.getMaster?.()??.86,s=saved?.sfx??audio?.getEffectsVolume?.()??1;
  UI.music.value=Math.round(m*100);UI.sfx.value=Math.round(s*100);UI.musicVal.textContent=UI.music.value;UI.sfxVal.textContent=UI.sfx.value;audio?.setMaster?.(m);audio?.setEffectsVolume?.(s);
  const save=()=>safeStore('harun-roomrun-audio',{master:+UI.music.value/100,sfx:+UI.sfx.value/100});
  UI.music.addEventListener('input',()=>{UI.musicVal.textContent=UI.music.value;audio?.setMaster?.(+UI.music.value/100);save()});
  UI.sfx.addEventListener('input',()=>{UI.sfxVal.textContent=UI.sfx.value;audio?.setEffectsVolume?.(+UI.sfx.value/100);save()});
}
function selfTest(){
  const checks={
    canvas:!!canvas&&!!ctx,
    ui:[UI.resource,UI.grain,UI.meat,UI.coin,UI.carry,UI.level,UI.objective,UI.objectiveKicker,UI.joy,UI.pause,UI.start].every(Boolean),
    spawn:isWalkableRadius(5.2,15.2),
    field:enemyCanWalk({kind:'shade'},16,4),
    input:!mobileInput||mobileInput.validate?.().ok!==false,
    market:builds.length===4&&Object.keys(PRODUCT).length===5&&typeof spawnCustomer==='function',
    nativeArt:typeof drawNativeHarun==='function'&&typeof drawNativeShade==='function'&&typeof drawNativeBoss==='function',
    allCropsHarvestable:fieldCrops.length>40&&fieldCrops.every(h=>typeof h.amount==='number'&&typeof h.respawn==='number'),
    processing:typeof processBusiness==='function'&&typeof addSale==='function',
    infinite:typeof beginNextLevel==='function'&&typeof completeLevel==='function',
    audio:!audio||typeof audio.setState==='function',
    runtimeErrors:runtimeErrors.length===0
  };
  return{version:VERSION,pass:Object.values(checks).every(Boolean),checks,runtimeErrors:[...runtimeErrors],tier:perf?.snapshot?.()||null}
}
bindAudio();resetRun();syncViewport();
const p0=isoRaw(player.x,player.y);camera.x=p0.x;camera.y=p0.y;
perf?.onChange?.(s=>window.MUNDUSVFX?.setQuality?.(s.tier==='low' ? .68 : s.tier==='medium' ? .88 : 1.06));
requestAnimationFrame(loop);
const stateSnapshot=()=>({
  runState,paused,objective,resource,grain,meat,coins,sales,salesLevel,level,bestLevel,kills,fieldKills,rescued,
  carry:{load:+carryLoad().toFixed(2),capacity:carryCapacity()},goods:{...goods},meta:{...metaLoot},customers:customers.length,
  hp:player.hp,maxHp:player.maxHp,x:player.x,y:player.y,depot:{input:+depot.input.toFixed(2),process:+depot.process.toFixed(2)},
  builds:builds.map(b=>({id:b.id,name:b.name,invest:+b.invest.toFixed(2),cost:b.cost,height:+b.height.toFixed(3),done:b.done,available:buildAvailable(b),input:+(b.input||0).toFixed(2),stock:goods[b.product]||0})),
  enemies:enemies.filter(e=>!e.dead).length,boss:boss?Math.max(0,boss.hp):null,
  fps:Math.round(1000/Math.max(1,frameEma)),width:W,height:H,viewportMode,tier:perf?.tier?.()||'standalone',runtimeErrors:[...runtimeErrors]
});
const qaEnabled=new URLSearchParams(window.location?.search||'').get('qa')==='dev';
const qaTools=qaEnabled?{
  step:(dt=.016)=>{if(runState==='playing'&&!paused)update(Math.max(0,Math.min(.033,Number(dt)||.016)));return stateSnapshot()},
  setMove:(x=0,y=0)=>{pointer.active=Math.hypot(x,y)>.001;pointer.vx=Math.max(-1,Math.min(1,Number(x)||0));pointer.vy=Math.max(-1,Math.min(1,Number(y)||0));return stateSnapshot()},
  release:()=>{endPointer();return stateSnapshot()},
  setPlayer:(x,y)=>{if(isWalkableRadius(Number(x),Number(y))){player.x=Number(x);player.y=Number(y);player.vx=player.vy=0}return stateSnapshot()},
  setObjective:n=>{objective=Math.max(0,Math.min(6,Number(n)||0));updateHUD();return stateSnapshot()},
  grant:(kind,n)=>{const v=Math.max(0,Number(n)||0);if(kind==='grain')grain+=v;else if(kind==='meat')meat+=v;else if(kind==='coins')coins+=v;else if(kind==='essence')resource+=v;else if(goods[kind]!=null)goods[kind]+=v;updateHUD();return stateSnapshot()},
  fillBuild:i=>{const b=builds[Math.max(0,Math.min(builds.length-1,Number(i)||0))];if(b){b.invest=b.cost;b.height=1;b.done=true;b.tier=Math.max(1,b.tier||0)}updateHUD();return stateSnapshot()},
  awakenAll:()=>{for(const a of acolytes)if(!a.ambient)a.rescued=true;rescued=3;updateHUD();return stateSnapshot()},
  spawnCustomer:kind=>{const c={x:4,y:18.55,want:PRODUCT[kind]?kind:'provision',state:'wait',tx:depot.x,ty:depot.y,wait:.4,buyFlash:0,speed:1.8};customers.push(c);return stateSnapshot()},
  sell:kind=>{const k=PRODUCT[kind]?kind:'provision';goods[k]++;const c={x:depot.x,y:depot.y,want:k,state:'wait',wait:1,buyFlash:0,speed:1};customers.push(c);updateCustomers(.5);return stateSnapshot()},
  killField:()=>{for(const e of [...enemies])if(e!==boss&&!e.dead)damageEnemy(e,9999);return stateSnapshot()},
  spawnBoss:()=>{spawnBoss();return stateSnapshot()},
  killBoss:()=>{if(boss&&!boss.dead)damageEnemy(boss,99999);return stateSnapshot()},
  cropCount:()=>fieldCrops.length,
  setAtCrop:i=>{const h=fieldCrops[Math.max(0,Math.min(fieldCrops.length-1,Number(i)||0))];if(h){player.x=h.x;player.y=h.y;player.vx=player.vy=0}return stateSnapshot()},
  cropState:i=>{const h=fieldCrops[Math.max(0,Math.min(fieldCrops.length-1,Number(i)||0))];return h?{x:h.x,y:h.y,amount:h.amount,max:h.max,cut:h.cut,respawn:h.respawn}:null},
  nextLevel:()=>{completeLevel();levelTimer=0;beginNextLevel();return stateSnapshot()}
}:Object.freeze({enabled:false});
window.__HARUN_ROOMRUN_V12__={version:VERSION,start:startGame,reset:resetRun,selfTest,state:stateSnapshot,qa:qaTools,sentinel:{gameId:'harun-survivor',mode:'native-reference-market-infinite',institutionalWrite:false,sourceArt:'native-in-engine-only',mobileFirst:true,desktopAdaptive:true,infinite:true,market:true,allVisibleCropsHarvestable:true}};
window.__HARUN_ROOMRUN_V11__=window.__HARUN_ROOMRUN_V12__;
window.__HARUN_ROOMRUN_V10__=window.__HARUN_ROOMRUN_V12__;
window.__HARUN_ROOMRUN_V9__=window.__HARUN_ROOMRUN_V12__;
window.__MUNDUS_SENTINEL__=window.__MUNDUS_SENTINEL__||{};
window.__MUNDUS_SENTINEL__.roomrunV12=window.__HARUN_ROOMRUN_V12__;
window.__MUNDUS_SENTINEL__.roomrunQA=selfTest();
})();
