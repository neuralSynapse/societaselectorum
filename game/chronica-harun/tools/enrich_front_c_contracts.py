#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROG = ROOT/'data'/'roguelite'

CATEGORY_KIND = {
    'tarot_thoth.json':'arcana',
    'sigilla_goetia.json':'sigillum_contract',
    'pharmaka.json':'pharmakon',
    'talismans_decanic.json':'decan_modifier',
    'instrumenta.json':'instrument_action',
    'powers.json':'matrix_power',
    'daimones.json':'daimon_action',
    'relics.json':'relic_rule',
    'transformations.json':'transformation',
    'curses.json':'curse',
    'blessings.json':'blessing',
    'routes.json':'route',
}

def write(name, rows):
    (ROG/name).write_text(json.dumps(rows, ensure_ascii=False, indent=2)+'\n')

def prov(row):
    cls = row.get('provenance_class', 'electorum_dramatization')
    return {'level': cls, 'source': row.get('source_note') or 'Cânone CHRONICA HARUN; efeito de gameplay é dramatização Electorum.'}

def effect_for(name, row):
    kind = CATEGORY_KIND[name]
    fx = {'kind':kind, 'effect_id':row.get('effect_id', row.get('id',''))}
    if name == 'tarot_thoth.json':
        fx.update({'arcana_class':row.get('group','minor'), 'rank':row.get('rank'), 'suit':row.get('suit',''), 'element':row.get('element','')})
    elif name == 'sigilla_goetia.json':
        fx.update({'dominium':row.get('dominium',''), 'pretium':row.get('pretium',''), 'boon':row.get('boon_magnitude',0), 'cost':row.get('cost_magnitude',0)})
    elif name == 'pharmaka.json':
        fx.update({'benefit':row.get('benefit',''), 'side_effect':row.get('side_effect',''), 'magnitude':row.get('magnitude',0)})
    elif name == 'instrumenta.json':
        fx.update({'action':row.get('effect_id',''), 'charges':row.get('charges',2)})
    elif name == 'powers.json':
        fx.update({'mutations':[m.get('effect_id',m.get('id','')) for m in row.get('mutations',[])]})
    elif name == 'transformations.json':
        fx.update({'requires':row.get('requires',[])})
    return fx

def enrich(name, row):
    pool = name.replace('.json','').replace('_thoth','').replace('_goetia','').replace('_decanic','')
    row.setdefault('name', row.get('display_name') or row.get('id','').replace('_',' ').title())
    row.setdefault('rarity', 'rare' if pool in {'relics','transformations','routes'} else 'common')
    row.setdefault('pool', pool)
    row.setdefault('eligibility', {'min_stage':0,'min_cycle':0,'requires_tags':[],'forbids_tags':[]})
    row.setdefault('effect', effect_for(name,row))
    row.setdefault('cost', {'resource':'none','amount':0})
    row.setdefault('duration', {'mode':'instant','seconds':0,'rooms':0})
    row.setdefault('stacking', {'mode':'none','max_stacks':1})
    row.setdefault('synergies', [])
    row.setdefault('exclusions', [])
    row.setdefault('vfx_hook', f"vfx.{row.get('id','content')}")
    row.setdefault('sfx_hook', f"sfx.{row.get('id','content')}")
    row.setdefault('save_state', {'scope':'run','persist':True})
    row.setdefault('codex', {'category':pool,'summary':row.get('name','')})
    row.setdefault('provenance', prov(row))
    return row

def special_room(id_, name, reward_pool, *, role='special', chance=.25, risk='medium', access='door_after_clear', cost=None, exclusive=None, requires=None):
    row = {
        'id':id_,'name':name,'base_chance':chance,'min_stage':0,'max_per_floor':1,
        'eligibility':requires or {'min_rooms_cleared':1}, 'access':access,'risk':risk,
        'reward_pool':[reward_pool] if isinstance(reward_pool,str) else reward_pool,
        'telegraph':f'{id_}_telegraph','room_size':[9,5,9],
        'provenance_class':'electorum_dramatization',
        'rarity':'rare','pool':'special_rooms',
        'effect':{'kind':'room_event','event':id_,'reward_pool':reward_pool},
        'cost':cost or {'resource':'none','amount':0},
        'duration':{'mode':'room','seconds':0,'rooms':1},
        'stacking':{'mode':'none','max_stacks':1},'synergies':[],'exclusions':[],
        'vfx_hook':f'vfx.room.{id_}','sfx_hook':f'sfx.room.{id_}',
        'save_state':{'scope':'run','persist':True},
        'codex':{'category':'Salas Especiais','summary':name},
        'provenance':{'level':'electorum_dramatization','source':'Sala autoral CHRONICA HARUN.'},
        'entry':{'mode':access,'accepted_openers':['ritual_bomb','rupture_charge','wall_break'] if 'secret' in id_ else []},
        'runtime_event':f'room.{id_}','persistent_state':{'visited':True,'resolved':True},
        'map_icon':f'map.room.{id_}','discovery_feedback':f'discover.room.{id_}',
    }
    if exclusive: row['exclusive_group']=exclusive
    return row

def main():
    for name in CATEGORY_KIND:
        rows = json.loads((ROG/name).read_text())
        rows = [enrich(name,r) for r in rows]
        if name == 'transformations.json':
            ids={r['id'] for r in rows}
            additions=[
                {'id':'corpus_ignis','name':'Corpus Ignis','requires':['black_flame_matrix','phosphoros_ash','wands'],'effect_id':'corpus_ignis_effect','visual_profile':{'mesh_overlay':'ember_skin','material_shift':'charcoal_to_ember','vfx':'low_black_flame','emission_cap':.32},'provenance_class':'electorum_dramatization'},
                {'id':'hand_of_artificer','name':'Mão do Artífice','requires':['hand_of_work','foundation_hammer','disks'],'effect_id':'hand_of_artificer_effect','visual_profile':{'mesh_overlay':'ritual_gauntlet','material_shift':'stone_to_burnished_gold','vfx':'construction_sigils','emission_cap':.28},'provenance_class':'electorum_dramatization'},
            ]
            for a in additions:
                if a['id'] not in ids: rows.append(enrich(name,a))
        write(name,rows)

    room_path=ROG/'special_rooms.json'
    rooms=json.loads(room_path.read_text())
    # Legacy post-boss rooms remain readable but cease to participate in the exclusive group.
    for r in rooms:
        r.pop('exclusive_group',None)
        r.setdefault('rarity','rare'); r.setdefault('pool','special_rooms')
        r.setdefault('effect',{'kind':'room_event','event':r['id'],'reward_pool':r.get('reward_pool',[])})
        r.setdefault('cost',{'resource':'none','amount':0}); r.setdefault('duration',{'mode':'room','seconds':0,'rooms':1})
        r.setdefault('stacking',{'mode':'none','max_stacks':1}); r.setdefault('synergies',[]); r.setdefault('exclusions',[])
        r.setdefault('vfx_hook',f"vfx.room.{r['id']}"); r.setdefault('sfx_hook',f"sfx.room.{r['id']}")
        r.setdefault('save_state',{'scope':'run','persist':True}); r.setdefault('codex',{'category':'Salas Especiais','summary':r.get('name',r['id'])})
        r.setdefault('provenance',prov(r)); r.setdefault('runtime_event',f"room.{r['id']}"); r.setdefault('persistent_state',{'visited':True,'resolved':True})
    ids={r['id'] for r in rooms}
    additions=[
        special_room('pneumatic','Câmara Pneumática','blessings',role='postboss',chance=.45,risk='commitment',access='postboss_portal',exclusive='postboss_path',requires={'min_rooms_cleared':1,'postboss':True}),
        special_room('chthonic','Câmara Ctônica','pact_reward',role='postboss',chance=.45,risk='curse_heat',access='postboss_portal',cost={'resource':'max_hp','amount':8},exclusive='postboss_path',requires={'min_rooms_cleared':1,'postboss':True}),
        special_room('pact_table','Mesa do Pacto','sigilla',role='postboss',chance=.35,risk='contract_debt',access='postboss_portal',cost={'resource':'essence','amount':12},exclusive='postboss_path',requires={'min_rooms_cleared':1,'postboss':True}),
        special_room('sacrifice','Câmara do Sacrifício','sacrifice_reward',chance=.20,risk='blood_price',cost={'resource':'hp','amount':12}),
        special_room('eden','Jardim do Éden','eden_fruit',chance=.18,risk='choice',access='eden_gate'),
        special_room('arbor_mortis','Arbor Mortis','mortis_fruit',chance=.14,risk='debt',access='mortis_gate'),
        special_room('liminal_laboratory','Laboratorium Liminale','quantum_branch',chance=.08,risk='decoherence',access='hidden_wall',requires={'min_rooms_cleared':2,'requires_quantum_lab':True}),
    ]
    for a in additions:
        if a['id'] not in ids: rooms.append(a)
    room_path.write_text(json.dumps(rooms,ensure_ascii=False,indent=2)+'\n')
    print('enriched', {n:len(json.loads((ROG/n).read_text())) for n in CATEGORY_KIND}, 'rooms',len(rooms))

if __name__=='__main__': main()
