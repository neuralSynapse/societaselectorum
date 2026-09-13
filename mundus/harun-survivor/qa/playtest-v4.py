import json, os
from pathlib import Path
from playwright.sync_api import sync_playwright

OUT = Path(os.environ.get('QA_OUT', '/tmp/harun-survivor-v4-qa'))
OUT.mkdir(parents=True, exist_ok=True)
URL = os.environ.get('QA_URL', 'http://127.0.0.1:8765/mundus/harun-survivor/index.html?debug=1')
BROWSER = os.environ.get('QA_BROWSER')
checks, errors = [], []

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
    page.wait_for_function('window.HarunSurvivorDebug && window.HarunSurvivorV4Debug && window.HarunCanonicalProgression && window.HarunProgressionDebug', timeout=10000)
    page.wait_for_timeout(220)

    version = page.evaluate('window.HarunSurvivorV4Debug.version')
    check('v4-runtime-present', version.startswith('4.'), version)
    canon = page.evaluate('''()=>({
      v:HarunCanonicalProgression.version,pre:HarunCanonicalProgression.preStudentName,
      initial:HarunCanonicalProgression.initialIngressusAct,result:HarunCanonicalProgression.ingressusResult,
      studentIsDegree:HarunCanonicalProgression.studentIsDegree,degrees:HarunCanonicalProgression.degrees.length,
      first:HarunCanonicalProgression.firstDegree,last:HarunCanonicalProgression.lastDegree,
      ingressus:HarunCanonicalProgression.ingressus.length,student:HarunCanonicalProgression.student.length,
      g1:HarunCanonicalProgression.degrees[0].steps.length,g2:HarunCanonicalProgression.degrees[1].steps.length,
      g22:HarunCanonicalProgression.degrees[21].steps.length,g23:HarunCanonicalProgression.degrees[22].steps.length,
      g23public:HarunCanonicalProgression.degrees[22].public,g33:HarunCanonicalProgression.degrees[32].name,
      reserved:HarunCanonicalProgression.publicThirdOrderReserved
    })''')
    check('canonical-prestudent-ingressus', canon['pre'] == 'INGRESSUS', canon)
    check('actus-ingressus-opens-journey', canon['initial'] == 'ACTUS INGRESSUS', canon)
    check('ingressus-result-ready99d', canon['result'] == 'pronto_99d', canon)
    check('student-is-not-degree', canon['studentIsDegree'] is False, canon)
    check('thirty-three-degrees', canon['degrees'] == 33, canon)
    check('first-degree-peregrinus', canon['first'] == 'Peregrinus Ignis', canon)
    check('final-degree-ipsissimus', canon['last'] == 'Ipsissimus' and canon['g33'] == 'Ipsissimus', canon)
    check('ingressus-current-ten-stages', canon['ingressus'] == 10, canon)
    check('student-fifteen-gates-and-cycles', canon['student'] == 15, canon)
    check('peregrinus-thirteen-scroll-forge-steps', canon['g1'] == 13, canon)
    check('degrees-have-own-fractal-stages', canon['g2'] == 10 and canon['g22'] == 10 and canon['g23'] == 10, canon)
    check('third-order-publicly-reserved', canon['reserved'] is True and canon['g23public'] is False, canon)

    snap = page.evaluate('HarunProgressionDebug.snapshot()')
    check('ingressus-map-rendered', len(snap['nodes']) == 10 and page.locator('[data-prog-index]').count() == 10, snap['nodes'])
    check('actus-first-node', snap['nodes'][0]['id'] == 'documentacao_actus' and 'ACTUS INGRESSUS' in snap['nodes'][0]['name'], snap['nodes'][0])
    check('plan-is-final-ingressus-node', snap['nodes'][-1]['id'] == 'plano_individual', snap['nodes'][-1])
    check('timeline-has-33-degree-chips', page.locator('.prog-degree').count() == 33, str(page.locator('.prog-degree').count()))

    page.evaluate("HarunProgressionDebug.setPath({phase:'ingressus',ingressusStage:9,studentStage:0,degree:1,degreeStage:0,completedDegrees:[]})")
    page.wait_for_timeout(80)
    page.evaluate('HarunProgressionDebug.advanceCurrentForQA()')
    page.wait_for_timeout(100)
    snap = page.evaluate('HarunProgressionDebug.snapshot()')
    check('ingressus-transitions-to-student', snap['path']['phase'] == 'student' and snap['path']['studentStage'] == 0, snap['path'])
    check('student-map-fifteen-stages', len(snap['nodes']) == 15 and page.locator('[data-prog-index]').count() == 15, len(snap['nodes']))

    page.evaluate("HarunProgressionDebug.setPath({phase:'student',ingressusStage:10,studentStage:14,degree:1,degreeStage:0,completedDegrees:[]})")
    page.evaluate('HarunProgressionDebug.advanceCurrentForQA()')
    page.wait_for_timeout(100)
    snap = page.evaluate('HarunProgressionDebug.snapshot()')
    check('student-transitions-to-degree-I', snap['path']['phase'] == 'degrees' and snap['path']['degree'] == 1, snap['path'])
    check('peregrinus-map-thirteen-stages', len(snap['nodes']) == 13, len(snap['nodes']))
    check('peregrinus-title-visible', 'Peregrinus Ignis' in page.locator('#campaign').inner_text())

    page.evaluate("HarunProgressionDebug.setPath({phase:'degrees',ingressusStage:10,studentStage:15,degree:23,degreeStage:0,completedDegrees:Array.from({length:22},(_,i)=>i+1)})")
    page.wait_for_timeout(100)
    body = page.locator('#campaign').inner_text()
    check('third-order-screen-is-sealed', 'ARBOR DRACONIS' in body and 'reservado' in body.lower(), body[:400])
    check('third-order-does-not-leak-internal-planning-name', 'Umbra Interior' not in body, body[:400])

    # Restore beginning for normal gameplay QA.
    page.evaluate("HarunProgressionDebug.setPath({phase:'ingressus',ingressusStage:0,studentStage:0,degree:1,degreeStage:0,completedDegrees:[]})")
    page.wait_for_timeout(80)
    check('initial-glory-surface', page.locator('#v4Glory').count() == 1, 'missing #v4Glory')

    page.evaluate('window.HarunSurvivorV4Debug.quickStart(1)')
    page.wait_for_timeout(250)
    check('glory-opens-before-run', page.locator('#v4Glory:not([hidden])').count() == 1)
    page.locator('#v4Glory [data-v4-glory]').first.click()
    page.wait_for_timeout(350)
    st = page.evaluate('window.HarunSurvivorDebug.getState()')
    check('run-started', st['state'] == 'run', st['state'])
    check('fast-wave-contract', st['run']['waveDuration'] <= 8, str(st['run']['waveDuration']))

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
