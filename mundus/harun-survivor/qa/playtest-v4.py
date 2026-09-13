import json, os
from pathlib import Path
from playwright.sync_api import sync_playwright

OUT=Path(os.environ.get('QA_OUT','/tmp/harun-survivor-v4-qa'));OUT.mkdir(parents=True,exist_ok=True)
URL=os.environ.get('QA_URL','http://127.0.0.1:8765/mundus/harun-survivor/index.html?debug=1');BROWSER=os.environ.get('QA_BROWSER')
checks=[];errors=[]
def check(name,ok,detail=''):
    checks.append({'name':name,'ok':bool(ok),'detail':detail})
    if not ok: raise AssertionError(f'{name}: {detail}')

with sync_playwright() as p:
    browser=p.chromium.launch(headless=True,executable_path=BROWSER or None,args=['--no-sandbox'])
    page=browser.new_page(viewport={'width':540,'height':960},device_scale_factor=1)
    page.on('pageerror',lambda exc:errors.append(str(exc)));page.on('console',lambda msg:errors.append(msg.text) if msg.type=='error' else None)
    page.goto(URL,wait_until='domcontentloaded');page.wait_for_function('window.HarunSurvivorDebug&&window.HarunSurvivorV4Debug&&window.HarunCanonicalProgression&&window.HarunProgressionDebug&&window.HarunDegreeRuntime',timeout=10000);page.wait_for_timeout(220)

    canon=page.evaluate('''()=>({v:HarunCanonicalProgression.version,pre:HarunCanonicalProgression.preStudentName,rite:HarunCanonicalProgression.ingressusRite,adapt:HarunCanonicalProgression.gameIngressusAdaptation,replica:HarunCanonicalProgression.institutionalCurriculumReplica,studentIsDegree:HarunCanonicalProgression.studentIsDegree,degrees:HarunCanonicalProgression.degrees.length,first:HarunCanonicalProgression.firstDegree,last:HarunCanonicalProgression.lastDegree,ingressus:HarunCanonicalProgression.ingressus.length,student:HarunCanonicalProgression.student.length,g1:HarunCanonicalProgression.degrees[0].steps.length,g2:HarunCanonicalProgression.degrees[1].steps.length,g22:HarunCanonicalProgression.degrees[21].steps.length,g23:HarunCanonicalProgression.degrees[22].steps.length,g23public:HarunCanonicalProgression.degrees[22].public,g33:HarunCanonicalProgression.degrees[32].name,reserved:HarunCanonicalProgression.publicThirdOrderReserved})''')
    check('progression-v4.4',canon['v']=='4.4.0',canon);check('prestudent-is-ingressus',canon['pre']=='INGRESSUS',canon);check('actus-ingressus-rite',canon['rite']=='ACTUS INGRESSUS',canon)
    check('game-adaptation-not-institutional-replica',canon['adapt'] is True and canon['replica'] is False,canon);check('student-is-not-degree',canon['studentIsDegree'] is False,canon)
    check('thirty-three-degrees',canon['degrees']==33,canon);check('peregrinus-to-ipsissimus',canon['first']=='Peregrinus Ignis' and canon['last']=='Ipsissimus' and canon['g33']=='Ipsissimus',canon)
    check('existing-sixteen-stages-now-ingressus',canon['ingressus']==16,canon);check('student-fifteen-stages',canon['student']==15,canon);check('peregrinus-thirteen-steps',canon['g1']==13,canon)
    check('later-degrees-own-fractal-stages',canon['g2']==10 and canon['g22']==10 and canon['g23']==10,canon);check('third-order-publicly-reserved',canon['reserved'] is True and canon['g23public'] is False,canon)

    snap=page.evaluate('HarunProgressionDebug.snapshot()');check('ingressus-map-16',len(snap['nodes'])==16 and page.locator('[data-prog-index]').count()==16,len(snap['nodes']))
    check('ingressus-keeps-o-olho',snap['nodes'][0]['id']=='o_olho' and snap['nodes'][0]['name']=='O OLHO',snap['nodes'][0]);check('final-is-actus-chamber',snap['nodes'][-1]['id']=='actus_ingressus_chamber' and 'ACTUS INGRESSUS' in snap['nodes'][-1]['name'],snap['nodes'][-1])
    check('timeline-33-chips',page.locator('.prog-degree').count()==33,page.locator('.prog-degree').count())

    page.evaluate("HarunProgressionDebug.setPath({phase:'ingressus',ingressusStage:15,studentStage:0,degree:1,degreeStage:0,completedDegrees:[]})");page.evaluate('HarunProgressionDebug.advanceCurrentForQA()');page.wait_for_timeout(100)
    snap=page.evaluate('HarunProgressionDebug.snapshot()');check('ingressus-to-student',snap['path']['phase']=='student' and len(snap['nodes'])==15,snap['path'])
    page.evaluate("HarunProgressionDebug.setPath({phase:'student',ingressusStage:16,studentStage:14,degree:1,degreeStage:0,completedDegrees:[]})");page.evaluate('HarunProgressionDebug.advanceCurrentForQA()');page.wait_for_timeout(100)
    snap=page.evaluate('HarunProgressionDebug.snapshot()');check('student-to-degree-I',snap['path']['phase']=='degrees' and snap['path']['degree']==1 and len(snap['nodes'])==13,snap['path']);check('peregrinus-visible','Peregrinus Ignis' in page.locator('#campaign').inner_text())
    page.evaluate("HarunProgressionDebug.setPath({phase:'degrees',ingressusStage:16,studentStage:15,degree:23,degreeStage:0,completedDegrees:Array.from({length:22},(_,i)=>i+1)})");page.wait_for_timeout(100)
    body=page.locator('#campaign').inner_text();check('third-order-sealed','ARBOR DRACONIS' in body and 'reservado' in body.lower(),body[:400]);check('no-secret-planning-name','Umbra Interior' not in body,body[:400])

    # Test real canonical launch and degree runtime identity.
    page.evaluate("HarunProgressionDebug.setPath({phase:'degrees',ingressusStage:16,studentStage:15,degree:12,degreeStage:0,completedDegrees:Array.from({length:11},(_,i)=>i+1)})");page.wait_for_timeout(80);page.locator('[data-prog-index="0"]').click();page.wait_for_timeout(120);page.locator('#v4Glory [data-prog-glory]').first.click();page.wait_for_timeout(350)
    active=page.evaluate('HarunDegreeRuntime.active()');check('degree-runtime-mortis-active',active and active['key']=='mortis' and active['degree']==12,active);check('degree-badge-visible',page.locator('#degreeRuntimeBadge:not([hidden])').count()==1)

    # Restore generic gameplay QA path.
    page.evaluate("HarunProgressionDebug.setPath({phase:'ingressus',ingressusStage:0,studentStage:0,degree:1,degreeStage:0,completedDegrees:[]})");page.wait_for_timeout(80)
    page.evaluate('window.HarunSurvivorV4Debug.quickStart(1)');page.wait_for_timeout(250);check('glory-before-run',page.locator('#v4Glory:not([hidden])').count()==1);page.locator('#v4Glory [data-v4-glory]').first.click();page.wait_for_timeout(350)
    st=page.evaluate('HarunSurvivorDebug.getState()');check('run-started',st['state']=='run',st['state']);check('fast-wave-contract',st['run']['waveDuration']<=8,st['run']['waveDuration'])
    page.wait_for_function('HarunSurvivorDebug.getState().run.wave>=2',timeout=12000);elapsed=page.evaluate('HarunSurvivorV4Debug.metrics().lastWaveSeconds');check('wave-cadence-under-9s',elapsed<=9.0,elapsed)
    metrics=page.evaluate('HarunSurvivorV4Debug.metrics()');check('burst-density',metrics['peakEnemies']>=5,metrics['peakEnemies']);page.evaluate("HarunSurvivorV4Debug.grant('energy_ring',1)");page.wait_for_timeout(150)
    check('behavioral-skill',page.evaluate("HarunSurvivorDebug.getState().run.skills.energy_ring>=1"));check('fx-overlay',page.locator('#v4fx').count()==1);check('daimon-companion',page.evaluate('HarunSurvivorV4Debug.metrics().companionVisible===true'))
    page.evaluate('HarunSurvivorV4Debug.jumpWave(10)');page.wait_for_timeout(700);st=page.evaluate('HarunSurvivorDebug.getState()');check('boss-wave',st['run']['wave']==10 and st['run']['boss'] is not None,st['run']['wave']);check('danger',page.evaluate('HarunSurvivorV4Debug.metrics().dangerCount>=1'))
    page.evaluate('HarunSurvivorV4Debug.stress(28)');fps=page.evaluate('HarunSurvivorV4Debug.measureFps(1800)');check('stress-fps-45plus',fps>=45,fps)
    page.screenshot(path=str(OUT/'desktop-combat.png'),full_page=True);page.set_viewport_size({'width':390,'height':844});page.wait_for_timeout(250);check('mobile-no-overflow',page.evaluate('document.documentElement.scrollWidth<=document.documentElement.clientWidth+1'));page.screenshot(path=str(OUT/'mobile-combat.png'),full_page=True)
    browser.close()

report={'status':'PASS' if all(x['ok'] for x in checks) and not errors else 'FAIL','checks':checks,'errors':errors};(OUT/'qa-report-v4.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(report,ensure_ascii=False,indent=2))
if report['status']!='PASS':raise SystemExit(1)
