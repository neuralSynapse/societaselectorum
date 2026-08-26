import fs from 'node:fs';

const files=['dist/index.html','dist/oraculo.html'];
const runtime=`<script id="h93-v12-persistence">
(function(){
'use strict';
var H93_OF_001_V12_PROGRESS_RUNTIME=true;
var installed=false,observer=null,restoreQueued=false;
function state(){return window.__H93_GET_STATE&&window.__H93_GET_STATE()}
function save(){if(window.__H93_SAVE_STATE)window.__H93_SAVE_STATE()}
function app(){return document.getElementById('app')}
function draftKey(el){var id=String(el&&el.id||'').trim(),name=String(el&&el.name||'').trim();return id?'id:'+id:name?'name:'+name:''}
function isField(el){return !!(el&&el.tagName&&/^(INPUT|TEXTAREA|SELECT)$/.test(String(el.tagName).toUpperCase()))}
function ensureDrafts(s){if(!s.__h93Drafts||typeof s.__h93Drafts!=='object'||Array.isArray(s.__h93Drafts))s.__h93Drafts={};return s.__h93Drafts}
function captureOne(el){if(!isField(el))return;var root=app();if(root&&root.contains&&!root.contains(el))return;var key=draftKey(el);if(!key)return;var s=state();if(!s)return;var drafts=ensureDrafts(s),type=String(el.type||'').toLowerCase();drafts[key]={value:String(el.value==null?'':el.value),checked:type==='checkbox'||type==='radio'?!!el.checked:undefined,type:type||String(el.tagName||'').toLowerCase()};s.__h93ScrollY=Math.max(0,Number(window.scrollY||0));save()}
function captureAll(){var root=app(),s=state();if(!root||!s)return;ensureDrafts(s);var fields=root.querySelectorAll?root.querySelectorAll('input[id],input[name],textarea[id],textarea[name],select[id],select[name]'):[];for(var i=0;i<fields.length;i++)captureOne(fields[i]);s.__h93ScrollY=Math.max(0,Number(window.scrollY||0));save()}
function restoreNow(){restoreQueued=false;var root=app(),s=state();if(!root||!s)return;var drafts=ensureDrafts(s),fields=root.querySelectorAll?root.querySelectorAll('input[id],input[name],textarea[id],textarea[name],select[id],select[name]'):[];for(var i=0;i<fields.length;i++){var el=fields[i],d=drafts[draftKey(el)];if(!d)continue;var type=String(el.type||'').toLowerCase();if((type==='checkbox'||type==='radio')&&typeof d.checked==='boolean')el.checked=d.checked;if(typeof d.value==='string'&&type!=='checkbox'&&type!=='radio')el.value=d.value}var y=Number(s.__h93ScrollY||0);if(y>0&&window.scrollTo)window.scrollTo(0,y)}
function queueRestore(){if(restoreQueued)return;restoreQueued=true;(window.requestAnimationFrame||function(fn){setTimeout(fn,0)})(restoreNow)}
function unlockTransientCheckout(){var s=state();if(!s)return false;var changed=false;if(s.v12CheckoutPending===true){s.v12CheckoutPending=false;changed=true}if(String(s.v12CheckoutRequestId||'')){s.v12CheckoutRequestId='';changed=true}if(changed){save();if(window.__H93_RENDER)window.__H93_RENDER()}return changed}
function onField(e){captureOne(e&&e.target)}
function install(){if(installed||typeof window.__H93_GET_STATE!=='function'||typeof window.__H93_SAVE_STATE!=='function')return;installed=true;unlockTransientCheckout();document.addEventListener('input',onField,true);document.addEventListener('change',onField,true);window.addEventListener('pagehide',captureAll);document.addEventListener('visibilitychange',function(){if(document.visibilityState==='hidden')captureAll()});var root=app();if(root&&typeof MutationObserver!=='undefined'){observer=new MutationObserver(queueRestore);observer.observe(root,{childList:true,subtree:true})}queueRestore()}
var tries=0,timer=setInterval(function(){install();tries++;if(installed||tries>200)clearInterval(timer)},50);
})();
</script>`;

for(const file of files){
  let html=fs.readFileSync(file,'utf8');
  if(html.includes('H93_OF_001_V12_PROGRESS_RUNTIME'))throw new Error(`Persistência V12 já aplicada em ${file}`);
  if(!html.includes("const STATE_KEY='H93_OF_001_V11_2_STATE'"))throw new Error(`Persistência V12: estado base localStorage ausente em ${file}`);
  if(!html.includes('window.__H93_GET_STATE'))throw new Error(`Persistência V12: bridge de estado ausente em ${file}`);
  const pos=html.lastIndexOf('</body>');
  if(pos<0)throw new Error(`Persistência V12: body final ausente em ${file}`);
  html=html.slice(0,pos)+runtime+'\n'+html.slice(pos);
  fs.writeFileSync(file,html);
}

console.log('H93 V12 durable progress applied: existing localStorage state + partial drafts + transient checkout recovery');
