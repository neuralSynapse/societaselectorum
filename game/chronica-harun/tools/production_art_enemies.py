from __future__ import annotations

import math
import trimesh

from production_art_core import (
    add, add_armor_plate, add_claw, add_eye, add_horn, box, capsule, cone,
    cylinder, ground_scene, production_material, seed_for, sphere, torus, transform,
)


def ram_archon(sc, mat, v):
    add(sc, sphere(.50, 2), "ram_torso", transform(0,.82,.08,sx=1.15+v,sy=.92,sz=.78), mat)
    add(sc, sphere(.30, 2), "ram_skull", transform(0,1.46,-.34,sx=1.05,sy=.86,sz=.94), production_material("bone_ash"))
    add_horn(sc,"ram_horn_l",-.20,1.58,-.18,-1,.78,.13); add_horn(sc,"ram_horn_r",.20,1.58,-.18,1,.78,.13)
    for side in (-1,1):
        add(sc,capsule(.075,.62),f"ram_leg_{side}_front",transform(side*.28,.38,-.20,rz=side*.08),mat)
        add(sc,capsule(.075,.58),f"ram_leg_{side}_rear",transform(side*.31,.37,.25,rz=-side*.06),mat)
    add_eye(sc,"ram_eye_l",-.10,1.49,-.58,.70); add_eye(sc,"ram_eye_r",.10,1.49,-.58,.70)
    add_armor_plate(sc,"ram_brow",0,1.66,-.42,.42,.13,.11,material_name="burnt_gold")


def asinine_archon(sc, mat, v):
    add(sc, sphere(.43,2), "asinine_torso", transform(0,.82,.12,sx=.92,sy=1.03,sz=.78),mat)
    add(sc, sphere(.26,2), "asinine_head", transform(0,1.49,-.35,sx=.75,sy=.90,sz=1.32), production_material("burnt_stone"))
    add(sc, box((.11,.62,.10)), "asinine_ear_l", transform(-.13,1.88,-.25,rz=-.10), production_material("bone_ash"))
    add(sc, box((.11,.62,.10)), "asinine_ear_r", transform(.13,1.88,-.25,rz=.10), production_material("bone_ash"))
    add(sc, sphere(.17,1), "asinine_muzzle", transform(0,1.34,-.64,sx=.74,sy=.52,sz=1.40),production_material("bone_ash"))
    for side in (-1,1):
        add(sc,capsule(.07,.70),f"asinine_leg_{side}",transform(side*.23,.34,.05),mat)
    add_eye(sc,"asinine_eye_l",-.11,1.55,-.54,.58); add_eye(sc,"asinine_eye_r",.11,1.55,-.54,.58)
    add_armor_plate(sc,"asinine_chest",0,1.02,-.31,.46,.33,.09,material_name="copper")


def hyena_archon(sc, mat, v):
    add(sc, sphere(.48,2), "hyena_hindquarters", transform(0,.66,.20,sx=1.12,sy=.82,sz=.92),mat)
    add(sc, sphere(.39,2), "hyena_shoulders", transform(0,.94,-.24,sx=1.02,sy=1.08,sz=.80),mat)
    add(sc, sphere(.25,2), "hyena_head", transform(0,1.22,-.65,sx=.92,sy=.72,sz=1.28), production_material("burnt_stone"))
    for side in (-1,1):
        add(sc,cone(.10,.34,8),f"hyena_ear_{side}",transform(side*.15,1.49,-.59,rz=side*.18),production_material("bone_ash"))
        add(sc,capsule(.065,.58),f"hyena_foreleg_{side}",transform(side*.23,.32,-.25,rz=side*.10),mat)
        add(sc,capsule(.07,.45),f"hyena_hindleg_{side}",transform(side*.28,.28,.33,rz=-side*.12),mat)
    add(sc,box((.27,.13,.34)),"hyena_muzzle",transform(0,1.12,-.89),production_material("bone_ash"))
    add_eye(sc,"hyena_eye_l",-.105,1.28,-.84,.52); add_eye(sc,"hyena_eye_r",.105,1.28,-.84,.52)
    add_armor_plate(sc,"hyena_spine",0,1.23,-.02,.23,.68,.10,rz=math.pi/2,material_name="ritual_red")


def seven_head_serpent(sc, mat, v):
    for i in range(8):
        add(sc,sphere(.22-i*.009,1),f"serpent_body_{i}",transform(math.sin(i*.62)*(.18+v),.20+i*.15,.10+i*.035,sx=1.0,sy=.76,sz=.92),mat)
    crown_y=1.48
    for head in range(7):
        a=(head-3)*.29
        x=math.sin(a)*.62; y=crown_y+math.cos(a)*.15; z=-.12+abs(head-3)*.035
        add(sc,capsule(.055,.43),f"serpent_neck_{head}",transform(x*.68,y-.16,z+.10,rz=-a*.72),mat)
        add(sc,sphere(.16,2),f"serpent_head_{head}",transform(x,y,z,sx=1.0,sy=.62,sz=1.22),production_material("burnt_stone"))
        add_eye(sc,f"serpent_eye_{head}",x,y+.015,z-.17,.34)
    add(sc,torus(.63,.035,24),"sevenfold_crown",transform(0,1.52,.10,rx=math.pi/2),production_material("burnt_gold"))


def draconic_archon(sc, mat, v):
    for i in range(6):
        add(sc,sphere(.25-i*.012,1),f"dragon_segment_{i}",transform(math.sin(i*.65)*.18,.28+i*.21,.12+i*.055,sx=1.05,sy=.86,sz=1.10),mat)
    add(sc,sphere(.33,2),"dragon_head",transform(-.05,1.62,-.18,sx=1.12,sy=.72,sz=1.28),production_material("burnt_stone"))
    add_horn(sc,"dragon_horn_l",-.18,1.84,-.05,-1,.55,.09); add_horn(sc,"dragon_horn_r",.14,1.84,-.05,1,.55,.09)
    add(sc,box((.28,.12,.34)),"dragon_jaw",transform(-.02,1.47,-.51),production_material("bone_ash"))
    for i in range(5):
        add(sc,cone(.065,.28,8),f"dragon_spine_{i}",transform(math.sin(i*.62)*.15,.55+i*.24,.34+i*.04,rx=-.65),production_material("copper"))
    for side in (-1,1):
        add(sc,box((.70,.06,.42)),f"dragon_fin_{side}",transform(side*.45,1.08,.18,rz=side*.38),production_material("ritual_red"))
    add_eye(sc,"dragon_eye_l",-.15,1.67,-.47,.52); add_eye(sc,"dragon_eye_r",.10,1.67,-.47,.52)


def simian_archon(sc, mat, v):
    add(sc,sphere(.47,2),"simian_torso",transform(0,.92,.08,sx=1.18,sy=1.05,sz=.78),mat)
    add(sc,sphere(.29,2),"simian_head",transform(0,1.62,-.18,sx=1.02,sy=.92,sz=.90),production_material("burnt_stone"))
    add(sc,box((.30,.16,.22)),"simian_muzzle",transform(0,1.50,-.43),production_material("bone_ash"))
    for side in (-1,1):
        add(sc,capsule(.105,.92),f"simian_arm_{side}",transform(side*.50,.78,-.02,rz=side*.13),mat)
        add(sc,sphere(.14,1),f"simian_fist_{side}",transform(side*.57,.23,-.04),production_material("burnt_stone"))
        add(sc,capsule(.085,.58),f"simian_leg_{side}",transform(side*.23,.30,.12,rz=-side*.07),mat)
    add_eye(sc,"simian_eye_l",-.11,1.67,-.41,.58); add_eye(sc,"simian_eye_r",.11,1.67,-.41,.58)
    add(sc,torus(.34,.04,20),"simian_authority_ring",transform(0,1.72,.08,rx=math.pi/2),production_material("burnt_gold"))


def fire_face(sc, mat, v):
    add(sc,cone(.46,1.50,14),"fire_body",transform(0,.76,.08),production_material("charcoal"))
    add(sc,sphere(.30,2),"fire_mask",transform(0,1.50,-.20,sx=1.02,sy=1.08,sz=.54),production_material("heated_metal"))
    add(sc,box((.38,.09,.07)),"fire_mouth",transform(0,1.38,-.38),production_material("void"))
    for i in range(7):
        a=(i-3)*.30
        add(sc,cone(.08,.47+(i%2)*.10,8),f"fire_ray_{i}",transform(math.sin(a)*.34,1.72+math.cos(a)*.25,-.08,rz=-a*.65),production_material("heated_metal"))
    add_eye(sc,"fire_eye_l",-.115,1.56,-.39,.64); add_eye(sc,"fire_eye_r",.115,1.56,-.39,.64)
    for side in (-1,1):
        add(sc,capsule(.07,.68),f"fire_arm_{side}",transform(side*.39,.80,-.04,rz=side*.16),mat)


def crawler(sc, mat, v):
    add(sc,sphere(.45),"crawler_thorax",transform(0,.45,0,sx=1.35+v,sy=.55,sz=.9),mat)
    add(sc,sphere(.27),"crawler_head",transform(0,.46,-.5,sx=1,sy=.8,sz=1.05),production_material("burnt_stone"))
    for i in range(6):
        side=-1 if i%2==0 else 1; row=i//2
        add(sc,cylinder(.045,.72,8),f"crawler_leg_{i}",transform(side*(.45+.05*row),.28,-.25+row*.27,rz=side*(.7+.05*row)),mat)
    add_eye(sc,"crawler_eye",0,.51,-.72,.60)


def eye(sc, mat, v):
    add(sc,sphere(.52,3),"eye_shell",transform(0,1.05,0,sx=1.1+v,sy=.78,sz=.58),mat)
    add_eye(sc,"eye_focus",0,1.05,-.46,1.20)
    for i in range(4): add(sc,cylinder(.032,.72,8),f"eye_tendril_{i}",transform((i-1.5)*.17,.58,.08,rz=(i-1.5)*.22),production_material("copper"))
    add(sc,torus(.64,.035,20),"eye_halo",transform(0,1.05,.05,rx=math.pi/2),production_material("burnt_gold"))


def ritualist(sc, mat, v):
    add(sc,cone(.53,1.5,16),"ritualist_robe",transform(0,.76,0,sx=1+v*.3),mat)
    add(sc,sphere(.23),"ritualist_head",transform(0,1.58,0,sy=.95,sz=.9),production_material("void"))
    add(sc,cylinder(.045,1.6,10),"ritualist_staff",transform(.55,.82,0),production_material("copper"))
    add(sc,torus(.16,.025),"ritualist_sigil",transform(.55,1.58,0,rx=math.pi/2),production_material("burnt_gold"))
    add_armor_plate(sc,"ritualist_mask",0,1.60,-.20,.29,.31,.07,material_name="bone_ash")


def shade(sc, mat, v):
    add(sc,cone(.48,1.6,13),"shade_veil",transform(0,.82,0,sx=1+v*.35,sz=.7),mat)
    add(sc,sphere(.2),"shade_hollow",transform(0,1.5,-.12,sx=.9,sy=1.15,sz=.65),production_material("void"))
    for i in range(3): add(sc,cone(.13,.5,8),f"shade_tail_{i}",transform((i-1)*.2,.25,.12),production_material("ritual_red"))


def chain(sc, mat, v):
    add(sc,box((.72,1.25,.55)),"chain_torso",transform(0,.72,0,sx=1+v*.2),mat)
    add(sc,sphere(.25),"chain_head",transform(0,1.52,0),production_material("burnt_stone"))
    for side in (-1,1):
        for j in range(4): add(sc,torus(.10,.025),f"chain_link_{side}_{j}",transform(side*(.46+j*.11),.95-j*.18,0,rx=math.pi/2,rz=side*.4),production_material("copper"))


def beast(sc, mat, v):
    add(sc,sphere(.48),"beast_body",transform(0,.65,.08,sx=1.25+v,sy=.72,sz=1.3),mat)
    add(sc,sphere(.31),"beast_head",transform(0,.78,-.65,sx=1.1,sy=.85,sz=1.2),production_material("burnt_stone"))
    for side in (-1,1):
        add(sc,cone(.09,.42,8),f"beast_ear_{side}",transform(side*.18,1.05,-.64,rz=side*.2),production_material("bone_ash"))
        for zi,z in enumerate((-.27,.30)): add(sc,cylinder(.065,.6,8),f"beast_leg_{side}_{zi}",transform(side*.28,.3,z),mat)


def winged(sc, mat, v):
    add(sc,cone(.42,1.35,14),"winged_body",transform(0,.8,0),mat); add(sc,sphere(.22),"winged_head",transform(0,1.55,0),production_material("burnt_stone"))
    for side in (-1,1): add(sc,box((.8,.055,.65)),f"wing_{side}",transform(side*.6,1.12,.08,rz=side*(.28+v)),production_material("copper"))
    add_eye(sc,"winged_eye",0,1.58,-.21,.55)


def construct(sc, mat, v):
    add(sc,box((.82,1.25,.65)),"construct_core",transform(0,.72,0,sx=1+v*.2),production_material("burnt_stone")); add(sc,box((.58,.35,.52)),"construct_head",transform(0,1.5,-.04),mat)
    for side in (-1,1):
        add(sc,box((.2,.85,.22)),f"construct_arm_{side}",transform(side*.54,.82,0,rz=side*.08),production_material("copper"))
        add(sc,box((.24,.72,.25)),f"construct_leg_{side}",transform(side*.22,.28,0),production_material("burnt_stone"))
    add_armor_plate(sc,"construct_keystone",0,1.02,-.38,.28,.42,.08,material_name="burnt_gold")


def chorus(sc, mat, v):
    add(sc,sphere(.5),"chorus_mass",transform(0,.92,0,sx=1+v*.3,sy=1.2,sz=.72),mat)
    for i in range(5):
        a=(i-2)*.48; add(sc,sphere(.11),f"chorus_mouth_{i}",transform(math.sin(a)*.3,.92+math.cos(a)*.36,-.42,sx=1.25,sy=.45,sz=.32),production_material("ritual_red"))


def serpent(sc, mat, v):
    for i in range(8): add(sc,sphere(.19-i*.006),f"serpent_segment_{i}",transform(math.sin(i*.72)*(.18+v),.25+i*.16,i*.035,sx=1.05,sy=.72,sz=.9),mat)
    add(sc,sphere(.28),"serpent_head",transform(math.sin(7*.72)*(.18+v),1.48,-.08,sx=1.2,sy=.65,sz=1.05),production_material("burnt_stone"))
    add_eye(sc,"serpent_eye",math.sin(7*.72)*(.18+v),1.50,-.34,.56)


def fire(sc, mat, v):
    add(sc,cone(.43,1.42,13),"ember_body",transform(0,.72,0),production_material("charcoal"))
    for i in range(5):
        a=i/5*math.tau; add(sc,cone(.11,.52,8),f"heated_blade_{i}",transform(math.cos(a)*.3,1.22,math.sin(a)*.23,rz=math.cos(a)*.3),production_material("heated_metal"))
    add_armor_plate(sc,"ember_mask",0,1.25,-.25,.38,.32,.07,material_name="ritual_red")


def walker(sc, mat, v):
    add(sc,box((.62,1.12,.5)),"walker_torso",transform(0,.82,0,sx=1+v*.15),mat); add(sc,sphere(.23),"walker_head",transform(0,1.52,0),production_material("burnt_stone"))
    for side in (-1,1):
        add(sc,cylinder(.06,.85,8),f"walker_arm_{side}",transform(side*.4,.82,0,rz=side*.12),mat)
        add(sc,cylinder(.07,.82,8),f"walker_leg_{side}",transform(side*.18,.3,0),mat)
    add_armor_plate(sc,"walker_chest",0,1.05,-.28,.38,.40,.07,material_name="copper")


ENEMY_BUILDERS = {
    "ram_archon": ram_archon, "asinine_archon": asinine_archon, "hyena_archon": hyena_archon,
    "seven_head_serpent": seven_head_serpent, "draconic_archon": draconic_archon,
    "simian_archon": simian_archon, "fire_face": fire_face,
    "crawler": crawler, "eye": eye, "ritualist": ritualist, "shade": shade, "chain": chain,
    "beast": beast, "winged": winged, "construct": construct, "chorus": chorus,
    "serpent": serpent, "fire": fire, "walker": walker,
}


def canonical_enemy_builder(silhouette: str) -> str:
    if silhouette in ENEMY_BUILDERS:
        return silhouette
    low = silhouette.lower()
    aliases = (
        ("ram", "ram_archon"), ("asinine", "asinine_archon"), ("hyena", "hyena_archon"),
        ("seven_head", "seven_head_serpent"), ("draconic", "draconic_archon"),
        ("simian", "simian_archon"), ("fire_face", "fire_face"), ("serpent", "serpent"),
        ("fire", "fire"), ("construct", "construct"), ("wing", "winged"),
    )
    for token, builder in aliases:
        if token in low:
            return builder
    return "walker"


def stage_material(stage_id: str, role: str):
    if stage_id == "o_olho": return production_material("burnt_gold" if role == "elite" else "charcoal")
    if stage_id == "a_chama": return production_material("ritual_red" if role == "elite" else "charcoal")
    if stage_id in {"a_fundacao","a_obra"}: return production_material("burnt_stone")
    return production_material("charcoal")


def add_stage_identity(sc, stage_id: str, role: str, seed: int):
    if stage_id == "o_olho":
        add(sc,torus(.19+(seed%3)*.025,.022),"stage_eye_ring",transform(0,1.10,.36,rx=math.pi/2),production_material("burnt_gold"))
    elif stage_id == "a_chama":
        for side in (-1,1): add(sc,cone(.055,.30,7),f"stage_heat_{side}",transform(side*.24,1.15,.30,rz=side*.22),production_material("heated_metal"))
    elif stage_id in {"a_fundacao","a_obra"}:
        add_armor_plate(sc,"foundation_mark",0,.67,.34,.42,.25,.08,material_name="burnt_stone")
    if role == "elite":
        add(sc,torus(.37,.035,20),"elite_authority",transform(0,1.54,.12,rx=math.pi/2),production_material("burnt_gold"))


def enemy_scene(row: dict) -> trimesh.Scene:
    eid = str(row["id"]); stage = str(row.get("stage_id", "")); role = str(row.get("role", "common"))
    silhouette = str(row.get("visual_profile", {}).get("silhouette", row.get("family", "walker")))
    builder_name = canonical_enemy_builder(silhouette)
    seed = seed_for(eid); variation = (seed % 1000) / 1000 * .12
    sc = trimesh.Scene(); ENEMY_BUILDERS[builder_name](sc, stage_material(stage, role), variation)
    add_stage_identity(sc, stage, role, seed)
    add_armor_plate(sc,"identity_plate",.18-.04*(seed%4),1.02,.39,.08+.01*(seed%5),.11,.025,rz=(seed%7)*.08,material_name="copper")
    return ground_scene(sc)
