import fs from 'node:fs';
import zlib from 'node:zlib';

const chunks=[1,2,3].map(i=>fs.readFileSync(`source/v11/snapshot-${String(i).padStart(2,'0')}.b64`,'utf8').trim());
const html=zlib.brotliDecompressSync(Buffer.from(chunks.join(''),'base64')).toString('utf8');
fs.mkdirSync('dist',{recursive:true});
fs.writeFileSync('dist/index.html',html);
fs.writeFileSync('dist/H93-OF-001-Oraculo-Financeiro-THOTH-V11.html',html);
console.log(`V11 montada: ${Buffer.byteLength(html)} bytes`);
