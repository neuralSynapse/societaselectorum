import fs from 'node:fs';
import zlib from 'node:zlib';
import {spawnSync} from 'node:child_process';

const encoded=fs.readFileSync('source/v11/patch-v11.py.br.b64','utf8').trim();
const code=zlib.brotliDecompressSync(Buffer.from(encoded,'base64'));
const tmp='/tmp/h93-patch-v11.py';
fs.writeFileSync(tmp,code);
const run=spawnSync('python3',[tmp],{stdio:'inherit'});
if(run.status!==0)process.exit(run.status??1);
