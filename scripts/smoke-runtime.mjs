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
const document = {
  getElementById(id) {
    return nodes[id] || (nodes[id] = { value: '', innerHTML: '', textContent: '', style: {}, classList: { add(){} } });
  },
  querySelectorAll() { return []; },
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
vm.runInContext(match[1], sandbox, { filename: 'H93-V9.4-runtime.js' });

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

console.log(`Smoke runtime OK. Primeiro quadro renderizado com ${nodes.app.innerHTML.length} caracteres.`);
