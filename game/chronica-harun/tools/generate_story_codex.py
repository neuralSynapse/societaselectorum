#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
story=json.loads((ROOT/'data/narrative/chronica_story_bible.json').read_text(encoding='utf-8'))
rows=[]
for scene in story['prologue']:
    prov=scene.get('provenance',{})
    rows.append({
        'id':'story_scene:'+scene['id'],
        'title':scene['title'],
        'body':scene['narration'],
        'provenance_class':prov.get('primary_class','electorum_dramatization'),
        'source_note':prov.get('source_note',''),
        'unlock_key':'scene:'+scene['id'],
        'category':'chronica_prologue'
    })
for stage in story['student_journey']:
    rows.append({
        'id':'story_stage:'+stage['stage_id'],
        'title':f"{stage['title']} · {stage['subtitle']}",
        'body':f"{stage['personal_stake']} {stage['boss_revelation']} {stage['reward_meaning']}",
        'provenance_class':'electorum_dramatization',
        'source_note':'Arco de Harun e mecânica narrativa pertencem à dramatização canônica da CHRONICA.',
        'unlock_key':'stage:'+stage['stage_id'],
        'category':'student_journey'
    })
for key,motif in story['recurring_motifs'].items():
    rows.append({
        'id':'story_motif:'+key,
        'title':key.replace('_',' ').upper(),
        'body':motif['meaning'],
        'provenance_class':'interpretation',
        'source_note':'Motivo cinematográfico/editorial usado para ligar eventos e leituras do cânone.',
        'unlock_key':'motif:'+key,
        'category':'motif'
    })
ep=story['epilogue']
rows.append({
    'id':'story_epilogue:'+ep['id'],
    'title':ep['title'],
    'body':ep['narration'],
    'provenance_class':ep.get('provenance',{}).get('primary_class','electorum_dramatization'),
    'source_note':ep.get('provenance',{}).get('source_note',''),
    'unlock_key':'epilogue:'+ep['id'],
    'category':'epilogue'
})
out=ROOT/'data/codex/story_codex.json'
out.parent.mkdir(parents=True,exist_ok=True)
out.write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'{out} ({len(rows)} entries)')
