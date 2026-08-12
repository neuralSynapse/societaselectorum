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
const location={search:'?step=19',href:'https://www.sociedadedoseleitos.com/oraculo-financeiro-thoth.html?step=19',hostname:'www.sociedadedoseleitos.com'};
let submitted=null;
const WP={sapi(projectId){if(projectId!==25063)throw new Error('Projeto SAPI incorreto');return{async submitForm(payload){submitted=payload;return{ok:true}}}}};
const window={location,WP,scrollTo(){},open(){return null},__H93_FRATER_PHOTO:'data:image/webp;base64,TEST_PHOTO'};
const checkout={provider:'stripe',status:'awaiting_stripe_account_verification',offers:{},payment_links:{essential:{none:'',pdf:'',extra:'',pdf_extra:''},deep:{none:'',pdf:'',extra:'',pdf_extra:''},complete:{none:'',pdf:'',extra:'',pdf_extra:''},horusai:{none:''}},upsells:{magnet:{payment_link:''},numerology:{payment_link:''}}};
const sandbox={console,window,WP,document,location,URLSearchParams,Intl,Math,Date,JSON,Number,String,Object,Array,RegExp,Promise,Set,setTimeout,clearTimeout,alert(){throw new Error('Alert inesperado')},localStorage:{getItem:k=>storage.get(k)??null,setItem:(k,v)=>storage.set(k,v),removeItem:k=>storage.delete(k)},fetch:async()=>({ok:true,json:async()=>checkout,text:async()=>''})};
sandbox.globalThis=sandbox;
vm.createContext(sandbox);vm.runInContext(runtime,sandbox,{filename:'H93-final-runtime.js'});await new Promise(r=>setTimeout(r,60));

if(!nodes.app.innerHTML.includes('Dados da consulta'))throw new Error('Etapa de dados não renderizou em revisão');
if(!nodes.app.innerHTML.includes('leadConsent'))throw new Error('Consentimento não renderizou');

nodes.name.value='Pessoa de Teste';
nodes.email.value='teste@example.com';
nodes.birth.value='1990-01-01';
nodes.time.value='12:30';
nodes.leadConsent.checked=true;
await window.saveLead();
await new Promise(r=>setTimeout(r,20));

if(!submitted)throw new Error('SAPI não recebeu submissão');
if(submitted.form_name!=='oraculo_financeiro_thoth')throw new Error('Formulário SAPI incorreto');
for(const key of ['name','email','birth','question','axis','source'])if(!submitted.form_data?.[key])throw new Error(`Lead sem campo obrigatório: ${key}`);
if(submitted.form_data.email!=='teste@example.com')throw new Error('E-mail não chegou ao SAPI');
const state=JSON.parse(storage.get('H93_OF_001_V11_2_STATE')||'{}');
if(state.step!==20)throw new Error(`Lead não avançou ao processamento: step=${state.step}`);
if(nodes.leadSubmit.disabled!==true)throw new Error('Botão não foi protegido durante submissão');
console.log('Smoke final OK: consentimento + lead SAPI real do domínio oficial + avanço ao processamento validados.');
