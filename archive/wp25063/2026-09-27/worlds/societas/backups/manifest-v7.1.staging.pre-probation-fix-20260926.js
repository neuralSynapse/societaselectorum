const pergaminhos = [
  ['I','Autoeleição'],['II','Autorresponsabilidade'],['III','Verdadeira Vontade'],['IV','Caráter'],['V','Disciplina'],['VI','Clareza'],['VII','Transmutação'],['VIII','Corpo e Energia'],['IX','Obra'],['X','Fortuna'],['XI','Influência'],['XII','Legado']
].map(([numeral,title],i)=>({
  id:`pergaminho-${i+1}`,
  numeral,
  title:`${numeral} · ${title.toUpperCase()}`,
  shortTitle:title,
  kind:'pergaminho_maior',
  status:'peregrinus',
  parent:'peregrinus-ignis',
  summary:`Pergaminho Maior ${numeral} do Peregrinus Ignis. Pertence ao Grau I, não à Etapa do Estudante.`
}));

const ciclos = [
  ['xi-1','XI·1','Autogoverno, limites, intenção e método','periodo-1'],
  ['xi-2','XI·2','Estudo, registro, autoria e proveniência','periodo-1'],
  ['xi-3','XI·3','Continuidade, Chama Negra e transferência','periodo-1'],
  ['xi-4','XI·4','Filosofias adversariais e autonomia','periodo-2'],
  ['xi-5','XI·5','Thelema, Hermetismo e Verdadeira Vontade','periodo-2'],
  ['xi-6','XI·6','Cabala, Árvores, Tarot e correspondências','periodo-2'],
  ['xi-7','XI·7','Alquimia, grimórios e transmissão','periodo-3'],
  ['xi-8','XI·8','Responsabilidade material e Obra','periodo-3'],
  ['xi-9','XI·9','Síntese, autoria, defesa e passagem','periodo-3']
].map(([id,code,title,parent])=>({id,title:`${code} · ${title}`,shortTitle:code,kind:'cycle',status:'student',parent,summary:title}));

const competencias = [
  ['c1','C1','Governança, ética e limites do Estudante'],
  ['c2','C2','Método interno da SOCIETAS ELECTORUM e linguagem interna'],
  ['c3','C3','Pesquisa, fichamento e proveniência'],
  ['c4','C4','Filosofias adversariais e autonomia'],
  ['c5','C5','Thelema, hermetismo e currículo histórico da A∴A∴'],
  ['c6','C6','Cabala, Árvore, Qliphoth e Tarot'],
  ['c7','C7','Alquimia, grimórios e transmissão mágica'],
  ['c8','C8','Responsabilidade material e construção da Obra'],
  ['c9','C9','Síntese, autoria e defesa']
].map(([id,code,title])=>({id,title:`${code} · ${title}`,shortTitle:code,kind:'competency',status:'student',summary:title,hiddenByDefault:true}));

const modulos = [
  ['e01','E0.1','Fundação institucional'],['e02','E0.2','Método e identidade operacional'],['e03','E0.3','Fontes e pensamento crítico'],
  ['e04','E0.4','Filosofias adversariais'],['e05','E0.5','Thelema, hermetismo e A∴A∴'],['e06','E0.6','Cabala, Árvores e Tarot'],
  ['e07','E0.7','Alquimia, grimórios e transmissão'],['e08','E0.8','Obra e responsabilidade material'],['e09','E0.9','Síntese e passagem']
].map(([id,code,title])=>({id,title:`${code} · ${title}`,shortTitle:code,kind:'module',status:'student',summary:title,hiddenByDefault:true}));

export const SOCIETAS_WORLD = Object.freeze({
  schemaVersion: 2,
  worldKey: 'societas',
  sortOrder: 2,
  title: 'MUNDUS · SOCIETAS',
  shortTitle: 'SOCIETAS',
  descriptor: 'Arquitetura viva da SOCIETAS ELECTORUM convertida em território navegável, causal, interrogável e verificável.',
  status: 'staging_v7_1_arbores_geminae',
  canon: {
    code: 'MET-MUNDUS-001:SOCIETAS',
    version: '2.1-staging',
    isolation: true,
    sourceOfTruth: 'METHODUS ARBORUM GEMINARUM v2.1 + MAPA CANÔNICO v7.1',
    sourceDocumentId: '1UZVXFmQNl-OvNbwYBdoUMqR4OkV1kuAONdc4lfHQYCg',
    sourceDate: '2026-09-26'
  },
  method: 'MET-MUNDUS-001',
  entryRoute: '/mundus/societas.html',
  accent: 'gold',
  visibility: 'staging_restricted',
  technical: {
    version:'2.4.0-arbores-geminae-v7.1-staging',
    renderer:'three@0.180.0',
    runtimeAsset:'worlds/societas/runtime-3d-v7.1.staging.js',
    rendererAsset:'worlds/societas/renderer-3d.js',
    arborVitaeAsset:'worlds/societas/tree-of-life-3d.js',
    semanticFormsAsset:'worlds/societas/semantic-forms-3d.js',
    sequenceAsset:'worlds/societas/sequence-v7.1.staging.js',
    fallbackAsset:'worlds/societas/runtime-v7.1.staging.js',
    worldFirst:true,
    guidedAndFree:true,
    progressiveManifestation:true,
    cameraModes:['auto','orbit','free'],
    audio:['procedural_ambient','speech_synthesis_narration'],
    persistenceNamespace:'mundus:societas:*',
    webglFallback:true,
    canonicalHost:'www.sociedadedoseleitos.com',
    stagingDependency:true
  },
  progression: {
    type:'competence_and_evidence',
    xpPromotesDegree:false,
    streakPromotesDegree:false,
    paymentPromotesDegree:false,
    elapsedTimeAlonePromotesDegree:false,
    minimumStudentDays:99,
    periods:3,
    daysPerPeriod:33,
    cycles:9,
    daysPerCycle:11,
    eligibilityTarget:'peregrinus-ignis'
  },
  epistemicClasses: [
    'canonical_source','historical_source','institutional_synthesis','comparative_model','interpretation','tradition','experience','hypothesis','praxis_record','open_question'
  ],
  evidenceClasses: [
    {id:'recuperacao',title:'RECUPERAÇÃO',meaning:'reproduzir sem consulta'},
    {id:'discriminacao',title:'DISCRIMINAÇÃO',meaning:'distinguir de conceito, tradição ou caso semelhante'},
    {id:'transferencia',title:'TRANSFERÊNCIA',meaning:'usar em contexto novo'},
    {id:'opus',title:'OBRA',meaning:'produzir mudança, decisão ou entrega verificável'}
  ],
  studentOperations: [
    {id:'regencia',title:'REGÊNCIA',meaning:'autonomia, direção, responsabilidade e não submissão pessoal'},
    {id:'estudo',title:'ESTUDO',meaning:'recuperação, explicação, discriminação, espaçamento, feedback e transferência'},
    {id:'registro',title:'REGISTRO',meaning:'memória auditável, proveniência e distinção entre fonte, interpretação, hipótese e criação autoral'},
    {id:'contemplacao',title:'CONTEMPLAÇÃO',meaning:'presença, lucidez, disciplina e agência; núcleo inicial com Meditação da Chama Negra'},
    {id:'transferencia',title:'TRANSFERÊNCIA',meaning:'conhecimento convertido em decisão, comportamento, produção, comunicação e Obra verificável'}
  ],
  dailyLearningLoop: ['ALVO','PRÉ-TESTE','FONTE','EVOCAÇÃO','FEEDBACK','TRANSFERÊNCIA','REGISTRO'],
  clavePedagogy: ['IMAGO','VERBUM','CLAVIS','ARCANUM','PRAXIS','PROBATIO','OPUS'],
  fractalEngine: ['CAVERNA','REVELAÇÃO','RUPTURA','LIMIAR','TRAVESSIA','PROVAÇÃO','REINTEGRAÇÃO','ENCARNAR','OBRA','NOVA CAVERNA'],
  perspectives: ['observador','navegador','interlocutor','operador','praticante'],
  modes: ['mapa','orbita','foco','caminho','comparacao','comunhao','praxis','chronica'],
  guidedSequence: ['t0','nucleus','vitae-root','vitae-form','vitae-sephirot','vitae-paths','vitae-student','trees','systems','student','periods','cycles','evidence','degree1','major-scrolls','integration'],
  fourWorlds: [
    {id:'assiah',title:'ASSIAH',meaning:'materialidade, comportamento, execução, registro e consequência concreta'},
    {id:'yetzirah',title:'YETZIRAH',meaning:'forma psíquica, imagem, hábito, emoção, padrão e organização interna'},
    {id:'briah',title:'BRIAH',meaning:'visão, inteligência estruturante, formulação, obra e capacidade de criar forma'},
    {id:'atziluth',title:'ATZILUTH',meaning:'princípio, direção, vontade e unidade de comando'}
  ],
  institutionalArchitecture: {
    formalDegrees:11,
    culmen:'KETHER ↔ THAUMIEL · CULMEN RESERVATUM',
    adamas:'OPUS TERMINALE · RECTIFICATIO MAGNA',
    firstDegree:'Peregrinus Ignis',
    publicInterfaceTrees:['arbor-vitae','arbor-draconis','arbor-electorum'],
    technicalAliases:{
      'arbor-vitae':'CAMERA LUCIS · COLLEGIUM LUCIS',
      'arbor-draconis':'CAMERA NOCTIS · AUREA SERPENS',
      'arbor-electorum':'TERTIA ARBOR · VELADA'
    },
    doctrinalProvenanceNotes:[
      'A arquitetura vigente é Arbores Geminae: Camera Lucis e Camera Noctis são trabalhadas dentro de cada Grau pertinente.',
      'Collegium Lucis governa Camera Lucis; Aurea Serpens governa Camera Noctis; Rectificatio reconcilia ambas.',
      'Os IDs arbor-vitae, arbor-draconis e arbor-electorum permanecem apenas como aliases técnicos no staging para preservar compatibilidade do renderer.',
      'A Tertia Arbor permanece velada; nenhuma terceira carreira é inventada por simetria.'
    ]
  },
  nodes: [
    {id:'societas-electorum',title:'SOCIETAS ELECTORUM',kind:'institution',status:'canonical',summary:'Núcleo institucional. A experiência digital deve tornar visíveis relações entre Árvores, Jornada, Pergaminho, Biblioteca, formação, prática e evidência sem criar áreas concorrentes.'},
    {id:'arbor-vitae',title:'CAMERA LUCIS · ARBOR VITAE',kind:'tree',status:'present',canonicalRole:'camera_lucis',summary:'Alias técnico da Camera Lucis. Representa a potência sefirótica ordenada trabalhada sob Collegium Lucis; não constitui uma primeira carreira inteira separada.'},
    {id:'arbor-draconis',title:'CAMERA NOCTIS · AUREA SERPENS',kind:'tree',status:'present',canonicalRole:'camera_noctis',summary:'Alias técnico da Camera Noctis. Representa o contraditório qliphótico e a distorção possível de cada potência, sempre com Lex Reditus e Rectificatio; não é segunda carreira cronológica.'},
    {id:'arbor-electorum',title:'TERTIA ARBOR · VELADA',kind:'tree',status:'veiled',canonicalRole:'tertia_arbor_velata',summary:'Alias técnico da camada velada. Não recebe conteúdo, graus ou sequência posterior por simetria.'},
    {id:'estudante',title:'ESTUDANTE',kind:'stage',status:'preparatory',summary:'Etapa preparatória anterior ao primeiro Grau. Não é Grau, título ou iniciação. Possui mínimo estrutural de 99 dias em 3 Períodos de 33 e 9 Ciclos XI de 11.'},
    {id:'periodo-1',title:'PERÍODO I · REGÊNCIA',kind:'period',status:'student',summary:'XI·1–XI·3. Forma autogoverno, método, registro, continuidade e transferência.'},
    {id:'periodo-2',title:'PERÍODO II · DISCERNIMENTO',kind:'period',status:'student',summary:'XI·4–XI·6. Aprofunda filosofias adversariais, Thelema, Hermetismo, Cabala, Árvores, Tarot e distinção crítica.'},
    {id:'periodo-3',title:'PERÍODO III · OBRA',kind:'period',status:'student',summary:'XI·7–XI·9. Integra transmissão, responsabilidade material, síntese, autoria, defesa e passagem.'},
    {id:'clavis-1',title:'CLAVIS I · O OLHO',kind:'clavis',status:'student',summary:'CLAVIS DO UMBRAL transversal do Período I. Função: VER. Perceber antes de concluir; reconhecer filtros, fontes e limites.'},
    {id:'clavis-2',title:'CLAVIS II · A CHAMA',kind:'clavis',status:'student',summary:'CLAVIS DO UMBRAL transversal do Período II. Função: GOVERNAR. Escolher o centro que governa e interromper automatismos.'},
    {id:'clavis-3',title:'CLAVIS III · A OBRA',kind:'clavis',status:'student',summary:'CLAVIS DO UMBRAL transversal do Período III. Função: FAZER. Fazer a compreensão adquirir consequência e Obra verificável.'},
    ...ciclos,
    {id:'biblioteca',title:'BIBLIOTECA',kind:'system',status:'canonical',summary:'Único destino funcional de acervo na UX corrente. Publicação pública, entitlement curricular, leitura, tarefa, conclusão e progressão são estados distintos.'},
    {id:'jornada',title:'JORNADA',kind:'system',status:'canonical',summary:'Mostra posição, histórico e horizonte do percurso. Não substitui o Pergaminho nem cria progressão autônoma.'},
    {id:'pergaminho',title:'PERGAMINHO',kind:'system',status:'canonical',summary:'Núcleo operacional do percurso diário: leitura, prática, registro, integração e evidência. “Hipercaminho” não é nomenclatura válida.'},
    {id:'lm-001',title:'LM-001 · LUX MENTIS',kind:'work',status:'transversal',summary:'Obra fundamental transversal de mente, linguagem, distinção de camadas e consciência operativa.'},
    {id:'na-001',title:'NA-001 · NINGUÉM ACIMA',kind:'work',status:'transversal',summary:'Obra fundamental de Regência e autogoverno. A publicação ou leitura, por si só, não conclui sua função curricular.'},
    {id:'an-001',title:'AN-001 · LIBER ANTRI',kind:'work',status:'transversal',summary:'Obra fundamental transversal de percepção, discernimento e retorno. Mantém firewall explícito entre fonte, interpretação, leitura Electorum, hipótese e prática.'},
    {id:'exame-peregrinus',title:'EXAME DE PASSAGEM',kind:'gate',status:'student',summary:'Elegibilidade exige Caderno de Estudos, Dossiê Final, prova escrita individual, leitura ativa, ensaio, defesa oral e verificação de autoria. Rubrica não compensável: nível 3 ou superior em todas as dimensões.'},
    {id:'peregrinus-ignis',title:'PEREGRINUS IGNIS',kind:'degree',status:'degree_1',summary:'Grau I. A passagem reconhece competência demonstrada e não decorre automaticamente de tempo, acesso, pagamento, clique ou intensidade subjetiva.'},
    ...pergaminhos,
    ...competencias,
    ...modulos
  ],
  relations: [
    ['societas-electorum','arbor-vitae','camera_lucis'],['societas-electorum','arbor-draconis','camera_noctis'],['societas-electorum','arbor-electorum','tertia_velada'],
    ['societas-electorum','biblioteca','acervo_unico'],['societas-electorum','jornada','orienta_percurso'],['societas-electorum','pergaminho','opera_percurso'],
    ['societas-electorum','estudante','forma'],['estudante','periodo-1','contém'],['estudante','periodo-2','contém'],['estudante','periodo-3','contém'],
    ['periodo-1','clavis-1','regido_por'],['periodo-2','clavis-2','regido_por'],['periodo-3','clavis-3','regido_por'],
    ['periodo-1','xi-1','contém'],['periodo-1','xi-2','contém'],['periodo-1','xi-3','contém'],
    ['periodo-2','xi-4','contém'],['periodo-2','xi-5','contém'],['periodo-2','xi-6','contém'],
    ['periodo-3','xi-7','contém'],['periodo-3','xi-8','contém'],['periodo-3','xi-9','contém'],
    ['clavis-1','clavis-2','ver_para_governar'],['clavis-2','clavis-3','governar_para_fazer'],
    ['estudante','lm-001','obra_transversal'],['estudante','na-001','obra_transversal'],['estudante','an-001','obra_transversal'],
    ['estudante','exame-peregrinus','elegibilidade_por_competencia'],['exame-peregrinus','peregrinus-ignis','passagem_humana_documentada'],
    ['peregrinus-ignis','pergaminho-1','recebe'],['peregrinus-ignis','pergaminho-2','recebe'],['peregrinus-ignis','pergaminho-3','recebe'],['peregrinus-ignis','pergaminho-4','recebe'],['peregrinus-ignis','pergaminho-5','recebe'],['peregrinus-ignis','pergaminho-6','recebe'],['peregrinus-ignis','pergaminho-7','recebe'],['peregrinus-ignis','pergaminho-8','recebe'],['peregrinus-ignis','pergaminho-9','recebe'],['peregrinus-ignis','pergaminho-10','recebe'],['peregrinus-ignis','pergaminho-11','recebe'],['peregrinus-ignis','pergaminho-12','recebe']
  ].map(([from,to,type])=>({from,to,type})),
  hiddenLayerGroups: {
    competencies: competencias.map(x=>x.id),
    modules: modulos.map(x=>x.id)
  },
  antiRegression: [
    'representar Arbores Geminae como Camera Lucis + Camera Noctis dentro do percurso de cada Grau pertinente; aliases técnicos antigos nunca podem ser apresentados como três carreiras vigentes',
    'Arbor Vitae deve ser representada como Árvore da Vida tridimensional reconhecível, com forma arbórea, dez sefirot e caminhos; nunca voltar a um nó geométrico genérico quando a cena exigir a própria Árvore',
    'objetos reconhecíveis devem usar formas 3D semânticas próprias; não regredir sistemas, etapas, graus, portões, claves, ciclos, obras ou pergaminhos a esferas ou poliedros genéricos quando houver forma identificável',
    'A Tertia Arbor permanece velada; não preencher sua arquitetura por simetria, desejo estético ou lacuna técnica',
    'usar AS CLAVES DO UMBRAL / CLAVIS I–III na linguagem corrente; “Pergaminho-Superchave” é histórico',
    'não promover Grau por XP, streak, clique, pagamento, posse de conta, acesso por URL, tempo de tela ou mero decurso temporal',
    'não apresentar metáfora, experiência, tradição ou hipótese como fato histórico ou científico',
    'não fundir tradições silenciosamente',
    'não inventar geometria, grau, doutrina, obra ou sequência para preencher lacunas',
    'não concluir aprendizagem por mera visualização',
    'preservar camada explícita de fontes, edição, proveniência e grau de certeza',
    'preservar competências e evidências já demonstradas em remediação focal',
    'Biblioteca é única; não recriar Armarium ou Academia Arcana como destinos paralelos',
    'Pergaminho e Jornada têm funções distintas; “Hipercaminho” é proibido',
    'mobile não pode ser versão amputada'
  ]
});

export default SOCIETAS_WORLD;
