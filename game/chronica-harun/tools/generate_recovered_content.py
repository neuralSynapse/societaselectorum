#!/usr/bin/env python3
from __future__ import annotations
import json, re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def dump(rel,obj):
    p=ROOT/rel; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n')

def slug(s):
    table=str.maketrans('áàâãäéêëíïóôõöúüçÁÀÂÃÄÉÊËÍÏÓÔÕÖÚÜÇ','aaaaaeeeii oooouucAAAAAEEEIIOOOOUUC'.replace(' ',''))
    return re.sub(r'[^a-z0-9]+','_',s.translate(table).lower()).strip('_')

stages=[
('o_olho','O OLHO','PERCEPÇÃO','discernimento, atenção e visão do oculto','blind_observer','revelatory_eye'),
('a_chama','A CHAMA','REGÊNCIA','governo interno, foco e comando','impulse_archon','black_flame_matrix'),
('a_fundacao','A FUNDAÇÃO','ESTRUTURA','base, limite e sustentação','inert_stone_guardian','foundation_hammer'),
('a_eleicao','A ELEIÇÃO','AUTOELEIÇÃO','escolha consciente contra reflexo de massa','seal_of_no','election_sigil'),
('a_balanca','A BALANÇA','AUTORRESPONSABILIDADE','custo, consequência e proporção','mask_collector','inner_balance'),
('a_vontade','A VONTADE','VERDADEIRA VONTADE','direção própria contra desejo implantado','false_daimon','will_vector'),
('o_carater','O CARÁTER','CARÁTER','coerência entre palavra, ato e pressão','stone_witness','character_column'),
('a_disciplina','A DISCIPLINA','DISCIPLINA','ritmo, repetição e constância sob atrito','rhythm_devourer','discipline_rhythm'),
('a_clareza','A CLAREZA','CLAREZA','redução de ruído e leitura de causalidade','clouding_one','clarity_light'),
('a_transmutacao','A TRANSMUTAÇÃO','TRANSMUTAÇÃO','converter dano, escória e conflito em recurso','slag_dragon','transmutation_serpent'),
('o_corpo','O CORPO','CORPO E ENERGIA','sustentar ação sem colapso de recurso','exhaustion_tyrant','vital_pulse'),
('a_obra','A OBRA','OBRA','construir forma externa a partir da direção interna','blind_architect','hand_of_work'),
('a_fortuna','A FORTUNA','FORTUNA','troca, risco e recursos sem servidão ao acaso','archontic_banker','sigillar_fortune'),
('a_influencia','A INFLUÊNCIA','INFLUÊNCIA','voz, comando e contágio social sem dissolução','approval_chorus','verbum'),
('o_legado','O LEGADO','LEGADO','memória, nome e continuidade que sobrevivem ao ciclo','durable_name_guardian','memoria_ignis'),
('initiation_chamber','CÂMARA DE INICIAÇÃO','INICIAÇÃO','síntese e passagem narrativa do Estudante ao estado Peregrinus Ignis','initiation_throne','memoria_ignis')]
journey=[]
for i,(sid,title,sub,theme,boss,power) in enumerate(stages):
    next_stage=stages[i+1][0] if i<len(stages)-1 else 'PEREGRINUS_IGNIS_GAME'
    commons=[f'{sid}_presence_{j+1:02d}' for j in range(4)]
    elite=f'{sid}_elite'
    journey.append({'id':sid,'index':i,'title':title,'subtitle':sub,'theme':theme,'boss_id':boss,'power_id':power,'common_enemy_ids':commons,'elite_id':elite,'room_budget':[1+min(2,i//5),2+min(2,i//6),3+min(2,i//7)],'next_stage':next_stage})
dump('data/stages/student_journey.json',journey)

families=['crawler','eye','ritualist','shade','chain','beast','winged','construct','chorus','serpent','fire','walker']
archon_names=['Athoth','Eloaios','Astaphaios','Yao','Adonin','Sabbataios','Sabaoth']
archon_sil=['ram_archon','asinine_archon','hyena_archon','seven_head_serpent','simian_archon','fire_face','draconic']
enemies=[]
for i,s in enumerate(journey):
    for j,eid in enumerate(s['common_enemy_ids']):
        fam=families[(i*3+j)%len(families)]
        name=f"{s['subtitle'].title()} · Presença {j+1}"
        if i==0 and j<4:
            name=archon_names[j]
            fam=archon_sil[j]
        enemies.append({'id':eid,'display_name':name,'stage_id':s['id'],'role':'common','family':fam,'model_path':f'res://art/generated/enemies/{eid}.glb','max_hp':42+i*6+j*4,'move_speed':1.65+(j%3)*.18,'visual_profile':{'silhouette':fam,'accent':['ochre','ashen','copper','violet'][j%4],'emission_cap':0.32},'attack':{'id':eid+'_attack','display_name':['Investida Telegrafada','Orbe de Pressão','Corte Angular','Pulso Radial'][j%4],'attack_kind':'projectile' if j%2 else 'movement','pattern':['dash','line','fan','radial'][j%4],'windup':round(0.78+i*.015+j*.05,2),'telegraph_time':round(.45+j*.04,2),'active':round(.28+j*.04,2),'recovery':round(.72+j*.05,2),'damage':8+i+j*2},'codex':f"Forma de prova de {s['subtitle']}. A identidade de gameplay é dramatização Electorum.",'provenance':{'class':'electorum_dramatization','source_note':'Gameplay autoral; nomes tradicionais, quando usados, são marcados separadamente.'}})
    elite_id=s['elite_id']
    elite_name=f"{s['subtitle'].title()} · Autoridade"
    fam=families[(i*5+7)%len(families)]
    if i<3:
        elite_name=archon_names[4+i]
        fam=archon_sil[4+i]
    enemies.append({'id':elite_id,'display_name':elite_name,'stage_id':s['id'],'role':'elite','family':fam,'model_path':f'res://art/generated/enemies/{elite_id}.glb','max_hp':140+i*15,'move_speed':1.85+(i%4)*.12,'visual_profile':{'silhouette':fam,'accent':'old_gold','emission_cap':0.38},'attack':{'id':elite_id+'_attack','display_name':'Autoridade em Três Tempos','attack_kind':'projectile','pattern':'fan','windup':.7,'telegraph_time':.5,'active':.5,'recovery':.9,'damage':20+i},'codex':f"Autoridade intermediária de {s['subtitle']}; forma autoral de jogo.",'provenance':{'class':'electorum_dramatization','source_note':'Dramatização de mecânica.'}})
# add 2 rare entities to hit 82
for k in range(2):
    enemies.append({'id':f'rare_witness_{k+1}','display_name':['Testemunha do Limite','Serpente do Intervalo'][k],'stage_id':'global','role':'rare','family':['eye','serpent'][k],'model_path':f'res://art/generated/enemies/rare_witness_{k+1}.glb','max_hp':180+k*40,'move_speed':1.6,'visual_profile':{'silhouette':['eye','serpent'][k],'accent':'cold_gold','emission_cap':.3},'attack':{'id':f'rare_witness_{k+1}_attack','display_name':'Ruptura Rara','attack_kind':'projectile','pattern':'radial','windup':1.0,'telegraph_time':.65,'active':.55,'recovery':1.1,'damage':28+k*4},'codex':'Presença rara da Jornada.','provenance':{'class':'electorum_dramatization','source_note':'Gameplay autoral.'}})
dump('data/enemies/student_enemies.json',enemies)

boss_defs=[
('blind_observer','O Observador Cego','orbital_eye'),('impulse_archon','Arconte do Impulso','horned_flame'),('inert_stone_guardian','Guardião da Pedra Inerte','stone_colossus'),('seal_of_no','O Selo do Não','living_seal'),('mask_collector','O Cobrador de Máscaras','mask_swarm'),('false_daimon','O Falso Daimon','split_daemon'),('stone_witness','A Testemunha de Pedra','pillar_judge'),('rhythm_devourer','O Devorador de Ritmo','clock_maw'),('clouding_one','O Nublador','fog_oracle'),('slag_dragon','O Dragão da Escória','slag_dragon'),('exhaustion_tyrant','O Tirano da Exaustão','rib_tyrant'),('blind_architect','O Arquiteto Cego','blind_architect'),('archontic_banker','O Banqueiro Arcôntico','coin_throne'),('approval_chorus','O Coral da Aprovação','chorus_mass'),('durable_name_guardian','O Guardião do Nome Durável','archive_guardian'),('initiation_throne','Trono da Iniciação','sevenfold_throne')]
bosses=[]
for i,(bid,name,sil) in enumerate(boss_defs):
    phases=[]
    for p,thr in enumerate([1.0,.66,.32]):
        attacks=[]
        for k in range(2):
            attacks.append({'id':f'{bid}_p{p+1}_a{k+1}','display_name':f'{name} · Movimento {p*2+k+1}','attack_kind':'projectile' if k==0 or p==2 else 'movement','pattern':['line','fan','radial','dash','zone','summon'][(i+p+k)%6],'windup':round(.9-p*.1+k*.06,2),'telegraph_time':round(.58-p*.04+k*.02,2),'active':round(.35+p*.1,2),'recovery':round(.82-p*.08,2),'damage':20+i*2+p*5+k*2})
        phases.append({'index':p+1,'threshold':thr,'arena_modifier':['stable','pressure','collapse'][p],'attacks':attacks})
    bosses.append({'id':bid,'display_name':name,'stage_id':journey[i]['id'],'model_path':f'res://art/generated/bosses/{bid}.glb','silhouette':sil,'max_hp':900+i*120,'move_speed':1.5+(i%4)*.12,'reward_id':bid+'_relic','phases':phases,'codex':f'{name} encerra {journey[i]["subtitle"]}. As fases são dramatização Electorum, não reconstrução histórica.','provenance':{'class':'electorum_dramatization' if i<15 else 'source_inspired_synthesis','source_note':'Motivos tradicionais são separados de mecânicas autorais.'}})
dump('data/bosses/student_bosses.json',bosses)

# Tarot Thoth structure
atu=['The Fool','The Magus','The Priestess','The Empress','The Emperor','The Hierophant','The Lovers','The Chariot','Adjustment','The Hermit','Fortune','Lust','The Hanged Man','Death','Art','The Devil','The Tower','The Star','The Moon','The Sun','The Aeon','The Universe']
atu_fx=['threshold_reset','echo_instrument','secret_sight','fecundity','command','tradition','syzygy','chariot','adjustment','hermit','fortune','lust','suspension','death','art','devil','tower','star','moon','sun','aeon','universe']
tarot=[{'id':f'atu_{i:02d}_{slug(fx)}','group':'atu','rank':i,'name':n,'effect_id':fx,'provenance_class':'tradition','gameplay_class':'electorum_dramatization'} for i,(n,fx) in enumerate(zip(atu,atu_fx))]
minor_titles={
'wands':['Root of the Powers of Fire','Dominion','Virtue','Completion','Strife','Victory','Valour','Swiftness','Strength','Oppression','Princess of Wands','Prince of Wands','Queen of Wands','Knight of Wands'],
'cups':['Root of the Powers of Water','Love','Abundance','Luxury','Disappointment','Pleasure','Debauch','Indolence','Happiness','Satiety','Princess of Cups','Prince of Cups','Queen of Cups','Knight of Cups'],
'swords':['Root of the Powers of Air','Peace','Sorrow','Truce','Defeat','Science','Futility','Interference','Cruelty','Ruin','Princess of Swords','Prince of Swords','Queen of Swords','Knight of Swords'],
'disks':['Root of the Powers of Earth','Change','Works','Power','Worry','Success','Failure','Prudence','Gain','Wealth','Princess of Disks','Prince of Disks','Queen of Disks','Knight of Disks']}
for suit,titles in minor_titles.items():
    for r,title in enumerate(titles,1):
        tarot.append({'id':f'{suit}_{r:02d}','group':'minor','suit':suit,'rank':r,'name':title,'effect_id':f'{suit}_{r:02d}_effect','magnitude':8+r*2,'provenance_class':'tradition','gameplay_class':'electorum_dramatization'})
dump('data/roguelite/tarot_thoth.json',tarot)

goetia=['Bael','Agares','Vassago','Samigina','Marbas','Valefor','Amon','Barbatos','Paimon','Buer','Gusion','Sitri','Beleth','Leraje','Eligos','Zepar','Botis','Bathin','Sallos','Purson','Marax','Ipos','Aim','Naberius','Glasya-Labolas','Bune','Ronove','Berith','Astaroth','Forneus','Foras','Asmoday','Gaap','Furfur','Marchosias','Stolas','Phenex','Halphas','Malphas','Raum','Focalor','Vepar','Sabnock','Shax','Vine','Bifrons','Uvall','Haagenti','Crocell','Furcas','Balam','Alloces','Caim','Murmur','Orobas','Gremory','Ose','Amy','Orias','Vapula','Zagan','Valac','Andras','Haures','Andrealphus','Cimejes','Amdusias','Belial','Decarabia','Seere','Dantalion','Andromalius']
ranks=['King','Duke','Prince','Marquis','President','Duke','Marquis','Duke','King','President','Duke','Prince','King','Marquis','Duke','Duke','President / Earl','Duke','Duke','King','Earl / President','Prince / Earl','Duke','Marquis','President / Earl','Duke','Marquis / Earl','Duke','Duke','Marquis','President','King','President / Prince','Earl','Marquis','Prince','Marquis','Earl','President','Earl','Duke','Duke','Marquis','Marquis','King / Earl','Earl','Duke','President','Duke','Knight','King','Duke','President','Duke','Prince','Duke','President','President','Marquis','Duke','King / President','President','Marquis','Duke','Marquis','Marquis','Duke','King','Marquis','Prince','Duke','Earl']
doms=['authority','secret','mobility','guard','fortune','verbum','rupture','vision']; costs=['focus','max_hp','essence','curse','threat','instrument_charge','no_heal','talisman_lock']
sig=[{'id':f'sigil_{i:02d}_{slug(n)}','order':i,'name':n,'historical_rank':r,'effect_id':f'sigil_{i:02d}_{doms[(i-1)%8]}','dominium':doms[(i-1)%8],'pretium':costs[((i-1)*3)%8],'boon_magnitude':6+((i*7)%19),'cost_magnitude':5+((i*11)%17),'provenance_class':'tradition','gameplay_class':'electorum_dramatization'} for i,(n,r) in enumerate(zip(goetia,ranks),1)]
dump('data/roguelite/sigilla_goetia.json',sig)

principles=['Sulphur','Mercurius','Sal']; planets=['Sol','Lua','Mercúrio','Vênus','Marte','Júpiter','Saturno']; benefits=['damage','focus','speed','heal','burst','essence','armor']; sides=['none','fragility','focus_drain','slow','hp_cost','curse_chance','locked_slot']
ph=[]
for pi,p in enumerate(principles):
    for ji,planet in enumerate(planets):
        idx=pi*7+ji; ph.append({'id':f'ph_{idx+1:02d}_{slug(p)}_{slug(planet)}','principle':p,'planet':planet,'effect_id':f'pharmakon_{idx+1:02d}','benefit':benefits[ji],'side_effect':sides[(pi*2+ji)%7],'magnitude':8+ji*3,'provenance_class':'interpretation','gameplay_class':'electorum_dramatization'})
dump('data/roguelite/pharmaka.json',ph)

signs=['Áries','Touro','Gêmeos','Câncer','Leão','Virgem','Libra','Escorpião','Sagitário','Capricórnio','Aquário','Peixes']; base_fx=['opening_strike','armor_heal','double_activation','damage_shield','visible_damage','precision_recharge','resource_balance','execute_poison','range_speed','discipline_reward','chain_effect','focus_phase']
tals=[]
for si,sign in enumerate(signs):
    for dec in range(1,4):
        idx=si*3+dec; tals.append({'id':f'decan_{idx:02d}','sign':sign,'decan':dec,'effect_id':f'{base_fx[si]}_{dec}','magnitude':2+dec*2,'provenance_class':'interpretation','gameplay_class':'electorum_dramatization'})
dump('data/roguelite/talismans_decanic.json',tals)

inst=[('Bastão Ígneo','cone_fire'),('Vara Serpentina','chain_strike'),('Cetro Solar','solar_burst'),('Bastão de Mercúrio','tempo_shift'),('Vara de Marte','dash_break'),('Bastão da Chama Negra','black_flame'),('Cálice Lunar','focus_well'),('Taça do Véu','phase'),('Copa de Vênus','heal_link'),('Cratera de Sophia','transmute_hurt'),('Cálice de Água Negra','curse_cleanse'),('Taça do Retorno','return'),('Lâmina de Ruptura','armor_break'),('Athame de Thoth','mark_reveal'),('Espada Solar','line_beam'),('Faca do Verbum','silence'),('Lâmina de Saturno','slow_cut'),('Espada do Limiar','door_cut'),('Disco de Saturno','fortify'),('Pentáculo Solar','ward'),('Disco de Fortuna','reroll'),('Selo de Terra','anchor'),('Moeda de Júpiter','multiply_essence'),('Placa de Belial','grounding'),('Espelho de Sophia','reflect'),('Lâmpada de Phosphoros','reveal_all'),('Livro do Verbum','command_wave'),('Ampulheta de Kairos','time_stop'),('Máscara de Paimon','dominate'),('Olho de Hórus','precision'),('Tabuleta de Thoth','echo_card'),('Chave Dracônica','red_path')]
dump('data/roguelite/instrumenta.json',[{'id':f'instrument_{i+1:02d}','name':n,'effect_id':e,'charges':2+i%4,'provenance_class':'electorum_dramatization'} for i,(n,e) in enumerate(inst)])

power_rows=[('revelatory_eye','Olho Revelatório',['revealed_crit','projectile_vision','secret_map']),('black_flame_matrix','Chama Negra',['ember_corpse','hurt_fuels_flame','chain_flame']),('foundation_hammer','Martelo de Fundação',['shockwave','break_armor_secret','elite_stamina']),('election_sigil','Sigilo da Eleição',['first_mark_crit','fear_immunity','choice_shield']),('inner_balance','Balança Interna',['hp_to_focus','focus_to_shield','balance_cleanse']),('will_vector','Vetor da Vontade',['projectile_dash','unstoppable_action','execute_low']),('character_column','Coluna de Caráter',['still_defense','block_attack','calm_focus']),('discipline_rhythm','Ritmo da Disciplina',['combo_recharge','perfect_dodge_charge','no_damage_speed']),('clarity_light','Luz de Clareza',['telegraph_reveal','visual_cleanse','route_marker']),('transmutation_serpent','Serpente da Transmutação',['hurt_to_focus','curse_to_buff','overflow_to_essence']),('vital_pulse','Pulso Vital',['room_heal','perfect_dodge_stamina','low_hp_speed']),('hand_of_work','Mão da Obra',['temporary_ward','virtual_charge','break_fragment']),('sigillar_fortune','Fortuna Sigilar',['reward_reroll','essence_rare_room','pact_refund']),('verbum','Verbum',['push_wave','silence_ranged','temporary_dominate']),('memoria_ignis','Memoria Ignis',['first_card_free','instrument_charge_memory','build_trait_memory'])]
dump('data/roguelite/powers.json',[{'id':pid,'name':name,'stage_index':i,'effect_id':pid+'_base','mutations':[{'id':pid+f'_m{j+1}','effect_id':m,'tier':j+1} for j,m in enumerate(muts)],'provenance_class':'electorum_dramatization'} for i,(pid,name,muts) in enumerate(power_rows)])

daim=[('daimon_lampadary','Daimon Lampadário','reveal_secret'),('daimon_serpentine','Daimon Serpentino','execute_bite'),('daimon_scribe','Daimon Escriba','arcana_echo'),('daimon_specular','Daimon Specular','attack_echo'),('daimon_funerary','Daimon Funerário','corpse_essence'),('daimon_saturnine','Daimon Saturnino','projectile_intercept'),('daimon_solar','Daimon Solar','curse_purge')]
dump('data/roguelite/daimones.json',[{'id':i,'name':n,'effect_id':e,'provenance_class':'electorum_dramatization'} for i,n,e in daim])
relics=[('mirror_sophia','Espelho de Sophia','reflect_first_projectile'),('pleroma_fragment','Fragmento do Pleroma','third_arcana_free'),('blind_eye','Olho do Cego','secret_reveal_hp_hidden'),('broken_crown','Coroa Quebrada','elite_risk_reward'),('phosphoros_ash','Cinza de Phosphoros','one_hp_black_flame'),('saturn_disk','Disco de Saturno','slow_damage_reduction'),('belial_seal','Selo de Belial','knockback_immunity_melee'),('lilith_veil','Véu de Lilith','slower_detection_pact_focus'),('thoth_feather','Pena de Thoth','first_arcana_echo')]
dump('data/roguelite/relics.json',[{'id':i,'name':n,'effect_id':e,'provenance_class':'electorum_dramatization'} for i,n,e in relics])
curses=[('fog','Névoa','map_visibility'),('silence','Silêncio','power_lock'),('scarcity','Escassez','reduced_drops'),('focus_ruin','Ruína de Foco','focus_regen_down'),('chamber_warp','Distorção de Câmara','room_links_shift'),('labyrinth','Labirinto','map_hidden'),('ritual_blindness','Cegueira Ritual','enemy_hp_hidden'),('hostile_echo','Eco Hostil','extra_echo_enemy')]
dump('data/roguelite/curses.json',[{'id':i,'name':n,'effect_id':e,'provenance_class':'electorum_dramatization'} for i,n,e in curses])
bless=[('sophia_light','Luz de Sophia','second_chance_focus'),('lucifer_glow','Fulgor de Lúcifer','damage_reveal'),('horus_eye','Olho de Hórus','precision'),('thoth_word','Palavra de Thoth','arcana_echo'),('belial_order','Ordem de Belial','armor'),('paimon_crown','Coroa de Paimon','command')]
dump('data/roguelite/blessings.json',[{'id':i,'name':n,'effect_id':e,'provenance_class':'electorum_dramatization'} for i,n,e in bless])
routes=[('student','Rota do Estudante'),('initiation','Rota da Iniciação'),('sophia','Rota de Sophia'),('luciferian','Rota Luciferiana'),('archontic','Rota Arcôntica'),('draconis','Rota Velada · Draconis'),('pleroma','Rota do Pleroma'),('exile','Rota do Exílio')]
dump('data/roguelite/routes.json',[{'id':i,'name':n,'effect_id':'route_'+i,'provenance_class':'electorum_dramatization'} for i,n in routes])

trans=[('mark_of_cain',['cain_mark','rupture'],'scar_line','iron_to_ember','red_sparks'),('child_of_flame',['black_flame_matrix','phosphoros_ash'],'ember_crown','charcoal_to_gold','black_flame_veil'),('open_eye',['revelatory_eye','blind_eye'],'third_eye_plate','ashen_to_cold_gold','iris_scan'),('sophia_herald',['mirror_sophia','pleroma_fragment'],'mirror_shards','violet_to_pearl','soft_refraction'),('verbum_bearer',['verbum','thoth_feather'],'script_band','ochre_to_ivory','glyph_wave'),('transmutation_serpent_form',['transmutation_serpent','pharmaka'],'serpent_coil','copper_to_serpentine','alchemical_mist'),('peregrine_vestment',['memoria_ignis','15_stages'],'pilgrim_cloak','black_to_old_gold','ember_steps'),('archon_mask',['sigillum','pact'],'archon_mask','bone_to_obsidian','sigil_orbit'),('legacy_seal',['memoria_ignis','durable_name_guardian'],'name_seal','iron_to_archive_gold','memory_dust'),('phosphoros_lamp',['instrument_26','lucifer'],'lamp_halo','dark_to_cold_gold','phosphoros_rays')]
dump('data/roguelite/transformations.json',[{'id':i,'requires':req,'effect_id':i+'_effect','visual_profile':{'mesh_overlay':mesh,'material_shift':mat,'vfx':vfx,'emission_cap':.34},'provenance_class':'electorum_dramatization'} for i,req,mesh,mat,vfx in trans])

# Special rooms: all have explicit conditions and spatial/runtime contracts
special_specs=[
('arcana',.20,0,'door_after_clear','low',['tarot'],'tarot glyph rotating slowly'),('reliquary',.13,1,'key_or_cost','medium',['relics'],'sealed reliquary arch'),('instrumentarium',.16,1,'door_after_clear','low',['instrumenta'],'weapon silhouette rack'),('laboratorium',.15,2,'door_after_clear','medium',['pharmaka'],'alchemical glass and planetary seal'),('sigillar',.12,2,'essence_cost','medium',['sigilla'],'72-fold seal lattice'),('market',.18,1,'essence_cost','low',['mixed'],'balanced scales'),('bibliotheca',.11,2,'codex_threshold','low',['codex'],'book-and-eye lintel'),('speculum',.10,3,'reflection_condition','medium',['transformations'],'black mirror'),('planetary',.10,3,'planetary_condition','medium',['talismans'],'planetary ring'),('trial',.25,0,'door_after_clear','high',['mixed'],'red trial stele'),('cursed',.08,4,'curse_accept','high',['relics','tarot'],'cracked inverted halo'),('secret',.75,0,'rupture_charge','medium',['mixed'],'hairline wall fracture'),('super_secret',.22,3,'rupture_charge_plus_condition','high',['rare'],'double fracture with cold draft'),('archon',.11,4,'archon_route_or_mark','high',['sigilla','relics'],'animal-mask lintel'),('theophany',.08,5,'vision_condition','variable',['blessings'],'non-hostile radiant threshold'),('historical_echo',.07,4,'codex_or_route_condition','low',['codex','insight'],'documentary echo markers'),('initiation',1.0,15,'stage_final','high',['initiation'],'sevenfold threshold'),('solar_benediction',.35,2,'post_boss_exclusive','medium',['blessings'],'upright solar aperture'),('chthonic_pact',.35,2,'post_boss_exclusive','high',['sigilla','relics'],'descending pact aperture')]
special=[]
for rid,ch,minstage,access,risk,pool,tel in special_specs:
    eligibility={'min_rooms_cleared':1,'forbidden_after_choice':rid in ['solar_benediction','chthonic_pact']}
    if rid=='super_secret': eligibility.update({'requires_secret_found':True,'min_cycle':1})
    if rid=='theophany': eligibility.update({'requires_no_hostile_echo':True})
    if rid=='historical_echo': eligibility.update({'requires_codex_entries':4})
    if rid=='initiation': eligibility={'stage_id':'initiation_chamber'}
    special.append({'id':rid,'name':rid.replace('_',' ').title(),'base_chance':ch,'min_stage':minstage,'max_per_floor':1,'eligibility':eligibility,'access':access,'risk':risk,'reward_pool':pool,'telegraph':tel,'room_size':[8,5,8] if rid not in ['trial','archon'] else [12,6,12],'provenance_class':'electorum_dramatization'})
dump('data/roguelite/special_rooms.json',special)

# Theophanies and echoes with contextual conditions
theo_specs=[('lucifer_phosphoros','Lúcifer / Phosphoros','vision_or_patron','luciferian',{'route':['luciferian','draconis'],'min_stage':4}),('horus','Hórus','judge','horus',{'precision_events':3}),('thoth','Thoth','vision_or_patron','thoth',{'codex_entries':8}),('belial','Belial','pact','belial',{'route':['archontic','draconis']}),('paimon','Paimon','vision_or_patron','paimon',{'sigilla_bound':1}),('lilith','Lilith','vision_or_patron','lilith',{'secrets_found':1}),('sophia','Sophia','blessing','sophia',{'route':['sophia','pleroma']}),('yaldabaoth','Yaldabaoth','judge','yaldabaoth',{'stage':['a_clareza','initiation_chamber']}),('sabaoth','Sabaoth','blessing','sabaoth',{'archon_defeats':3}),('seth','Seth','memory','seth',{'route':['pleroma','student']}),('samael','Samael','judge','samael',{'curse_count':2}),('baphomet','Baphomet','vision_or_patron','baphomet',{'transformation_count':1}),('mammon','Mammon','pact','mammon',{'essence_spent':15}),('agares','Agares','pact','agares',{'sigillum':'sigil_02_agares'}),('sitri','Sitri','pact','sitri',{'sigillum':'sigil_12_sitri'}),('ra','Rá','blessing','ra',{'solar_room':True}),('vishnu','Vishnu','vision_or_patron','vishnu',{'survived_low_hp':True}),('ganesh','Ganesh','blessing','ganesh',{'blocked_route_reopened':True})]
theoph=[]
for i,name,app,tag,conditions in theo_specs:
    theoph.append({'id':i,'name':name,'appearance':app,'role':tag,'effect_id':'theophany_'+i,'conditions':conditions,'codex_note':f'{name}: aparição contextual de jogo. O papel tradicional e a dramatização mecânica permanecem separados.','provenance_class':'tradition','source_note':'Tradição/recepção identificada no Codex; efeito e condição são dramatização Electorum.'})
dump('data/roguelite/theophanies.json',theoph)
echo_specs=[('aleister_crowley','Aleister Crowley','source',{'codex_entries':6}),('michael_w_ford','Michael W. Ford','source',{'route':['luciferian','draconis']}),('paracelsus','Paracelso','source',{'pharmaka_used':3}),('eliphas_levi','Éliphas Lévi','source',{'sigilla_bound':1}),('giordano_bruno','Giordano Bruno','source',{'theophanies_seen':2}),('hermes_trismegistus','Hermes Trismegistus','tradition',{'codex_entries':10})]
echoes=[]
for i,n,prov,cond in echo_specs:
    echoes.append({'id':i,'name':n,'appearance':'narrative_echo','effect_id':'echo_'+i,'conditions':cond,'codex_note':f'{n}: eco documental/narrativo, nunca inimigo genérico.','provenance_class':prov,'source_note':'Figura histórica/tradicional separada da dramatização Electorum.'})
dump('data/roguelite/historical_echoes.json',echoes)

# Gauntlets
gauntlets=[
{'id':'blind_crown','name':'Coroa Cega','unlock_conditions':{'student_completion':True},'modifiers':['enemy_telegraphs_faster','no_map'],'completion_mark':'gauntlet_blind_crown'},
{'id':'seven_authorities','name':'Sete Autoridades','unlock_conditions':{'archon_codex':7},'modifiers':['archon_rooms_forced','elite_budget_plus_one'],'completion_mark':'gauntlet_seven_authorities'},
{'id':'phosphoros_trial','name':'Prova de Phosphoros','unlock_conditions':{'route':'luciferian','theophanies_seen':3},'modifiers':['light_reveals_damage','curse_rooms_plus_one'],'completion_mark':'gauntlet_phosphoros_trial'},
{'id':'pleroma_return','name':'Retorno ao Pleroma','unlock_conditions':{'routes_completed':4},'modifiers':['no_market','visions_forced','boss_phase_speed_plus'],'completion_mark':'gauntlet_pleroma_return'}]
for g in gauntlets: g['provenance_class']='electorum_dramatization'
dump('data/roguelite/gauntlets.json',gauntlets)

# Codex, including explicit source/tradition/interpretation/dramatization classes
codex=[
{'id':'method:source','title':'FONTE','body':'O que uma fonte primária ou testemunho documental permite afirmar.','provenance_class':'source','source_note':'Regra epistemológica do projeto.'},
{'id':'method:tradition','title':'TRADIÇÃO','body':'Recepção ou estrutura historicamente transmitida, sem confundi-la com uma fonte única.','provenance_class':'tradition','source_note':'Regra epistemológica do projeto.'},
{'id':'method:interpretation','title':'INTERPRETAÇÃO','body':'Leitura filosófica ou comparativa explicitamente marcada.','provenance_class':'interpretation','source_note':'Regra epistemológica do projeto.'},
{'id':'method:electorum','title':'DRAMATIZAÇÃO ELECTORUM','body':'Mecânica, síntese ou encenação autoral do videogame.','provenance_class':'electorum_dramatization','source_note':'Regra autoral do projeto.'}]
for s in journey: codex.append({'id':'stage:'+s['id'],'title':s['title']+' · '+s['subtitle'],'body':s['theme'],'provenance_class':'electorum_dramatization','source_note':'Etapa ficcional de gameplay.'})
for e in enemies: codex.append({'id':'enemy:'+e['id'],'title':e['display_name'],'body':e['codex'],'provenance_class':'electorum_dramatization','source_note':e['provenance']['source_note']})
for b in bosses: codex.append({'id':'boss:'+b['id'],'title':b['display_name'],'body':b['codex'],'provenance_class':'electorum_dramatization' if b['id']!='initiation_throne' else 'source_inspired_synthesis','source_note':b['provenance']['source_note']})
for t in theoph: codex.append({'id':'theophany:'+t['id'],'title':t['name'],'body':t['codex_note'],'provenance_class':t['provenance_class'],'source_note':t['source_note']})
for e in echoes: codex.append({'id':'echo:'+e['id'],'title':e['name'],'body':e['codex_note'],'provenance_class':e['provenance_class'],'source_note':e['source_note']})
dump('data/codex/full_codex.json',codex)

# room themes
room_themes=[]
for i,s in enumerate(journey): room_themes.append({'stage_id':s['id'],'palette':['#0b0a09','#1c1814','#4b4033','#8e7148'],'floor_material':s['id']+'_floor','wall_material':s['id']+'_wall','props':['stele','arch','plinth','seal'],'fog_density':round(.012+(i%5)*.003,3),'accent_emission_cap':.32})
dump('data/rooms/student_room_themes.json',room_themes)
print('generated recovery content')
