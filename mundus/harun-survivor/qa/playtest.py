import json, os, sys, time
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE=os.environ.get('QA_URL','http://127.0.0.1:8765/mundus/harun-survivor/index.html')
BROWSER=os.environ.get('QA_BROWSER') or '/usr/bin/google-chrome'
OUT=Path(os.environ.get('QA_OUT','/tmp/harun-survivor-qa'))
OUT.mkdir(parents=True,exist_ok=True)
results=[]
errors=[]

def check(name, cond, detail=''):
    row={'name':name,'ok':bool(cond),'detail':str(detail)}; results.append(row)
    if not cond: raise AssertionError(f'{name}: {detail}')

def state(page):
    return page.evaluate("""()=>{const s=window.HarunSurvivorDebug.getState();return {state:s.state,meta:s.meta,run:s.run&&{wave:s.run.wave,level:s.run.level,coins:s.run.coins,skills:s.run.skills,synergies:s.run.synergies,enemies:s.run.enemies.length,shots:s.run.shots.length,gems:s.run.gems.length,boss:!!s.run.boss,hp:s.run.player.hp,maxHp:s.run.player.maxHp,x:s.run.player.x,y:s.run.player.y}}}""")

try:
  with sync_playwright() as p:
    browser=p.chromium.launch(headless=True, executable_path=BROWSER, args=['--no-sandbox','--disable-dev-shm-usage','--disable-gpu'])
    ctx=browser.new_context(viewport={'width':540,'height':960}, device_scale_factor=1)
    page=ctx.new_page()
    page.on('pageerror',lambda e: errors.append('pageerror:'+str(e)))
    page.on('console',lambda m: errors.append('console:'+m.text) if m.type=='error' else None)
    page.goto(BASE+'?autoplay=1&debug=1',wait_until='domcontentloaded',timeout=20000)
    page.wait_for_function("window.HarunSurvivorDebug && window.HarunSurvivorDebug.getState().state==='run'",timeout=10000)
    page.wait_for_timeout(400)
    s=state(page); check('boot run',s['state']=='run',s['state']); check('wave 1',s['run']['wave']==1,s['run']['wave']); check('hp valid',s['run']['hp']>0 and s['run']['hp']<=s['run']['maxHp'],s['run'])
    canvas=page.locator('#game'); box=canvas.bounding_box(); check('canvas rendered',box and box['height']>=900,box)
    page.screenshot(path=str(OUT/'01-boot.png'),full_page=True)

    x0=state(page)['run']['x']; page.keyboard.down('d'); page.wait_for_timeout(320); page.keyboard.up('d'); page.wait_for_timeout(80); x1=state(page)['run']['x']; check('keyboard movement',x1>x0+8,f'{x0}->{x1}')

    page.evaluate("""()=>{const s=HarunSurvivorDebug.getState(),p=s.run.player;p.damage=100;p.fireRate=.04;s.run.enemies.length=0;s.run.gems.length=0;s.run.enemies.push({kind:'crawler',x:p.x,y:p.y-70,r:11,hp:1,maxHp:1,speed:0,damage:0,xp:1,phase:0,hit:0,cd:9,charge:9,poison:0,burn:0})}""")
    page.wait_for_function("HarunSurvivorDebug.getState().run.enemies.length===0",timeout=3000)
    s=state(page); check('autoattack combat',s['run']['enemies']==0,s['run']); check('combat drop',s['run']['gems']>0 or s['run']['level']>1,s['run'])

    page.evaluate("""()=>{const s=HarunSurvivorDebug.getState(),p=s.run.player;s.run.gems.push({x:p.x,y:p.y,big:true,xp:s.run.xpNeed+3})}""")
    page.wait_for_function("HarunSurvivorDebug.getState().state==='upgrade'",timeout=3000)
    check('upgrade overlay',page.locator('#upgrade').is_visible()); check('three cards',page.locator('#cards [data-skill]').count()==3,page.locator('#cards [data-skill]').count())
    page.screenshot(path=str(OUT/'02-upgrade.png'),full_page=True)
    page.locator('#cards [data-skill]').first.click(); page.wait_for_function("HarunSurvivorDebug.getState().state==='run'",timeout=2000)
    s=state(page); check('skill applied',len(s['run']['skills'])==1,s['run']['skills'])

    page.evaluate("HarunSurvivorDebug.getState().meta.essence=100;HarunSurvivorDebug.showMenu('talents')")
    page.wait_for_timeout(100); first=page.locator('[data-buy]').first; check('talent button',first.count()==1); key=first.get_attribute('data-buy'); before=page.evaluate(f"HarunSurvivorDebug.getState().meta.talents['{key}']||0"); first.click(); page.wait_for_timeout(120); after=page.evaluate(f"HarunSurvivorDebug.getState().meta.talents['{key}']||0"); check('talent purchase',after==before+1,f'{before}->{after}')

    page.evaluate("HarunSurvivorDebug.getState().meta.essence=100;HarunSurvivorDebug.showMenu('roulette')")
    page.locator('#spin').click(); page.wait_for_timeout(1750); roulette=page.locator('#rouletteCopy').inner_text(); check('roulette resolves','ESSÊNCIA' in roulette,roulette)

    page.evaluate("HarunSurvivorDebug.startRun(1)"); page.wait_for_timeout(80)
    page.evaluate("""()=>{const s=HarunSurvivorDebug.getState();s.run.wave=9;s.run.waveDuration=.05;s.run.waveTime=.06;s.run.enemies.length=0}""")
    page.wait_for_function("HarunSurvivorDebug.getState().run.wave===10 && HarunSurvivorDebug.getState().run.boss",timeout=2500)
    s=state(page); check('boss wave',s['run']['wave']==10,s['run']['wave']); check('boss spawned',s['run']['boss']); page.screenshot(path=str(OUT/'03-boss.png'),full_page=True)
    page.evaluate("""()=>{const s=HarunSurvivorDebug.getState(),p=s.run.player;p.damage=999;p.fireRate=.02;s.run.boss.x=p.x;s.run.boss.y=p.y-65;s.run.boss.hp=.01}""")
    page.wait_for_function("!HarunSurvivorDebug.getState().run.boss",timeout=3000)
    s=state(page); check('boss defeated',not s['run']['boss']); check('act II unlocked',s['meta']['unlockedAct']>=2,s['meta']['unlockedAct'])

    saved=page.evaluate("JSON.parse(localStorage.getItem('mundus_harun_survivor_v3')||'{}')"); check('save persisted',saved.get('unlockedAct',0)>=2 and saved.get('talents',{}).get(key,0)>=1,saved)
    page.reload(wait_until='domcontentloaded'); page.wait_for_function("window.HarunSurvivorDebug",timeout=5000); restored=page.evaluate("HarunSurvivorDebug.getState().meta"); check('save restores after reload',restored.get('unlockedAct',0)>=2 and restored.get('talents',{}).get(key,0)>=1,restored)

    mobile=ctx.new_page(); mobile.set_viewport_size({'width':390,'height':844}); mobile.goto(BASE,wait_until='domcontentloaded',timeout=15000); mobile.wait_for_function("window.HarunSurvivorDebug",timeout=5000); mobile.wait_for_timeout(250)
    dims=mobile.evaluate("()=>({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,frame:document.querySelector('.frame').getBoundingClientRect().width,menu:!document.querySelector('#menu').hidden})")
    check('mobile no horizontal overflow',dims['sw']<=dims['cw']+1,dims); check('mobile frame fits',dims['frame']<=391,dims); check('mobile menu visible',dims['menu'],dims)
    mobile.screenshot(path=str(OUT/'04-mobile-menu.png'),full_page=True)

    page.goto(BASE+'?autoplay=1&debug=1',wait_until='domcontentloaded',timeout=15000); page.wait_for_function("window.HarunSurvivorDebug && HarunSurvivorDebug.getState().state==='run'",timeout=5000); page.wait_for_timeout(2200); s=state(page); check('entity cap respected',s['run']['enemies']<=90,s['run']['enemies']); check('shot count sane',s['run']['shots']<250,s['run']['shots'])
    check('no runtime JS errors',len(errors)==0,errors)
    browser.close()
except Exception as exc:
  report={'status':'FAIL','error':repr(exc),'results':results,'runtime_errors':errors}
  (OUT/'qa-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
  print(json.dumps(report,ensure_ascii=False,indent=2)); sys.exit(1)

report={'status':'PASS','checks':len(results),'results':results,'runtime_errors':errors}
(OUT/'qa-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
