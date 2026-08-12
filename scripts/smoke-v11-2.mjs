import fs from 'node:fs';
import vm from 'node:vm';

const html=fs.readFileSync('dist/index.html','utf8');
const scripts=[...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)].map(x=>x[1]);
const runtime=scripts.find(x=>x.includes("const STATE_KEY='H93_OF_001_V11_2_STATE'"));
if(!runtime)throw new Error('Runtime V11.2 ausente');

const mkNode=()=>({value:'',innerHTML:'',textContent:'',style:{},disabled:false,classList:{add(){},remove(){},toggle(){}},querySelectorAll(){return[]},scrollIntoView(){},focus(){}});
const nodes={app:mkNode(),progress:mkNode(),phase:mkNode(),review:mkNode(),stepSelect:mkNode(),jumpBtn:mkNode(),resetBtn:mkNode()};
let cardNodes=[];
const document={getElementById(id){return nodes[id]||(nodes[id]=mkNode())},querySelectorAll(sel){return sel==='.flip-card'?cardNodes:[]},open(){},write(){},close(){}};
const storage=new Map();
const location={search:'',href:'https://example.test/oraculo-v11-2.html'};
const window={location,scrollTo(){},open(){return null},__H93_FRATER_PHOTO:'data:image/webp;base64,TEST_PHOTO'};
const checkout={provider:'stripe',status:'awaiting_stripe_account_verification',offers:{},payment_links:{essential:{none:'',pdf:'',extra:'',pdf_extra:''},deep:{none:'',pdf:'',extra:'',pdf_extra:''},complete:{none:'',pdf:'',extra:'',pdf_extra:''},horusai:{none:''}},upsells:{magnet:{payment_link:''},numerology:{payment_link:''}}};
const sandbox={console,window,document,location,URLSearchParams,Intl,Math,Date,JSON,Number,String,Object,Array,RegExp,Promise,Set,setTimeout,clearTimeout,alert(){throw new Error('Alert inesperado')},localStorage:{getItem:k=>storage.get(k)??null,setItem:(k,v)=>storage.set(k,v),removeItem:k=>storage.delete(k)},fetch:async()=>({ok:true,json:async()=>checkout,text:async()=>''})};
sandbox.globalThis=sandbox;vm.createContext(sandbox);vm.runInContext(runtime,sandbox,{filename:'H93-V11.2-runtime.js'});await new Promise(r=>setTimeout(r,40));
const state=()=>JSON.parse(storage.get('H93_OF_001_V11_2_STATE')||'{}');

if(!nodes.app.innerHTML.includes('entrar ou permanecer na sua vida'))throw new Error('Abertura não renderizou');
if(!nodes.app.innerHTML.includes('INICIAR MINHA TIRAGEM'))throw new Error('CTA único da abertura ausente');
if(nodes.app.innerHTML.includes('QUESTÃO ESPECÍFICA')||nodes.app.innerHTML.includes('entryQuestion'))throw new Error('Campo/caminho de pergunta livre ainda aparece');
if(nodes.app.innerHTML.includes('micro-game')||nodes.app.innerHTML.includes('question-echo'))throw new Error('Perguntinhas secundárias aparecem na abertura');

window.startGuidedQuestion();
if(state().step!==1)throw new Error('CTA inicial não iniciou o percurso');
if(nodes.app.innerHTML.includes('micro-game')||nodes.app.innerHTML.includes('question-echo'))throw new Error('Perguntinhas secundárias aparecem no Advertorial I');
window.next();
if(state().step!==2)throw new Error('Advertorial I ainda exige micropergunta para avançar');

window.answer('pain','vanish');
if(state().step!==3)throw new Error('Pergunta principal de dor não avançou normalmente');
window.answer('emotion','frustration');
window.answer('duration','months');
window.jump(13);
if(nodes.app.innerHTML.includes('micro-game')||nodes.app.innerHTML.includes('question-echo'))throw new Error('Perguntinhas secundárias reapareceram no percurso');

window.beginCardSelection();
const ids=[...nodes.app.innerHTML.matchAll(/chooseCard\('([^']+)',(\d)\)/g)].map(x=>x[1]);
if(ids.length!==3||new Set(ids).size!==3)throw new Error('Tiragem de três cartas inválida');
cardNodes=Array.from({length:3},()=>({disabled:false,classList:{add(){}}}));
window.chooseCard(ids[0],0);await new Promise(r=>setTimeout(r,1050));
if(state().step!==8||!nodes.app.innerHTML.includes('tarot-thoth-full/'))throw new Error('Carta THOTH não revelou corretamente');
if(nodes.app.innerHTML.includes('question-echo'))throw new Error('Eco pequeno da pergunta reapareceu na carta');

window.jump(19);
if(nodes.app.innerHTML.includes('Sua pergunta para a tiragem')||nodes.app.innerHTML.includes('id="question"'))throw new Error('Tela de dados ainda pede pergunta digitada');

window.jump(25);
for(const variant of ['none','pdf','extra','pdf_extra'])if(!nodes.app.innerHTML.includes(`quickCheckout('essential','${variant}')`))throw new Error(`Variação comercial ausente: ${variant}`);

console.log(`Smoke V11.2 OK: entrada guiada única, sem pergunta livre, sem microperguntas, fluxo principal, carta THOTH e ofertas preservados. Carta testada: ${ids[0]}.`);
