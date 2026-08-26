import fs from 'node:fs';

const files=['dist/index.html','dist/oraculo.html'];
const runtime=`<style id="h93-v12-birth-numerology-style">
.h93-birth-note{margin:6px 0 0;color:#9fb1b6;font-size:12px;line-height:1.45}.h93-numerology-preview{margin:18px 0;padding:16px 17px;border:1px solid rgba(214,177,90,.24);border-radius:14px;background:linear-gradient(135deg,rgba(214,177,90,.07),rgba(128,86,199,.06));color:#d9d0dd}.h93-numerology-preview b{display:block;color:#f4dfaa;margin-bottom:7px}.h93-numerology-preview span{color:#aebdc0;font-size:12px;line-height:1.55}
</style>
<script id="h93-v12-birth-numerology">
(function(){
'use strict';
var H93_V12_BIRTH_NUMEROLOGY_RUNTIME=true;
function pad(n){return String(n).padStart(2,'0')}
function isoLocal(d){return d.getFullYear()+'-'+pad(d.getMonth()+1)+'-'+pad(d.getDate())}
function cutoff(now){var d=new Date(now||Date.now());return isoLocal(new Date(d.getFullYear()-18,d.getMonth(),d.getDate()))}
function parseBirth(v){var m=/^(\\d{4})-(\\d{2})-(\\d{2})$/.exec(String(v||''));if(!m)return null;var y=Number(m[1]),mo=Number(m[2]),da=Number(m[3]);if(y<1900||mo<1||mo>12||da<1||da>31)return null;var d=new Date(y,mo-1,da);if(d.getFullYear()!==y||d.getMonth()!==mo-1||d.getDate()!==da)return null;return{year:y,month:mo,day:da,date:d}}
function validateBirth(v,nowValue){var p=parseBirth(v),now=nowValue?new Date(nowValue):new Date();if(!p||!Number.isFinite(now.getTime()))return{valid:false,reason:'invalid_date',age:null};var today=new Date(now.getFullYear(),now.getMonth(),now.getDate());if(p.date>today)return{valid:false,reason:'future_date',age:null};var age=today.getFullYear()-p.year;if(today.getMonth()+1<p.month||(today.getMonth()+1===p.month&&today.getDate()<p.day))age--;if(age<18)return{valid:false,reason:'under_18',age:age};return{valid:true,reason:'ok',age:age,iso:String(v)}}
function reduce(n){var x=Math.abs(Math.trunc(Number(n)||0));while(x>9&&[11,22,33].indexOf(x)<0)x=String(x).split('').reduce(function(a,d){return a+Number(d)},0);return x}
function nameNumbers(name){var text=String(name||'').normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').toUpperCase().replace(/[^A-Z]/g,''),vowels={A:1,E:1,I:1,O:1,U:1},all=0,soul=0,personality=0;for(var i=0;i<text.length;i++){var n=((text.charCodeAt(i)-65)%9)+1;all+=n;if(vowels[text[i]])soul+=n;else personality+=n}return{expression:reduce(all),soul_urge:reduce(soul),personality:reduce(personality)}}
function axis(n){var map={1:'iniciativa e decisão',2:'equilíbrio e cooperação',3:'expressão e criação de valor',4:'estrutura e disciplina',5:'movimento e adaptação',6:'responsabilidade e sustentação',7:'análise e profundidade',8:'gestão e poder material',9:'visão ampla e fechamento de ciclos',11:'intuição e direção',22:'construção e escala',33:'responsabilidade e serviço'};return map[n]||'organização e consciência material'}
function numerology(name,birth,nowValue){var chk=validateBirth(birth,nowValue);if(!chk.valid)return null;var p=parseBirth(birth),digits=String(birth).replace(/\\D/g,''),life=reduce(digits.split('').reduce(function(a,d){return a+Number(d)},0)),now=nowValue?new Date(nowValue):new Date(),yearSum=String(now.getFullYear()).split('').reduce(function(a,d){return a+Number(d)},0),base=nameNumbers(name);return{name:String(name||'').trim(),birth:String(birth),life_path:life,birthday:reduce(p.day),personal_year:reduce(p.month+p.day+yearSum),expression:base.expression,soul_urge:base.soul_urge,personality:base.personality,financial_axis:axis(life),framework:'pitagorico_simbolico',calculated_at_year:now.getFullYear()}}
function state(){return window.__H93_GET_STATE&&window.__H93_GET_STATE()}
function save(){if(window.__H93_SAVE_STATE)window.__H93_SAVE_STATE()}
function message(reason){return reason==='under_18'?'Esta experiência é destinada somente a pessoas com 18 anos completos ou mais.':reason==='future_date'?'A data de nascimento não pode estar no futuro.':'Informe uma data de nascimento real e válida.'}
function sync(){var s=state(),birth=document.getElementById('birth'),name=document.getElementById('name');if(!s||!birth)return null;var check=validateBirth(birth.value);if(!check.valid)return null;var snap=numerology(name?name.value:(s.lead&&s.lead.name||''),birth.value);if(snap){s.financialNumerology=snap;save()}return snap}
function configureBirth(){var el=document.getElementById('birth');if(!el)return;el.type='date';el.min='1900-01-01';el.max=cutoff();el.setAttribute&&el.setAttribute('data-h93-birth','1');if(el.dataset)el.dataset.h93Birth='1';if(!el.dataset||!el.dataset.h93AgeGuard){if(el.dataset)el.dataset.h93AgeGuard='1';var check=function(){var r=validateBirth(el.value);if(el.setCustomValidity)el.setCustomValidity(el.value&&!r.valid?message(r.reason):'');if(r.valid)sync()};el.addEventListener&&el.addEventListener('input',check);el.addEventListener&&el.addEventListener('change',check)}if(!document.getElementById('h93BirthNote')&&el.insertAdjacentElement){var note=document.createElement('div');note.id='h93BirthNote';note.className='h93-birth-note';note.textContent='Somente para maiores de 18 anos. Nome e nascimento também compõem uma camada numerológica financeira simbólica da leitura.';el.insertAdjacentElement('afterend',note)}}
function preview(){var s=state(),app=document.getElementById('app');if(!s||!app||Number(s.step)<20||!s.financialNumerology||app.querySelector&&app.querySelector('.h93-numerology-preview'))return;var n=s.financialNumerology,box=document.createElement('div');box.className='h93-numerology-preview';box.innerHTML='<b>Camada numerológica financeira integrada</b><span>Caminho de vida '+String(n.life_path)+' · Expressão '+String(n.expression)+' · Ano pessoal '+String(n.personal_year)+' · eixo simbólico: '+String(n.financial_axis)+'. Esta camada será cruzada com o Tarot e suas respostas, sem tratar numerologia como previsão financeira.</span>';var content=app.querySelector&&app.querySelector('.content');if(content&&content.firstChild)content.insertBefore(box,content.firstChild);else if(content)content.appendChild(box)}
function wrapSaveLead(){if(typeof window.saveLead!=='function'||window.saveLead.__h93BirthWrapped)return;var original=window.saveLead;var wrapped=function(){var el=document.getElementById('birth'),r=validateBirth(el&&el.value);if(!r.valid){var msg=message(r.reason);if(el&&el.setCustomValidity)el.setCustomValidity(msg);if(el&&el.reportValidity)el.reportValidity();alert(msg);return}if(el&&el.setCustomValidity)el.setCustomValidity('');sync();var out=original.apply(this,arguments);sync();setTimeout(preview,0);return out};wrapped.__h93BirthWrapped=true;window.saveLead=wrapped}
function install(){configureBirth();wrapSaveLead();preview()}
window.__H93_VALIDATE_BIRTH=validateBirth;window.__H93_FINANCIAL_NUMEROLOGY=numerology;
install();var app=document.getElementById('app');if(app&&typeof MutationObserver!=='undefined'){new MutationObserver(function(){install()}).observe(app,{childList:true,subtree:true})}var tries=0,t=setInterval(function(){install();if(++tries>200)clearInterval(t)},50);
})();
</script>`;

for(const file of files){
  let html=fs.readFileSync(file,'utf8');
  if(html.includes('id="h93-v12-birth-numerology"'))throw new Error('Birth/numerology runtime duplicado em '+file);
  const birth=/<input\b([^>]*\bid=["']birth["'][^>]*)>/i;
  if(!birth.test(html))throw new Error('Campo birth não localizado em '+file);
  html=html.replace(birth,(whole,attrs)=>{
    let a=attrs.replace(/\sdata-h93-birth(?:=["'][^"']*["'])?/gi,'').replace(/\smin=["'][^"']*["']/gi,'').replace(/\smax=["'][^"']*["']/gi,'');
    return '<input'+a+' data-h93-birth="1" min="1900-01-01">';
  });
  const ctx="desired_depth:s.product&&s.product.id||''}}";
  if(!html.includes(ctx))throw new Error('Contexto V12 não localizado em '+file);
  html=html.replace(ctx,"desired_depth:s.product&&s.product.id||'',financial_numerology:s.financialNumerology||null}}");
  const body=html.lastIndexOf('</body>');if(body<0)throw new Error('body final ausente em '+file);
  html=html.slice(0,body)+runtime+'\n'+html.slice(body);
  fs.writeFileSync(file,html);
}
console.log('H93 V12 birth 18+ and financial numerology applied');
