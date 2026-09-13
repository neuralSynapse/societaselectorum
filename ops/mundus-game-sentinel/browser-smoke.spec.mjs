import { test, expect } from '@playwright/test';
const BASE='https://project27912.websitepublisher.ai';
const cases=[
  {id:'chronica-3d',route:'/chronica-harun-3d.html',viewport:{width:1440,height:900},start:'#action',settle:9000,timeout:90000},
  {id:'harun-roguelite',route:'/harun-roguelite.html',viewport:{width:1280,height:720},start:'#start',settle:2500,timeout:45000},
  {id:'harun-survivor',route:'/harun-survivor.html',viewport:{width:390,height:844},start:'#startQuick',settle:2500,timeout:45000},
];
for(const cfg of cases){
  test(`${cfg.id} boots and accepts primary input`,async({browser})=>{
    test.setTimeout(cfg.timeout);
    const context=await browser.newContext({viewport:cfg.viewport}); const page=await context.newPage(); const fatal=[],failed=[];
    page.on('pageerror',e=>fatal.push(`pageerror:${e.message}`));
    page.on('console',m=>{if(m.type()==='error')fatal.push(`console:${m.text()}`)});
    page.on('requestfailed',r=>failed.push(`${r.url()} :: ${r.failure()?.errorText||'failed'}`));
    const response=await page.goto(BASE+cfg.route,{waitUntil:'domcontentloaded',timeout:30000}); expect(response?.status()).toBeLessThan(400); await expect(page.locator('canvas')).toBeVisible();
    await page.screenshot({path:`artifacts/${cfg.id}-boot.png`}); const start=page.locator(cfg.start);
    if(await start.count()){await start.first().click({force:true}); if(cfg.id==='harun-roguelite'){for(let i=0;i<4;i++){await page.waitForTimeout(250);if(await start.isVisible().catch(()=>false))await start.click({force:true})}}}
    await page.keyboard.press('KeyW').catch(()=>{}); await page.keyboard.press('KeyE').catch(()=>{}); await page.waitForTimeout(cfg.settle);
    if(cfg.id==='chronica-3d'){const retry=page.getByText('TENTAR NOVAMENTE',{exact:true});expect(await retry.count()).toBe(0)}
    await page.screenshot({path:`artifacts/${cfg.id}-after-input.png`}); const criticalFailed=failed.filter(x=>/chronica-|harun-|three|cdn\.websitepublisher/i.test(x));
    expect(fatal,fatal.join('\n')).toEqual([]); expect(criticalFailed,criticalFailed.join('\n')).toEqual([]); await context.close();
  });
}
