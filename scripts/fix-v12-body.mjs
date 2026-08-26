import fs from 'node:fs';

for (const path of ['dist/index.html','dist/oraculo.html']) {
  let html=fs.readFileSync(path,'utf8');
  const marker='<script id="h93-v12-runtime">';
  const start=html.indexOf(marker);
  if(start<0)throw new Error(`V12 repair: runtime não localizado em ${path}`);
  const close=html.indexOf('</script>',start);
  if(close<0)throw new Error(`V12 repair: fechamento do runtime não localizado em ${path}`);
  const end=close+'</script>'.length;
  const runtime=html.slice(start,end);
  html=html.slice(0,start)+html.slice(end);
  const body=html.lastIndexOf('</body>');
  if(body<0)throw new Error(`V12 repair: body final não localizado em ${path}`);
  html=html.slice(0,body)+runtime+'\n'+html.slice(body);
  if(html.indexOf(marker)!==html.lastIndexOf(marker))throw new Error(`V12 repair: runtime duplicado em ${path}`);
  fs.writeFileSync(path,html);
}

console.log('V12 runtime reposicionado no body final real.');
