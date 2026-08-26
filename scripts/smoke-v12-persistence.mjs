import fs from 'node:fs';
import vm from 'node:vm';

const html=fs.readFileSync('dist/index.html','utf8');
const scripts=[...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)].map(x=>x[1]);
const runtime=scripts.find(x=>x.includes("const STATE_KEY='H93_OF_001_V11_2_STATE'"));
const persistence=scripts.find(x=>x.includes('H93_OF_001_V12_PROGRESS_RUNTIME'));
if(!runtime)throw new Error('Persistência: runtime base V11.2 ausente');
if(!persistence)throw new Error('Persistência: reforço V12 ausente');
for(const marker of ['__h93Drafts','pagehide','visibilitychange','MutationObserver','v12CheckoutPending=false','v12CheckoutRequestId=\'\''])if(!persistence.includes(marker))throw new Error('Persistência: marcador ausente '+marker);

const storage=new Map();
const checkout={provider:'stripe',status:'ready',offers:{},payment_links:{essential:{none:'',pdf:'',extra:'',pdf_extra:''},deep:{none:'',pdf:'',extra:'',pdf_extra:''},complete:{none:'',pdf:'',extra:'',pdf_extra:''},horusai:{none:''}},upsells:{magnet:{payment_link:''},numerology:{payment_link:''}}};
function boot(){
  const mkNode=()=>({value:'',innerHTML:'',textContent:'',style:{},disabled:false,checked:false,classList:{add(){},remove(){},toggle(){}},querySelectorAll(){return[]},querySelector(){return null},addEventListener(){},removeEventListener(){},scrollIntoView(){},focus(){}});
  const nodes={app:mkNode(),progress:mkNode(),phase:mkNode(),review:mkNode(),stepSelect:mkNode(),jumpBtn:mkNode(),resetBtn:mkNode()};
  const document={getElementById(id){return nodes[id]||(nodes[id]=mkNode())},querySelectorAll(){return[]},querySelector(){return null},addEventListener(){},removeEventListener(){},open(){},write(){},close(){},visibilityState:'visible'};
  const location={search:'',href:'https://example.test/oraculo.html'};
  const window={location,scrollY:0,scrollTo(){},open(){return null},addEventListener(){},removeEventListener(){},__H93_FRATER_PHOTO:'data:image/webp;base64,TEST_PHOTO'};
  const sandbox={console,window,document,location,URLSearchParams,Intl,Math,Date,JSON,Number,String,Object,Array,RegExp,Promise,Set,setTimeout,clearTimeout,setInterval,clearInterval,requestAnimationFrame:fn=>fn(),MutationObserver:class{observe(){} disconnect(){}},alert(){throw new Error('Alert inesperado')},localStorage:{getItem:k=>storage.get(k)??null,setItem:(k,v)=>storage.set(k,v),removeItem:k=>storage.delete(k)},fetch:async()=>({ok:true,json:async()=>checkout,text:async()=>''})};
  sandbox.globalThis=sandbox;vm.createContext(sandbox);vm.runInContext(runtime,sandbox,{filename:'H93-base-runtime.js'});return{sandbox,window,nodes};
}

const first=boot();await new Promise(r=>setTimeout(r,40));
first.window.startGuidedQuestion();
first.window.next();
first.window.answer('pain','vanish');
first.window.answer('emotion','frustration');
let saved=JSON.parse(storage.get('H93_OF_001_V11_2_STATE')||'{}');
if(saved.step!==4||saved.answers?.pain!=='vanish'||saved.answers?.emotion!=='frustration')throw new Error('Persistência: estado não foi salvo antes do reload');
saved.v12CheckoutPending=true;saved.v12CheckoutRequestId='transient';storage.set('H93_OF_001_V11_2_STATE',JSON.stringify(saved));

const second=boot();await new Promise(r=>setTimeout(r,40));
vm.runInContext(persistence,second.sandbox,{filename:'H93-persistence-runtime.js'});await new Promise(r=>setTimeout(r,40));
const restored=JSON.parse(storage.get('H93_OF_001_V11_2_STATE')||'{}');
if(restored.step!==4)throw new Error('Persistência: reload não preservou a etapa');
if(restored.answers?.pain!=='vanish'||restored.answers?.emotion!=='frustration')throw new Error('Persistência: reload perdeu respostas');
if(restored.v12CheckoutPending!==false||restored.v12CheckoutRequestId!=='')throw new Error('Persistência: estado transitório de checkout ficou travado após reload');

console.log('Smoke V12 persistence OK: etapa e respostas sobrevivem ao reload; checkout transitório é destravado; drafts possuem runtime dedicado.');
