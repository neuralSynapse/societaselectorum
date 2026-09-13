import json, os, traceback
from pathlib import Path
from playwright.sync_api import sync_playwright

OUT=Path(os.environ.get('QA_OUT','/tmp/harun-survivor-v5-qa'));OUT.mkdir(parents=True,exist_ok=True)
URL=os.environ.get('QA_URL','http://127.0.0.1:8765/mundus/harun-survivor/v5.html?debug=1');BROWSER=os.environ.get('QA_BROWSER')
checks=[];errors=[];failure=None

def check(name,ok,detail=''):
    checks.append({'name':name,'ok':bool(ok),'detail':detail})
    if not ok: raise AssertionError(f'{name}: {detail}')

try:
  with sync_playwright() as p:
    browser=p.chromium.launch(headless=True,executable_path=BROWSER or None,args=['--no-sandbox','--autoplay-policy=no-user-gesture-required'])
    page=browser.new_page(viewport={'width':540,'height':960},device_scale_factor=1)
    page.on('pageerror',lambda exc: errors.append(str(exc)))
    page.on('console',lambda msg: errors.append(msg.text) if msg.type=='error' else None)
    page.goto(URL,wait_until='domcontentloaded',timeout=30000);page.wait_for_timeout(1800)
    names=['HarunSurvivorDebug','HarunSurvivorV4Debug','HarunV5Progression','HarunV5Systems','HarunV5World','HarunV5Runtime','HarunV5BlackBook','HarunV5Audio']
    boot=page.evaluate('(names)=>Object.fromEntries(names.map(n=>[n,!!window[n]]))',names)
    (OUT/'boot-diagnostic.json').write_text(json.dumps({'boot':boot,'errors':errors},ensure_ascii=False,indent=2),encoding='utf-8')
    check('all-v5-modules-booted',all(boot.values()),boot)

    prog=page.evaluate('HarunV5Progression.snapshot()')
    check('v5-starts-preingressus',prog['path']['phase']=='prelude',prog['path']);check('preingressus-three-plus-ritual',len(prog['nodes'])==4,[x['name'] for x in prog['nodes']]);check('preingressus-order',[x['id'] for x in prog['nodes'][:3]]==['o_olho','a_chama','a_fundacao'],[x['id'] for x in prog['nodes']]);check('initial-ritual',prog['nodes'][3]['id']=='ritual_inicial',prog['nodes'][3]);check('thirty-three-degrees',len(prog['degrees'])==33,len(prog['degrees']));check('grade-I-peregrinus',prog['degrees'][0]['name']=='Peregrinus Ignis',prog['degrees'][0]['name']);check('grade-XXXIII-ipsissimus',prog['degrees'][32]['name']=='Ipsissimus',prog['degrees'][32]['name'])

    page.evaluate("HarunV5Progression.setPathForQA({phase:'ingressus',index:0,degree:1,degreeIndex:0,completedDegrees:[]})");page.wait_for_timeout(160);prog=page.evaluate('HarunV5Progression.snapshot()');check('ingressus-three-scrolls-plus-actus',len(prog['nodes'])==4,[x['name'] for x in prog['nodes']]);check('horus-three-forms',[x['id'] for x in prog['nodes'][:3]]==['heru_pa_khered','heru_sa_aset','heru_behdeti'],[x['id'] for x in prog['nodes']]);check('actus-ritual',prog['nodes'][3]['id']=='actus_ingressus',prog['nodes'][3])
    page.evaluate("HarunV5Progression.setPathForQA({phase:'student',index:0,degree:1,degreeIndex:0,completedDegrees:[]})");page.wait_for_timeout(160);prog=page.evaluate('HarunV5Progression.snapshot()');expected=['a_eleicao','a_balanca','a_vontade','o_carater','a_disciplina','a_clareza','a_transmutacao','o_corpo','a_obra','a_fortuna','a_influencia','o_legado'];check('student-twelve-plus-ritual',len(prog['nodes'])==13,len(prog['nodes']));check('student-scroll-order',[x['id'] for x in prog['nodes'][:12]]==expected,[x['id'] for x in prog['nodes'][:12]])

    page.evaluate("HarunV5Progression.setPathForQA({phase:'prelude',index:0,degree:1,degreeIndex:0,completedDegrees:[]})");page.wait_for_timeout(120);page.locator('[data-v5-index="0"]').click();page.wait_for_timeout(100);check('glory-choice-visible',page.locator('#v4Glory:not([hidden])').count()==1);page.locator('#v4Glory [data-v5-glory]').first.click();page.wait_for_timeout(550)
    st=page.evaluate('HarunSurvivorDebug.getState()');check('run-started',st['state']=='run',st['state']);check('movement-materially-faster',st['run']['player']['speed']>=155,st['run']['player']['speed']);active=page.evaluate('HarunV5Runtime.active()');check('runtime-prelude-active',active and active['key']=='prelude',active)

    floor=page.evaluate('HarunV5World.getFloor()');check('floor-ten-rooms',len(floor)==10,len(floor));check('room-types-nonrepeating',len({x['type'] for x in floor})==len(floor),[x['type'] for x in floor]);check('layout-ids-nonrepeating',len({x['layout'] for x in floor})==len(floor),[x['layout'] for x in floor]);check('minimap-visible',page.locator('#v5MiniMap').count()==1)
    page.keyboard.press('Tab');page.wait_for_timeout(90);check('tab-expands-map',page.locator('#v5MapOverlay:not([hidden])').count()==1);current=page.locator('#v5MapTitle').inner_text();check('expanded-map-names-room',len(current)>2,current);page.keyboard.press('Tab');page.wait_for_timeout(70);check('tab-closes-map',page.locator('#v5MapOverlay[hidden]').count()==1)
    page.keyboard.press('Escape');page.wait_for_timeout(100);check('esc-opens-blackbook',page.locator('#v5BlackBook:not([hidden])').count()==1);check('blackbook-has-system-tabs',page.locator('#v5BookTabs [data-v5-book]').count()>=10,page.locator('#v5BookTabs [data-v5-book]').count());page.keyboard.press('Escape');page.wait_for_timeout(100);check('esc-closes-blackbook',page.locator('#v5BlackBook[hidden]').count()==1)

    tarot_count=page.evaluate('HarunV5Systems.tarot.length');check('thoth-78',tarot_count==78,tarot_count);owned_before=page.evaluate('HarunV5Systems.state().tarotOwned.length');page.evaluate('HarunV5Systems.chooseTarot()');page.wait_for_timeout(100);check('three-tarot-options',page.locator('#v5Choice [data-tarot]').count()==3,page.locator('#v5Choice [data-tarot]').count());ids=page.locator('#v5Choice [data-tarot]').evaluate_all('(els)=>els.map(x=>x.dataset.tarot)');check('tarot-offers-unique',len(set(ids))==3,ids);page.locator('#v5Choice [data-tarot]').first.click();page.wait_for_timeout(120);check('unchosen-cards-disappear',page.locator('#v5Choice:not([hidden]) [data-tarot]').count()==0);owned_after=page.evaluate('HarunV5Systems.state().tarotOwned.length');check('chosen-tarot-recorded',owned_after==owned_before+1,(owned_before,owned_after))

    page.evaluate('HarunV5World.spawnMagnet()');page.wait_for_timeout(50);before_coins=page.evaluate('HarunSurvivorDebug.getState().run.coins');page.evaluate('''()=>{const r=HarunSurvivorDebug.getState().run,m=r.gems.find(x=>x.v5Magnet);if(m){m.x=r.player.x+25;m.y=r.player.y}}''');page.wait_for_timeout(180);check('magnet-consumed',page.evaluate('!HarunSurvivorDebug.getState().run.gems.some(x=>x.v5Magnet)'));after_coins=page.evaluate('HarunSurvivorDebug.getState().run.coins');check('magnet-rewarded',after_coins>=before_coins+2,(before_coins,after_coins))

    page.mouse.click(300,500);page.wait_for_timeout(350);audio=page.evaluate('HarunV5Audio.snapshot()');check('audio-core-configured',audio and audio['game']=='survivor',audio);check('audio-context-running',audio and audio['contextState']=='running',audio);check('audio-loud-profile',audio and audio['profile']['music']>=.7 and audio['profile']['sfx']>=.95,audio)
    page.evaluate('HarunSurvivorV4Debug.jumpWave(10)');page.wait_for_timeout(750);st=page.evaluate('HarunSurvivorDebug.getState()');check('boss-present',st['run']['boss'] is not None);check('prelude-boss-name',st['run']['boss']['name']=='OBSERVADOR CEGO',st['run']['boss']['name'])
    page.evaluate('HarunSurvivorV4Debug.stress(28)');fps=page.evaluate('HarunSurvivorV4Debug.measureFps(1800)');check('stress-fps-45plus',fps>=45,fps);page.screenshot(path=str(OUT/'v5-desktop-combat.png'),full_page=True)
    page.set_viewport_size({'width':390,'height':844});page.wait_for_timeout(250);check('mobile-no-overflow',page.evaluate('document.documentElement.scrollWidth<=document.documentElement.clientWidth+1'));page.screenshot(path=str(OUT/'v5-mobile-combat.png'),full_page=True)
    browser.close()
except Exception as exc:
  failure=f'{type(exc).__name__}: {exc}'
  (OUT/'exception.txt').write_text(failure+'\n'+traceback.format_exc(),encoding='utf-8')

report={'status':'PASS' if failure is None and all(x['ok'] for x in checks) and not errors else 'FAIL','checks':checks,'errors':errors,'failure':failure}
(OUT/'qa-report-v5.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(report,ensure_ascii=False,indent=2))
if report['status']!='PASS':raise SystemExit(1)
