import json, os, time
from pathlib import Path
from playwright.sync_api import sync_playwright

OUT = Path(os.environ.get('QA_OUT', '/tmp/harun-survivor-v4-qa'))
OUT.mkdir(parents=True, exist_ok=True)
URL = os.environ.get('QA_URL', 'http://127.0.0.1:8765/mundus/harun-survivor/index.html?debug=1')
BROWSER = os.environ.get('QA_BROWSER')
checks = []
errors = []

def check(name, ok, detail=''):
    checks.append({'name': name, 'ok': bool(ok), 'detail': detail})
    if not ok:
        raise AssertionError(f'{name}: {detail}')

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True, executable_path=BROWSER or None, args=['--no-sandbox'])
    page = browser.new_page(viewport={'width': 540, 'height': 960}, device_scale_factor=1)
    page.on('pageerror', lambda exc: errors.append(str(exc)))
    page.on('console', lambda msg: errors.append(msg.text) if msg.type == 'error' else None)
    page.goto(URL, wait_until='domcontentloaded')
    page.wait_for_function('window.HarunSurvivorDebug && window.HarunSurvivorV4Debug && window.HarunCanonicalProgression', timeout=10000)
    page.wait_for_timeout(180)

    version = page.evaluate('window.HarunSurvivorV4Debug.version')
    check('v4-runtime-present', version.startswith('4.'), version)

    canon = page.evaluate('''()=>({v:HarunCanonicalProgression.version,pre:HarunCanonicalProgression.preStudentName,final:HarunCanonicalProgression.finalIngressusAct,studentIsDegree:HarunCanonicalProgression.studentIsDegree,degrees:HarunCanonicalProgression.degrees.length,first:HarunCanonicalProgression.firstDegree,last:HarunCanonicalProgression.lastDegree,ingressus:HarunCanonicalProgression.ingressus.length,student:HarunCanonicalProgression.student.length,g1:HarunCanonicalProgression.degrees[0].steps.length})''')
    check('canonical-prestudent-ingressus', canon['pre'] == 'INGRESSUS', canon)
    check('actus-ingressus-final', canon['final'] == 'ACTUS INGRESSUS', canon)
    check('student-is-not-degree', canon['studentIsDegree'] is False, canon)
    check('thirty-three-degrees', canon['degrees'] == 33, canon)
    check('first-degree-peregrinus', canon['first'] == 'Peregrinus Ignis', canon)
    check('final-degree-ipsissimus', canon['last'] == 'Ipsissimus', canon)
    check('ingressus-sixteen-stages', canon['ingressus'] == 16, canon)
    check('student-fifteen-gates-and-cycles', canon['student'] == 15, canon)
    check('peregrinus-thirteen-scroll-forge-steps', canon['g1'] == 13, canon)
    check('ingressus-map-rendered', page.locator('[data-prog-index]').count() == 16, str(page.locator('[data-prog-index]').count()))
    check('ingressus-label-visible', 'INGRESSUS' in page.locator('#campaign').inner_text())

    page.evaluate("""()=>{const m=HarunSurvivorDebug.getState().meta;m.path={phase:'student',ingressusStage:16,studentStage:0,degree:1,degreeStage:0,completedDegrees:[]};HarunSurvivorDebug.showMenu('campaign')}""")
    page.wait_for_timeout(180)
    check('student-map-fifteen-stages', page.locator('[data-prog-index]').count() == 15, str(page.locator('[data-prog-index]').count()))
    check('student-label-visible', 'ESTUDANTE' in page.locator('#campaign').inner_text())

    page.evaluate("""()=>{const m=HarunSurvivorDebug.getState().meta;m.path={phase:'degrees',ingressusStage:16,studentStage:15,degree:1,degreeStage:0,completedDegrees:[]};HarunSurvivorDebug.showMenu('campaign')}""")
    page.wait_for_timeout(180)
    check('peregrinus-map-thirteen-stages', page.locator('[data-prog-index]').count() == 13, str(page.locator('[data-prog-index]').count()))
    check('peregrinus-title-visible', 'Peregrinus Ignis' in page.locator('#campaign').inner_text())

    page.evaluate("""()=>{const m=HarunSurvivorDebug.getState().meta;m.path={phase:'ingressus',ingressusStage:0,studentStage:0,degree:1,degreeStage:0,completedDegrees:[]};HarunSurvivorDebug.showMenu('campaign')}""")
    page.wait_for_timeout(120)
    check('initial-glory-surface', page.locator('#v4Glory').count() == 1, 'missing #v4Glory')

    page.evaluate('window.HarunSurvivorV4Debug.quickStart(1)')
    page.wait_for_timeout(250)
    check('glory-opens-before-run', page.locator('#v4Glory:not([hidden])').count() == 1)
    page.locator('#v4Glory [data-v4-glory]').first.click()
    page.wait_for_timeout(350)
    st = page.evaluate('window.HarunSurvivorDebug.getState()')
    check('run-started', st['state'] == 'run', st['state'])
    check('fast-wave-contract', st['run']['waveDuration'] <= 8, str(st['run']['waveDuration']))

    # V4 is finite-wave/burst driven. Wave 2 must arrive quickly rather than after v3's 26 seconds.
    page.wait_for_function('window.HarunSurvivorDebug.getState().run.wave >= 2', timeout=12000)
    elapsed = page.evaluate('window.HarunSurvivorV4Debug.metrics().lastWaveSeconds')
    check('wave-cadence-under-9s', elapsed <= 9.0, str(elapsed))

    metrics = page.evaluate('window.HarunSurvivorV4Debug.metrics()')
    check('burst-density', metrics['peakEnemies'] >= 5, str(metrics['peakEnemies']))

    page.evaluate("window.HarunSurvivorV4Debug.grant('energy_ring', 1)")
    page.wait_for_timeout(200)
    skills = page.evaluate('window.HarunSurvivorDebug.getState().run.skills')
    check('behavioral-skill-granted', skills.get('energy_ring', 0) >= 1)

    check('fx-overlay-canvas', page.locator('#v4fx').count() == 1)
    check('daimon-companion-layer', page.evaluate('window.HarunSurvivorV4Debug.metrics().companionVisible === true'))

    page.evaluate('window.HarunSurvivorV4Debug.jumpWave(10)')
    page.wait_for_timeout(700)
    st = page.evaluate('window.HarunSurvivorDebug.getState()')
    check('boss-wave-10', st['run']['wave'] == 10, str(st['run']['wave']))
    check('boss-present', st['run']['boss'] is not None)
    check('danger-visible-or-fired', page.evaluate('window.HarunSurvivorV4Debug.metrics().dangerCount >= 1'))

    page.evaluate('window.HarunSurvivorV4Debug.stress(28)')
    fps = page.evaluate('window.HarunSurvivorV4Debug.measureFps(1800)')
    check('stress-fps-45plus', fps >= 45, str(fps))

    page.screenshot(path=str(OUT/'desktop-combat.png'), full_page=True)
    page.set_viewport_size({'width': 390, 'height': 844})
    page.wait_for_timeout(250)
    overflow = page.evaluate('document.documentElement.scrollWidth <= document.documentElement.clientWidth + 1')
    check('mobile-no-horizontal-overflow', overflow)
    page.screenshot(path=str(OUT/'mobile-combat.png'), full_page=True)
    browser.close()

report = {'status': 'PASS' if all(x['ok'] for x in checks) and not errors else 'FAIL', 'checks': checks, 'errors': errors}
(OUT/'qa-report-v4.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, ensure_ascii=False, indent=2))
if report['status'] != 'PASS':
    raise SystemExit(1)
