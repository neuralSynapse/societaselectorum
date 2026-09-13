(function(){
'use strict';
const D=window.HarunSurvivorData,Core=window.HarunSurvivorDebug;
if(!D||!Core) throw new Error('Canonical progression requires Survivor core');
const $=s=>document.querySelector(s),campaign=$('#campaign'),quick=$('#startQuick');
if(!campaign) return;
const debugMode=new URLSearchParams(location.search).has('debug');
const ROMAN=['','I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII','XIII','XIV','XV','XVI','XVII','XVIII','XIX','XX','XXI','XXII','XXIII','XXIV','XXV','XXVI','XXVII','XXVIII','XXIX','XXX','XXXI','XXXII','XXXIII'];
const fractal=['Caverna','Revelação','Ruptura','Limiar','Travessia','Provação','Reintegração','Encarnar','Obra','Passagem'];

// Jornada Inicial vigente: porta anterior ao Estudante.
const ingressus=[
 {id:'documentacao_actus',name:'Documentação / ACTUS INGRESSUS',kind:'rite',desc:'Entrada formal na Jornada Inicial.'},
 {id:'unidade_1',name:'Unidade I · REGÊNCIA',kind:'stage',desc:'Primeiro eixo de autorregência.'},
 {id:'unidade_2',name:'Unidade II · REGÊNCIA + TRANSFERÊNCIA',kind:'stage',desc:'Regência aplicada a consequência observável.'},
 {id:'unidade_3',name:'Unidade III · ESTUDO + REGISTRO',kind:'stage',desc:'Estudo rastreável, registro e revisão.'},
 {id:'unidade_4',name:'Unidade IV · CONTEMPLAÇÃO + TRANSFERÊNCIA',kind:'stage',desc:'Contemplação que precisa atravessar a ação.'},
 {id:'unidade_5',name:'Unidade V · OBRA INICIAL',kind:'stage',desc:'Primeira materialização verificável.'},
 {id:'unidade_6',name:'Unidade VI · INTEGRAÇÃO',kind:'stage',desc:'Integração dos eixos da Jornada Inicial.'},
 {id:'conferencia',name:'Conferência',kind:'gate',desc:'Síntese e revisão da travessia.'},
 {id:'cartografia',name:'Cartografia',kind:'gate',desc:'Mapa de forças, limites e direção.'},
 {id:'plano_individual',name:'Plano Individual de 33 dias',kind:'gate',desc:'Fecho da Jornada Inicial e preparação para os 99 dias.'}
].map((x,i)=>({...x,index:i}));

// Estudante: etapa preparatória de 99 dias, nunca Grau.
const student=[
 ['xi1','XI·1 · O OLHO / PERCEPÇÃO I','Perceber antes de concluir.'],
 ['xi2','XI·2 · O OLHO / PERCEPÇÃO II','Atenção, linguagem e teste de realidade.'],
 ['xi3','XI·3 · O OLHO / PERCEPÇÃO III','Metapercepção e discriminação.'],
 ['period1','PROVA DE PASSAGEM · PERÍODO I','Transferência da percepção para uma convicção real.'],
 ['xi4','XI·4 · A CHAMA / REGÊNCIA I','Escolher o centro que governa.'],
 ['xi5','XI·5 · A CHAMA / REGÊNCIA II','Interromper automatismos e assumir autoria.'],
 ['xi6','XI·6 · A CHAMA / REGÊNCIA III','Regência, decisão e consequência.'],
 ['period2','PROVA DE PASSAGEM · PERÍODO II','Transformar padrão automático em ação deliberada.'],
 ['xi7','XI·7 · A OBRA I','Fazer a consciência tocar o mundo.'],
 ['xi8','XI·8 · A OBRA II','Continuidade, execução e revisão.'],
 ['xi9','XI·9 · A OBRA III','Transferência e integração da Obra inicial.'],
 ['period3','PROVA DE PASSAGEM · PERÍODO III','Concluir Obra inicial pequena, verificável e explicável.'],
 ['regencia','GATE DE REGÊNCIA','Autoria, ética e integridade são gates não compensáveis.'],
 ['dossie','Dossiê','Consolidar evidências da etapa formativa.'],
 ['exame','EXAME INDIVIDUAL','Passagem por competência para Peregrinus Ignis ou remediação.']
].map((x,i)=>({id:x[0],name:x[1],desc:x[2],index:i,kind:x[0].startsWith('period')||['regencia','dossie','exame'].includes(x[0])?'gate':'stage'}));

const peregrinus=[
 ['Autoeleição','Romper identidade puramente recebida e assumir autoria.'],
 ['Autorresponsabilidade','Converter desculpa em capacidade de resposta sem negar contexto.'],
 ['Verdadeira Vontade','Distinguir impulso, desejo, pressão externa e direção estável.'],
 ['Caráter','Reduzir a distância entre valor declarado e conduta repetida.'],
 ['Disciplina','Tornar a ação menos dependente do estado momentâneo.'],
 ['Clareza','Refinar discriminação, linguagem, metapercepção e revisão de modelos.'],
 ['Transmutação','Converter conflito, sombra e fricção em recurso de integração e ação.'],
 ['Corpo e Energia','Interocepção, presença, regulação e linguagem energética responsável.'],
 ['Obra','Converter Vontade em construção concreta e sustentável.'],
 ['Fortuna','Trabalhar oportunidade, preparação, probabilidade e recursos.'],
 ['Influência','Linguagem, presença, reciprocidade, persuasão e limite ético.'],
 ['Legado','Investigar o que permanece no mundo, nos outros e nas instituições.'],
 ['Forja do Pergaminho Pessoal','Síntese autoral testável, revisável e situada.']
].map((x,i)=>({id:`g1_${i+1}`,name:x[0],desc:x[1],index:i,kind:i===12?'gate':'scroll'}));

const profiles={
 1:['Peregrinus Ignis','Entrada, compromisso, continuidade, estudo geral e registro cuidadoso.','Fogo inicial e registro de prova'],
 2:['Neophyte','Visão simbólica, imaginação, percepção e discernimento.','Oculus Hori'],
 3:['Architectus','Fundamentos corporais, respiração, disciplina, precisão e estabilidade.','Architectus Fundamentorum'],
 4:['Practicus','Cabala, correspondências, intelecto, pesquisa e divinação.','Draconis · operação reservada'],
 5:['Philosophus','Formação moral, desejo, devoção, valores e vontade.','Sol Internus'],
 6:['Dominus Liminis','Síntese, concentração, domínio da atenção e permanência no limiar.','Lamina Voluntatis'],
 7:['Adeptus Minor','Direção central, Daimon Interior e Verdadeira Vontade.','Ritual do Daimon Interior'],
 8:['Clavis Potestatis','Magia prática, poder aplicado, Obra, sistemas e governança.','Chave do poder aplicado'],
 9:['Adeptus Exemptus','Autossuficiência, tese, método e transmissão.','Horus Invictus · máscara'],
 10:['Magister Templi','Compreensão, dissolução, silêncio e transmissão responsável.','Aurora Lux Ferre'],
 11:['Magus','Palavra, Lei, corpus autoral, responsabilidade e legado.','Vigil Liminis · transição'],
 12:['Lilith','Entrada no desconhecido com aterramento, vontade e limites.','Porta Ignoti'],
 13:['Gamaliel','Sonhos, imaginação, inconsciente e campo lunar.','Somnia Noctis'],
 14:['Samael','Pensamento independente, ruptura de certezas e discernimento.','Sapientia Sinistra'],
 15:['A’arab Zaraq','Desejo, beleza, erotismo consciente, coragem e continuidade criativa.','Bellator Veneris'],
 16:['Thagirion','Integração das polaridades e formação do centro solar sombrio.','Sol Niger'],
 17:['Golachab','Ruptura, sofrimento, impulsos destrutivos e transmutação responsável.','Transmutatio Ignea'],
 18:['Gha’agsheblah','Consolidação do trabalho e preparação para o Abismo.','Vigilia Abyssi'],
 19:['Satariel','Visão draconiana, leitura de padrões e percepção estratégica.','Apertio Draconis'],
 20:['Ghagiel','Lucidez convertida em direção luciferiana materializada.','Stella Luciferi'],
 21:['Thaumiel','Soberania, criação, poder, autoridade e consequência.','Promissum Serpentis'],
 22:['Adamas Ater','Fechamento provisório da Segunda Ordem e preparação da nova criação.','Creatio Nova · provisório'],
 33:['Ipsissimus','Ápice nominal do sistema; conteúdo interno reservado.','Apotheosis cumulativa']
};

function makeFractal(n,theme){return fractal.map((name,i)=>({id:`g${n}_${i+1}`,name,desc:`${name} aplicada ao eixo deste Grau: ${theme}`,index:i,kind:i===9?'gate':'stage'}));}
const degrees=Array.from({length:33},(_,i)=>{
 const n=i+1,order=n<=11?'ARBOR VITAE':n<=22?'ARBOR MORTIS':'ARBOR DRACONIS',reserved=n>=23&&n<=32;
 const p=profiles[n];
 const name=reserved?`Grau ${ROMAN[n]} · reservado`:(p?p[0]:`Grau ${ROMAN[n]}`);
 const theme=reserved?'Conteúdo interno reservado. A versão pública preserva apenas a travessia lúdica da Arbor Draconis.':(p?p[1]:'Conteúdo em construção controlada.');
 const operation=reserved?'Operação interna não divulgada.':(p?p[2]:'Operação em construção.');
 return {number:n,roman:ROMAN[n],name,order,theme,operation,public:!reserved,provisional:n===22,steps:n===1?peregrinus:makeFractal(n,theme)};
});

window.HarunCanonicalProgression=Object.freeze({
 version:'4.3.0',pathVersion:2,preStudentName:'INGRESSUS',initialIngressusAct:'ACTUS INGRESSUS',
 ingressusResult:'pronto_99d',studentIsDegree:false,studentMinimumDays:99,studentCycles:9,
 firstDegree:'Peregrinus Ignis',lastDegree:'Ipsissimus',publicThirdOrderReserved:true,
 ingressus,student,degrees,ludic:true,institutionalWrite:false
});

function migratePath(meta){
 let p=meta.path;
 if(!p||typeof p!=='object')p=meta.path={phase:'ingressus',ingressusStage:0,studentStage:0,degree:1,degreeStage:0,completedDegrees:[]};
 if(!Array.isArray(p.completedDegrees))p.completedDegrees=[];
 if(meta.pathVersion!==2){
   if(p.phase==='ingressus'&&Number.isFinite(p.ingressusStage)&&p.ingressusStage>0)p.ingressusStage=Math.min(9,Math.floor(p.ingressusStage*10/16));
   p.ingressusStage=Math.max(0,Math.min(10,p.ingressusStage||0));p.studentStage=Math.max(0,Math.min(15,p.studentStage||0));
   p.degree=Math.max(1,Math.min(33,p.degree||1));p.degreeStage=Math.max(0,p.degreeStage||0);meta.pathVersion=2;
 }
 return p;
}
function persist(meta){try{localStorage.setItem(D.metaKey,JSON.stringify(meta))}catch(e){}}
function phaseTitle(p){
 if(p.phase==='ingressus')return 'JORNADA INICIAL · INGRESSUS';
 if(p.phase==='student')return 'ESTUDANTE · 99 DIAS';
 if(p.phase==='degrees'){const g=degrees[p.degree-1];return g.public?`GRAU ${g.roman} · ${g.name}`:`GRAU ${g.roman} · ARBOR DRACONIS`;}
 return 'APOTHEOSIS';
}
function phaseCopy(p){
 if(p.phase==='ingressus')return 'Documentação e ACTUS INGRESSUS abrem a Jornada Inicial; seis unidades, Conferência, Cartografia e Plano Individual conduzem ao pronto_99d.';
 if(p.phase==='student')return 'Etapa preparatória de 99 dias: 3 Períodos de 33, XI·1–XI·9, provas, Gate de Regência, Dossiê e Exame Individual. Estudante não é Grau.';
 if(p.phase==='degrees'){const g=degrees[p.degree-1];return g.public?`${g.order} · ${g.theme} · Operação: ${g.operation}`:`${g.order} · conteúdo institucional reservado. O jogo preserva apenas a estrutura lúdica da travessia.`;}
 return 'XXXIII Graus atravessados no jogo. Apotheosis permanece processo cumulativo, não um “fim metafísico”.';
}
function currentNodes(p){if(p.phase==='ingressus')return ingressus;if(p.phase==='student')return student;if(p.phase==='degrees')return degrees[p.degree-1].steps;return []}
function currentIndex(p){return p.phase==='ingressus'?p.ingressusStage:p.phase==='student'?p.studentStage:p.phase==='degrees'?p.degreeStage:0}
function actFor(p,idx){if(p.phase==='ingressus')return 1+Math.min(4,Math.floor(idx/2));if(p.phase==='student')return 1+(Math.floor(idx/3)%5);if(p.phase==='degrees'){if(p.degree<=11)return 1+((p.degree+idx)%3);if(p.degree<=22)return 3+((p.degree+idx)%3);return 5;}return 1}
function degreeTooltip(g){return g.public?`${g.roman} · ${g.name}`:`${g.roman} · reservado`;}
function timeline(p){
 const degreeChips=degrees.map(g=>{const done=p.completedDegrees.includes(g.number),on=p.phase==='degrees'&&p.degree===g.number,lock=p.phase!=='apotheosis'&&!done&&!on;return `<i class="prog-degree ${done?'done':''} ${on?'on':''} ${lock?'locked':''}" title="${degreeTooltip(g)}">${g.roman}</i>`}).join('');
 return `<div class="prog-timeline"><span class="${p.phase==='ingressus'?'on':''}">INGRESSUS</span><span class="${p.phase==='student'?'on':''}">ESTUDANTE</span><div class="prog-degrees">${degreeChips}</div></div>`;
}
function render(){
 const st=Core.getState(),meta=st.meta||{},p=migratePath(meta);persist(meta);if(st.state!=='menu')return;
 const nodes=currentNodes(p),idx=currentIndex(p),degree=p.phase==='degrees'?degrees[p.degree-1]:null;
 const reserved=degree&&!degree.public;
 const header=`<section class="prog-header ${reserved?'reserved':''}"><small>TRILHA INICIÁTICA · JOGO</small><h3>${phaseTitle(p)}</h3><p>${phaseCopy(p)}</p>${timeline(p)}</section>`;
 if(!nodes.length){campaign.innerHTML=header+`<div class="prog-finale"><b>XXXIII · IPSISSIMUS</b><p>Fim da progressão desta campanha. A conquista é lúdica e não concede Grau institucional.</p></div>`;return;}
 campaign.innerHTML=header+`<div class="v4-stage-map prog-map">${nodes.map((n,i)=>{const done=i<idx,on=i===idx,locked=i>idx;const sub=p.phase==='ingressus'?'INGRESSUS':p.phase==='student'?'ESTUDANTE':`${degree.order} · ${degree.roman}`;return `<button class="v4-stage prog-stage ${done?'done':''} ${on?'current':''} ${locked?'locked':''} ${(n.kind==='gate'||n.kind==='rite')?'boss':''}" data-prog-index="${i}" ${locked||done?'disabled':''}><strong>${String(i+1).padStart(2,'0')} · ${n.name}</strong><small>${sub}</small><p>${n.desc||''}</p><span>${done?'CONCLUÍDO':on?'ENTRAR':'SELADO'}</span></button>`}).join('')}</div>`;
 campaign.querySelectorAll('[data-prog-index]:not([disabled])').forEach(b=>b.onclick=()=>beginNode(+b.dataset.progIndex));
}
function showStartChoice(context){
 const box=$('#v4Glory'),choices=$('#v4GloryChoices');if(!box||!choices){startNode(context,'glory_thunder');return}
 const opts=[['glory_thunder','Raio','ϟ'],['glory_poison','Veneno','☣'],['glory_meteor','Meteoro','☄']];
 choices.innerHTML=opts.map(o=>`<button class="v4-choice rare" data-prog-glory="${o[0]}"><b>${o[1]}</b><i>${o[2]}</i><p>Manifestação inicial desta travessia.</p><small>GLÓRIA</small></button>`).join('');box.hidden=false;
 choices.querySelectorAll('[data-prog-glory]').forEach(b=>b.onclick=()=>{box.hidden=true;startNode(context,b.dataset.progGlory)});
}
function beginNode(index){const st=Core.getState(),meta=st.meta,p=migratePath(meta),nodes=currentNodes(p);if(index!==currentIndex(p)||!nodes[index])return;showStartChoice({phase:p.phase,index,degree:p.degree||0,node:nodes[index],act:actFor(p,index)});}
if(quick)quick.onclick=()=>beginNode(currentIndex(migratePath(Core.getState().meta)));
function startNode(context,glory){
 Core.startRun(context.act);setTimeout(()=>{const st=Core.getState(),r=st.run;if(!r)return;r.progressionContext=context;r.skills[glory]=Math.max(1,r.skills[glory]||0);r.waveDuration=7.2;r._progressionBossSeen=false;r._progressionComplete=false;r._progressionCompleteAt=0;const story=$('#story');if(story)story.textContent=`${phaseTitle(migratePath(st.meta))} · ${context.node.name}`;},30);
}
function advance(meta,ctx){
 const p=migratePath(meta);if(ctx.phase!==p.phase)return;
 if(p.phase==='ingressus'){p.ingressusStage++;if(p.ingressusStage>=ingressus.length){p.phase='student';p.ingressusStage=ingressus.length;p.studentStage=0;}}
 else if(p.phase==='student'){p.studentStage++;if(p.studentStage>=student.length){p.phase='degrees';p.studentStage=student.length;p.degree=1;p.degreeStage=0;}}
 else if(p.phase==='degrees'){const g=degrees[p.degree-1];p.degreeStage++;if(p.degreeStage>=g.steps.length){if(!p.completedDegrees.includes(g.number))p.completedDegrees.push(g.number);if(g.number>=33){p.phase='apotheosis';p.degreeStage=0}else{p.degree=g.number+1;p.degreeStage=0}}}
 persist(meta);
}
function qaSetPath(next){if(!debugMode)return;const meta=Core.getState().meta;meta.path=Object.assign({phase:'ingressus',ingressusStage:0,studentStage:0,degree:1,degreeStage:0,completedDegrees:[]},next||{});meta.pathVersion=2;persist(meta);Core.showMenu('campaign');lastSig='';}
function qaAdvance(){if(!debugMode)return;const meta=Core.getState().meta,p=migratePath(meta),nodes=currentNodes(p),idx=currentIndex(p);if(nodes[idx])advance(meta,{phase:p.phase,degree:p.degree,node:nodes[idx]});Core.showMenu('campaign');lastSig='';}
window.HarunProgressionDebug=Object.freeze({snapshot:()=>{const st=Core.getState(),p=migratePath(st.meta);return JSON.parse(JSON.stringify({path:p,phaseTitle:phaseTitle(p),nodes:currentNodes(p),degrees}));},setPath:qaSetPath,advanceCurrentForQA:qaAdvance});

let lastSig='';
function loop(){
 const st=Core.getState(),meta=st.meta||{},p=migratePath(meta),r=st.run;
 if(st.state==='run'&&r&&r.progressionContext&&!r._progressionComplete){
   if(r.boss)r._progressionBossSeen=true;
   if(r._progressionBossSeen&&!r.boss){
     if(!r._progressionCompleteAt)r._progressionCompleteAt=performance.now()+240;
     if(performance.now()>=r._progressionCompleteAt){r._progressionComplete=true;advance(meta,r.progressionContext);const toast=$('#v4Toast');if(toast){const c=r.progressionContext;toast.textContent=c.phase==='ingressus'&&c.node.id==='plano_individual'?'JORNADA INICIAL CONCLUÍDA · ESTUDANTE DESBLOQUEADO':c.phase==='student'&&c.node.id==='exame'?'ESTUDANTE CONCLUÍDO · PEREGRINUS IGNIS DESBLOQUEADO':'ETAPA CONCLUÍDA';toast.hidden=false;setTimeout(()=>toast.hidden=true,1700)}setTimeout(()=>Core.showMenu('campaign'),650);}
   }
 }
 if(st.state==='menu'){const sig=JSON.stringify(p);if(sig!==lastSig||!campaign.querySelector('.prog-header')){lastSig=sig;render()}}
 requestAnimationFrame(loop);
}
requestAnimationFrame(loop);
})();