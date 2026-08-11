import fs from 'node:fs';
import vm from 'node:vm';

const html = fs.readFileSync('dist/index.html', 'utf8');
const match = html.match(/<script>([\s\S]*?)<\/script>/i);
if (!match) throw new Error('Runtime <script> não encontrado no HTML montado');

const nodes = {
  app: { innerHTML: '', style: {}, classList: { add(){} } },
  progress: { style: {} },
  phase: { textContent: '', style: {} },
  review: { style: {} },
  stepSelect: { innerHTML: '', style: {} },
  jumpBtn: { style: {} },
  resetBtn: { style: {} }
};
const storage = new Map();
const location = { search: '', href: 'https://example.test/' };
let cardNodes = [];
const document = {
  getElementById(id) {
    return nodes[id] || (nodes[id] = { value: '', innerHTML: '', textContent: '', style: {}, classList: { add(){} } });
  },
  querySelectorAll(selector) {
    if (selector === '.flip-card') return cardNodes;
    return [];
  },
  open(){},
  write(){},
  close(){}
};
const window = {
  location,
  scrollTo(){},
  open(){ return null; }
};

const sandbox = {
  console,
  window,
  document,
  location,
  URLSearchParams,
  Intl,
  Math,
  Date,
  JSON,
  Number,
  String,
  Object,
  Array,
  RegExp,
  Promise,
  Set,
  setTimeout,
  clearTimeout,
  alert(){},
  localStorage: {
    getItem: key => storage.get(key) ?? null,
    setItem: (key, value) => storage.set(key, value),
    removeItem: key => storage.delete(key)
  },
  fetch: async () => ({
    ok: true,
    json: async () => ({ offers: {} }),
    text: async () => ''
  })
};
sandbox.globalThis = sandbox;
vm.createContext(sandbox);
vm.runInContext(match[1], sandbox, { filename: 'H93-V9.5-runtime.js' });

await new Promise(resolve => setTimeout(resolve, 30));

if (!nodes.app.innerHTML || nodes.app.innerHTML.length < 300) {
  throw new Error(`Primeiro quadro não renderizou. app.innerHTML=${nodes.app.innerHTML.length}`);
}
if (!nodes.app.innerHTML.includes('INICIAR MINHA TIRAGEM')) {
  throw new Error('CTA inicial não apareceu no primeiro quadro');
}
if (!nodes.app.innerHTML.includes('O que está impedindo seu dinheiro')) {
  throw new Error('Headline inicial não apareceu no primeiro quadro');
}
if (nodes.phase.textContent !== 'Abertura') {
  throw new Error(`Fase inicial inválida: ${nodes.phase.textContent}`);
}
if (nodes.progress.style.width !== '0%') {
  throw new Error(`Progresso inicial inválido: ${nodes.progress.style.width}`);
}
if (typeof window.beginCardSelection !== 'function' || typeof window.chooseCard !== 'function') {
  throw new Error('API pública da tiragem não foi exposta');
}

const STATE_KEY = 'H93_OF_001_V9_5_STATE';
const readState = () => JSON.parse(storage.get(STATE_KEY) || 'null');

window.beginCardSelection();
let selectionState = readState();
if (!selectionState) throw new Error('Tiragem não salvou estado');
if (selectionState.step !== 7) throw new Error(`Tiragem não abriu no quadro 7: ${selectionState.step}`);
if (selectionState.card !== null) throw new Error('Tiragem nova começou com carta antiga selecionada');
const ids = selectionState.spread.map(c => c.id);
if (ids.length !== 3 || new Set(ids).size !== 3) throw new Error('Tiragem não possui três cartas distintas');
if (!nodes.app.innerHTML.includes('Qual posição chama você primeiro?')) throw new Error('Quadro de escolha das cartas não renderizou');

cardNodes = Array.from({ length: 3 }, () => {
  const classes = new Set();
  return {
    disabled: false,
    classList: { add(name){ classes.add(name); } },
    hasClass(name){ return classes.has(name); }
  };
});
const chosenId = ids[1];
window.chooseCard(chosenId, 1);
selectionState = readState();
if (selectionState.step !== 7 || selectionState.card?.id !== chosenId || selectionState.cardPos !== 1) {
  throw new Error('Clique não registrou a carta escolhida corretamente');
}
if (!cardNodes.every(n => n.disabled)) throw new Error('Cartas não foram bloqueadas após a primeira escolha');
if (!cardNodes[1].hasClass('selected')) throw new Error('Carta escolhida não recebeu classe selected');
if (!cardNodes[0].hasClass('dim') || !cardNodes[2].hasClass('dim')) throw new Error('Cartas não escolhidas não foram atenuadas');

await new Promise(resolve => setTimeout(resolve, 1100));
const revealed = readState();
if (revealed.step !== 8 || revealed.card?.id !== chosenId) throw new Error(`Carta não avançou para revelação: quadro ${revealed.step}`);
if (!nodes.app.innerHTML.includes('Carta revelada')) throw new Error('Quadro de carta revelada não apareceu');
if (!nodes.app.innerHTML.includes(revealed.card.name)) throw new Error('A carta revelada não corresponde à carta clicada');

window.beginCardSelection();
const repeated = readState();
if (repeated.step !== 7 || repeated.card !== null || repeated.cardPos !== null || repeated.spread.length !== 3) {
  throw new Error('Nova tiragem herdou estado da carta anterior');
}

console.log(`Smoke runtime OK. Primeiro quadro + escolha/virada/revelação validados; carta testada: ${revealed.card.name}.`);
