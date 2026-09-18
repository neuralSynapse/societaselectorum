
(function(){
'use strict';
const canvas=document.getElementById('game'),ctx=canvas.getContext('2d');
const VERSION='10.0.0-reference-parity';
const W=540,TW=72,TH=36,TAU=Math.PI*2;
let H=960;
const $=s=>document.querySelector(s);
const mobileInput=window.CHRONICA_MOBILE_INPUT||null;
const ART_URLS={
  hero:'https://cdn.websitepublisher.ai/custom/wid27912/images/harun-peregrino-v1.png',
  shade:'https://cdn.websitepublisher.ai/custom/wid27912/images/harun-espectro-cinza-v1.png',
  boss:'https://cdn.websitepublisher.ai/custom/wid27912/images/harun-observador-cego-v1.png'
};
function loadArt(src){const im=new Image();im.decoding='async';im.loading='eager';im.src=src;return im}
const ART={hero:loadArt(ART_URLS.hero),shade:loadArt(ART_URLS.shade),boss:loadArt(ART_URLS.boss)};
const perf=window.CHRONICA_PERFORMANCE||null;
const reducedMotion=()=>window.matchMedia?.('(prefers-reduced-motion: reduce)')?.matches||false;
const runtimeErrors=[];
const captureError=(kind,e)=>{runtimeErrors.push({kind,message:String(e?.message||e?.reason||e||'erro'),at:Date.now()});if(runtimeErrors.length>20)runtimeErrors.shift()};
window.addEventListener('error',e=>captureError('error',e));
window.addEventListener('unhandledrejection',e=>captureError('promise',e));
const UI={resource:$('#resourceCount'),grain:$('#grainCount'),meat:$('#meatCount'),level:$('#levelCount'),objective:$('#objectiveText'),objectiveKicker:$('#objectiveKicker'),tip:$('#moveTip'),joy:$('#touchJoy'),knob:$('#touchJoy i'),pause:$('#pauseOverlay'),start:$('#startOverlay'),victory:$('#victoryOverlay'),pauseBtn:$('#pauseBtn'),resume:$('#resumeBtn'),restart:$('#restartBtn'),restartVictory:$('#restartVictory'),music:$('#musicVol'),sfx:$('#sfxVol'),musicVal:$('#musicVal'),sfxVal:$('#sfxVal')};
const perfProfile=perf?.profile?.()||{dpr:1.25};
const DPR=Math.min(Number(perfProfile.dpr)||1.25,window.devicePixelRatio||1.25);
function syncViewport(){
  const vh=Math.max(420,Math.round(window.visualViewport?.height||window.innerHeight||960));
  document.documentElement.style.setProperty('--app-h',vh+'px');
  const r=canvas.getBoundingClientRect(),nextH=Math.max(820,Math.min(1240,Math.round(W*(r.height/Math.max(1,r.width)))));
  if(nextH!==H||canvas.width!==Math.round(W*DPR)||canvas.height!==Math.round(nextH*DPR)){
    H=nextH;canvas.width=Math.round(W*DPR);canvas.height=Math.round(H*DPR);ctx.setTransform(DPR,0,0,DPR,0,0);
  }
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
 {x0:7.5,y0:-.2,x1:22.7,y1:9.3,type:'field'}
];
const floorCells=[];
for(let y=0;y<21;y++)for(let x=0;x<24;x++){
  const cx=x+.5,cy=y+.5,z=walkZones.find(q=>cx>=q.x0&&cx<=q.x1&&cy>=q.y0&&cy<=q.y1);
  if(z)floorCells.push({x,y,type:z.type});
}
floorCells.sort((a,b)=>(a.x+a.y)-(b.x+b.y));
function isWalkable(x,y){return walkZones.some(q=>x>=q.x0&&x<=q.x1&&y>=q.y0&&y<=q.y1)}
function isWalkableRadius(x,y,r=.16){return isWalkable(x-r,y)&&isWalkable(x+r,y)&&isWalkable(x,y-r)&&isWalkable(x,y+r)}
function typeAt(x,y){const z=walkZones.slice().reverse().find(q=>x>=q.x0&&x<=q.x1&&y>=q.y0&&y<=q.y1);return z?z.type:null}
function hasLineOfSight(a,b){for(let i=1;i<8;i++){const t=i/8;if(!isWalkable(lerp(a.x,b.x,t),lerp(a.y,b.y,t)))return false}return true}
function enemyCanWalk(e,x,y){const t=typeAt(x,y);return t==='field'||t==='hall'}
function moveEnemy(e,dx,dy,dt){const nx=e.x+dx*e.speed*dt,ny=e.y+dy*e.speed*dt;if(enemyCanWalk(e,nx,e.y))e.x=nx;if(enemyCanWalk(e,e.x,ny))e.y=ny}
function project(x,y){
  const p=isoRaw(x,y);return{x:p.x-camera.x+W*.5+shakeX,y:p.y-camera.y+H*.56+shakeY}
}
function rr(x,y,w,h,r,fill,stroke,lw=1){ctx.beginPath();ctx.roundRect(x,y,w,h,r);if(fill){ctx.fillStyle=fill;ctx.fill()}if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=lw;ctx.stroke()}}
function line(x1,y1,x2,y2,color,w=1,a=1){ctx.save();ctx.globalAlpha=a;ctx.strokeStyle=color;ctx.lineWidth=w;ctx.lineCap='round';ctx.beginPath();ctx.moveTo(x1,y1);ctx.lineTo(x2,y2);ctx.stroke();ctx.restore()}
function poly(pts,fill,stroke=null,lw=1){ctx.beginPath();ctx.moveTo(pts[0][0],pts[0][1]);for(let i=1;i<pts.length;i++)ctx.lineTo(pts[i][0],pts[i][1]);ctx.closePath();ctx.fillStyle=fill;ctx.fill();if(stroke){ctx.strokeStyle=stroke;ctx.lineWidth=lw;ctx.stroke()}}
function ell(x,y,rx,ry,fill,a=1,rot=0){ctx.save();ctx.globalAlpha*=a;ctx.translate(x,y);ctx.rotate(rot);ctx.fillStyle=fill;ctx.beginPath();ctx.ellipse(0,0,rx,ry,0,0,TAU);ctx.fill();ctx.restore()}
function glow(x,y,r,color,a=.25){ctx.save();ctx.globalAlpha=a;ctx.shadowColor=color;ctx.shadowBlur=r;ctx.fillStyle=color;ctx.beginPath();ctx.arc(x,y,Math.max(2,r*.12),0,TAU);ctx.fill();ctx.restore()}
function diamond(x,y,fill,stroke='#332c25'){poly([[x,y-TH*.5],[x+TW*.5,y],[x,y+TH*.5],[x-TW*.5,y]],fill,stroke,.8)}
function floorColor(cell){
  if(cell.type==='field'){const n=hash(cell.x,cell.y);return n>.5?'#20342d':'#1b3029'}
  const n=hash(cell.x,cell.y);return n>.66?'#3b3c3b':n>.32?'#343635':'#2f3332'
}
function drawFloor(){
  ctx.fillStyle='#06100d';ctx.fillRect(0,0,W,H);
  for(const c of floorCells){
    const p=project(c.x+.5,c.y+.5);
    if(p.x<-TW||p.x>W+TW||p.y<-TH||p.y>H+TH)continue;
    diamond(p.x,p.y,floorColor(c),c.type==='field'?'#29483c':'#4d4c47');
    if(c.type!=='field'&&hash(c.x,c.y,9)>.78){line(p.x-TW*.18,p.y,p.x+TW*.18,p.y,'#ffffff10',1)}
    if(c.type==='field'){
      const tier=perf?.tier?.()||'medium',threshold=tier==='low' ? .48 : tier==='high' ? .18 : .32;
      if(hash(c.x,c.y,2)>threshold){const path=Math.abs((c.x-c.y)-7)<1.6||Math.abs(c.x-15)<1.1;if(!path)drawCrop(c.x+.5,c.y+.5,c.x*31+c.y*19)}
    }
  }
}
function drawCrop(x,y,seed){
  const p=project(x,y),tier=perf?.tier?.()||'medium',count=tier==='low'?3:tier==='high'?7:5;for(let i=0;i<count;i++){const a=hash(seed,i,1),b=hash(seed,i,2);const ox=(a-.5)*38,oy=(b-.5)*14,h=15+hash(seed,i,3)*17;
    line(p.x+ox,p.y+oy,p.x+ox-2,p.y+oy-h,'#8f7a34',1.4,.9);
    line(p.x+ox-2,p.y+oy-h,p.x+ox+4,p.y+oy-h-3,'#d1b957',1.2,.88);
    line(p.x+ox-1,p.y+oy-h*.65,p.x+ox+4,p.y+oy-h*.78,'#b19a43',1,.8);
  }
}
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
const depot={x:6.2,y:16.0,amount:40,max:40,respawn:0,kind:'grain'};
const harvestNodes=[
 {x:9.2,y:2.2,amount:18,max:18,respawn:0},{x:11.6,y:1.4,amount:18,max:18,respawn:0},{x:13.5,y:3.0,amount:18,max:18,respawn:0},
 {x:15.7,y:1.5,amount:18,max:18,respawn:0},{x:18.0,y:2.8,amount:18,max:18,respawn:0},{x:20.1,y:1.4,amount:18,max:18,respawn:0}
];
const builds=[
 {x:13.0,y:13.2,cost:40,invest:0,done:false,name:'PILAR DE HÓRUS',height:0,currency:'grain',tier:0},
 {x:17.2,y:7.2,cost:32,invest:0,done:false,name:'SELO DO LIMIAR',height:0,currency:'meat',tier:0}
];
let fx=[],drops=[],enemies=[],boss=null,objective=0,kills=0,fieldKills=0,rescued=0,resource=0,grain=0,meat=0,level=1,bestLevel=1,levelTarget=6,levelTimer=0,waveTimer=0,harvestSfxCd=0,buildSfxCd=0;
const player={x:5.2,y:15.2,hp:100,maxHp:100,speed:7.25,accel:44,decel:58,vx:0,vy:0,atkCd:0,hitCd:0,walk:0,moveBlend:0,angle:0,attackPulse:0,stepCd:0};
try{bestLevel=Math.max(1,Number(localStorage.getItem('harun-roomrun-best'))||1)}catch(_){}
function resetRun(){
  player.x=5.2;player.y=15.2;player.vx=0;player.vy=0;player.hp=100;player.maxHp=100;player.atkCd=0;player.hitCd=0;player.walk=0;player.moveBlend=0;player.angle=0;player.stepCd=0;lastCombat=false;
  clearTimeout(deathTimer);clearTimeout(victoryTimer);deathTimer=victoryTimer=0;
  objective=0;kills=0;fieldKills=0;rescued=0;resource=0;grain=0;meat=0;level=1;bestLevel=Math.max(bestLevel,1);levelTarget=6;levelTimer=0;waveTimer=0;harvestSfxCd=0;buildSfxCd=0;fx=[];drops=[];enemies=[];boss=null;depot.amount=40;depot.max=40;depot.respawn=0;
  harvestNodes.forEach(h=>{h.amount=h.max;h.respawn=0});
  builds.forEach(b=>{b.invest=0;b.done=false;b.height=0;b.tier=0});acolytes.forEach(a=>{a.x=a.homeX??a.x;a.y=a.homeY??a.y;a.rescued=false;a.cool=0});
  spawnInitialEnemies();updateHUD();
}
function spawnInitialEnemies(){
  const pts=[[14,4.6],[16.2,3.5],[18.2,5.4],[19.4,2.8],[12.8,2.8],[20.5,6.2],[11.2,4.2],[21.2,4.7],[15.2,6.0],[18.9,7.0]];
  const count=Math.min(pts.length,6+Math.floor((level-1)/2));for(let i=0;i<count;i++){const p=pts[i];spawnEnemy(p[0],p[1],i%3===0?'hound':'shade',level%5===0&&i===count-1)}
}
function spawnEnemy(x,y,kind='shade',elite=false){
  const scale=1+(level-1)*.12,hp=Math.round((elite?70:kind==='hound'?28:22)*scale),speed=(kind==='hound'?2.35:1.7)*(1+Math.min(.28,(level-1)*.012));
  enemies.push({x,y,kind,hp,maxHp:hp,r:elite ? .42 : .27,speed,hit:0,dead:false,elite});
}
function spawnBoss(){
  const scale=1+(level-1)*.18,bhp=Math.round(360*scale);
  boss={x:18.3,y:3.3,hp:bhp,maxHp:bhp,r:.72,speed:1.18*(1+Math.min(.2,(level-1)*.01)),hit:0,dead:false,name:'OBSERVADOR CEGO',phase:0,specialCd:2.5,telegraph:0,struck:false};
  enemies.push(boss);
  audio&&audio.setState('boss',{intensity:.95});audio&&audio.sfx('boss_windup',{gain:1});
}
function currencyAmount(kind){return kind==='grain'?grain:kind==='meat'?meat:resource}
function addCurrency(kind,value){if(kind==='grain')grain+=value;else if(kind==='meat')meat+=value;else resource+=value;updateHUD()}
function spendCurrency(kind,value){const have=currencyAmount(kind),take=Math.min(have,Math.max(0,value));if(kind==='grain')grain-=take;else if(kind==='meat')meat-=take;else resource-=take;return take}
function levelCosts(){
  return{grain:40+Math.min(60,(level-1)*5),meat:32+Math.min(64,(level-1)*4),kills:6+Math.min(10,Math.floor((level-1)*.75))}
}
function updateHUD(){
  const costs=levelCosts();levelTarget=costs.kills;builds[0].cost=costs.grain;builds[1].cost=costs.meat;
  if(UI.resource)UI.resource.textContent=Math.floor(resource);
  if(UI.grain)UI.grain.textContent=Math.floor(grain);
  if(UI.meat)UI.meat.textContent=Math.floor(meat);
  if(UI.level)UI.level.textContent=String(level);
  const data=[
    ['COLETA','REÚNA GRÃOS PARA O PILAR'],
    ['CONSTRUÇÃO','ALIMENTE O PILAR DE HÓRUS'],
    ['CHAMADO','DESPERTE 3 ACÓLITOS'],
    ['CAÇA','DERRUBE AS SOMBRAS E RECOLHA CARNE'],
    ['LIMIAR','ALIMENTE O SELO DO LIMIAR'],
    ['PROVA','VENÇA O OBSERVADOR CEGO'],
    ['ASCENSÃO','O PRÓXIMO NÍVEL ESTÁ SE ABRINDO']
  ][objective]||['TRAVESSIA','AVANCE'];
  if(UI.objectiveKicker)UI.objectiveKicker.textContent='NÍVEL '+level+' · '+data[0];
  let text=data[1];
  if(objective===0)text='GRÃOS '+Math.floor(grain)+' / '+costs.grain;
  if(objective===1)text='PILAR '+Math.floor(builds[0].height*100)+'% · GRÃOS '+Math.floor(grain);
  if(objective===2)text='ACÓLITOS '+rescued+' / 3';
  if(objective===3)text='SOMBRAS '+Math.min(levelTarget,fieldKills)+' / '+levelTarget+' · CARNE '+Math.floor(meat)+' / '+costs.meat;
  if(objective===4)text='SELO '+Math.floor(builds[1].height*100)+'% · CARNE '+Math.floor(meat);
  if(objective===5&&boss)text='OBSERVADOR CEGO · '+Math.max(0,Math.ceil(boss.hp))+' / '+boss.maxHp;
  if(UI.objective)UI.objective.textContent=text;
}
function setObjective(n){if(objective===n)return;objective=n;updateHUD();fx.push({kind:'banner',text:UI.objective?.textContent||'',t:0,d:1.25});audio&&audio.sfx('special_room_activate',{gain:.75})}
function emit(kind,x,y,data={}){fx.push(Object.assign({kind,x,y,t:0,d:.65},data))}
function pickupDrop(d){
  addCurrency(d.kind||'meat',d.value);d.dead=true;emit('pickup',d.x,d.y,{text:'+'+d.value+(d.kind==='grain'?' GRÃO':d.kind==='meat'?' CARNE':' ESSÊNCIA')});
  audio&&audio.sfx('pickup',{gain:.68,pitch:d.kind==='meat' ? .9 : 1.08});try{navigator.vibrate?.(4)}catch(_){}
}
function completeLevel(){
  if(runState!=='playing')return;objective=6;levelTimer=1.25;resource+=3+Math.floor(level*.5);player.hp=Math.min(player.maxHp,player.hp+28);
  builds.forEach(b=>{b.tier=(b.tier||0)+1;b.done=true;b.height=1});
  bestLevel=Math.max(bestLevel,level+1);try{localStorage.setItem('harun-roomrun-best',String(bestLevel))}catch(_){}
  updateHUD();fx.push({kind:'banner',text:'NÍVEL '+level+' CONCLUÍDO · +'+(3+Math.floor(level*.5))+' ESSÊNCIAS',t:0,d:1.2});
  audio&&audio.setState('ritual',{intensity:.5});audio&&audio.sfx('level_up',{gain:1});window.MUNDUSMusic?.sync?.();try{navigator.vibrate?.([16,28,24])}catch(_){}
}
function beginNextLevel(){
  level++;levelTimer=0;objective=0;fieldKills=0;kills=0;boss=null;enemies=[];drops=[];waveTimer=0;
  player.maxHp=Math.min(180,100+(level-1)*2);player.hp=player.maxHp;player.vx=player.vy=0;player.x=5.2;player.y=15.2;
  const costs=levelCosts();
  grain=Math.min(grain,Math.ceil(costs.grain*.22));meat=Math.min(meat,Math.ceil(costs.meat*.18));
  depot.max=costs.grain;depot.amount=Math.ceil(costs.grain*.72);depot.respawn=0;
  harvestNodes.forEach(h=>{h.max=18+Math.min(18,level);h.amount=h.max;h.respawn=0});
  builds.forEach(b=>{b.invest=0;b.done=false;b.height=0;b.soundCd=0});
  if(level>1&&acolytes.filter(a=>a.rescued&&!a.ambient).length>=3)rescued=3;
  spawnInitialEnemies();updateHUD();audio&&audio.setState('explore',{intensity:.4});
  fx.push({kind:'banner',text:'NÍVEL '+level+' · A CIDADELA SE RECOMPÕE',t:0,d:1.2});
}
function damageEnemy(e,dmg){
  if(e.dead||runState!=='playing')return;const power=1+(level-1)*.035;e.hp=Math.max(0,e.hp-dmg*power);e.hit=.11;emit('damage',e.x,e.y,{text:String(Math.round(dmg*power)),crit:dmg>22});
  audio&&audio.sfx('impact',{gain:.45,pitch:e===boss ? .86 : 1});
  if(e.hp<=0){
    e.dead=true;kills++;if(e!==boss)fieldKills++;emit('burst',e.x,e.y,{big:e===boss});audio&&audio.sfx(e===boss?'boss_death':'enemy_death',{gain:e===boss?1:.55});
    if(e===boss){resource+=2+Math.floor(level*.4);completeLevel()}
    else{const value=e.elite?10:e.kind==='hound'?7:5;drops.push({x:e.x,y:e.y,value,kind:'meat',dead:false,t:0})}
  }
}
function spawnFieldWave(){
  const pts=[[10.2,4.8],[12.1,2.5],[14.4,4.1],[16.6,2.0],[18.9,4.8],[21.0,2.7],[20.7,6.5],[15.0,6.4]];
  const count=Math.min(8,3+Math.floor(level/2));
  for(let i=0;i<count;i++){const p=pts[(i+level+fieldKills)%pts.length];spawnEnemy(p[0]+(Math.random()-.5)*.45,p[1]+(Math.random()-.5)*.35,i%3===0?'hound':'shade',level%4===0&&i===count-1)}
  audio&&audio.sfx('enemy_windup',{gain:.46});emit('banner',null,null,{text:'AS SOMBRAS RETORNAM',d:.8})
}
function maintainEncounter(dt){
  if(objective!==3&&objective!==4)return;
  const alive=enemies.some(e=>!e.dead&&e!==boss);
  if(alive){waveTimer=1.1;return}
  if(builds[1].done)return;
  waveTimer-=dt;if(waveTimer<=0){waveTimer=1.35;spawnFieldWave()}
}
function interactionUpdate(dt){
  const costs=levelCosts();harvestSfxCd=Math.max(0,harvestSfxCd-dt);buildSfxCd=Math.max(0,buildSfxCd-dt);
  if(levelTimer>0){levelTimer-=dt;if(levelTimer<=0)beginNextLevel();return}
  const pd=dist(player,depot);
  if(depot.amount>0&&pd<.9){
    const take=Math.min(depot.amount,dt*38);depot.amount-=take;grain+=take;updateHUD();
    if(Math.random()<dt*11)emit('pickup',depot.x+(Math.random()-.5)*.4,depot.y,{text:'+'});
    if(harvestSfxCd<=0){harvestSfxCd=.16;audio&&audio.sfx('pickup',{gain:.28,pitch:1.15})}
    if(depot.amount<=.05){depot.amount=0;audio&&audio.sfx('room_clear',{gain:.48});depot.respawn=10}
  }else if(depot.amount<=0&&depot.respawn>0){
    depot.respawn-=dt;if(depot.respawn<=0){depot.amount=Math.ceil(costs.grain*.55);depot.respawn=0}
  }
  for(const h of harvestNodes){
    if(h.amount>0&&dist(player,h)<.78){
      const take=Math.min(h.amount,dt*18);h.amount-=take;grain+=take;
      if(Math.random()<dt*8)emit('pickup',h.x+(Math.random()-.5)*.18,h.y,{text:'+'});updateHUD();
      if(harvestSfxCd<=0){harvestSfxCd=.14;audio&&audio.sfx('pickup',{gain:.32,pitch:1.22})}
      if(h.amount<=.05){h.amount=0;h.respawn=8+level*.25;audio&&audio.sfx('room_clear',{gain:.34,pitch:1.15})}
    }else if(h.amount<=0&&h.respawn>0){h.respawn-=dt;if(h.respawn<=0)h.amount=h.max}
  }

  if(objective===0&&grain>0)setObjective(1);

  builds.forEach((b,ix)=>{
    if(b.done)return;
    const active=(ix===0&&objective===1)||(ix===1&&(objective===3||objective===4));if(!active)return;
    if(dist(player,b)<.92&&currencyAmount(b.currency)>0){
      if(ix===1&&objective===3)setObjective(4);
      const need=b.cost-b.invest,take=spendCurrency(b.currency,Math.min(need,dt*30));b.invest+=take;b.height=clamp(b.invest/b.cost,0,1);updateHUD();
      if(Math.random()<dt*10)emit('spark',b.x,b.y,{});
      if(buildSfxCd<=0){buildSfxCd=.24;audio&&audio.sfx('instrumenta',{gain:.38,pitch:.9+b.height*.25})}
      if(b.invest>=b.cost-.01){
        b.done=true;b.height=1;audio&&audio.sfx('ritual_seal',{gain:.95});shake=4;try{navigator.vibrate?.([8,22,12])}catch(_){}
        if(ix===0){if(level===1&&rescued<3)setObjective(2);else setObjective(3)}
        else{setObjective(5);spawnBoss()}
      }
    }
  });

  if(objective===2){
    for(const a of acolytes){
      if(a.ambient||a.rescued)continue;
      if(dist(player,a)<.72){a.rescued=true;rescued++;audio&&audio.sfx('arcana',{gain:.6});emit('pickup',a.x,a.y,{text:'DESPERTO'});if(rescued>=3)setObjective(3)}
    }
  }

  if(objective===3&&meat>0)setObjective(4);
  maintainEncounter(dt);
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
  if(runState!=='playing')return;
  player.atkCd-=dt;player.hitCd=Math.max(0,player.hitCd-dt);player.attackPulse=Math.max(0,player.attackPulse-dt*3);
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
  if(objective>=3)acolytes.filter(a=>a.rescued&&!a.ambient).forEach((a,i)=>{
    a.cool=(a.cool||0)-dt;if(a.cool<=0&&nearest&&!nearest.dead&&nd<4.5&&hasLineOfSight(player,nearest)){a.cool=.82+i*.08;damageEnemy(nearest,4);emit('bolt',player.x,player.y,{to:nearest})}
  });
  for(const d of drops){if(d.dead)continue;d.t+=dt;const di=dist(player,d);if(di<2.15){const q=Math.min(1,dt*7);d.x=lerp(d.x,player.x,q);d.y=lerp(d.y,player.y,q)}if(di<.48)pickupDrop(d)}
  enemies=enemies.filter(e=>!e.dead);drops=drops.filter(d=>!d.dead);
  const combat=enemies.some(e=>dist(player,e)<5.8);if(combat!==lastCombat&&objective!==5){lastCombat=combat;audio&&audio.setState(combat?'combat':'explore',{intensity:combat ? .72 : .38})}
}
function restartAfterDeath(){
  if(runState==='dead')return;
  runState='dead';paused=true;endPointer();fx.push({kind:'banner',text:'HĀRŪN CAIU · O LIMIAR O DEVOLVE',t:0,d:.9});audio&&audio.setState('menu',{intensity:.15});
  clearTimeout(deathTimer);deathTimer=setTimeout(()=>{
    if(runState!=='dead')return;
    grain=Math.floor(grain*.82);meat=Math.floor(meat*.82);resource=Math.max(0,resource-1);
    player.x=5.2;player.y=15.2;player.vx=player.vy=0;player.hp=player.maxHp;player.hitCd=.8;
    enemies=enemies.filter(e=>!e.dead&&e!==boss);boss=null;
    if(objective===5){builds[1].done=false;builds[1].height=.92;builds[1].invest=builds[1].cost*.92;objective=4}
    if((objective===3||objective===4)&&!enemies.some(e=>!e.dead))spawnFieldWave();
    runState='playing';paused=false;last=performance.now();updateHUD();audio&&audio.setState('explore',{intensity:.38});
  },900)
}
function updateFollowers(dt){
  const rescuedList=acolytes.filter(a=>a.rescued&&!a.ambient);
  rescuedList.forEach((a,i)=>{
    const back=1.05+i*.55,side=(i-1)*.45;
    const target={x:player.x-Math.cos(player.angle)*back-Math.sin(player.angle)*side,y:player.y-Math.sin(player.angle)*back+Math.cos(player.angle)*side};
    const nx=lerp(a.x,target.x,Math.min(1,dt*5.4)),ny=lerp(a.y,target.y,Math.min(1,dt*5.4));
    if(isWalkable(nx,ny)){a.x=nx;a.y=ny}
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
  const p=project(depot.x,depot.y);ctx.save();ctx.setLineDash([5,5]);ctx.strokeStyle='#e9e6d8aa';ctx.lineWidth=1;ctx.beginPath();ctx.ellipse(p.x,p.y+3,28,13,0,0,TAU);ctx.stroke();ctx.restore();
  const stacks=Math.ceil(depot.amount/8);for(let i=0;i<stacks;i++){const ox=(i%3-1)*8,oy=-Math.floor(i/3)*4;ell(p.x+ox,p.y-2+oy,8,4,'#a95c2e');ell(p.x+ox,p.y-4+oy,6,2,'#d58a43')}
}
function drawHarvestNode(h){
  if(h.amount<=.05)return;
  const p=project(h.x,h.y),ratio=clamp(h.amount/h.max,0,1),stems=Math.max(3,Math.round(10*ratio));
  ctx.save();ctx.globalAlpha=.72+.28*ratio;
  for(let i=0;i<stems;i++){
    const a=hash(h.x*17+i,h.y*23,4),b=hash(h.x*11+i,h.y*19,8),ox=(a-.5)*32,oy=(b-.5)*12,hh=19+hash(i,h.x,9)*15;
    line(p.x+ox,p.y+oy,p.x+ox-2,p.y+oy-hh,'#9a8032',1.5,.92);
    line(p.x+ox-2,p.y+oy-hh,p.x+ox+4,p.y+oy-hh-3,'#e1c55e',1.25,.95);
  }
  ctx.restore();
  if(dist(player,h)<1.05){ctx.save();ctx.setLineDash([4,4]);ctx.strokeStyle='#f0df83aa';ctx.beginPath();ctx.ellipse(p.x,p.y+4,25,10,0,0,TAU);ctx.stroke();ctx.restore()}
}
function drawBuild(b){
  const p=project(b.x,b.y),done=b.done,prog=clamp(b.height||0,0,1),active=(!done&&((b===builds[0]&&objective===1)||(b===builds[1]&&(objective===3||objective===4))));
  ctx.save();ctx.setLineDash([4,4]);ctx.strokeStyle=done?'#6effb0aa':active?'#f5dc84dd':'#d7d4c299';ctx.lineWidth=active?1.8:1.15;ctx.beginPath();ctx.ellipse(p.x,p.y+3,30,13,0,0,TAU);ctx.stroke();ctx.restore();
  if(!done&&prog<.03)poly([[p.x-18,p.y-3],[p.x,p.y-12],[p.x+18,p.y-3],[p.x,p.y+7]],active?'#24452c':'#143524',active?'#f0cc61':'#47df8b');
  if(prog>0){
    const h=9+prog*76;ell(p.x,p.y+5,17,7,'#151514');
    poly([[p.x-11,p.y],[p.x-8,p.y-h],[p.x+8,p.y-h],[p.x+11,p.y]],done?'#7b412e':'#704033','#c08455',1.1);
    for(let yy=10;yy<h-4;yy+=12)line(p.x-7,p.y-yy,p.x+7,p.y-yy,'#e1b179',1,.35);
    ell(p.x,p.y-h,9,4,done?'#dfb95a':'#a36b44');
    if(done){glow(p.x,p.y-h-5,28,'#e6bd63',.28);line(p.x,p.y-h-14,p.x,p.y-h-2,'#ffe394',2.2)}
  }
  if(!done){
    const remain=Math.max(0,Math.ceil(b.cost-b.invest)),label=b.currency==='grain'?'GRÃO':'CARNE';
    rr(p.x-24,p.y-39,48,15,7,'#080908dd','#8b744d');
    ctx.fillStyle=b.currency==='grain'?'#f0d36b':'#f29a8c';ctx.font='800 6px Cinzel,serif';ctx.textAlign='center';ctx.fillText(label+' '+remain,p.x,p.y-29);
  }
}
function drawAcolyte(a){
  const p=project(a.x,a.y);ell(p.x,p.y+10,12,5,'#000',.35);ell(p.x,p.y-6,7,9,a.rescued?'#2f4157':'#4a3b56');ell(p.x,p.y-17,5.5,6,'#d2b89d');line(p.x-4,p.y+1,p.x-8,p.y+11,'#1f2026',3);line(p.x+4,p.y+1,p.x+8,p.y+11,'#1f2026',3);if(a.rescued)glow(p.x,p.y-4,18,'#7edfd0',.16);
  if(!a.rescued)drawBubble(p.x,p.y-43,a.bubble,a.ambient?'#7f6d5c':'#9b312c');
}
function artReady(im){return !!(im&&im.complete&&im.naturalWidth>1&&im.naturalHeight>1)}
function drawSprite(im,x,y,targetH,alpha=1,flip=false){
  if(!artReady(im))return false;const ar=im.naturalWidth/im.naturalHeight,w=Math.max(targetH*.42,Math.min(targetH*.9,targetH*ar));
  ctx.save();ctx.globalAlpha=alpha;ctx.translate(x,y);if(flip)ctx.scale(-1,1);ctx.drawImage(im,-w/2,-targetH,w,targetH);ctx.restore();return true
}
function drawHero(){
  const p=project(player.x,player.y);ell(p.x,p.y+17,18,6,'#000',.45);
  ctx.save();ctx.strokeStyle='#46f19a';ctx.lineWidth=3;ctx.beginPath();ctx.ellipse(p.x,p.y+14,21,8,0,0,TAU);ctx.stroke();glow(p.x,p.y-1,27,'#7ce5ad',.08);ctx.restore();
  const bob=Math.sin(player.walk*1.7)*1.3*player.moveBlend,flip=Math.cos(player.angle)+Math.sin(player.angle)<-.08;
  const used=drawSprite(ART.hero,p.x,p.y+20+bob,58,1,flip);
  if(!used){
    ctx.save();ctx.translate(p.x,p.y+bob);
    poly([[-9,2],[-12,17],[0,25],[12,17],[9,2]],'#17191d','#08090a',1.2);poly([[-6,1],[0,20],[6,1],[4,-6],[-4,-6]],'#35252b');line(-7,7,7,14,'#c3994d',3);
    ell(0,-11,7,8,'#bc9b7d');poly([[-9,-10],[-7,-20],[0,-24],[8,-20],[9,-9],[4,-14],[-4,-14]],'#08090b');line(6,6,15,-9,'#d0aa63',2);ctx.restore();
  }
  if(player.attackPulse>0){ctx.save();ctx.globalAlpha=player.attackPulse;ctx.strokeStyle='#7ae9ff';ctx.lineWidth=3.5;for(let i=0;i<3;i++){const a=time*7+i*TAU/3;ctx.beginPath();ctx.arc(p.x,p.y+5,24+i*2,a,a+.7);ctx.stroke()}ctx.restore()}
  rr(p.x-22,p.y-39,44,5,3,'#111');rr(p.x-22,p.y-39,44*(player.hp/player.maxHp),5,3,'#48e178');
  if(player.hp===player.maxHp){ctx.fillStyle='#effbe8';ctx.font='bold 6px Manrope';ctx.textAlign='center';ctx.fillText('MAX',p.x,p.y-43)}
}
function drawEnemy(e){
  const p=project(e.x,e.y),hit=e.hit>0;ell(p.x,p.y+12,e===boss?24:13,e===boss?8:5,'#000',.43);
  if(e===boss&&e.telegraph>0){const q=1-Math.max(0,Math.min(1,e.telegraph/(e.phase ? .52 : .68)));ctx.save();ctx.globalAlpha=.3+.5*q;ctx.strokeStyle='#ff5164';ctx.lineWidth=2.5;ctx.beginPath();ctx.ellipse(p.x,p.y+5,28+q*42,13+q*20,0,0,TAU);ctx.stroke();ctx.restore()}
  const a=hit?.58:1;
  let used=false;if(e===boss)used=drawSprite(ART.boss,p.x,p.y+24,94,a,false);else used=drawSprite(ART.shade,p.x,p.y+17,e.kind==='hound'?46:43,a,Math.sin(e.x+time)<0);
  if(!used){ctx.save();ctx.translate(p.x,p.y);ctx.globalAlpha=a;if(e===boss){glow(0,-4,42,'#ba2040',.15);ell(0,-4,23,18,'#16131e');ell(-7,-7,4,4,'#ff3c51');ell(7,-7,4,4,'#ff3c51')}else if(e.kind==='hound'){ell(0,0,14,8,'#11151d');poly([[-9,-4],[-16,-16],[-3,-11]],'#1e202b');poly([[9,-4],[16,-16],[3,-11]],'#1e202b');ell(6,-2,2,2,'#ff3b4d')}else{poly([[-11,10],[-8,-8],[0,-15],[8,-8],[11,10],[0,15]],'#17131d','#33243a');ell(0,-7,3,3,'#e53f5a')}ctx.restore()}
  const w=e===boss?82:32,y=p.y-(e===boss?50:29);rr(p.x-w/2,y,w,5,3,'#1b090d');rr(p.x-w/2,y,w*Math.max(0,e.hp/e.maxHp),5,3,e===boss?'#e92f4b':'#d3293b');
  if(e===boss){ctx.fillStyle='#f1d9c2';ctx.font='700 8px Cinzel,serif';ctx.textAlign='center';ctx.fillText(e.name,p.x,p.y-57)}
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
  if(objective===0){const candidates=[depot,...harvestNodes.filter(h=>h.amount>0)];return candidates.sort((a,b)=>dist(player,a)-dist(player,b))[0]||depot}
  if(objective===1)return builds[0];if(objective===2)return acolytes.find(a=>!a.ambient&&!a.rescued)||null;
  if(objective===3)return enemies.find(e=>!e.dead)||{x:16,y:4};if(objective===4)return builds[1];if(objective===5)return boss;return null
}
function drawObjectiveBeacon(){
  const t=objectiveTarget();if(!t)return;const p=project(t.x,t.y),margin=34;
  if(p.x>margin&&p.x<W-margin&&p.y>105&&p.y<H-margin){ctx.save();ctx.globalAlpha=.45+.2*Math.sin(time*4);ctx.strokeStyle='#e9c26c';ctx.lineWidth=1.5;ctx.beginPath();ctx.ellipse(p.x,p.y+4,24,11,0,0,TAU);ctx.stroke();ctx.restore();return}
  const cx=Math.max(margin,Math.min(W-margin,p.x)),cy=Math.max(112,Math.min(H-margin,p.y)),ang=Math.atan2(p.y-H*.5,p.x-W*.5);ctx.save();ctx.translate(cx,cy);ctx.rotate(ang);poly([[12,0],[-7,-6],[-4,0],[-7,6]],'#f0ca75');ctx.restore()
}
function drawScene(){
  drawFloor();drawWalls();drawDepot();harvestNodes.forEach(drawHarvestNode);builds.forEach(drawBuild);
  const drawables=[];
  props.forEach(p=>drawables.push({d:p.x+p.y,fn:()=>drawProp(p)}));
  acolytes.forEach(a=>drawables.push({d:a.x+a.y+.05,fn:()=>drawAcolyte(a)}));
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
    ui:Object.values(UI).every(Boolean),
    spawn:isWalkableRadius(5.2,15.2),
    field:enemyCanWalk({kind:'shade'},16,4),
    input:!mobileInput||mobileInput.validate?.().ok!==false,
    objectives:objective>=0&&objective<=6,
    audio:!audio||typeof audio.setState==='function',
    runtimeErrors:runtimeErrors.length===0
  };return{version:VERSION,pass:Object.values(checks).every(Boolean),checks,runtimeErrors:[...runtimeErrors],tier:perf?.snapshot?.()||null}
}
bindAudio();resetRun();syncViewport();
const p0=isoRaw(player.x,player.y);camera.x=p0.x;camera.y=p0.y;
perf?.onChange?.(s=>window.MUNDUSVFX?.setQuality?.(s.tier==='low' ? .68 : s.tier==='medium' ? .88 : 1.06));
requestAnimationFrame(loop);
const stateSnapshot=()=>({runState,paused,objective,resource,kills,fieldKills,rescued,hp:player.hp,x:player.x,y:player.y,enemies:enemies.filter(e=>!e.dead).length,boss:boss?Math.max(0,boss.hp):null,fps:Math.round(1000/Math.max(1,frameEma)),height:H,tier:perf?.tier?.()||'standalone',runtimeErrors:[...runtimeErrors]});
const qaEnabled=new URLSearchParams(window.location?.search||'').get('qa')==='dev';
const qaTools=qaEnabled?{
  step:(dt=.016)=>{if(runState==='playing'&&!paused)update(Math.max(0,Math.min(.033,Number(dt)||.016)));return stateSnapshot()},
  setMove:(x=0,y=0)=>{pointer.active=Math.hypot(x,y)>.001;pointer.vx=Math.max(-1,Math.min(1,Number(x)||0));pointer.vy=Math.max(-1,Math.min(1,Number(y)||0));return stateSnapshot()},
  release:()=>{endPointer();return stateSnapshot()},
  setPlayer:(x,y)=>{if(isWalkableRadius(Number(x),Number(y))){player.x=Number(x);player.y=Number(y);player.vx=player.vy=0}return stateSnapshot()},
  setObjective:n=>{const v=Math.max(0,Math.min(6,Number(n)||0));objective=v;updateHUD();return stateSnapshot()},
  grantResource:n=>{resource=Math.max(0,resource+(Number(n)||0));updateHUD();return stateSnapshot()},
  killField:()=>{if(objective===3){for(const e of [...enemies])if(e!==boss&&!e.dead)damageEnemy(e,9999);interactionUpdate(0)}return stateSnapshot()},
  killBoss:()=>{if(boss&&!boss.dead)damageEnemy(boss,9999);return stateSnapshot()}
}:Object.freeze({enabled:false});
window.__HARUN_ROOMRUN_V9__={version:VERSION,start:startGame,reset:resetRun,selfTest,state:stateSnapshot,qa:qaTools,sentinel:{gameId:'harun-survivor',mode:'reference-roomrun',institutionalWrite:false,sourceArt:'procedural-original',mobileFirst:true}};
window.__MUNDUS_SENTINEL__=window.__MUNDUS_SENTINEL__||{};window.__MUNDUS_SENTINEL__.roomrunV9=window.__HARUN_ROOMRUN_V9__;window.__MUNDUS_SENTINEL__.roomrunQA=selfTest();
})();
