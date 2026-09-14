import { test, expect } from '@playwright/test';
import fs from 'node:fs';
const BASE='https://project27912.websitepublisher.ai';
const CANON_CONTRACT='1.0.0';
const CANONICAL_STAGES=16;
const cases=[
  {id:'chronica-3d',sentinelId:'chronica-3d',label:'desktop',route:'/chronica-harun-3d.html',viewport:{width:1440,height:900},start:'#action',canvas:'#stage canvas',settle:650,timeout:60000,capture:false,keyboard:false},
  {id:'harun-roguelite',sentinelId:'jogo-3-roguelite-evolved',label:'desktop',route:'/harun-roguelite.html',viewport:{width:1280,height:720},start:'#start',canvas:'#game',settle:1500,timeout:45000,capture:true,keyboard:true},
  {id:'harun-roguelite',sentinelId:'jogo-3-roguelite-evolved',label:'mobile',route:'/harun-roguelite.html',viewport:{width:390,height:844},start:'#start',canvas:'#game',settle:1500,timeout:45000,capture:true,keyboard:false},
  {id:'harun-survivor',sentinelId:'harun-survivor',label:'mobile',route:'/harun-survivor.html',viewport:{width:390,height:844},start:'#startQuick',canvas:'#game',settle:1500,timeout:45000,capture:true,keyboard:true},
  {id:'harun-survivor',sentinelId:'harun-survivor',label:'desktop-compat',route:'/harun-survivor.html',viewport:{width:1280,height:720},start:'#startQuick',canvas:'#game',settle:1500,timeout:45000,capture:true,keyboard:true},
];
const perf=[];
for(const cfg of cases){
  test(`${cfg.id} ${cfg.label} boots, matches immutable shared contract and accepts primary interaction`,async({page})=>{
    test.setTimeout(cfg.timeout);
    await page.setViewportSize(cfg.viewport);
    const fatal=[],failed=[];
    page.on('pageerror',e=>fatal.push(`pageerror:${e.message}`));
    page.on('console',m=>{if(m.type()==='error')fatal.push(`console:${m.text()}`)});
    page.on('requestfailed',r=>failed.push(`${r.url()} :: ${r.failure()?.errorText||'failed'}`));
    await page.addInitScript(()=>{
      window.__MUNDUS_ASYNC_ERRORS__=[];
      addEventListener('error',e=>window.__MUNDUS_ASYNC_ERRORS__.push(`error:${e.message||'unknown'}`));
      addEventListener('unhandledrejection',e=>window.__MUNDUS_ASYNC_ERRORS__.push(`unhandledrejection:${String(e.reason?.message||e.reason||'unknown')}`));
    });
    const started=Date.now();
    const response=await page.goto(BASE+cfg.route,{waitUntil:'domcontentloaded',timeout:30000});
    expect(response?.status()).toBeLessThan(400);
    await expect(page.locator(cfg.canvas)).toBeVisible();
    await page.waitForFunction(()=>Boolean(window.__MUNDUS_SENTINEL__?.gameId),null,{timeout:12000});
    const sentinelReadyMs=Date.now()-started;
    const canon=await page.evaluate(()=>window.__MUNDUS_SENTINEL__);
    expect(canon?.gameId,JSON.stringify(canon)).toBe(cfg.sentinelId);
    expect(canon?.institutionalWrite ?? canon?.qa?.institutionalWrite ?? false).toBe(false);
    expect(canon?.canonContract,JSON.stringify(canon)).toBe(CANON_CONTRACT);
    expect(canon?.canonicalStages,JSON.stringify(canon)).toBe(CANONICAL_STAGES);
    if(cfg.id==='harun-roguelite'){
      expect(canon?.floors).toBe(16);
      expect(canon?.primaryRooms).toBe(112);
    }
    if(cfg.id==='harun-survivor'){
      expect(canon?.degrees).toBe(33);
      expect(canon?.tarot).toBe(78);
    }
    if(cfg.capture)await page.screenshot({path:`artifacts/${cfg.id}-${cfg.label}-boot.png`});
    const start=page.locator(cfg.start);
    await expect(start).toBeVisible();
    if(cfg.id==='chronica-3d'){
      const before=(await page.locator('#title').textContent())?.trim();
      await start.click({force:true,timeout:20000});
      await expect.poll(async()=>((await page.locator('#title').textContent())||'').trim(),{timeout:12000}).not.toBe(before);
      await page.waitForFunction(()=>window.__chronicaReady===true,null,{timeout:20000});
      const retry=page.getByText('TENTAR NOVAMENTE',{exact:true});
      expect(await retry.count()).toBe(0);
    }else{
      await start.click({force:true});
      if(cfg.id==='harun-roguelite'){
        for(let i=0;i<4;i++){
          await page.waitForTimeout(180);
          if(await start.isVisible().catch(()=>false))await start.click({force:true});
        }
      }
      if(cfg.keyboard){await page.keyboard.press('KeyW').catch(()=>{});await page.keyboard.press('KeyE').catch(()=>{});}
    }
    await page.waitForTimeout(cfg.settle);
    if(cfg.capture)await page.screenshot({path:`artifacts/${cfg.id}-${cfg.label}-after-input.png`});
    const asyncErrors=await page.evaluate(()=>window.__MUNDUS_ASYNC_ERRORS__||[]);
    const nav=await page.evaluate(()=>{const n=performance.getEntriesByType('navigation')[0];return n?{domContentLoaded:n.domContentLoadedEventEnd,loadEventEnd:n.loadEventEnd,transferSize:n.transferSize,decodedBodySize:n.decodedBodySize}:{};});
    perf.push({gameId:cfg.id,label:cfg.label,viewport:cfg.viewport,sentinelReadyMs,...nav});
    fs.writeFileSync('artifacts/browser-performance.json',JSON.stringify(perf,null,2));
    const criticalFailed=failed.filter(x=>/chronica-|harun-|three|cdn\.websitepublisher|cdn\.jsdelivr/i.test(x));
    expect(fatal,fatal.join('\n')).toEqual([]);
    expect(asyncErrors,asyncErrors.join('\n')).toEqual([]);
    expect(criticalFailed,criticalFailed.join('\n')).toEqual([]);
  });
}
