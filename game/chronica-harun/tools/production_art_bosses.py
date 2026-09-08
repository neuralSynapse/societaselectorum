from __future__ import annotations

import math
import trimesh

from production_art_core import (
    add, add_armor_plate, add_eye, add_horn, add_rib_arc, box, capsule, cone,
    cylinder, ground_scene, production_material, seed_for, sphere, torus, transform,
)


def blind_observer_candidate(sc, mat, v):
    add(sc,sphere(.84,3),"observer_eye_shell",transform(0,1.72,0,sx=1.28,sy=.72,sz=.62),production_material("charcoal"))
    add(sc,sphere(.48,3),"observer_sclera",transform(0,1.72,-.53,sx=1.20,sy=.78,sz=.24),production_material("bone_ash"))
    add(sc,sphere(.20,3),"observer_blind_iris",transform(0,1.72,-.67,sx=1.0,sy=.92,sz=.18),production_material("blind_iris"))
    add(sc,torus(1.10,.055,28),"observer_orbit_a",transform(0,1.72,.04,rx=.18,ry=.15),production_material("burnt_gold"))
    add(sc,torus(1.29,.045,28),"observer_orbit_b",transform(0,1.72,.05,rx=-.25,ry=.33,rz=.22),production_material("copper"))
    for i in range(7):
        a=i/7*math.tau
        x=math.cos(a)*1.16; y=1.72+math.sin(a)*.76
        add_eye(sc,f"observer_eyelet_{i}",x,y,-.23,.66)
    for side in (-1,1):
        add(sc,capsule(.09,1.28),f"observer_support_{side}",transform(side*.72,.69,.22,rz=side*.21),production_material("burnt_stone"))
        add(sc,box((.32,.20,.46)),f"observer_guard_{side}",transform(side*.76,.18,.20),production_material("burnt_stone"))
    for i in range(4):
        add(sc,capsule(.045,.82),f"observer_tendril_{i}",transform((i-1.5)*.24,.54,.38,rz=(i-1.5)*.16),production_material("copper"))
    add(sc,box((.55,.09,.09)),"observer_windup_bar",transform(0,1.20,-.68),production_material("ritual_red"))


def impulse_archon_candidate(sc, mat, v):
    add(sc,cone(.76,2.15,18),"impulse_torso",transform(0,1.10,.08,sx=1.04,sz=.82),production_material("charcoal"))
    add(sc,sphere(.38,2),"impulse_skull",transform(0,2.12,-.12,sx=.92,sy=1.05,sz=.72),production_material("heated_metal"))
    add_horn(sc,"impulse_horn_l",-.23,2.28,-.06,-1,.95,.13); add_horn(sc,"impulse_horn_r",.23,2.28,-.06,1,.95,.13)
    add_eye(sc,"impulse_eye_l",-.13,2.14,-.39,.72); add_eye(sc,"impulse_eye_r",.13,2.14,-.39,.72)
    for side in (-1,1):
        add(sc,capsule(.105,1.38),f"impulse_arm_{side}",transform(side*.72,1.10,-.02,rz=side*.18),production_material("ritual_red"))
        add(sc,cone(.15,.78,10),f"impulse_blade_{side}",transform(side*.84,.35,-.08,rz=side*.15),production_material("heated_metal"))
    for i in range(7): add_rib_arc(sc,f"impulse_rib_{i}",.78+i*.18,.90+(i%2)*.05,-.44)
    for i in range(6):
        a=i/6*math.tau
        add(sc,cone(.09,.48+(i%2)*.12,8),f"impulse_material_flame_{i}",transform(math.cos(a)*.48,1.68+math.sin(a)*.42,.20,rz=math.cos(a)*.35),production_material("heated_metal"))
    add(sc,box((.58,.10,.08)),"impulse_windup_bar",transform(0,1.40,-.54),production_material("burnt_gold"))


def inert_stone_guardian_candidate(sc, mat, v):
    add(sc,box((1.50,1.90,1.02)),"guardian_core",transform(0,1.22,.12),production_material("burnt_stone"))
    add(sc,box((.92,.52,.82)),"guardian_low_head",transform(0,2.24,-.18),production_material("charcoal"))
    add(sc,box((.48,.16,.09)),"guardian_face_cut",transform(0,2.22,-.63),production_material("void"))
    for side in (-1,1):
        add(sc,box((.58,1.55,.56)),f"guardian_arm_{side}",transform(side*1.02,1.20,.03,rz=side*.04),production_material("burnt_stone"))
        add(sc,box((.70,.42,.66)),f"guardian_fist_{side}",transform(side*1.02,.29,-.02),production_material("burnt_stone"))
        add(sc,box((.56,.72,.62)),f"guardian_leg_{side}",transform(side*.42,.32,.15),production_material("charcoal"))
        add(sc,box((.56,.30,1.04)),f"guardian_buttress_{side}",transform(side*.78,2.04,.28,rz=side*.35),production_material("burnt_stone"))
    for i in range(5):
        add(sc,box((.08,.62,.055)),f"guardian_fissure_{i}",transform((i-2)*.22,1.24,-.43,rz=(i-2)*.12),production_material("copper"))
    add_armor_plate(sc,"guardian_keystone",0,1.70,-.54,.52,.44,.10,material_name="burnt_gold")


def living_seal(sc,mat,v):
    add(sc,cylinder(.16,2.35,16),"seal_spine",transform(0,1.20,.22),production_material("burnt_stone"))
    for i in range(4): add(sc,torus(.50+i*.18,.052),f"seal_ring_{i}",transform(0,1.55,0,rx=math.pi/2,rz=i*.28),production_material("burnt_gold" if i%2==0 else "copper"))
    for i in range(2): add(sc,box((1.72,.08,.11)),f"seal_cross_{i}",transform(0,1.55,-.08,rz=math.pi/4+i*math.pi/2),production_material("burnt_stone"))
    for side in (-1,1): add(sc,box((.24,1.08,.24)),f"seal_leg_{side}",transform(side*.30,.52,.18),production_material("charcoal"))


def mask_swarm(sc,mat,v):
    add(sc,cone(.52,2.1,16),"mask_spine",transform(0,1.08,.2),production_material("charcoal"))
    for i in range(7):
        a=i/7*math.tau
        add(sc,sphere(.23,2),f"mask_{i}",transform(math.cos(a)*.92,1.5+math.sin(a)*.72,-.25,sx=1.15,sy=.75,sz=.40),production_material("bone_ash"))
        add(sc,box((.18,.04,.04)),f"mask_slit_{i}",transform(math.cos(a)*.92,1.5+math.sin(a)*.72,-.36),production_material("void"))
    for side in (-1,1): add(sc,capsule(.075,.82),f"mask_arm_{side}",transform(side*.46,.72,.10,rz=side*.20),production_material("copper"))


def split_daemon(sc,mat,v):
    for side in (-1,1):
        add(sc,cone(.46,1.95,15),f"split_half_{side}",transform(side*.36,1.08,0,rz=side*.08),production_material("ritual_red" if side<0 else "charcoal"))
        add(sc,sphere(.29,2),f"split_head_{side}",transform(side*.27,2.2,0),production_material("burnt_stone"))
        add_horn(sc,f"split_horn_{side}",side*.32,2.38,.04,side,.52,.08)
    add(sc,box((.09,1.72,.12)),"split_gap",transform(0,1.24,-.25),production_material("void"))
    add(sc,torus(.66,.045),"split_bind",transform(0,1.20,.10,rx=math.pi/2),production_material("copper"))


def pillar_judge(sc,mat,v):
    add(sc,cylinder(.50,2.75,18),"judge_pillar",transform(0,1.38,0),production_material("burnt_stone")); add(sc,box((1.45,.27,1.05)),"judge_capital",transform(0,2.85,0),production_material("burnt_stone"))
    add(sc,box((.74,.32,.32)),"judge_face",transform(0,2.42,-.54),production_material("charcoal"))
    for side in (-1,1): add(sc,box((.28,1.28,.28)),f"judge_arm_{side}",transform(side*.62,1.38,.02),production_material("copper"))
    add(sc,torus(.54,.045),"judge_halo",transform(0,2.54,.12,rx=math.pi/2),production_material("burnt_gold"))


def clock_maw(sc,mat,v):
    add(sc,torus(.98,.11,28),"clock_outer",transform(0,1.65,0,rx=math.pi/2),production_material("copper")); add(sc,torus(.68,.07,24),"clock_inner",transform(0,1.65,-.05,rx=math.pi/2),production_material("burnt_gold"))
    add(sc,sphere(.58,2),"clock_maw",transform(0,1.65,-.05,sx=1,sy=.7,sz=.6),production_material("charcoal"))
    for i in range(8):
        a=i/8*math.tau; add(sc,cone(.07,.30,7),f"clock_tooth_{i}",transform(math.cos(a)*.44,1.65+math.sin(a)*.31,-.48,rz=-a),production_material("bone_ash"))
    for side in (-1,1): add(sc,box((.18,1.18,.18)),f"clock_leg_{side}",transform(side*.40,.54,.16),production_material("burnt_stone"))


def fog_oracle(sc,mat,v):
    for i in range(8): add(sc,sphere(.46,2),f"oracle_cloud_{i}",transform(math.sin(i*1.4)*.62,1.15+(i%4)*.4,math.cos(i*.9)*.26,sx=1.2,sy=.72,sz=.82),production_material("charcoal"))
    add(sc,cone(.42,1.62,14),"oracle_body",transform(0,.82,.18),production_material("burnt_stone"))
    add_armor_plate(sc,"oracle_mask",0,1.82,-.42,.54,.64,.08,material_name="bone_ash")
    add(sc,torus(.66,.035),"oracle_halo",transform(0,1.96,.10,rx=math.pi/2),production_material("burnt_gold"))


def slag_dragon(sc,mat,v):
    for i in range(9): add(sc,sphere(.33-i*.012,1),f"slag_segment_{i}",transform(math.sin(i*.7)*.3,.34+i*.27,i*.11,sx=1.15,sy=.72,sz=1.05),production_material("heated_metal" if i%3==0 else "charcoal"))
    add(sc,sphere(.52,2),"slag_head",transform(math.sin(8*.7)*.3,2.62,.5,sx=1.3,sy=.7,sz=1.15),production_material("burnt_stone"))
    add_horn(sc,"slag_horn_l",-.24,2.80,.48,-1,.72,.11); add_horn(sc,"slag_horn_r",.18,2.80,.48,1,.72,.11)
    for side in (-1,1): add(sc,box((.86,.06,.54)),f"slag_fin_{side}",transform(side*.58,1.62,.42,rz=side*.34),production_material("ritual_red"))


def rib_tyrant(sc,mat,v):
    add(sc,cylinder(.26,2.3,16),"rib_spine",transform(0,1.3,0),production_material("charcoal"))
    for i in range(7): add_rib_arc(sc,f"tyrant_rib_{i}",.62+i*.27,1.0+i*.04,-.18)
    add(sc,sphere(.32,2),"tyrant_skull",transform(0,2.56,-.12),production_material("bone_ash"))
    for side in (-1,1): add(sc,capsule(.095,1.28),f"tyrant_arm_{side}",transform(side*.68,1.28,.08,rz=side*.16),production_material("ritual_red"))


def blind_architect(sc,mat,v):
    add(sc,box((1.3,2.25,.78)),"architect_core",transform(0,1.38,0),production_material("burnt_stone"))
    for i in range(4): add(sc,box((.28,1.72,.28)),f"architect_measure_{i}",transform((i-1.5)*.52,1.28,.42 if i%2 else -.42),production_material("copper"))
    add(sc,box((.84,.20,.12)),"architect_blindfold",transform(0,2.10,-.46),production_material("void"))
    add(sc,torus(.74,.045),"architect_compass",transform(0,1.62,-.48,rx=math.pi/2),production_material("burnt_gold"))


def coin_throne(sc,mat,v):
    add(sc,box((1.45,2.05,.88)),"coin_throne",transform(0,1.22,.2),production_material("charcoal"))
    for i in range(9): add(sc,cylinder(.25,.07,20),f"coin_{i}",transform((i%3-1)*.46,.43+(i//3)*.46,-.53,rx=math.pi/2),production_material("burnt_gold" if i%3==0 else "copper"))
    add(sc,sphere(.31,2),"coin_regent",transform(0,2.18,-.12),production_material("burnt_stone"))
    for side in (-1,1): add(sc,box((.30,1.20,.28)),f"coin_arm_{side}",transform(side*.72,1.34,.10),production_material("burnt_stone"))


def chorus_mass(sc,mat,v):
    add(sc,sphere(.92,3),"chorus_core",transform(0,1.5,0,sx=1.1,sy=1.28,sz=.72),production_material("charcoal"))
    for i in range(10):
        a=i/10*math.tau; add(sc,sphere(.16,1),f"chorus_mouth_{i}",transform(math.cos(a)*.7,1.5+math.sin(a)*.9,-.54,sx=1.25,sy=.45,sz=.35),production_material("ritual_red"))
    for side in (-1,1): add(sc,capsule(.08,1.08),f"chorus_leg_{side}",transform(side*.43,.48,.16),production_material("burnt_stone"))


def archive_guardian(sc,mat,v):
    add(sc,box((1.4,2.3,.78)),"archive_core",transform(0,1.42,0),production_material("burnt_stone"))
    for i in range(8): add(sc,box((1.05,.075,.055)),f"archive_line_{i}",transform(0,.7+i*.24,-.43),production_material("copper" if i%2 else "burnt_gold"))
    for side in (-1,1): add(sc,box((.30,1.38,.30)),f"archive_arm_{side}",transform(side*.80,1.28,.06),production_material("charcoal"))
    add(sc,box((.72,.30,.56)),"archive_head",transform(0,2.72,-.08),production_material("charcoal"))


def sevenfold_throne(sc,mat,v):
    add(sc,box((1.6,2.45,1.0)),"sevenfold_core",transform(0,1.42,.25),production_material("charcoal")); add(sc,torus(1.15,.075,28),"sevenfold_crown",transform(0,1.95,-.35,rx=math.pi/2),production_material("burnt_gold"))
    for i in range(7):
        a=i/7*math.tau; add(sc,sphere(.21,2),f"authority_{i}",transform(math.cos(a)*1.15,1.95+math.sin(a)*.76,-.45),production_material("burnt_stone"))
        add_eye(sc,f"authority_eye_{i}",math.cos(a)*1.15,1.95+math.sin(a)*.76,-.64,.42)
    for side in (-1,1): add(sc,box((.34,1.56,.32)),f"sevenfold_arm_{side}",transform(side*.86,1.25,.18),production_material("copper"))


BOSS_BUILDERS = {
    "blind_observer_candidate": blind_observer_candidate,
    "impulse_archon_candidate": impulse_archon_candidate,
    "inert_stone_guardian_candidate": inert_stone_guardian_candidate,
    "living_seal": living_seal, "mask_swarm": mask_swarm, "split_daemon": split_daemon,
    "pillar_judge": pillar_judge, "clock_maw": clock_maw, "fog_oracle": fog_oracle,
    "slag_dragon": slag_dragon, "rib_tyrant": rib_tyrant, "blind_architect": blind_architect,
    "coin_throne": coin_throne, "chorus_mass": chorus_mass, "archive_guardian": archive_guardian,
    "sevenfold_throne": sevenfold_throne,
}

BOSS_PRIORITY_BUILDERS = {
    "blind_observer": "blind_observer_candidate",
    "impulse_archon": "impulse_archon_candidate",
    "inert_stone_guardian": "inert_stone_guardian_candidate",
}

BOSS_SILHOUETTE_ALIASES = {
    "orbital_eye": "blind_observer_candidate",
    "horned_flame": "impulse_archon_candidate",
    "stone_colossus": "inert_stone_guardian_candidate",
}


def boss_builder_name(row: dict) -> str:
    bid = str(row["id"]); silhouette = str(row.get("silhouette", "sevenfold_throne"))
    name = BOSS_PRIORITY_BUILDERS.get(bid) or BOSS_SILHOUETTE_ALIASES.get(silhouette, silhouette)
    return name if name in BOSS_BUILDERS else "sevenfold_throne"


def boss_scene(row: dict) -> trimesh.Scene:
    bid = str(row["id"]); seed = seed_for(bid); builder = boss_builder_name(row)
    sc = trimesh.Scene(); BOSS_BUILDERS[builder](sc, production_material("charcoal"), (seed%1000)/1000*.10)
    add_armor_plate(sc,"boss_identity_seal",.31-.05*(seed%4),1.05,.52,.09+.01*(seed%5),.14,.03,rz=(seed%9)*.07,material_name="copper")
    return ground_scene(sc)
