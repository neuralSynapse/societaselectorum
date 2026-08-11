import fs from 'node:fs';
import vm from 'node:vm';

const html=fs.readFileSync('dist/index.html','utf8');
const match=html.match(/<script>([\s\S]*?)<\/script>/i);
if(!match)throw new Error('Runtime inline da V10.1 não encontrado');

const mkNode=()=>({value:'',innerHTML:'',textContent:'',style:{},disabled:false,classList:{add(){},remove(){},toggle(){}},querySelectorAll(){return[]},scrollIntoView(){}});
const nodes={app:mkNode(),progress:mkNode(),phase:mkNode(),review:mkNode(),stepSelect:mkNode(),jumpBtn:mkNode(),resetBtn:mkNode()};
let cardNodes=[];
const document={
  getElementById(id){return nodes[id]||(nodes[id]=mkNode())},
  querySelectorAll(sel){return sel==='.flip-card'?cardNodes:[]},
  open(){},write(){},close(){}
};
const storage=new Map();
const location={search:'',href:'https://example.test/oraculo-v10.html'};
const window={location,scrollTo(){},open(){return null},__H93_FRATER_PHOTO:'data:image/webp;base64,TEST_PHOTO'};
const sandbox={console,window,document,location,URLSearchParams,Intl,Math,Date,JSON,Number,String,Object,Array,RegExp,Promise,Set,setTimeout,clearTimeout,alert(){throw new Error('Alert inesperado')},localStorage:{getItem:k=>storage.get(k)??null,setItem:(k,v)=>storage.set(k,v),removeItem:k=>storage.delete(k)},fetch:async()=>({ok:true,json:async()=>({provider:'stripe',status:'awaiting_account_verification',offers:{},payment_links:{essential:{none:'',pdf:'',extra:'',pdf_extra:''},deep:{none:'',pdf:'',extra:'',pdf_extra:''},complete:{none:'',pdf:'',extra:'',pdf_extra:''},horusai:{none:''}}}),text:async()=>''})};
sandbox.globalThis=sandbox;
vm.createContext(sandbox);
vm.runInContext(match[1],sandbox,{filename:'H93-V10.1-runtime.js'});
await new Promise(r=>setTimeout(r,50));
const state=()=>JSON.parse(storage.get('H93_OF_001_V10_STATE')||'{}');

if(!nodes.app.innerHTML.includes('INICIAR MINHA TIRAGEM'))throw new Error('Quadro inicial não renderizou');
if(!html.includes('favicon-flame-v4.svg'))throw new Error('Favicon ausente');

window.next();
if(state().step!==1)throw new Error('Navegação inicial falhou');
window.next();
if(state().step!==1)throw new Error('Etapa narrativa avançou sem microescolha');
window.chooseMicro(1,'repeat');window.next();
if(state().step!==2)throw new Error('Microganho não liberou avanço');

window.beginCardSelection();
if(state().step!==7)throw new Error('Tiragem não abriu no quadro 7');
const ids=[...nodes.app.innerHTML.matchAll(/chooseCard\('([^']+)',(\d)\)/g)].map(x=>x[1]);
if(ids.length!==3||new Set(ids).size!==3)throw new Error(`Tiragem inválida: ${ids.join(',')}`);
cardNodes=Array.from({length:3},()=>{const classes=new Set();return{disabled:false,classList:{add:n=>classes.add(n)},has:n=>classes.has(n)}});
window.chooseCard(ids[1],1);
await new Promise(r=>setTimeout(r,1050));
if(state().step!==8)throw new Error('Carta não avançou para revelação');
if(!nodes.app.innerHTML.includes('Carta revelada'))throw new Error('Tela de revelação ausente');
if(!nodes.app.innerHTML.includes('cdn.websitepublisher.ai/custom/wid25063/images/tarot-thoth/'))throw new Error('Revelação não usa imagem THOTH hospedada');

window.chooseMicro(8,'recognition');window.jump(14);
if(!nodes.app.innerHTML.includes('data:image/webp;base64,TEST_PHOTO'))throw new Error('Foto oficial não entrou na seção de autoridade');
window.chooseMicro(14,'balanced');window.jump(16);
if((nodes.app.innerHTML.match(/v10-system-icon/g)||[]).length<6)throw new Error('Seis ícones/vetores do sistema não renderizaram');
window.chooseMicro(16,'symbols');window.jump(21);
if(nodes.app.innerHTML.includes('O valor desta leitura está no cruzamento'))throw new Error('Copy antiga do diagnóstico reapareceu');
if(!nodes.app.innerHTML.includes('Você marcou'))throw new Error('Diagnóstico não está usando resposta do usuário');

if(!html.includes('function checkoutVariant()'))throw new Error('Arquitetura de variantes do checkout ausente');
if(!html.includes("const key=product+'|'+checkoutVariant()"))throw new Error('Checkout não preserva produto+bump');
if(html.includes("alert('O checkout Stripe está em ativação"))throw new Error('Alert antigo do checkout reapareceu');

console.log(`Smoke V10.1 OK: abertura, microganho, tiragem THOTH, foto, ícones, diagnóstico personalizado e checkout seguro validados. Carta testada: ${ids[1]}.`);
