import fs from 'node:fs';
import vm from 'node:vm';

const html=fs.readFileSync('dist/index.html','utf8');
const scripts=[...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)].map(x=>x[1]).filter(Boolean);
const runtime=scripts.find(x=>x.includes("H93_OF_001_V11_2_STATE"));
if(!runtime)throw new Error('Runtime final ausente');

const mkNode=()=>({value:'',checked:false,innerHTML:'',textContent:'',style:{},disabled:false,className:'',classList:{add(){},remove(){},toggle(){}},querySelectorAll(){return[]},scrollIntoView(){},focus(){}});
const nodes={app:mkNode(),progress:mkNode(),phase:mkNode(),review:mkNode(),stepSelect:mkNode(),jumpBtn:mkNode(),resetBtn:mkNode()};
const document={getElementById(id){return nodes[id]||(nodes[id]=mkNode())},querySelectorAll(){return[]},open(){},write(){},close(){}};
const storage=new Map();
const location={search:'?step=19',href:'https://neuralsynapse.github.io/societaselectorum/oraculo.html?step=19',hostname:'neuralsynapse.github.io'};
const listeners=new Map();
let posted=null;
const parent={postMessage(message){posted=message;setTimeout(()=>{const fn=listeners.get('message');fn?.({data:{type:'H93_LEAD_RESULT',requestId:message.requestId,ok:true,message:'Dados registrados.'},origin:'https://www.sociedadedoseleitos.com',source:parent})},5)}};
const window={location,parent,scrollTo(){},open(){return null},__H93_FRATER_PHOTO:'data:image/webp;base64,TEST_PHOTO',addEventListener(type,fn){listeners.set(type,fn)},removeEventListener(type,fn){if(listeners.get(type)===fn)listeners.delete(type)}};
const checkout={provider:'stripe',status:'awaiting_stripe_account_verification',offers:{},payment_links:{essential:{none:'',pdf:'',extra:'',pdf_extra:''},deep:{none:'',pdf:'',extra:'',pdf_extra:''},complete:{none:'',pdf:'',extra:'',pdf_extra:''},horusai:{none:''}},upsells:{magnet:{payment_link:''},numerology:{payment_link:''}}};
const sandbox={console,window,document,location,URLSearchParams,Intl,Math,Date,JSON,Number,String,Object,Array,RegExp,Promise,Set,setTimeout,clearTimeout,alert(){throw new Error('Alert inesperado')},localStorage:{getItem:k=>storage.get(k)??null,setItem:(k,v)=>storage.set(k,v),removeItem:k=>storage.delete(k)},fetch:async()=>({ok:true,json:async()=>checkout,text:async()=>''})};
sandbox.globalThis=sandbox;
vm.createContext(sandbox);vm.runInContext(runtime,sandbox,{filename:'H93-iframe-runtime.js'});await new Promise(r=>setTimeout(r,60));

for(const [id,value] of [['name','Pessoa Ponte'],['email','ponte@example.com'],['birth','1991-02-03'],['time','10:10']])document.getElementById(id).value=value;
document.getElementById('leadConsent').checked=true;
await window.saveLead();
await new Promise(r=>setTimeout(r,30));
if(!posted)throw new Error('Iframe não enviou H93_LEAD_SUBMIT ao parent');
if(posted.type!=='H93_LEAD_SUBMIT'||posted.form_name!=='oraculo_financeiro_thoth')throw new Error('Mensagem de ponte incorreta');
if(posted.form_data?.email!=='ponte@example.com')throw new Error('Payload da ponte perdeu e-mail');
const state=JSON.parse(storage.get('H93_OF_001_V11_2_STATE')||'{}');
if(state.step!==20)throw new Error(`Resposta positiva da ponte não avançou: step=${state.step}`);
if(document.getElementById('leadStatus').className!=='lead-status ok')throw new Error('Sucesso da ponte não foi refletido no status');
if(listeners.has('message'))throw new Error('Listener da ponte não foi removido após resposta');
console.log('Smoke iframe OK: GitHub iframe -> postMessage -> domínio oficial -> retorno -> processamento validado.');
