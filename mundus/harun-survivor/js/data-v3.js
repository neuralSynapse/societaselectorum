(function(root){
'use strict';
const D={};
D.version='3.0.0';
D.metaKey='mundus_harun_survivor_v3';
D.acts=[
 {id:1,name:'LIMIAR',boss:'ATHOTH',subtitle:'O ESQUECIMENTO',bg:['#e2bd76','#b87f4d','#28444f'],accent:'#5fe0d0'},
 {id:2,name:'GALERIA DO PESO',boss:'ELOAIOS',subtitle:'O PESO',bg:['#bd88a5','#6a4b70','#273950'],accent:'#f5b35b'},
 {id:3,name:'CORREDOR DAS MÁSCARAS',boss:'ASTAPHAIOS',subtitle:'AS MÁSCARAS',bg:['#80b6aa','#396d77','#34345c'],accent:'#db8eff'},
 {id:4,name:'CÂMARA DA BALANÇA',boss:'SABAOTH',subtitle:'A MEDIDA',bg:['#89c9c2','#43818b','#283d58'],accent:'#8ff2e7'},
 {id:5,name:'TRONO DA INICIAÇÃO',boss:'OBSERVADOR CEGO',subtitle:'O LIMITE DO OLHAR',bg:['#a55d65','#653541','#261e35'],accent:'#ff8b6f'}
];
D.enemyKinds={
 shade:{label:'Espectro',hp:2.2,speed:48,r:15,xp:1,damage:.7,behavior:'chase'},
 crawler:{label:'Rastejante',hp:1.45,speed:75,r:11,xp:1,damage:.55,behavior:'chase'},
 tank:{label:'Censor',hp:7.5,speed:27,r:23,xp:3,damage:1.05,behavior:'chase'},
 charger:{label:'Investidor',hp:4.2,speed:43,r:17,xp:2,damage:.9,behavior:'charge'},
 seer:{label:'Vidente',hp:3.1,speed:31,r:16,xp:2,damage:.7,behavior:'shooter'},
 warden:{label:'Guardião',hp:4.8,speed:35,r:19,xp:3,damage:.85,behavior:'orbit'}
};
D.skills=[
 {id:'phosphoros',name:'Chama Phosphoros',tier:'rare',icon:'✦',desc:'Projéteis incendeiam e deixam brasas.',max:5,tags:['projectile','fire']},
 {id:'thoth_eye',name:'Olho de Thoth',tier:'rare',icon:'◉',desc:'Campo reduz a velocidade dos inimigos próximos.',max:5,tags:['control']},
 {id:'horus_blades',name:'Lâminas de Hórus',tier:'epic',icon:'➚',desc:'Adiciona projéteis diagonais ao disparo.',max:5,tags:['projectile']},
 {id:'electorum_circle',name:'Círculo Electorum',tier:'epic',icon:'⟲',desc:'Orbes luminosos orbitam Hārūn e causam dano.',max:5,tags:['orbit']},
 {id:'ash_step',name:'Passo da Cinza',tier:'rare',icon:'➤',desc:'Aumenta velocidade e concede breve esquiva.',max:5,tags:['mobility']},
 {id:'foundation',name:'Corpo da Fundação',tier:'rare',icon:'⬟',desc:'Aumenta Sopro Vital e resistência.',max:5,tags:['vitality']},
 {id:'pierce',name:'Lâmina Penetrante',tier:'rare',icon:'↑',desc:'Projéteis atravessam inimigos adicionais.',max:5,tags:['projectile']},
 {id:'echo',name:'Eco da Cidadela',tier:'epic',icon:'↝',desc:'Projéteis ricocheteiam entre alvos.',max:5,tags:['projectile']},
 {id:'daimon',name:'Voz do Daimon',tier:'legend',icon:'◇',desc:'Amplifica dano, crítico e velocidade de ataque.',max:5,tags:['power']},
 {id:'rupture',name:'Ruptura',tier:'legend',icon:'⧖',desc:'Pulso periódico de energia limpa a área próxima.',max:5,tags:['burst']},
 {id:'fortune',name:'Roda da Fortuna',tier:'rare',icon:'☸',desc:'Aumenta sorte, coleta e chance de crítico.',max:5,tags:['fortune']},
 {id:'nuit_veil',name:'Véu de Nuit',tier:'epic',icon:'☾',desc:'Após receber dano, ganha invulnerabilidade maior.',max:5,tags:['defense']}
];
D.synergies=[
 {a:'phosphoros',b:'echo',name:'ECO SOLAR',desc:'Ricochetes deixam brasas maiores.'},
 {a:'electorum_circle',b:'thoth_eye',name:'ÓRBITA LÚCIDA',desc:'Orbes ampliam o campo de lentidão.'},
 {a:'ash_step',b:'horus_blades',name:'PASSO CORTANTE',desc:'Movimento dispara lâminas laterais.'},
 {a:'rupture',b:'daimon',name:'VERBO DE RUPTURA',desc:'Pulso pode critar e repetir.'}
];
D.talents={
 vitality:{name:'Sopro Vital',desc:'+8% de vida inicial por nível'},
 power:{name:'Potência',desc:'+7% de dano inicial por nível'},
 fortune:{name:'Fortuna',desc:'+3% de coleta e crítico por nível'}
};
D.defaultMeta=()=>({version:3,essence:0,bestWave:0,bestLevel:0,runs:0,victories:0,unlockedAct:1,selectedAct:1,talents:{vitality:0,power:0,fortune:0},collection:[],seenEvents:[]});
D.rankColor={rare:'#69d8ff',epic:'#e98aff',legend:'#ffe36d'};
root.HarunSurvivorData=Object.freeze(D);
})(typeof globalThis!=='undefined'?globalThis:window);