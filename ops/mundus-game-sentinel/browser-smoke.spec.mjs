import { test, expect } from '@playwright/test';
import fs from 'node:fs';
const BASE='https://project27912.websitepublisher.ai';
const cases=[
  {id:'chronica-3d',label:'desktop',route:'/chronica-harun-3d.html',viewport:{width:1440,height:900},start:'#action',settle:650,timeout:60000,capture:false,keyboard:false},
  {id:'harun-roguelite',label:'desktop',route:'/harun-roguelite.html',viewport:{width:1280,height:720},start:'#start',settle:1500,timeout:45000,capture:true,keyboard:true},
  {id:'harun-roguelite',label:'mobile',route:'/harun-roguelite.html',viewport:{width:390,height:844},start:'#start',settle:1500,timeout:45000,capture:true,keyboard:false},
  {id:'harun-survivor',label:'mobile',route:'/harun-survivor.html',viewport:{width:390,height:844},start:'#startQuick',settle:1500,timeout:45000,capture:true,keyboard:true},
  {id:'harun-survivor',label:'desktop-compat',route:'/harun-survivor.html',viewport:{width:1280,height:720},start:'#startQuick',settle:1500,timeout:45000,capture:true,keyboard:true},
];
const perf=[];
for(const cfg of cases){
  test(`${cfg.id} ${cfg.label} boots, matches canon and accepts primary interaction`,async({page})=>{
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
    await expect(page.locator('canvas')).toBeVisible();

    await page.waitForFunction(()=>window.__MUNDUS_SENTINEL__?.loaded===true,null,{timeout:12000});
    const sentinelReadyMs=Date.now()-started;
    const canon=await page.evaluate(()=>window.__MUNDUS_SENTINEL__);
    expect(canon?.status,JSON.stringify(canon)).toBe('GREEN');
    expect(canon?.gameId).toBe(cfg.id);

    if(cfg.capture)await page.screenshot({path:`artifacts/${cfg.id}-${cfg.label}-boot.png`});
    const start=page.locator(cfg.start);
    await expect(start).toBeVisible();

    if(cfg.id==='chronica-3d'){
      const before=(await page.locator('#title').textContent())?.trim();
      await start.click({force:true,timeout:20000});
      await expect.poll(async()=>((await page.locator('#title').textContent())||'').trim(),{timeout:10000}).not.toBe(before);
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
      if(cfg.keyboard){
        await page.keyboard.press('KeyW').catch(()=>{});
        await page.keyboard.press('KeyE').catch(()=>{});
      }
    }

    await page.waitForTimeout(cfg.settle);
    if(cfg.capture)await page.screenshot({path:`artifacts/${cfg.id}-${cfg.label}-after-input.png`});
    const asyncErrors=await page.evaluate(()=>window.__MUNDUS_ASYNC_ERRORS__||[]);
    const nav=await page.evaluate(()=>{
      const n=performance.getEntriesByType('navigation')[0];
      return n?{domContentLoaded:n.domContentLoadedEventEnd,loadEventEnd:n.loadEventEnd,transferSize:n.transferSize,decodedBodySize:n.decodedBodySize}:{};
    });
    perf.push({gameId:cfg.id,label:cfg.label,viewport:cfg.viewport,sentinelReadyMs,...nav});
    fs.writeFileSync('artifacts/browser-performance.json',JSON.stringify(perf,null,2));

    const criticalFailed=failed.filter(x=>/chronica-|harun-|three|cdn\.websitepublisher/i.test(x));
    expect(fatal,fatal.join('\n')).toEqual([]);
    expect(asyncErrors,asyncErrors.join('\n')).toEqual([]);
    expect(criticalFailed,criticalFailed.join('\n')).toEqual([]);
  });
}
