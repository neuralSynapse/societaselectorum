import fs from 'node:fs';

let html=fs.readFileSync('dist/index.html','utf8');

// Identidade pública canônica.
html=html.replaceAll('SOCIEDADE DOS ELEITOS','SOCIETAS ELECTORUM');
html=html.replaceAll('Sociedade dos Eleitos','Societas Electorum');

// Remove qualquer rótulo legado de versão interna que tenha escapado para o público.
html=html.replace(/V8 Consolidado funcional para aprovação\.[^<]*/g,'Societas Electorum · Oráculo Financeiro de THOTH · Leitura simbólica e reflexiva. Não substitui orientação financeira, jurídica, contábil ou de investimentos e não garante resultados.');
html=html.replace(/V8 Consolidado[^<]*/g,'Societas Electorum · Oráculo Financeiro de THOTH · Leitura simbólica e reflexiva. Não substitui orientação financeira, jurídica, contábil ou de investimentos e não garante resultados.');

// A URL pública é estável. O número de build fica apenas no código/testes.
html=html.replace(/<title>Oráculo Financeiro de THOTH · V11\.2<\/title>/,'<title>Oráculo Financeiro de THOTH · Societas Electorum</title>');

fs.writeFileSync('dist/index.html',html);
fs.writeFileSync('dist/oraculo.html',html);
console.log('Finalização pública aplicada:',html.length,'caracteres');
