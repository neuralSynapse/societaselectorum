import fs from 'node:fs';

for (const path of ['dist/index.html','dist/oraculo.html']) {
  let html=fs.readFileSync(path,'utf8');

  const replacements=[
    ['O Ímã de Dinheiro reúne sete áudios de hipnose e reprogramação mental para trabalhar identidade, receptividade, preservação, foco e ação material.','O Ímã de Dinheiro reúne sete práticas guiadas escritas para trabalhar foco, identidade, preservação, decisão, disciplina e ação material.'],
    ['<b>Forja simbólica:</b> a edição foi preparada na quinta-feira, na primeira hora planetária após o nascer do sol, sob a regência de Júpiter e em fase crescente, e selada no domingo, na primeira hora após o nascer do sol, sob a regência do Sol. A estrutura combina expansão joviana e direção solar como símbolos de intenção, disciplina e construção.','<b>Estrutura simbólica:</b> Júpiter e Sol aparecem apenas como referências de expansão responsável e direção. O valor do protocolo está nas práticas e ações observáveis, não em promessa de efeito material automático.'],
    ['Hipnose e prática ritual não garantem dinheiro. A ferramenta busca fortalecer estados internos e comportamentos compatíveis com construção financeira.','Práticas reflexivas e linguagem simbólica não garantem resultado financeiro. O protocolo busca apoiar foco, registro, decisão e comportamento observável.'],
    ['SEGUIR SEM OS ÁUDIOS','SEGUIR SEM O PROTOCOLO'],
    ['ADICIONAR ÍMÃ DE DINHEIRO · ${fmt(9.97)}','DISPONÍVEL NA ÁREA PRIVADA · ${fmt(9.97)}'],
    ['QUERO MEU MAPA FINANCEIRO · ${fmt(147)}','DISPONÍVEL NA ÁREA PRIVADA · ${fmt(147)}'],
    ['O Mapa Numerológico Financeiro organiza números do nome e nascimento, ciclos, tensões, potenciais materiais e períodos simbólicos em uma leitura completa.','O Mapa Numerológico Financeiro calcula números do nome e nascimento e os interpreta como linguagem simbólica de reflexão, com forças, tensões, ciclo do ano e plano de ação.'],
    ['ciclos e tendências materiais','ciclo simbólico e pontos de reflexão'],
    ['Após a confirmação do pagamento, você receberá as instruções de entrega e, quando aplicável, o agendamento.','Após a confirmação do pagamento, você receberá a entrega privada correspondente.']
  ];

  for (const [from,to] of replacements) {
    if(!html.includes(from)) throw new Error(`V12 cleanup: trecho não localizado em ${path}: ${from}`);
    html=html.replaceAll(from,to);
  }

  const legacy="function postDecision(id,accepted){if(accepted&&!state.upsells.includes(id))state.upsells.push(id);state.postStage=id==='magnet'?'numerology':'summary';save();render();window.scrollTo({top:0,behavior:'smooth'})}";
  const safe="function postDecision(id,accepted){if(accepted)alert('Os extras pagos são contratados somente na área privada, depois da confirmação da consulta principal. Nenhuma aquisição foi registrada nesta tela.');state.postStage=id==='magnet'?'numerology':'summary';save();render();window.scrollTo({top:0,behavior:'smooth'})}";
  if(!html.includes(legacy)) throw new Error(`V12 cleanup: postDecision legado não localizado em ${path}`);
  html=html.replace(legacy,safe);

  fs.writeFileSync(path,html);
}

console.log('V12 commerce cleanup aplicado: telas legadas informativas e sem aquisição local.');
