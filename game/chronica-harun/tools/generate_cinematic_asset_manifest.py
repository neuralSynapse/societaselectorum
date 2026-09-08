#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
STORY=ROOT/'data/narrative/chronica_story_bible.json'
OUT=ROOT/'data/narrative/cinematic_asset_manifest.json'
FINAL_ROOT=ROOT/'art/cinematics'


def priority(scene_id: str, shot_index: int) -> str:
    if scene_id in {'sophia_at_edge','first_scream','form_without_breath','cain','dismembered_book','see_govern_make'}:
        return 'A'
    if shot_index in {1,5}:
        return 'A'
    if scene_id in {'pleroma','lilith_first_refusal','eve_epinoia_knowledge','lineage_of_mark'}:
        return 'B'
    return 'C'


def infer_asset_needs(scene_id: str, visual: str) -> list[str]:
    needs=['camera_rig','lighting_cue']
    low=(scene_id+' '+visual).lower()
    for token,asset in [
      ('pleroma','cosmic_field'),('sophia','sophia_manifestation'),('yald','yaldabaoth_manifestation'),
      ('authority','archontic_geometry'),('terra','earth_environment'),('hum','human_body'),
      ('lilith','lilith_character'),('eva','eve_character'),('serpent','serpent_manifestation'),
      ('caim','cain_character'),('abel','abel_character'),('harun','harun_character'),('livro','grimorium_prop'),
      ('fragment','grimorium_fragments'),('porta','threshold_door'),('mark','cain_mark_vfx')]:
        if token in low and asset not in needs:
            needs.append(asset)
    return needs


def final_asset_paths(scene_id: str, shot_id: str) -> list[str]:
    shot_dir=FINAL_ROOT/scene_id/shot_id
    if not shot_dir.exists():
        return []
    allowed={'.glb','.gltf','.png','.webp','.jpg','.jpeg','.exr','.tscn','.res','.tres','.ogg','.wav'}
    paths=[]
    for path in sorted(shot_dir.rglob('*')):
        if path.is_file() and path.suffix.lower() in allowed:
            paths.append(path.relative_to(ROOT).as_posix())
    return paths


def main():
    story=json.loads(STORY.read_text(encoding='utf-8'))
    rows=[]
    sequences = list(story['prologue']) + [story['epilogue']]
    for scene in sequences:
        for i,shot in enumerate(scene['shots'],1):
            final_paths=final_asset_paths(scene['id'], shot['id'])
            status='final' if final_paths else 'proxy_runtime'
            rows.append({
              'scene_id':scene['id'],'scene_title':scene['title'],'shot_id':shot['id'],'order_in_scene':i,
              'duration_seconds':shot['duration_seconds'],'camera_contract':shot['camera'],'visual_contract':shot['visual_event'],
              'audio_contract':shot['audio_event'],'transition':shot['transition'],'tension':shot['tension'],
              'priority':'A' if scene['id']=='aleppo_1585' else priority(scene['id'],i),'runtime_owner':'narrative','asset_needs':infer_asset_needs(scene['id'],str(shot['visual_event'])),
              'asset_status':status,
              'final_asset_paths':final_paths,
              'runtime_proxy':'procedural_cinematic_stage' if status=='proxy_runtime' else None,
              'implementation_note':'Proxy procedural de runtime; não é arte cinematográfica final.' if status=='proxy_runtime' else 'Assets finais concretos encontrados no diretório canônico do plano.'
            })
    OUT.write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'{OUT} ({len(rows)} shots; {sum(1 for r in rows if r["asset_status"]=="final")} final; {sum(1 for r in rows if r["asset_status"]=="proxy_runtime")} proxy_runtime)')


if __name__=='__main__':
    main()
