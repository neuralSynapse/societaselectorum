import fs from 'node:fs';

let html=fs.readFileSync('dist/index.html','utf8');

// 1) Entrada guiada única. Sem campo livre, sem segundo caminho.
const case0=/case 0:\{[\s\S]*?;break\}/;
if(!case0.test(html))throw new Error('V11.1: case 0 não localizado');
html=html.replace(case0,`case 0:{h=\`<div class="content center"><div class="eyebrow">Experiência oracular · Frater Hórus L93</div><h1>O que está impedindo o dinheiro de <span class="accent">entrar ou permanecer na sua vida?</span></h1><p class="lead center">A tiragem começa por esta questão central e vai afinando a leitura a partir das escolhas principais que você fizer ao longo do percurso.</p><div class="preview-cards"><div class="mini-card"></div><div class="mini-card"></div><div class="mini-card"></div></div><button class="btn btn-primary" onclick="startGuidedQuestion()">INICIAR MINHA TIRAGEM</button><div class="price-note">Tiragem inicial gratuita · o primeiro resultado e o diagnóstico aparecem antes de qualquer oferta</div></div>\`;break}`);

// 2) As microperguntas extras deixam de bloquear ou aparecer.
const oldNext="function next(){if(state.step===0&&!state.entryQuestion)return;const m=MICRO_PROMPTS[state.step];if(m&&!state.micro?.[state.step]){const el=document.getElementById('micro-'+state.step);if(el){el.classList.add('need-choice');el.scrollIntoView?.({behavior:'smooth',block:'center'})}return}if(state.step<STEPS.length-1){state.step++;save();render();window.scrollTo({top:0,behavior:'smooth'})}}";
const newNext="function next(){if(state.step===0&&!state.entryQuestion){startGuidedQuestion();return}if(state.step<STEPS.length-1){state.step++;save();render();window.scrollTo({top:0,behavior:'smooth'})}}";
if(!html.includes(oldNext))throw new Error('V11.1: next com microperguntas não localizado');
html=html.replace(oldNext,newNext);

// Remove a injeção automática das caixas pequenas antes dos CTAs.
html=html.replace(/const microBlock=microPromptHtml\(state\.step\);if\(microBlock\)\{[\s\S]*?\}app\.innerHTML=adaptStepHtml\(h,state\.step\);\}/,
  'app.innerHTML=adaptStepHtml(h,state.step);}'
);

// 3) Remove os pequenos ecos repetidos da pergunta. A personalização fica na copy principal.
const qthreadRe=/function qthread\([^)]*\)\{[^\n]*\}/;
if(!qthreadRe.test(html))throw new Error('V11.1: qthread não localizado');
html=html.replace(qthreadRe,"function qthread(){return''}");
html=html.replace("${qthread('Esta escolha afina uma parte da sua pergunta')}",'');
html=html.replace(/<div class="question-echo"><span>Sua pergunta<\/span><b>\$\{esc\(activeQuestion\(\)\)\}<\/b><\/div>/g,'');
html=html.replace(/<div class="question-echo light"><span>Pergunta que orienta esta leitura<\/span><b>\$\{esc\(activeQuestion\(\)\)\}<\/b><\/div>/g,'');

// 4) Dados finais não pedem a pergunta de novo.
html=html.replace(/<div class="field full"><label>Sua pergunta para a tiragem<\/label><textarea id="question"[\s\S]*?<\/textarea><\/div>/g,'');
html=html.replace(/function saveLead\(\)\{state\.lead=\{name:document\.getElementById\('name'\)\.value\.trim\(\),email:document\.getElementById\('email'\)\.value\.trim\(\),birth:document\.getElementById\('birth'\)\.value,time:document\.getElementById\('time'\)\.value,question:document\.getElementById\('question'\)\.value\.trim\(\)\};if\(!state\.lead\.name\|\|!state\.lead\.birth\|\|!state\.lead\.question\)\{alert\('Preencha nome, nascimento e a questão principal para continuar\.'\);return\}/,
  "function saveLead(){state.lead={name:document.getElementById('name').value.trim(),email:document.getElementById('email').value.trim(),birth:document.getElementById('birth').value,time:document.getElementById('time').value,question:activeQuestion()};if(!state.lead.name||!state.lead.birth){alert('Preencha nome e nascimento para continuar.');return}"
);

// 5) A personalização passa a vir das escolhas principais, não de texto digitado.
const qctxRe=/function qctx\(\)\{[\s\S]*?\}\nfunction qthread/;
const qctxNew=`function qctx(){
  const q=DEFAULT_ENTRY_QUESTION;
  const pain=state.answers?.pain||'',emotion=state.answers?.emotion||'',decision=state.answers?.decision||'',attempts=state.answers?.attempts||'',desired=state.answers?.desired||'';
  let theme='money';
  if(pain==='vanish'||desired==='stability')theme='retention';
  if(pain==='stuck'||desired==='expansion')theme='growth';
  if(pain==='choice'||decision==='delay'||emotion==='fear')theme='decision';
  if(attempts==='earn'&&pain==='stuck')theme='sales';
  if(attempts==='cut'&&pain==='vanish')theme='retention';
  const map={
    sales:['geração de receita, clientes e vendas','esforço comercial não se converter em previsibilidade','transformar geração em recorrência, margem e estrutura','Quando existe esforço para gerar receita, mas o resultado não ganha consistência, o ponto crítico pode estar entre tentativa e consolidação.'],
    retention:['dinheiro que entra, mas não permanece','o recurso desaparecer antes de virar reserva ou estrutura','preservar parte do que entra e transformar fluxo em base','Quando o dinheiro entra e some, o ponto crítico deixa de ser apenas geração e passa a ser o que acontece entre receber e consolidar.'],
    growth:['dinheiro que precisa ganhar crescimento e estrutura','esforço e recurso não se converterem em avanço sustentável','concentrar recursos, proteger base e criar expansão mensurável','Quando existe esforço, mas o crescimento não consolida, a questão passa a ser direção, continuidade e estrutura.'],
    decision:['decisões financeiras sob pressão, medo ou excesso de análise','o estado interno assumir o comando antes do critério','decidir com critério suficiente sem depender de certeza total','Quando o dinheiro ativa medo, urgência ou excesso de controle, a decisão pode custar antes mesmo de aparecer no saldo.'],
    money:['entrada, permanência e crescimento do dinheiro','o mesmo padrão financeiro continuar reaparecendo','transformar entrada em margem, margem em estrutura e estrutura em expansão','Quando o mesmo problema financeiro retorna, ele deixa de ser apenas um imprevisto e começa a revelar um padrão.']
  };
  const [subject,tension,build,article]=map[theme]||map.money;
  const axis=theme==='retention'?'permanência':theme==='growth'||theme==='sales'?'crescimento':theme==='decision'?'decisão sob pressão':'entrada e permanência';
  return{q,axis,theme,subject,tension,build,article,short:q};
}
function qthread`;
if(!qctxRe.test(html))throw new Error('V11.1: qctx não localizado');
html=html.replace(qctxRe,qctxNew);

// Mantém a pergunta central fixa como eixo de entrada.
html=html.replace("function activeQuestion(){return (state.entryQuestion||state.questionSuggested||state.questionRaw||DEFAULT_ENTRY_QUESTION).trim()}","function activeQuestion(){return DEFAULT_ENTRY_QUESTION}");

// Textos que ainda citavam o campo livre ou microescolhas.
html=html.replaceAll('problema que você escreveu','problema identificado nas suas escolhas');
html=html.replaceAll('pergunta que você fez','questão central da tiragem');
html=html.replaceAll('pergunta que iniciou esta leitura','questão central da tiragem');
html=html.replaceAll('Pergunta que organizou esta leitura','Questão central desta leitura');
html=html.replaceAll('microescolhas','escolhas principais');
html=html.replaceAll('Sua pergunta de abertura já está aqui. Você pode acrescentar um detalhe antes do processamento final.','A questão central já está definida. Agora os seus dados conectam a tiragem ao diagnóstico final.');
html=html.replaceAll('Agora conecte a pergunta à sua leitura.','Agora conecte seus dados à leitura.');

// Nova sessão para não herdar a experiência anterior.
html=html.replaceAll('H93_OF_001_V11_1_STATE','H93_OF_001_V11_2_STATE');
html=html.replaceAll("version:'11.1'","version:'11.2'");
html=html.replace('<title>Oráculo Financeiro de THOTH · V11.1</title>','<title>Oráculo Financeiro de THOTH · V11.2</title>');

fs.writeFileSync('dist/index.html',html);
fs.writeFileSync('dist/H93-OF-001-Oraculo-Financeiro-THOTH-V11-2.html',html);
console.log('V11.2 simplified UX applied',html.length);
