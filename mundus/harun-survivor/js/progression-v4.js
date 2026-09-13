(function(){
'use strict';
const D=window.HarunSurvivorData,Core=window.HarunSurvivorDebug;
if(!D||!Core) throw new Error('Canonical progression requires Survivor core');
const $=s=>document.querySelector(s);
const campaign=$('#campaign'),quick=$('#startQuick');
if(!campaign) return;

const ROMAN=['','I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII','XIII','XIV','XV','XVI','XVII','XVIII','XIX','XX','XXI','XXII','XXIII','XXIV','XXV','XXVI','XXVII','XXVIII','XXIX','XXX','XXXI','XXXII','XXXIII'];
const degreeNames={
 1:'Peregrinus Ignis',2:'Neophyte',3:'Architectus',4:'Practicus',5:'Philosophus',6:'Dominus Liminis',7:'Adeptus Minor',8:'Clavis Potestatis',9:'Adeptus Exemptus',10:'Magister Templi',11:'Magus',
 12:'Lilith',13:'Gamaliel',14:'Samael',15:'A’arab Zaraq',16:'Thagirion',17:'Golachab',18:'Gha’agsheblah',19:'Satariel',20:'Ghagiel',21:'Thaumiel',22:'Adamas Ater',
 33:'Ipsissimus'
};
const ingressus=[
 ['o_olho','O Olho'],['a_chama','A Chama'],['a_fundacao','A Fundação'],['a_eleicao','A Eleição'],['a_balanca','A Balança'],['a_vontade','A Vontade'],['o_carater','O Caráter'],['a_disciplina','A Disciplina'],['a_clareza','A Clareza'],['a_transmutacao','A Transmutação'],['o_corpo','O Corpo'],['a_obra','A Obra'],['a_fortuna','A Fortuna'],['a_influencia','A Influência'],['o_legado','O Legado'],['actus_ingressus','ACTUS INGRESSUS']
].map((x,i)=>({id:x[0],name:x[1],index:i,kind:i===15?'rite':'stage'}));
const student=[
 ['xi1','XI·1 · O OLHO / PERCEPÇÃO I'],['xi2','XI·2 · O OLHO / PERCEPÇÃO II'],['xi3','XI·3 · O OLHO / PERCEPÇÃO III'],['period1','PROVA DE PASSAGEM · PERÍODO I'],
 ['xi4','XI·4 · A CHAMA / REGÊNCIA I'],['xi5','XI·5 · A CHAMA / REGÊNCIA II'],['xi6','XI·6 · A CHAMA / REGÊNCIA III'],['period2','PROVA DE PASSAGEM · PERÍODO II'],
 ['xi7','XI·7 · A OBRA I'],['xi8','XI·8 · A OBRA II'],['xi9','XI·9 · A OBRA III'],['period3','PROVA DE PASSAGEM · PERÍODO III'],
 ['regencia','GATE DE REGÊNCIA'],['dossie','Dossiê'],['exame','EXAME INDIVIDUAL']
].map((x,i)=>({id:x[0],name:x[1],index:i,kind:x[0].startsWith('period')||['regencia','exame'].includes(x[0])?'gate':'stage'}));
const peregrinusScrolls=['Autoeleição','Autorresponsabilidade','Verdadeira Vontade','Caráter','Disciplina','Clareza','Transmutação','Corpo e Energia','Obra','Fortuna','Influência','Legado','Forja do Pergaminho Pessoal'];
const fractal=['Caverna','Revelação','Ruptura','Limiar','Travessia','Provação','Reintegração','Encarnar','Obra','Passagem'];
const degrees=Array.from({length:33},(_,i)=>{
 const n=i+1,order=n<=11?'ARBOR VITAE':n<=22?'ARBOR MORTIS':'ARBOR DRACONIS';
 const name=degreeNames[n]||(n<33?'Título em construção':'Ipsissimus');
 const steps=n===1?peregrinusScrolls.map((name,j)=>({id:`g1_${j+1}`,name,index:j,kind:j===12?'gate':'scroll'})):fractal.map((name,j)=>({id:`g${n}_${j+1}`,name,index:j,kind:j===9?'gate':'stage'}));
 return {number:n,roman:ROMAN[n],name,order,provisional:n===22||(!degreeNames[n]&&n<33),steps};
});

window.HarunCanonicalProgression=Object.freeze({version:'4.2.1',preStudentName:'INGRESSUS',finalIngressusAct:'ACTUS INGRESSUS',studentIsDegree:false,firstDegree:'Peregrinus Ignis',lastDegree:'Ipsissimus',ingressus,student,degrees,ludic:true});

function path(meta){
 if(!meta.path||typeof meta.path!=='object') meta.path={phase:'ingressus',ingressusStage:0,studentStage:0,degree:1,degreeStage:0,completedDegrees:[]};
 if(!Array.isArray(meta.path.completedDegrees))meta.path.completedDegrees=[];
 return meta.path;
}
function persist(meta){try{localStorage.setItem(D.metaKey,JSON.stringify(meta))}catch(e){}}
function phaseTitle(p){if(p.phase==='ingressus')return 'INGRESSUS';if(p.phase==='student')return 'ESTUDANTE';if(p.phase==='degrees'){const g=degrees[p.degree-1];return `GRAU ${g.roman} · ${g.name}`}return 'APOTHEOSIS'}
function phaseCopy(p){if(p.phase==='ingressus')return 'Travessia anterior à condição de Estudante. O ACTUS INGRESSUS encerra esta fase.';if(p.phase==='student')return 'Etapa formativa de 99 dias. Estudante não é grau.';if(p.phase==='degrees'){const g=degrees[p.degree-1];return `${g.order} · Grau ${g.roman} de XXXIII · progressão narrativa do jogo`;}return 'Travessia dos XXXIII graus concluída no jogo.'}
function currentNodes(p){if(p.phase==='ingressus')return ingressus;if(p.phase==='student')return student;if(p.phase==='degrees')return degrees[p.degree-1].steps;return []}
function currentIndex(p){return p.phase==='ingressus'?p.ingressusStage:p.phase==='student'?p.studentStage:p.phase==='degrees'?p.degreeStage:0}
function actFor(p,idx){if(p.phase==='ingressus')return Math.min(5,1+Math.floor(idx/3.2));if(p.phase==='student')return 1+(Math.floor(idx/3)%5);if(p.phase==='degrees'){if(p.degree<=11)return 1+((p.degree+idx)%3);if(p.degree<=22)return 3+((p.degree+idx)%2);return 5;}return 1}
function timeline(p){
 const degreeChips=degrees.map(g=>{const done=p.completedDegrees.includes(g.number),on=p.phase==='degrees'&&p.degree===g.number,lock=p.phase!=='apotheosis'&&!done&&!on;return `<i class="prog-degree ${done?'done':''} ${on?'on':''} ${lock?'locked':''}" title="${g.name}">${g.roman}</i>`}).join('');
 return `<div class="prog-timeline"><span class="${p.phase==='ingressus'?'on':''}">INGRESSUS</span><span class="${p.phase==='student'?'on':''}">ESTUDANTE</span><div class="prog-degrees">${degreeChips}</div></div>`;
}
function render(){
 const st=Core.getState(),meta=st.meta||{},p=path(meta);persist(meta);
 if(st.state!=='menu')return;
 const nodes=currentNodes(p),idx=currentIndex(p);
 const header=`<section class="prog-header"><small>TRILHA INICIÁTICA · JOGO</small><h3>${phaseTitle(p)}</h3><p>${phaseCopy(p)}</p>${timeline(p)}</section>`;
 if(!nodes.length){campaign.innerHTML=header+`<div class="prog-finale"><b>XXXIII · IPSISSIMUS</b><p>Fim da progressão canônica desta campanha. O estado é narrativo e não concede grau institucional.</p></div>`;return;}
 campaign.innerHTML=header+`<div class="v4-stage-map prog-map">${nodes.map((n,i)=>{const done=i<idx,on=i===idx,locked=i>idx;const g=p.phase==='degrees'?degrees[p.degree-1]:null;const sub=p.phase==='ingressus'?'INGRESSUS':p.phase==='student'?'ESTUDANTE':`${g.order} · ${g.roman}`;return `<button class="v4-stage prog-stage ${done?'done':''} ${on?'current':''} ${locked?'locked':''} ${n.kind==='gate'||n.kind==='rite'?'boss':''}" data-v4-stage="${n.id}" data-prog-index="${i}" ${locked||done?'disabled':''}><strong>${String(i+1).padStart(2,'0')} · ${n.name}</strong><small>${sub}</small><span>${done?'CONCLUÍDO':on?'ENTRAR':'SELADO'}</span></button>`}).join('')}</div>`;
 campaign.querySelectorAll('[data-prog-index]:not([disabled])').forEach(b=>b.onclick=()=>beginNode(+b.dataset.progIndex));
}
function showStartChoice(context){
 const box=$('#v4Glory'),choices=$('#v4GloryChoices');
 if(!box||!choices){startNode(context,'glory_thunder');return}
 const opts=[['glory_thunder','Raio','ϟ'],['glory_poison','Veneno','☣'],['glory_meteor','Meteoro','☄']];
 choices.innerHTML=opts.map(o=>`<button class="v4-choice rare" data-prog-glory="${o[0]}"><b>${o[1]}</b><i>${o[2]}</i><p>Manifestação inicial para esta travessia.</p><small>GLÓRIA</small></button>`).join('');
 box.hidden=false;
 choices.querySelectorAll('[data-prog-glory]').forEach(b=>b.onclick=()=>{box.hidden=true;startNode(context,b.dataset.progGlory)});
}
function beginNode(index){
 const st=Core.getState(),meta=st.meta,p=path(meta),nodes=currentNodes(p);if(index!==currentIndex(p)||!nodes[index])return;
 const ctx={phase:p.phase,index,degree:p.degree||0,node:nodes[index],act:actFor(p,index)};
 showStartChoice(ctx);
}
if(quick)quick.onclick=()=>beginNode(currentIndex(path(Core.getState().meta)));
function startNode(context,glory){
 Core.startRun(context.act);
 setTimeout(()=>{const st=Core.getState(),r=st.run;if(!r)return;r.progressionContext=context;r.skills[glory]=Math.max(1,r.skills[glory]||0);r.waveDuration=7.2;r._progressionBossSeen=false;r._progressionComplete=false;const story=$('#story');if(story)story.textContent=`${phaseTitle(path(st.meta))} · ${context.node.name}`;},30);
}
function advance(meta,ctx){
 const p=path(meta);if(ctx.phase!==p.phase)return;
 if(p.phase==='ingressus'){
   p.ingressusStage++;
   if(p.ingressusStage>=ingressus.length){p.phase='student';p.studentStage=0;}
 }else if(p.phase==='student'){
   p.studentStage++;
   if(p.studentStage>=student.length){p.phase='degrees';p.degree=1;p.degreeStage=0;}
 }else if(p.phase==='degrees'){
   const g=degrees[p.degree-1];p.degreeStage++;
   if(p.degreeStage>=g.steps.length){if(!p.completedDegrees.includes(g.number))p.completedDegrees.push(g.number);if(g.number>=33){p.phase='apotheosis';p.degreeStage=0}else{p.degree=g.number+1;p.degreeStage=0}}
 }
 persist(meta);
}
let lastSig='';
function loop(){
 const st=Core.getState(),meta=st.meta||{},p=path(meta),r=st.run;
 if(st.state==='run'&&r&&r.progressionContext&&!r._progressionComplete){
   if(r.boss)r._progressionBossSeen=true;
   if(r._progressionBossSeen&&!r.boss&&r.wave%10===0){
     r._progressionComplete=true;advance(meta,r.progressionContext);
     const toast=$('#v4Toast');if(toast){toast.textContent=r.progressionContext.phase==='ingressus'&&r.progressionContext.node.id==='actus_ingressus'?'INGRESSUS CONCLUÍDO · CONDIÇÃO ESTUDANTE DESBLOQUEADA':'ETAPA CONCLUÍDA';toast.hidden=false;setTimeout(()=>toast.hidden=true,1700)}
     setTimeout(()=>Core.showMenu('campaign'),900);
   }
 }
 if(st.state==='menu'){
   const sig=JSON.stringify(p);if(sig!==lastSig||!campaign.querySelector('.prog-header')){lastSig=sig;render()}
 }
 requestAnimationFrame(loop);
}
requestAnimationFrame(loop);
})();