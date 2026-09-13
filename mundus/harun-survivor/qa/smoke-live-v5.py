import json, os, time, traceback
from pathlib import Path
from playwright.sync_api import sync_playwright

OUT=Path(os.environ.get('QA_OUT','/tmp/harun-survivor-v5-live'));OUT.mkdir(parents=True,exist_ok=True)
URL=os.environ.get('QA_URL','https://project27912.websitepublisher.ai/harun-survivor-v5.html?debug=1')
BROWSER=os.environ.get('QA_BROWSER');checks=[];errors=[];failure=None

def check(name,ok,detail=''):
    checks.append({'name':name,'ok':bool(ok),'detail':detail})
    if not ok: raise AssertionError(f'{name}: {detail}')

try:
  with sync_playwright() as p:
    browser=p.chromium.launch(headless=True,executable_path=BROWSER or None,args=['--no-sandbox','--autoplay-policy=no-user-gesture-required'])
    page=browser.new_page(viewport={'width':390,'height':844},device_scale_factor=1)
    page.on('pageerror',lambda exc: errors.append('pageerror: '+str(exc)))
    page.on('console',lambda msg: errors.append('console: '+msg.text) if msg.type=='error' else None)
    sep='&' if '?' in URL else '?';url=URL+sep+'smoke='+str(int(time.time()))
    response=page.goto(url,wait_until='domcontentloaded',timeout=45000)
    check('public-http-ok',response is not None and response.ok,None if response is None else response.status)
    page.wait_for_timeout(6500)
    names=['HarunSurvivorDebug','HarunSurvivorV4Debug','HarunV5Progression','HarunV5Systems','HarunV5World','HarunV5Runtime','HarunV5BlackBook','HarunV5Audio','HarunV5Art','HarunV5Companions']
    boot=page.evaluate('(names)=>Object.fromEntries(names.map(n=>[n,!!window[n]]))',names)
    check('public-v5-modules-booted',all(boot.values()),boot)
    check('public-v5-art-5-1',page.evaluate("HarunV5Art.version==='5.1.0'"))
    check('public-thoth-78',page.evaluate('HarunV5Systems.tarot.length')==78,page.evaluate('HarunV5Systems.tarot.length'))
    check('public-mobile-no-overflow',page.evaluate('document.documentElement.scrollWidth<=document.documentElement.clientWidth+1'))

    page.locator('[data-v5-index="0"]').click();page.wait_for_timeout(120)
    check('public-glory-visible',page.locator('#v4Glory:not([hidden])').count()==1)
    page.locator('#v4Glory [data-v5-glory]').first.click();page.wait_for_timeout(700)
    st=page.evaluate('HarunSurvivorDebug.getState()')
    check('public-run-started',st['state']=='run',st['state'])
    check('public-fast-movement',st['run']['player']['speed']>=220,st['run']['player']['speed'])
    x0=page.evaluate('HarunSurvivorDebug.getState().run.player.x');page.keyboard.down('KeyD');page.wait_for_timeout(360);page.keyboard.up('KeyD');x1=page.evaluate('HarunSurvivorDebug.getState().run.player.x')
    check('public-responsive-displacement',x1-x0>=65,(x0,x1,x1-x0))
    floor=page.evaluate('HarunV5World.getFloor()');check('public-floor-ten',isinstance(floor,list) and len(floor)==10,floor)

    page.keyboard.press('Tab');page.wait_for_timeout(120);check('public-tab-map',page.locator('#v5MapOverlay:not([hidden])').count()==1);page.keyboard.press('Tab')
    page.keyboard.press('Escape');page.wait_for_timeout(120);check('public-esc-blackbook',page.locator('#v5BlackBook:not([hidden])').count()==1);page.keyboard.press('Escape')

    page.evaluate('HarunV5Systems.gain("familiars",HarunV5Systems.familiars[0])');page.wait_for_timeout(320)
    check('public-familiar-recorded',page.evaluate('HarunV5Systems.state().familiars.length>=1'))
    check('public-familiar-visible',page.evaluate('HarunV5Companions.visibleCount()>=1'))
    check('public-familiar-canvas',page.locator('#v5Companions').count()==1)
    page.screenshot(path=str(OUT/'public-v5-gameplay-familiar.png'),full_page=True)

    page.mouse.click(260,520);page.wait_for_timeout(400)
    audio=page.evaluate('HarunV5Audio.snapshot()')
    check('public-audio-running',audio and audio.get('game')=='survivor' and audio.get('contextState')=='running',audio)

    page.evaluate('HarunSurvivorV4Debug.jumpWave(10)');page.wait_for_timeout(500)
    check('public-boss-present',page.evaluate('HarunSurvivorDebug.getState().run.boss!==null'))
    check('public-boss-name',page.evaluate("HarunSurvivorDebug.getState().run.boss?.name==='OBSERVADOR CEGO'"))
    check('public-boss-wave-not-paused',page.locator('#pause').inner_text()=='Ⅱ',page.locator('#pause').inner_text())
    page.evaluate('HarunSurvivorDebug.getState().run.boss.hp=0')
    page.wait_for_function('HarunSurvivorDebug.getState().run.wave>=11',timeout=4000)
    page.wait_for_timeout(220)
    after=page.evaluate('''()=>{const s=HarunSurvivorDebug.getState();return {wave:s.run.wave,boss:s.run.boss?{name:s.run.boss.name,hp:s.run.boss.hp}:null,state:s.state}}''')
    check('public-boss-dead-no-respawn',after['wave']>=11 and after['boss'] is None,after)

    page.screenshot(path=str(OUT/'public-v5-mobile.png'),full_page=True)
    check('public-no-js-errors',len(errors)==0,errors)
    browser.close()
except Exception as exc:
  failure=f'{type(exc).__name__}: {exc}'
  (OUT/'exception.txt').write_text(failure+'\n'+traceback.format_exc(),encoding='utf-8')

report={'status':'PASS' if failure is None and all(x['ok'] for x in checks) and not errors else 'FAIL','url':URL,'checks':checks,'errors':errors,'failure':failure}
(OUT/'live-smoke-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
if report['status']!='PASS': raise SystemExit(1)
