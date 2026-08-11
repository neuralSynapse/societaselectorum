import fs from 'node:fs';
import vm from 'node:vm';

const parts = Array.from({ length: 9 }, (_, i) =>
  fs.readFileSync(`source/v8/part-${String(i).padStart(2, '0')}.txt`, 'utf8')
);
const v8 = parts.join('');
const patcher = fs.readFileSync('source/v9/patcher.js', 'utf8');

const sandbox = { window: {}, console };
vm.createContext(sandbox);
vm.runInContext(patcher, sandbox, { filename: 'source/v9/patcher.js' });

if (typeof sandbox.window.applyH93V9Patches !== 'function') {
  throw new Error('applyH93V9Patches não foi exposto');
}

const v9 = sandbox.window.applyH93V9Patches(v8);
const mustContain = [
  'H93_OF_001_V9_STATE',
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
  'Consulta Inicial com Hórus IA',
  'price_1U2MJK2aHZ9yiNGq8qWD2nC8'
];

for (const token of mustContain) {
  if (!v9.includes(token)) throw new Error(`V9 sem marcador obrigatório: ${token}`);
}

const mustNotContain = [
  "localStorage.setItem('h93of001v8'",
  "if(state.step>=21&&!state.card)state.card=state.spread[0]||CARDS[0]",
  'hotmart.com'
];
for (const token of mustNotContain) {
  if (v9.toLowerCase().includes(token.toLowerCase())) throw new Error(`Regressão detectada: ${token}`);
}

const frameCount = [...v9.matchAll(/case\s+(\d+)\s*:/g)].length;
if (frameCount < 28) throw new Error(`Fluxo incompleto: ${frameCount} cases encontrados`);

fs.mkdirSync('dist', { recursive: true });
fs.writeFileSync('dist/H93-OF-001-Oraculo-Financeiro-THOTH-V9.html', v9);
console.log(`V9 validada. HTML montado: ${v9.length} bytes; ${frameCount} cases.`);
