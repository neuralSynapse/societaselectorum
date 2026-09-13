import os, json, time
from playwright.sync_api import sync_playwright
URL='http://127.0.0.1:8765/mundus/harun-survivor/v5.html?debug=1'
BROWSER=os.environ.get('QA_BROWSER')
with sync_playwright() as p:
    browser=p.chromium.launch(headless=True,executable_path=BROWSER or None,args=['--no-sandbox','--autoplay-policy=no-user-gesture-required'])
    page=browser.new_page(viewport={'width':540,'height':960})
    page.goto(URL,wait_until='domcontentloaded');page.wait_for_timeout(1500)
    page.evaluate("HarunV5Progression.setPathForQA({phase:'prelude',index:0,degree:1,degreeIndex:0,completedDegrees:[]})")
    page.wait_for_timeout(100);page.locator('[data-v5-index="0"]').click();page.wait_for_timeout(80);page.locator('#v4Glory [data-v5-glory]').first.click();page.wait_for_timeout(500)
    page.evaluate('HarunSurvivorV4Debug.jumpWave(10)');page.wait_for_timeout(500)
    def snap(label):
        x=page.evaluate('''()=>{const s=HarunSurvivorDebug.getState(),r=s.run;return {state:s.state,wave:r?.wave,waveTime:r?.waveTime,waveDuration:r?.waveDuration,boss:r?.boss?{name:r.boss.name,hp:r.boss.hp,maxHp:r.boss.maxHp}:null,enemies:r?.enemies?.length,deathPending:r?._v5BossDeathPending,cleared:r?._v5BossClearedWave,bossWave:r?._v5BossWave,token:!!r?._v5BossToken,pauseButton:document.querySelector('#pause')?.textContent,upgradeHidden:document.querySelector('#upgrade')?.hidden,eventHidden:document.querySelector('#event')?.hidden}}''')
        print(label,json.dumps(x,ensure_ascii=False))
    snap('BEFORE')
    page.evaluate('HarunSurvivorDebug.getState().run.boss.hp=0')
    for i in range(20):
        page.wait_for_timeout(50);snap(f'T+{(i+1)*50}')
    browser.close()
