(function(){
'use strict';
const nativeRAF=window.requestAnimationFrame.bind(window),nativeCAF=window.cancelAnimationFrame.bind(window);let installed=null;
function makeThrottle(hz){const min=1000/Math.max(1,hz);let last=0;function schedule(cb){return nativeRAF(function wrapped(now){if(now-last<min)return schedule(cb);last=now;const prevRAF=window.requestAnimationFrame,prevCAF=window.cancelAnimationFrame;window.requestAnimationFrame=schedule;window.cancelAnimationFrame=nativeCAF;try{cb(now)}finally{window.requestAnimationFrame=prevRAF;window.cancelAnimationFrame=prevCAF}})}return schedule}
function install(hz){if(installed)restore();installed={raf:window.requestAnimationFrame,caf:window.cancelAnimationFrame,hz};window.requestAnimationFrame=makeThrottle(hz);window.cancelAnimationFrame=nativeCAF}
function restore(){if(!installed)return;window.requestAnimationFrame=installed.raf;window.cancelAnimationFrame=installed.caf;installed=null}
window.HarunV5Scheduler=Object.freeze({version:'5.0.0',install,restore,nativeRAF});
})();