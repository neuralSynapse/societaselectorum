import fs from 'node:fs';
import zlib from 'node:zlib';

const chunks=[1,2,3,4].map(i=>fs.readFileSync(`source/v10/snapshot-${String(i).padStart(2,'0')}.b64`,'utf8').trim());
let html=zlib.brotliDecompressSync(Buffer.from(chunks.join(''),'base64')).toString('utf8');

// V10.1: prova social fala com o que a pessoa acabou de responder, sem texto genérico de “casos semelhantes”.
const oldProof=/function proofIntro\(stage\)\{[\s\S]*?\}\nfunction proofHtml\(stage\)/;
const newProof=`function proofIntro(stage){
  const p=profile(),pain=label('pain'),emotion=label('emotion'),desired=label('desired'),lens=state.micro?.[15]||'direction';
  const lensText={direction:'onde a compreensão ganhou direção',execution:'onde uma orientação virou ação',structure:'onde um movimento começou a ganhar continuidade'}[lens]||'onde clareza virou movimento';
  if(stage==='first')return \`Você marcou <b>\${esc(pain)}</b> e descreveu <b>\${esc(emotion.toLowerCase())}</b>. Isso colocou <b>\${esc(p.short.toLowerCase())}</b> no centro da sua leitura. Nos relatos abaixo, preste atenção principalmente em <b>\${esc(lensText)}</b>, porque esse é o movimento que sua leitura está pedindo agora.\`;
  return \`Você quer <b>\${esc(desired.toLowerCase())}</b>, mas sua rota continua exigindo <b>\${esc(p.short.toLowerCase())}</b>. Por isso, estes relatos entram agora: observe o ponto exato em que a pessoa deixa de apenas entender e começa a transformar orientação em decisão, comportamento e estrutura.\`;
}
function proofHtml(stage)`;
if(!oldProof.test(html))throw new Error('proofIntro original não localizado no snapshot V10');
html=html.replace(oldProof,newProof);

fs.mkdirSync('dist',{recursive:true});
fs.writeFileSync('dist/index.html',html);
fs.writeFileSync('dist/H93-OF-001-Oraculo-Financeiro-THOTH-V10.html',html);
console.log(`V10.1 snapshot montada: ${Buffer.byteLength(html)} bytes`);
