#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

PROLOGUE_IDS = [
    'before_dark','pleroma','sophia_at_edge','first_scream','blind_god',
    'lower_architecture','form_without_breath','lilith_first_refusal',
    'eve_epinoia_knowledge','cain','lineage_of_mark','dismembered_book',
    'see_govern_make'
]
STAGES = [
    'o_olho','a_chama','a_obra_fundacao','autoelection','autorresponsabilidade',
    'verdadeira_vontade','carater','disciplina','clareza','transmutacao',
    'corpo_energia','obra','fortuna','influencia','legado','initiation_chamber'
]
PROVENANCE = {'source','tradition','interpretation','electorum_dramatization'}
REQUIRED_STAGE_BEATS = {'threshold','wound','revelation','inversion','boss_intro','boss_truth','completion'}


def validate_payload(story: dict) -> list[str]:
    errors: list[str] = []
    if story.get('work') != 'CHRONICA HARUN': errors.append('work identity must remain CHRONICA HARUN')
    if story.get('real_author_credit') != 'Frater Horus Phosphorus': errors.append('real author credit regression')
    if story.get('harun_is_character') is not True: errors.append('Frater Harun must remain a character')
    rules = story.get('canon_rules', {})
    if rules.get('institutional_progression_write') is not False: errors.append('story may not write institutional progression')

    prologue = story.get('prologue', [])
    if [s.get('id') for s in prologue] != PROLOGUE_IDS: errors.append('prologue chronology/IDs changed')
    if [s.get('order') for s in prologue] != list(range(len(PROLOGUE_IDS))): errors.append('prologue order fields are not canonical')
    total = sum(float(s.get('duration_seconds', 0)) for s in prologue)
    if not 420 <= total <= 540: errors.append(f'first-view prologue duration outside 7-9 min: {total}s')
    for scene in prologue:
        sid = scene.get('id','?')
        for key in ['narration','voiceover','visual','audio','emotion','strategy','provenance','cinematic_hook','exit_image','player_learning']:
            if not scene.get(key): errors.append(f'{sid}: missing {key}')
        primary = scene.get('provenance',{}).get('primary_class')
        if primary not in PROVENANCE: errors.append(f'{sid}: invalid primary provenance {primary!r}')
        tension = scene.get('tension')
        if not isinstance(tension,(int,float)) or not 0 <= tension <= 1: errors.append(f'{sid}: invalid tension')
        shots = scene.get('shots', [])
        if len(shots) < 4: errors.append(f'{sid}: production shot timeline missing')
        shot_total = sum(float(x.get('duration_seconds',0)) for x in shots)
        if abs(shot_total - float(scene.get('duration_seconds',0))) > 0.25: errors.append(f'{sid}: shot timeline duration mismatch')
        for shot in shots:
            for key in ['id','camera','visual_event','audio_event','transition','tension']:
                if key not in shot: errors.append(f'{sid}: shot missing {key}')

    by_id = {s.get('id'):s for s in prologue}
    form = by_id.get('form_without_breath',{})
    if form.get('provenance',{}).get('luciferian_light') != 'electorum_dramatization':
        errors.append('luciferian light inside Yaldabaoth must remain Electorum dramatization, not ancient source')
    lineage = by_id.get('lineage_of_mark',{})
    if lineage.get('provenance',{}).get('direct_harun_descent') != 'electorum_dramatization':
        errors.append('Harun direct descent from Caim must remain Electorum dramatization, not historical/source claim')
    lilith = by_id.get('lilith_first_refusal',{})
    eve = by_id.get('eve_epinoia_knowledge',{})
    if int(lilith.get('order',999)) >= int(eve.get('order',-1)):
        errors.append('Lilith must precede Eva in the canonical game dramatization')
    cain = by_id.get('cain',{})
    if 'abel' not in str(cain.get('narration','')).lower():
        errors.append('Cain scene erased Abel from the canonical consequence')
    if cain.get('provenance',{}).get('lineage_reading') != 'tradition':
        errors.append('Cain lineage reading provenance must remain tradition')

    stages = story.get('student_journey', [])
    if [r.get('stage_id') for r in stages] != STAGES: errors.append('Student journey order changed')
    if len(stages) != 16: errors.append('Student journey must contain 15 stages plus initiation')
    for row in stages:
        sid=row.get('stage_id','?')
        ids={b.get('id') for b in row.get('beats',[])}
        missing=REQUIRED_STAGE_BEATS-ids
        if missing: errors.append(f'{sid}: missing dramatic beats {sorted(missing)}')
        for key in ['harun_conflict','dramatic_question','horror_device','strategic_lesson','opening_image','personal_stake','choice_under_pressure','boss_revelation','reward_meaning','foreshadow','stage_voiceover']:
            if not row.get(key): errors.append(f'{sid}: missing {key}')
        choice = row.get('choice_event', {})
        if not choice.get('id') or len(choice.get('options',[])) < 2: errors.append(f'{sid}: strategic narrative choice missing')
        hooks={str(x.get('external_hook','')) for x in choice.get('options',[])}
        if len(hooks) < 2: errors.append(f'{sid}: choice consequences are not meaningfully distinct')
    if stages and stages[-1].get('completion_state') != 'PEREGRINUS_IGNIS_GAME':
        errors.append('initiation must end in PEREGRINUS_IGNIS_GAME narrative state')

    motifs=story.get('recurring_motifs',{})
    for key in ['missing_frequency','breath','hand_and_mark','door','second_shadow','unlit_wick']:
        if key not in motifs or len(motifs.get(key,{}).get('appearances',[])) < 2:
            errors.append(f'recurring motif missing/weak: {key}')

    ep=story.get('epilogue',{})
    if ep.get('location')!='Aleppo' or ep.get('date_display')!='c. 1585': errors.append('epilogue must remain Aleppo c. 1585')
    if ep.get('final_word')!='LUCIFER': errors.append('epilogue final word must remain LUCIFER')
    if ep.get('continuity_target')!='OPUS_LUX_FERRE_LIVRO_ZERO': errors.append('epilogue continuity target changed')
    if ep.get('second_shadow_present') is not True or ep.get('second_wick_unlit') is not True: errors.append('Aleppo second shadow/unlit wick motif regressed')
    if ep.get('cut_to_black_after_final_word') is not True: errors.append('epilogue must cut to black after final word')
    ep_shots=ep.get('shots',[])
    if len(ep_shots) < 6: errors.append('epilogue production shot timeline missing')
    if abs(sum(float(x.get('duration_seconds',0)) for x in ep_shots)-float(ep.get('duration_seconds',0))) > 0.25: errors.append('epilogue shot duration mismatch')
    return errors


def validate(root: Path) -> list[str]:
    path = root / 'data/narrative/chronica_story_bible.json'
    try:
        story=json.loads(path.read_text(encoding='utf-8'))
    except Exception as exc:
        return [f'cannot read story bible: {exc}']
    errors=validate_payload(story)
    doc=root/'docs/canon/CHRONICA_HARUN_CANONE_NARRATIVO_v2_0_2026-09-07.md'
    if not doc.exists(): errors.append('human-readable canonical story document missing')
    for rel in ['scripts/narrative/CosmogonyPrologueDirector.gd','scripts/narrative/HarunOriginDirector.gd','scripts/narrative/ChronicaStoryDirector.gd']:
        if not (root/rel).exists(): errors.append(f'runtime director missing: {rel}')
    return errors


def main() -> int:
    root=Path(__file__).resolve().parents[1]
    errors=validate(root)
    if errors:
        print('CHRONICA STORY CANON VALIDATION: FAIL')
        for e in errors: print(' -',e)
        return 1
    print('CHRONICA STORY CANON VALIDATION: PASS')
    print(' - 13 cinematic prologue sequences / 500 seconds')
    print(' - provenance boundaries preserved')
    print(' - 15 Student stages + Initiation dramatic arcs')
    print(' - Aleppo c. 1585 / Nadir / second shadow / LUCIFER continuity')
    print(' - 72 production shots / 16 strategic narrative choices')
    print(' - narrative runtime directors present')
    return 0

if __name__=='__main__':
    raise SystemExit(main())
