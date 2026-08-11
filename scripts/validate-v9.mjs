import fs from 'node:fs';
import vm from 'node:vm';

const parts = Array.from({ length: 9 }, (_, i) =>
  fs.readFileSync(`source/v8/part-${String(i).padStart(2, '0')}.txt`, 'utf8')
);
const v8 = parts.join('');
const patcher = fs.readFileSync('source/v9/patcher.js', 'utf8');
const stateFix = fs.readFileSync('source/v9/state-fix.js', 'utf8');
const checkout = JSON.parse(fs.readFileSync('config/checkout.json', 'utf8'));

const sandbox = { window: {}, console };
vm.createContext(sandbox);
vm.runInContext(patcher, sandbox, { filename: 'source/v9/patcher.js' });
vm.runInContext(stateFix, sandbox, { filename: 'source/v9/state-fix.js' });

if (typeof sandbox.window.applyH93V9Patches !== 'function' || typeof sandbox.window.applyH93V9StateFixes !== 'function') {
  throw new Error('Camadas V9 não foram expostas');
}

let v9 = sandbox.window.applyH93V9Patches(v8);
v9 = sandbox.window.applyH93V9StateFixes(v9);

const mustContain = [
  'H93_OF_001_V9_5_STATE',
  "const app=document.getElementById('app'),progress=document.getElementById('progress'),phase=document.getElementById('phase');",
  "if(!validStep(state.step)){state=initial();ensureSpread();save()}",
  'Math.min(Math.trunc(n),STEPS.length-1)',
  'function freshSpread(){',
  'function beginCardSelection(){',
  'onclick="beginCardSelection()">ESCOLHER ENTRE AS TRÊS CARTAS</button>',
  "if(state.step!==7||state.card||!Number.isInteger(pos)",
  "state.step===7&&state.card&&state.card.id===id",
  "window.beginCardSelection=beginCardSelection;",
  'function profile(){',
  'function answer(key,id){',
  'function option(key,id){',
  'function label(key){',
  'function qScreen(key,eyebrow',
  'function chooseCard(id,pos){',
  'function recommendation(){',
  'function proofHtml(stage){',
  'function updatePhase(){',
  'app.innerHTML=h;',
  'Custo invisível',
  'Mecanismo de repetição',
  'Primeiro comando de correção',
  'Verdade percebida ainda não executada',
  'Dinâmica financeira',
  'SALVAR MEU DIAGNÓSTICO EM PDF',
  'id="email"',
  'depoimento-02-meta-300-mil.png',
  'depoimento-03-abertura-possibilidades.png',
  'depoimento-04-orientacoes.png',
  'depoimento-05-captacao-comissoes.png',
  'Consulta Inicial com Hórus IA'
];
for (const token of mustContain) {
  if (!v9.includes(token)) throw new Error(`V9.5 sem marcador obrigatório: ${token}`);
}

const mustNotContain = [
  "localStorage.setItem('h93of001v8'",
  "if(state.step>=21&&!state.card)state.card=state.spread[0]||CARDS[0]",
  'if(n>28)n=28',
  'if(state.card)return;',
  'hotmart.com'
];
for (const token of mustNotContain) {
  if (v9.toLowerCase().includes(token.toLowerCase())) throw new Error(`Regressão detectada: ${token}`);
}

const expectedPrices = {
  essential: 'price_1U2MJK2aHZ9yiNGq8qWD2nC8',
  deep: 'price_1U2MJQ2aHZ9yiNGqKFQxHnFY',
  complete: 'price_1U2MJW2aHZ9yiNGquVnBSuRd',
  horusai: 'price_1U2MJe2aHZ9yiNGqIG82EJcZ'
};
for (const [offer, priceId] of Object.entries(expectedPrices)) {
  if (checkout.offers?.[offer]?.price_id !== priceId) throw new Error(`Price Stripe divergente: ${offer}`);
}
if (checkout.provider !== 'stripe' || checkout.mode !== 'live') throw new Error('Checkout não está configurado para Stripe live');

const cases = [...v9.matchAll(/case\s+(\d+)\s*:/g)].map(m => Number(m[1]));
if (cases.length < 28) throw new Error(`Fluxo incompleto: ${cases.length} cases encontrados`);
if (Math.min(...cases) !== 0 || Math.max(...cases) !== 27) throw new Error(`Faixa de quadros inválida: ${Math.min(...cases)}..${Math.max(...cases)}`);

const runtimeOrder = ['function jump(n){','function esc(s){','function answer(key,id){','function chooseCard(id,pos){','function profile(){','function recommendation(){'];
let last = -1;
for (const token of runtimeOrder) {
  const pos = v9.indexOf(token);
  if (pos < 0) throw new Error(`Helper runtime ausente: ${token}`);
  if (pos <= last) throw new Error(`Ordem runtime corrompida próximo de: ${token}`);
  last = pos;
}

fs.mkdirSync('dist', { recursive: true });
fs.writeFileSync('dist/H93-OF-001-Oraculo-Financeiro-THOTH-V9.html', v9);
fs.writeFileSync('dist/index.html', v9);
console.log(`V9.5 validada. HTML montado: ${v9.length} bytes; ${cases.length} cases (0..27); tiragem e estado de cartas protegidos.`);
