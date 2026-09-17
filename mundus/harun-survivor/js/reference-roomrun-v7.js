
(function(){
'use strict';
const canvas=document.getElementById('game'),ctx=canvas.getContext('2d');
const W=540,H=960,TW=72,TH=36,TAU=Math.PI*2;
const $=s=>document.querySelector(s);
const UI={resource:$('#resourceCount'),objective:$('#objectiveText'),objectiveKicker:$('#objectiveKicker'),tip:$('#moveTip'),joy:$('#touchJoy'),knob:$('#touchJoy i'),pause:$('#pauseOverlay'),start:$('#startOverlay'),victory:$('#victoryOverlay'),pauseBtn:$('#pauseBtn'),resume:$('#resumeBtn'),restart:$('#restartBtn'),restartVictory:$('#restartVictory'),music:$('#musicVol'),sfx:$('#sfxVol'),musicVal:$('#musicVal'),sfxVal:$('#sfxVal')};
const DPR=Math.min(2,window.devicePixelRatio||1);
canvas.width=W*DPR;canvas.height=H*DPR;ctx.setTransform(DPR,0,0,DPR,0,0);
const audio=window.MUNDUSAudio||null;
if(audio){audio.configure({game:'survivor',profile:{bpm:104,music:.47,sfx:.91,ui:.8,amb:.42}});audio.setState('menu',{intensity:.2})}
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const lerp=(a,b,t)=>a+(b-a)*t;
const dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
const hash=(x,y,k=0)=>{let n=Math.sin(x*127.1+y*311.7+k*74.7)*43758.5453;return n-Math.floor(n)};
const isoRaw=(x,y)=>({x:(x-y)*TW*.5,y:(x+y)*TH*.5});
let camera={x:0,y:0},shake=0,started=false,paused=false,last=performance.now(),time=0,idle=0,lastCombat=false;
let pointer={active:false,id:null,ox:0,oy:0,x:0,y:0,vx:0,vy:0};
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
function typeAt(x,y){const z=walkZones.slice().reverse().find(q=>x>=q.x0&&x<=q.x1&&y>=q.y0&&y<=q.y1);return z?z.type:null}
function project(x,y){
  const p=isoRaw(x,y),jx=shake?((Math.random()-.5)*shake):0,jy=shake?((Math.random()-.5)*shake):0;
  return{x:p.x-camera.x+W*.5+jx,y:p.y-camera.y+H*.56+jy}
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
    if(c.type==='field'&&hash(c.x,c.y,2)>.18){
      const path=Math.abs((c.x-c.y)-7)<1.6||Math.abs(c.x-15)<1.1;
      if(!path)drawCrop(c.x+.5,c.y+.5,c.x*31+c.y*19);
    }
  }
}
function drawCrop(x,y,seed){
  const p=project(x,y);for(let i=0;i<7;i++){const a=hash(seed,i,1),b=hash(seed,i,2);const ox=(a-.5)*38,oy=(b-.5)*14,h=15+hash(seed,i,3)*17;
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
 {x:9.3,y:17.2,rescued:false,follow:0,bubble:'☉'},
 {x:10.2,y:16.7,rescued:false,follow:1,bubble:'≡'},
 {x:11.2,y:16.3,rescued:false,follow:2,bubble:'△'},
 {x:12.2,y:15.8,rescued:false,ambient:true,bubble:'◌'},
 {x:13.0,y:15.3,rescued:false,ambient:true,bubble:'⚗'}
];
const depot={x:6.2,y:16.0,amount:40,max:40,respawn:0};
const builds=[
 {x:13.0,y:13.2,cost:40,invest:0,done:false,name:'PILAR DE HÓRUS',height:0},
 {x:17.2,y:7.2,cost:40,invest:0,done:false,name:'SELO DO LIMIAR',height:0}
];
let fx=[],drops=[],enemies=[],boss=null,objective=0,kills=0,rescued=0,resource=0;
const player={x:5.2,y:15.2,hp:100,maxHp:100,speed:5.05,atkCd:0,hitCd:0,walk:0,angle:0,attackPulse:0};
function resetRun(){
  player.x=5.2;player.y=15.2;player.hp=100;player.maxHp=100;player.atkCd=0;player.hitCd=0;player.walk=0;
  objective=0;kills=0;rescued=0;resource=0;fx=[];drops=[];enemies=[];boss=null;depot.amount=40;depot.respawn=0;
  builds.forEach(b=>{b.invest=0;b.done=false;b.height=0});acolytes.forEach(a=>{if(!a.ambient){a.rescued=false;a.follow=a.follow}else a.rescued=false});
  spawnInitialEnemies();updateHUD();
}
function spawnInitialEnemies(){
  const pts=[[14,4.6],[16.2,3.5],[18.2,5.4],[19.4,2.8],[12.8,2.8],[20.5,6.2]];
  pts.forEach((p,i)=>spawnEnemy(p[0],p[1],i%3===0?'hound':'shade'));
}
function spawnEnemy(x,y,kind='shade',elite=false){
  const hp=elite?70:kind==='hound'?28:22;
  enemies.push({x,y,kind,hp,maxHp:hp,r:elite?.42:.27,speed:kind==='hound'?2.35:1.7,hit:0,dead:false,elite});
}
function spawnBoss(){
  boss={x:18.3,y:3.3,hp:320,maxHp:320,r:.72,speed:1.15,hit:0,dead:false,name:'OBSERVADOR CEGO',phase:0};
  enemies.push(boss);
  audio&&audio.setState('boss',{intensity:.95});audio&&audio.sfx('boss_windup',{gain:1});
}
function updateHUD(){
  if(UI.resource)UI.resource.textContent=Math.floor(resource);
  const data=[
    ['OFÍCIO','COLETE 40 ESSÊNCIAS NO DEPÓSITO'],
    ['CONSTRUÇÃO','ERGA O PILAR DE HÓRUS'],
    ['CHAMADO','DESPERTE 3 ACÓLITOS'],
    ['EXTERIOR','ATRAVESSE O CAMPO E DERRUBE 6 SOMBRAS'],
    ['LIMIAR','REÚNA 40 ESSÊNCIAS E ERGA O SELO'],
    ['PROVA','VENÇA O OBSERVADOR CEGO'],
    ['CONCLUÍDO','A PASSAGEM FOI ABERTA']
  ][objective]||['TRAVESSIA','AVANCE'];
  UI.objectiveKicker.textContent=data[0];UI.objective.textContent=data[1];
}
function setObjective(n){if(objective===n)return;objective=n;updateHUD();fx.push({kind:'banner',text:UI.objective.textContent,t:0,d:1.35});audio&&audio.sfx('special_room_activate',{gain:.85})}
function emit(kind,x,y,data={}){fx.push(Object.assign({kind,x,y,t:0,d:.65},data))}
function pickupDrop(d){resource+=d.value;d.dead=true;emit('pickup',d.x,d.y,{text:'+'+d.value});audio&&audio.sfx('pickup',{gain:.7});updateHUD()}
function damageEnemy(e,dmg){
  if(e.dead)return;e.hp-=dmg;e.hit=.11;emit('damage',e.x,e.y,{text:String(Math.round(dmg)),crit:dmg>22});
  audio&&audio.sfx('impact',{gain:.45,pitch:e===boss?.86:1});
  if(e.hp<=0){e.dead=true;kills++;emit('burst',e.x,e.y,{big:e===boss});audio&&audio.sfx(e===boss?'boss_death':'enemy_death',{gain:e===boss?1:.55});
    if(e===boss){setObjective(6);setTimeout(showVictory,650)}
    else drops.push({x:e.x,y:e.y,value:8,dead:false,t:0});
  }
}
function interactionUpdate(dt){
  const pd=dist(player,depot);
  if(depot.amount>0&&pd<.85){
    const take=Math.min(depot.amount,dt*34);depot.amount-=take;resource+=take;updateHUD();
    if(Math.random()<dt*12)emit('pickup',depot.x+(Math.random()-.5)*.4,depot.y,{text:'+'});
    if(depot.amount<=.05){depot.amount=0;audio&&audio.sfx('room_clear',{gain:.55});if(objective===0)setObjective(1);depot.respawn=9}
  }else if(depot.amount<=0&&depot.respawn>0){depot.respawn-=dt;if(depot.respawn<=0&&objective>=3){depot.amount=40;depot.respawn=0}}
  builds.forEach((b,ix)=>{
    if(b.done)return;
    if(dist(player,b)<.82&&resource>0&&((ix===0&&objective===1)||(ix===1&&objective===4))){
      const take=Math.min(resource,b.cost-b.invest,dt*32);resource-=take;b.invest+=take;b.height=b.invest/b.cost;updateHUD();
      if(Math.random()<dt*8)emit('spark',b.x,b.y,{});
      if(b.invest>=b.cost-.01){b.done=true;b.height=1;audio&&audio.sfx('ritual_seal',{gain:.95});shake=4;
        if(ix===0)setObjective(2);else{setObjective(5);spawnBoss()}
      }
    }
  });
  if(objective===2){
    for(const a of acolytes){
      if(a.ambient||a.rescued)continue;
      if(dist(player,a)<.7){a.rescued=true;rescued++;audio&&audio.sfx('arcana',{gain:.6});emit('pickup',a.x,a.y,{text:'DESPERTO'});if(rescued>=3)setObjective(3)}
    }
  }
  if(objective===3&&kills>=6)setObjective(4);
}
function inputVector(){
  let sx=0,sy=0;
  if(keys.w||keys.arrowup)sy-=1;if(keys.s||keys.arrowdown)sy+=1;if(keys.a||keys.arrowleft)sx-=1;if(keys.d||keys.arrowright)sx+=1;
  if(pointer.active){sx=pointer.vx;sy=pointer.vy}
  const m=Math.hypot(sx,sy);if(m<.08)return{x:0,y:0};
  sx/=m;sy/=m;
  let wx=(sx/(TW*.5)+sy/(TH*.5))*.5,wy=(sy/(TH*.5)-sx/(TW*.5))*.5;
  const wm=Math.hypot(wx,wy)||1;return{x:wx/wm,y:wy/wm}
}
function movePlayer(dt){
  const v=inputVector();const moving=Math.hypot(v.x,v.y)>.01;
  if(moving){idle=0;UI.tip?.classList.add('hide');player.walk+=dt*10;player.angle=Math.atan2(v.y,v.x);
    const nx=player.x+v.x*player.speed*dt,ny=player.y+v.y*player.speed*dt;
    if(isWalkable(nx,player.y))player.x=nx;if(isWalkable(player.x,ny))player.y=ny;
  }else idle+=dt;
  if(idle>2.2&&!pointer.active&&started&&!paused)UI.tip?.classList.remove('hide');
}
function combatUpdate(dt){
  player.atkCd-=dt;player.hitCd=Math.max(0,player.hitCd-dt);player.attackPulse=Math.max(0,player.attackPulse-dt*3);
  const live=enemies.filter(e=>!e.dead);
  let nearest=null,nd=99;
  for(const e of live){const d=dist(player,e);if(d<nd){nd=d;nearest=e}
    if(d<7.5&&objective>=3){
      const dx=player.x-e.x,dy=player.y-e.y,m=Math.hypot(dx,dy)||1;e.x+=dx/m*e.speed*dt;e.y+=dy/m*e.speed*dt;
      if(d<.62&&player.hitCd<=0){player.hp=Math.max(0,player.hp-(e===boss?12:6));player.hitCd=.55;shake=7;emit('hurt',player.x,player.y,{});audio&&audio.sfx('player_hurt',{gain:.9});if(player.hp<=0)restartAfterDeath()}
    }
    e.hit=Math.max(0,e.hit-dt);
  }
  if(nearest&&nd<2.7&&player.atkCd<=0){
    player.atkCd=.32;player.attackPulse=1;audio&&audio.sfx('attack',{gain:.52,pitch:.95+Math.random()*.14});
    const dmg=nearest===boss?15:18;damageEnemy(nearest,dmg);
    for(const e of live)if(e!==nearest&&dist(player,e)<1.22)damageEnemy(e,9);
    emit('slash',player.x,player.y,{angle:Math.atan2(nearest.y-player.y,nearest.x-player.x)});
  }
  // awakened acolytes attack with slower bolts
  acolytes.filter(a=>a.rescued&&!a.ambient).forEach((a,i)=>{
    a.cool=(a.cool||0)-dt;if(a.cool<=0&&nearest&&nd<4.5){a.cool=.9+i*.08;damageEnemy(nearest,4);emit('bolt',player.x,player.y,{to:nearest})}
  });
  for(const d of drops){if(d.dead)continue;d.t+=dt;const di=dist(player,d);if(di<1.8){const q=Math.min(1,dt*5);d.x=lerp(d.x,player.x,q);d.y=lerp(d.y,player.y,q)}if(di<.48)pickupDrop(d)}
  enemies=enemies.filter(e=>!e.dead);drops=drops.filter(d=>!d.dead);
  const combat=live.some(e=>dist(player,e)<5.5);if(combat!==lastCombat&&objective!==5){lastCombat=combat;audio&&audio.setState(combat?'combat':'explore',{intensity:combat?.72:.38})}
}
function restartAfterDeath(){
  paused=true;setTimeout(()=>{paused=false;resetRun();audio&&audio.setState('explore',{intensity:.38})},700)
}
function updateFollowers(dt){
  const rescuedList=acolytes.filter(a=>a.rescued&&!a.ambient);
  rescuedList.forEach((a,i)=>{
    const back=1.05+i*.55,side=(i-1)*.45;
    const target={x:player.x-Math.cos(player.angle)*back-Math.sin(player.angle)*side,y:player.y-Math.sin(player.angle)*back+Math.cos(player.angle)*side};
    a.x=lerp(a.x,target.x,Math.min(1,dt*4.7));a.y=lerp(a.y,target.y,Math.min(1,dt*4.7));
  });
}
function update(dt){
  time+=dt;if(shake>0)shake=Math.max(0,shake-dt*28);
  movePlayer(dt);interactionUpdate(dt);combatUpdate(dt);updateFollowers(dt);
  for(const f of fx)f.t+=dt;fx=fx.filter(f=>f.t<f.d);
  const pr=isoRaw(player.x,player.y);camera.x=lerp(camera.x,pr.x,1-Math.pow(.001,dt));camera.y=lerp(camera.y,pr.y,1-Math.pow(.001,dt));
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
function drawBuild(b){
  const p=project(b.x,b.y);const done=b.done,prog=b.height||0;
  ctx.save();ctx.setLineDash([4,4]);ctx.strokeStyle=done?'#6effb0aa':'#f0eee0aa';ctx.lineWidth=1.2;ctx.beginPath();ctx.ellipse(p.x,p.y+3,29,13,0,0,TAU);ctx.stroke();ctx.restore();
  if(!done&&prog<.03){poly([[p.x-18,p.y-3],[p.x,p.y-12],[p.x+18,p.y-3],[p.x,p.y+7]],'#143524','#47df8b');ctx.fillStyle='#eaf8ed';ctx.font='bold 8px Cinzel,serif';ctx.textAlign='center';ctx.fillText(Math.max(0,Math.ceil(b.cost-b.invest)),p.x,p.y+2)}
  if(prog>0){const h=8+prog*72;ell(p.x,p.y+4,16,7,'#191717');poly([[p.x-10,p.y],[p.x-7,p.y-h],[p.x+7,p.y-h],[p.x+10,p.y]],done?'#6a352a':'#743d2f','#bd7d51',1);ell(p.x,p.y-h,8,4,done?'#d5a24e':'#9c633f');if(done){glow(p.x,p.y-h-4,25,'#e6bd63',.25);line(p.x,p.y-h-12,p.x,p.y-h-2,'#ffe394',2)}}
  if(!done&&objective>0)drawBubble(p.x,p.y-48,'✦');
}
function drawAcolyte(a){
  const p=project(a.x,a.y);ell(p.x,p.y+10,12,5,'#000',.35);ell(p.x,p.y-6,7,9,a.rescued?'#2f4157':'#4a3b56');ell(p.x,p.y-17,5.5,6,'#d2b89d');line(p.x-4,p.y+1,p.x-8,p.y+11,'#1f2026',3);line(p.x+4,p.y+1,p.x+8,p.y+11,'#1f2026',3);if(a.rescued)glow(p.x,p.y-4,18,'#7edfd0',.16);
  if(!a.rescued)drawBubble(p.x,p.y-43,a.bubble,a.ambient?'#7f6d5c':'#9b312c');
}
function drawHero(){
  const p=project(player.x,player.y);ell(p.x,p.y+18,19,7,'#000',.48);
  ctx.save();ctx.strokeStyle='#49e795';ctx.lineWidth=3;ctx.beginPath();ctx.ellipse(p.x,p.y+15,22,9,0,0,TAU);ctx.stroke();glow(p.x,p.y-1,30,'#7ce5ad',.08);
  const bob=Math.sin(player.walk*1.7)*1.2;ctx.translate(p.x,p.y+bob);
  poly([[-10,2],[-14,19],[0,28],[14,19],[10,2]],'#17191d','#08090a',1.5);poly([[-7,1],[0,22],[7,1],[5,-7],[-5,-7]],'#35252b');line(-8,8,8,15,'#c3994d',3);
  ell(0,-12,8,9,'#bc9b7d');poly([[-10,-11],[-8,-22],[0,-27],[9,-22],[11,-10],[5,-15],[-4,-15]],'#08090b');
  line(7,7,17,-10,'#d0aa63',2);line(17,-10,20,-18,'#f0dfb7',2);
  if(player.attackPulse>0){ctx.globalAlpha=player.attackPulse;ctx.strokeStyle='#7ae9ff';ctx.lineWidth=4;for(let i=0;i<4;i++){const a=time*6+i*TAU/4;ctx.beginPath();ctx.arc(0,7,27+i*2,a,a+.65);ctx.stroke();glow(Math.cos(a)*30,7+Math.sin(a)*12,10,'#6deeff',.22)}}
  ctx.restore();
  // health bar
  rr(p.x-23,p.y-39,46,5,3,'#111');rr(p.x-23,p.y-39,46*(player.hp/player.maxHp),5,3,'#48e178');if(player.hp===player.maxHp){ctx.fillStyle='#effbe8';ctx.font='bold 6px Manrope';ctx.textAlign='center';ctx.fillText('MAX',p.x,p.y-43)}
}
function drawEnemy(e){
  const p=project(e.x,e.y),hit=e.hit>0;ell(p.x,p.y+12,e===boss?25:14,e===boss?9:6,'#000',.45);
  ctx.save();ctx.translate(p.x,p.y);if(hit)ctx.globalAlpha=.55;
  if(e===boss){glow(0,-4,45,'#ba2040',.16);ell(0,-4,25,20,'#16131e');poly([[-28,-6],[-38,-28],[-12,-21]],'#3c1823');poly([[28,-6],[38,-28],[12,-21]],'#3c1823');ell(-8,-8,4,4,'#ff3c51');ell(8,-8,4,4,'#ff3c51');for(let i=0;i<5;i++){const a=time*1.2+i*TAU/5;ell(Math.cos(a)*34,3+Math.sin(a)*12,5,3,'#381521')}}
  else if(e.kind==='hound'){ell(0,0,15,9,'#11151d');poly([[-10,-5],[-18,-18],[-3,-12]],'#1e202b');poly([[10,-5],[18,-18],[3,-12]],'#1e202b');ell(7,-2,2,2,'#ff3b4d')}
  else{poly([[-13,11],[-9,-9],[0,-17],[9,-9],[13,11],[0,17]],'#17131d','#33243a');ell(0,-8,3,3,'#e53f5a')}
  ctx.restore();
  const w=e===boss?84:34;rr(p.x-w/2,p.y-(e===boss?48:31),w,5,3,'#1b090d');rr(p.x-w/2,p.y-(e===boss?48:31),w*Math.max(0,e.hp/e.maxHp),5,3,e===boss?'#e92f4b':'#d3293b');
  if(e===boss){ctx.fillStyle='#f1d9c2';ctx.font='700 8px Cinzel,serif';ctx.textAlign='center';ctx.fillText(e.name,p.x,p.y-55)}
}
function drawDrop(d){const p=project(d.x,d.y),bob=Math.sin(d.t*7)*2;glow(p.x,p.y-7+bob,18,'#6bffb2',.2);poly([[p.x-8,p.y-6+bob],[p.x,p.y-11+bob],[p.x+9,p.y-5+bob],[p.x,p.y+bob]],'#1e8a58','#7bffc0');ctx.fillStyle='#eafff1';ctx.font='bold 7px serif';ctx.textAlign='center';ctx.fillText('✦',p.x,p.y-5+bob)}
function drawFx(){
  for(const f of fx){const q=f.t/f.d,a=1-q,p=f.x!=null?project(f.x,f.y):null;
    if(f.kind==='damage'){ctx.globalAlpha=a;ctx.fillStyle=f.crit?'#ffe26b':'#ffffff';ctx.font=(f.crit?'900 18px':'800 13px')+' Manrope';ctx.textAlign='center';ctx.fillText(f.text,p.x,p.y-35-q*28);ctx.globalAlpha=1}
    else if(f.kind==='pickup'){ctx.globalAlpha=a;ctx.fillStyle='#a5ffca';ctx.font='800 10px Manrope';ctx.textAlign='center';ctx.fillText(f.text,p.x,p.y-24-q*20);ctx.globalAlpha=1}
    else if(f.kind==='spark'){for(let i=0;i<5;i++){const ang=i*1.7+f.t*5;ell(p.x+Math.cos(ang)*18*q,p.y-12+Math.sin(ang)*8*q,2,2,'#ffd66e',a)}}
    else if(f.kind==='burst'){for(let i=0;i<(f.big?18:8);i++){const ang=i*TAU/(f.big?18:8)+.4;ell(p.x+Math.cos(ang)*45*q,p.y+Math.sin(ang)*22*q,3,3,f.big?'#ff5672':'#a84d63',a)}}
    else if(f.kind==='hurt'){ctx.save();ctx.globalAlpha=a*.24;ctx.fillStyle='#d7253d';ctx.fillRect(0,0,W,H);ctx.restore()}
    else if(f.kind==='slash'){const s=project(f.x,f.y);ctx.save();ctx.globalAlpha=a;ctx.strokeStyle='#8ceaff';ctx.lineWidth=5;ctx.beginPath();ctx.arc(s.x,s.y,25+q*18,f.angle-.9,f.angle+.8);ctx.stroke();ctx.restore()}
    else if(f.kind==='bolt'&&f.to){const a1=project(f.x,f.y),a2=project(f.to.x,f.to.y);line(a1.x,a1.y-10,a2.x,a2.y-8,'#e8d47b',2,a)}
    else if(f.kind==='banner'){ctx.save();ctx.globalAlpha=Math.sin(Math.min(1,q)*Math.PI);rr(72,H*.24,W-144,52,12,'#070806dd','#8c6c42');ctx.fillStyle='#f3dfb5';ctx.font='800 11px Cinzel,serif';ctx.textAlign='center';ctx.fillText(f.text,W/2,H*.24+31);ctx.restore()}
  }
}
function drawGuide(){
  if(!pointer.active)return;const h=project(player.x,player.y),x=pointer.x,y=pointer.y;
  ctx.save();ctx.fillStyle='#f6f6f0';for(let i=1;i<=8;i++){const t=i/9;ctx.globalAlpha=.25+.65*t;ctx.beginPath();ctx.arc(lerp(h.x,x,t),lerp(h.y,y,t),2.2,0,TAU);ctx.fill()}ctx.globalAlpha=.85;ctx.strokeStyle='#fff';ctx.lineWidth=1.4;ctx.beginPath();ctx.arc(x,y,12,0,TAU);ctx.stroke();ctx.restore()
}
function drawScene(){
  drawFloor();drawWalls();drawDepot();builds.forEach(drawBuild);
  const drawables=[];
  props.forEach(p=>drawables.push({d:p.x+p.y,fn:()=>drawProp(p)}));
  acolytes.forEach(a=>drawables.push({d:a.x+a.y+.05,fn:()=>drawAcolyte(a)}));
  drops.forEach(d=>drawables.push({d:d.x+d.y+.08,fn:()=>drawDrop(d)}));
  enemies.forEach(e=>drawables.push({d:e.x+e.y+.12,fn:()=>drawEnemy(e)}));
  drawables.push({d:player.x+player.y+.14,fn:drawHero});
  drawables.sort((a,b)=>a.d-b.d).forEach(o=>o.fn());
  drawFx();drawGuide();
}
function loop(now){
  const dt=Math.min(.033,(now-last)/1000||0);last=now;
  if(started&&!paused)update(dt);drawScene();requestAnimationFrame(loop)
}
function setJoy(e){
  const r=canvas.getBoundingClientRect(),x=(e.clientX-r.left)*W/r.width,y=(e.clientY-r.top)*H/r.height;
  if(!pointer.active){pointer.ox=x;pointer.oy=y;UI.joy.style.left=(e.clientX-r.left)+'px';UI.joy.style.top=(e.clientY-r.top)+'px';UI.joy.style.display='block'}
  pointer.x=x;pointer.y=y;const dx=x-pointer.ox,dy=y-pointer.oy,m=Math.hypot(dx,dy),rad=48,sc=m>rad?rad/m:1;
  pointer.vx=(dx*sc)/rad;pointer.vy=(dy*sc)/rad;UI.knob.style.transform='translate('+(dx*sc)+'px,'+(dy*sc)+'px)'
}
canvas.addEventListener('pointerdown',e=>{e.preventDefault();if(!started)return;pointer.active=true;pointer.id=e.pointerId;canvas.setPointerCapture?.(e.pointerId);setJoy(e);audio&&audio.unlock()},{passive:false});
canvas.addEventListener('pointermove',e=>{if(!pointer.active||e.pointerId!==pointer.id)return;e.preventDefault();setJoy(e)},{passive:false});
function endPointer(e){if(pointer.active&&(!e||e.pointerId===pointer.id)){pointer.active=false;pointer.vx=pointer.vy=0;UI.joy.style.display='none';UI.knob.style.transform='translate(0,0)'}}
canvas.addEventListener('pointerup',endPointer);canvas.addEventListener('pointercancel',endPointer);
window.addEventListener('keydown',e=>{keys[e.key.toLowerCase()]=true;if(e.key==='Escape'){e.preventDefault();togglePause()}});
window.addEventListener('keyup',e=>keys[e.key.toLowerCase()]=false);
window.addEventListener('blur',()=>{endPointer();keys={}});
document.addEventListener('contextmenu',e=>e.preventDefault());
function startGame(){
  started=true;paused=false;UI.start.hidden=true;idle=0;audio&&audio.unlock();audio&&audio.setState('explore',{intensity:.38});resetRun();
}
function togglePause(){
  if(!started||!UI.victory.hidden)return;paused=!paused;UI.pause.hidden=!paused;audio&&audio.setState(paused?'menu':(objective===5?'boss':'explore'),{intensity:paused?.2:.45});endPointer()
}
function restart(){paused=false;UI.pause.hidden=true;UI.victory.hidden=true;resetRun();audio&&audio.setState('explore',{intensity:.38})}
function showVictory(){paused=true;UI.victory.hidden=false;audio&&audio.setState('pleroma',{intensity:.4});audio&&audio.sfx('room_clear',{gain:1})}
$('#startBtn').addEventListener('click',startGame);UI.pauseBtn.addEventListener('click',togglePause);UI.resume.addEventListener('click',togglePause);UI.restart.addEventListener('click',restart);UI.restartVictory.addEventListener('click',restart);
function bindAudio(){
  const m=audio?.getMaster?.()??.86,s=audio?.getEffectsVolume?.()??1;UI.music.value=Math.round(m*100);UI.sfx.value=Math.round(s*100);UI.musicVal.textContent=UI.music.value;UI.sfxVal.textContent=UI.sfx.value;
  UI.music.addEventListener('input',()=>{UI.musicVal.textContent=UI.music.value;audio?.setMaster?.(+UI.music.value/100)});
  UI.sfx.addEventListener('input',()=>{UI.sfxVal.textContent=UI.sfx.value;audio?.setEffectsVolume?.(+UI.sfx.value/100)});
}
bindAudio();resetRun();
const p0=isoRaw(player.x,player.y);camera.x=p0.x;camera.y=p0.y;
requestAnimationFrame(loop);
window.__HARUN_ROOMRUN_V7__={version:'7.0.0-reference-roomrun',reset:resetRun,state:()=>({objective,resource,kills,rescued,hp:player.hp,enemies:enemies.length,boss:boss?boss.hp:null}),sentinel:{gameId:'harun-survivor',mode:'reference-roomrun',institutionalWrite:false,sourceArt:'procedural-original',mobileFirst:true}};
})();
