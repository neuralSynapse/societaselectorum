import json, os, statistics, traceback
from pathlib import Path
from playwright.sync_api import sync_playwright

OUT=Path(os.environ.get('QA_OUT','/tmp/harun-survivor-v6-qa')); OUT.mkdir(parents=True,exist_ok=True)
URL=os.environ.get('QA_URL','http://127.0.0.1:8765/mundus/harun-survivor/v6.html?debug=1')
BROWSER=os.environ.get('QA_BROWSER')
checks=[]; errors=[]; failure=None

def check(name, ok, detail=''):
    checks.append({'name':name,'ok':bool(ok),'detail':detail})
    if not ok: raise AssertionError(f'{name}: {detail}')

def fps_samples(page, n=3, ms=850):
    vals=[float(page.evaluate(f'HarunSurvivorV4Debug.measureFps({ms})')) for _ in range(n)]
    return {'samples':vals,'median':statistics.median(vals),'min':min(vals),'max':max(vals)}

try:
  with sync_playwright() as p:
    browser=p.chromium.launch(headless=True,executable_path=BROWSER or None,args=['--no-sandbox','--autoplay-policy=no-user-gesture-required'])
    page=browser.new_page(viewport={'width':390,'height':844},device_scale_factor=1)
    page.add_init_script("localStorage.clear()")
    page.on('pageerror',lambda exc: errors.append('pageerror: '+str(exc)))
    page.on('console',lambda msg: errors.append('console: '+msg.text) if msg.type=='error' else None)
    page.goto(URL,wait_until='domcontentloaded',timeout=30000); page.wait_for_timeout(1800)

    names=['HarunSurvivorDebug','HarunSurvivorV4Debug','HarunV5Progression','HarunV5Systems','HarunV5World','HarunV6Art','HarunV6Feel','HarunV6Companions','HarunV6HUD','HarunV6Events','HarunV6Meta']
    boot=page.evaluate('(n)=>Object.fromEntries(n.map(x=>[x,!!window[x]]))',names)
    check('all-v6-modules-booted',all(boot.values()),boot)
    check('v6-art-version',page.evaluate("HarunV6Art.version==='6.0.0'"))
    rect=page.locator('.frame').bounding_box(); check('mobile-fullbleed-390x844',rect and rect['height']>=838,(rect,844))
    check('no-horizontal-overflow',page.evaluate('document.documentElement.scrollWidth<=document.documentElement.clientWidth+1'))
    check('meta-visible-on-menu',page.locator('#v6Meta:not([hidden])').count()==1)
    check('meta-five-nav-tabs',page.locator('#v6MetaNav [data-v6tab]').count()==5,page.locator('#v6MetaNav [data-v6tab]').count())
    page.screenshot(path=str(OUT/'v6-meta-campaign-390x844.png'),full_page=True)

    page.locator('#v6Meta [data-action="play"]').click(); page.wait_for_timeout(180)
    check('meta-hides-for-glory',page.locator('#v6Meta[hidden]').count()==1)
    check('glory-visible-from-meta-play',page.locator('#v4Glory:not([hidden])').count()==1)
    page.locator('#v4Glory [data-v5-glory]').first.click(); page.wait_for_timeout(650)
    st=page.evaluate('HarunSurvivorDebug.getState()'); check('run-started',st['state']=='run',st['state'])
    check('movement-speed-floor',st['run']['player']['speed']>=242,st['run']['player']['speed'])
    x0=page.evaluate('HarunSurvivorDebug.getState().run.player.x'); page.keyboard.down('KeyD'); page.wait_for_timeout(360); page.keyboard.up('KeyD'); x1=page.evaluate('HarunSurvivorDebug.getState().run.player.x')
    check('movement-real-displacement',x1-x0>=75,(x0,x1,x1-x0))

    page.evaluate('''()=>{const S=HarunV5Systems; for(const f of S.familiars.slice(0,3)) S.gain('familiars',f)}'''); page.wait_for_timeout(300)
    check('three-familiar-bodies',page.evaluate('HarunV6Companions.bodyCount()>=3'),page.evaluate('HarunV6Companions.bodyCount()'))
    check('v6-companion-canvas-visible',page.locator('#v6Companions').count()==1)

    page.evaluate("HarunV6Feel.pushText('hit',270,420,12);HarunV6Feel.pushText('crit',280,400,27);HarunV6Feel.pushText('heal',260,440,4);HarunV6Feel.pushText('block',250,450,0)"); page.wait_for_timeout(80)
    fstats=page.evaluate('HarunV6Feel.stats()')
    check('damage-feedback-channels',all(fstats.get(k,0)>=1 for k in ['hit','crit','heal','block']),fstats)
    check('floating-feedback-visible',page.locator('.v6-floating').count()>=4,page.locator('.v6-floating').count())
    page.screenshot(path=str(OUT/'v6-gameplay-familiars-390x844.png'),full_page=True)

    page.locator('#pause').click(); page.wait_for_timeout(100)
    check('v6-pause-visible',page.locator('#v6Pause:not([hidden])').count()==1)
    check('pause-skill-grid-exists',page.locator('#v6PauseSkills').count()==1)
    page.screenshot(path=str(OUT/'v6-pause-390x844.png'),full_page=True)
    page.locator('#v6Pause .resume').click(); page.wait_for_timeout(120)

    page.evaluate('HarunV5Systems.chooseTarot()'); page.wait_for_timeout(180)
    check('choice-opened',page.locator('#v5Choice:not([hidden])').count()==1)
    check('cinematic-reveal-applied',page.locator('#v5Choice .v6-reveal-card').count()>=3,page.locator('#v5Choice .v6-reveal-card').count())
    page.screenshot(path=str(OUT/'v6-card-reveal-390x844.png'),full_page=True)
    page.locator('#v5Choice [data-tarot]').first.click(); page.wait_for_timeout(160)

    page.evaluate('HarunSurvivorV4Debug.jumpWave(10)'); page.wait_for_timeout(180)
    check('danger-sequence-visible',page.locator('#danger:not([hidden])').count()==1)
    page.wait_for_timeout(450)
    b=page.evaluate('HarunSurvivorDebug.getState().run.boss'); check('boss-present',b is not None,b)
    check('boss-wave-not-paused',page.locator('#pause').inner_text()=='Ⅱ',page.locator('#pause').inner_text())
    page.evaluate('HarunSurvivorDebug.getState().run.boss.hp=0')
    page.wait_for_function('HarunSurvivorDebug.getState().run.wave>=11',timeout=4000); page.wait_for_timeout(180)
    post=page.evaluate('''()=>{const s=HarunSurvivorDebug.getState();return {wave:s.run.wave,boss:s.run.boss?{name:s.run.boss.name,hp:s.run.boss.hp}:null}}''')
    check('boss-single-life',post['wave']>=11 and post['boss'] is None,post)

    page.evaluate('''()=>{document.querySelector('#event').hidden=true;HarunSurvivorDebug.startRun(1)}'''); page.wait_for_timeout(250)
    page.evaluate('HarunSurvivorDebug.getState().run.wave=7'); page.evaluate("HarunSurvivorDebug.showMenu('campaign')"); page.wait_for_timeout(180)
    check('end-run-summary-visible',page.locator('#v6End:not([hidden])').count()==1)
    check('end-run-confetti',page.locator('#v6End .v6-confetti').count()>=30,page.locator('#v6End .v6-confetti').count())
    page.screenshot(path=str(OUT/'v6-end-run-390x844.png'),full_page=True)
    page.locator('#v6End').click(); page.wait_for_timeout(120)

    before=page.evaluate('HarunV6Meta.state()'); claimed=page.evaluate('HarunV6Meta.claimCheckin(1)'); after=page.evaluate('HarunV6Meta.state()')
    check('checkin-claim-works',claimed and 1 in after['checkin'],(claimed,before.get('checkin'),after.get('checkin')))
    page.reload(wait_until='domcontentloaded'); page.wait_for_timeout(1000)
    check('checkin-persists',page.evaluate('HarunV6Meta.state().checkin.includes(1)'))

    page.set_viewport_size({'width':430,'height':932}); page.wait_for_timeout(180)
    rect2=page.locator('.frame').bounding_box(); check('mobile-fullbleed-430x932',rect2 and rect2['height']>=926,(rect2,932))
    page.screenshot(path=str(OUT/'v6-meta-430x932.png'),full_page=True)

    page.evaluate('HarunSurvivorDebug.startRun(1)'); page.wait_for_timeout(350); page.evaluate('HarunSurvivorV4Debug.stress(28)'); page.wait_for_timeout(200); v6=fps_samples(page)
    v5=browser.new_page(viewport={'width':390,'height':844},device_scale_factor=1); v5.add_init_script("localStorage.clear()"); v5.goto(URL.replace('/v6.html','/v5.html'),wait_until='domcontentloaded'); v5.wait_for_timeout(1000); v5.evaluate('HarunSurvivorDebug.startRun(1)'); v5.wait_for_timeout(300); v5.evaluate('HarunSurvivorV4Debug.stress(28)'); v5.wait_for_timeout(200); v5fps=fps_samples(v5); v5.close()
    ratio=v6['median']/max(1.0,v5fps['median']); perf={'v6':v6,'v5':v5fps,'ratio':ratio}
    (OUT/'performance-v6-v5.json').write_text(json.dumps(perf,ensure_ascii=False,indent=2),encoding='utf-8')
    check('stress-fps-floor',v6['median']>=30,perf)
    check('stress-no-material-v5-regression',ratio>=.72,perf)
    check('no-js-errors',len(errors)==0,errors)
    browser.close()
except Exception as exc:
    failure=f'{type(exc).__name__}: {exc}'
    (OUT/'exception.txt').write_text(failure+'\n'+traceback.format_exc(),encoding='utf-8')

report={'status':'PASS' if failure is None and all(x['ok'] for x in checks) and not errors else 'FAIL','checks':checks,'errors':errors,'failure':failure}
(OUT/'qa-report-v6.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
if report['status']!='PASS': raise SystemExit(1)
