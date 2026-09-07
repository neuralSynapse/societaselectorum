#!/usr/bin/env python3
"""Generate deterministic individual GLB placeholders for CHRONICA HARUN.

These assets are intentionally dark, rough and emission-free. They are stable
1:1 placeholders: a later Blender asset can replace a GLB without changing the
content ID or gameplay contract.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import random

import numpy as np
import trimesh
from trimesh.visual.material import PBRMaterial

ROOT = Path(__file__).resolve().parents[1]
ENEMY_DATA = ROOT / 'data/enemies/student_enemies.json'
BOSS_DATA = ROOT / 'data/bosses/student_bosses.json'
ENEMY_OUT = ROOT / 'art/generated/enemies'
BOSS_OUT = ROOT / 'art/generated/bosses'


def seed_for(text: str) -> int:
    return int(hashlib.sha256(text.encode('utf-8')).hexdigest()[:16], 16)


def material(name: str, rgb=(48, 42, 34)) -> PBRMaterial:
    return PBRMaterial(
        name=name,
        baseColorFactor=[rgb[0]/255, rgb[1]/255, rgb[2]/255, 1.0],
        metallicFactor=0.05,
        roughnessFactor=0.93,
    )


def transform(x=0.0, y=0.0, z=0.0, sx=1.0, sy=1.0, sz=1.0, rx=0.0, ry=0.0, rz=0.0):
    matrix = np.eye(4)
    for angle, axis in ((rx,[1,0,0]), (ry,[0,1,0]), (rz,[0,0,1])):
        if angle:
            matrix = trimesh.transformations.rotation_matrix(angle, axis) @ matrix
    matrix[:3,:3] = matrix[:3,:3] @ np.diag([sx,sy,sz])
    matrix[:3,3] = [x,y,z]
    return matrix


def add(scene: trimesh.Scene, mesh: trimesh.Trimesh, name: str, matrix, mat: PBRMaterial):
    mesh = mesh.copy()
    mesh.visual.material = mat
    scene.add_geometry(mesh, node_name=name, transform=matrix)


def sphere(radius=.5, sub=2): return trimesh.creation.icosphere(subdivisions=sub, radius=radius)
def box(extents=(1,1,1)): return trimesh.creation.box(extents=extents)
def torus(major=.7, minor=.06): return trimesh.creation.torus(major_radius=major, minor_radius=minor, major_sections=20, minor_sections=8)

def cylinder(radius=.08, height=1.0, sections=12):
    mesh = trimesh.creation.cylinder(radius=radius, height=height, sections=sections)
    mesh.apply_transform(trimesh.transformations.rotation_matrix(math.pi/2,[1,0,0]))
    return mesh

def cone(radius=.3, height=.8, sections=12):
    mesh = trimesh.creation.cone(radius=radius, height=height, sections=sections)
    mesh.apply_transform(trimesh.transformations.rotation_matrix(math.pi/2,[1,0,0]))
    return mesh


def crawler(sc, mat, v):
    add(sc,sphere(.45),'thorax',transform(0,.45,0,1.35+v,.55,.9),mat)
    add(sc,sphere(.27),'head',transform(0,.46,-.5,1,.8,1.05),mat)
    for i in range(6):
        side=-1 if i%2==0 else 1; row=i//2
        add(sc,cylinder(.045,.72,8),f'leg_{i}',transform(side*(.45+.05*row),.28,-.25+row*.27,rz=side*(.7+.05*row)),mat)

def eye(sc, mat, v):
    add(sc,sphere(.52,3),'eye',transform(0,1.05,0,1.1+v,.78,.58),mat)
    iris=material('iris',(82,43,34)); add(sc,sphere(.18),'iris',transform(0,1.05,-.43,1,.85,.3),iris)
    for i in range(4): add(sc,cylinder(.032,.72,8),f'tendril_{i}',transform((i-1.5)*.17,.58,.08,rz=(i-1.5)*.22),mat)

def ritualist(sc, mat, v):
    add(sc,cone(.53,1.5,16),'robe',transform(0,.76,0,1+v*.3,1,1),mat)
    add(sc,sphere(.23),'head',transform(0,1.58,0,1,.95,.9),mat)
    add(sc,cylinder(.045,1.6,10),'staff',transform(.55,.82,0),mat)
    add(sc,torus(.16,.025),'sigil',transform(.55,1.58,0,rx=math.pi/2),mat)

def shade(sc, mat, v):
    add(sc,cone(.48,1.6,13),'veil',transform(0,.82,0,1+v*.35,1,.7),mat)
    dark=material('void',(22,20,23)); add(sc,sphere(.2),'hollow',transform(0,1.5,-.12,.9,1.15,.65),dark)
    for i in range(3): add(sc,cone(.13,.5,8),f'tail_{i}',transform((i-1)*.2,.25,.12),mat)

def chain(sc, mat, v):
    add(sc,box((.72,1.25,.55)),'torso',transform(0,.72,0,1+v*.2,1,1),mat)
    add(sc,sphere(.25),'head',transform(0,1.52,0),mat)
    for side in (-1,1):
        for j in range(4): add(sc,torus(.10,.025),f'link_{side}_{j}',transform(side*(.46+j*.11),.95-j*.18,0,rx=math.pi/2,rz=side*.4),mat)

def beast(sc, mat, v):
    add(sc,sphere(.48),'body',transform(0,.65,.08,1.25+v,.72,1.3),mat)
    add(sc,sphere(.31),'head',transform(0,.78,-.65,1.1,.85,1.2),mat)
    for side in (-1,1):
        add(sc,cone(.09,.42,8),f'ear_{side}',transform(side*.18,1.05,-.64,rz=side*.2),mat)
        for z in (-.27,.30): add(sc,cylinder(.065,.6,8),f'leg_{side}_{z}',transform(side*.28,.3,z),mat)

def winged(sc, mat, v):
    add(sc,cone(.42,1.35,14),'body',transform(0,.8,0),mat)
    add(sc,sphere(.22),'head',transform(0,1.55,0),mat)
    for side in (-1,1): add(sc,box((.8,.055,.65)),f'wing_{side}',transform(side*.6,1.12,.08,rz=side*(.28+v)),mat)

def construct(sc, mat, v):
    add(sc,box((.82,1.25,.65)),'core',transform(0,.72,0,1+v*.2,1,1),mat)
    add(sc,box((.58,.35,.52)),'head',transform(0,1.5,-.04),mat)
    for side in (-1,1):
        add(sc,box((.2,.85,.22)),f'arm_{side}',transform(side*.54,.82,0,rz=side*.08),mat)
        add(sc,box((.24,.72,.25)),f'leg_{side}',transform(side*.22,.28,0),mat)

def chorus(sc, mat, v):
    add(sc,sphere(.5),'mass',transform(0,.92,0,1+v*.3,1.2,.72),mat)
    mouth=material('mouth',(76,36,31))
    for i in range(5):
        a=(i-2)*.48; add(sc,sphere(.11),'mouth_'+str(i),transform(math.sin(a)*.3,.92+math.cos(a)*.36,-.42,1.25,.45,.32),mouth)

def serpent(sc, mat, v):
    for i in range(7): add(sc,sphere(.19-i*.006),'segment_'+str(i),transform(math.sin(i*.72)*(.18+v),.25+i*.18,i*.035,1.05,.72,.9),mat)
    add(sc,sphere(.28),'head',transform(math.sin(6*.72)*(.18+v),1.48,-.08,1.2,.65,1.05),mat)

def fire(sc, mat, v):
    add(sc,cone(.43,1.42,13),'ember_body',transform(0,.72,0),mat)
    hot=material('heated_rust',(86,41,26))
    for i in range(5):
        a=i/5*math.tau; add(sc,cone(.11,.52,8),f'blade_{i}',transform(math.cos(a)*.3,1.22,math.sin(a)*.23,rz=math.cos(a)*.3),hot)

def walker(sc, mat, v):
    add(sc,box((.62,1.12,.5)),'torso',transform(0,.82,0,1+v*.15,1,1),mat)
    add(sc,sphere(.23),'head',transform(0,1.52,0),mat)
    for side in (-1,1):
        add(sc,cylinder(.06,.85,8),f'arm_{side}',transform(side*.4,.82,0,rz=side*.12),mat)
        add(sc,cylinder(.07,.82,8),f'leg_{side}',transform(side*.18,.3,0),mat)

ENEMY_BUILDERS = {k:globals()[k] for k in ['crawler','eye','ritualist','shade','chain','beast','winged','construct','chorus','serpent','fire','walker']}


def enemy_scene(row: dict) -> trimesh.Scene:
    eid=row['id']; sil=str(row.get('visual_profile',{}).get('silhouette',row.get('family','walker')))
    base_family = sil if sil in ENEMY_BUILDERS else (
        'beast' if any(k in sil for k in ['ram','hyena','simian']) else
        'serpent' if any(k in sil for k in ['serpent','draconic']) else
        'fire' if 'fire' in sil else 'walker')
    seed=seed_for(eid); v=(seed%1000)/1000*.16
    rgb=(40+seed%19, 35+(seed>>5)%15, 28+(seed>>9)%13)
    sc=trimesh.Scene(); mat=material(eid,rgb); ENEMY_BUILDERS[base_family](sc,mat,v)
    nib=(seed>>12)%7
    add(sc,box((.07+.01*nib,.10+.008*(nib%3),.035)), 'identity_seal', transform(.2-.07*(nib%2),1.15,.36,rz=.13*nib), mat)
    return sc


def orbital_eye(sc,mat,v):
    add(sc,sphere(.82,3),'iris_core',transform(0,1.7,0,1.15,.75,.65),mat)
    for i in range(3): add(sc,torus(1.05+i*.15,.045),f'ring_{i}',transform(0,1.7,0,rx=.3+i*.4,ry=.2*i),mat)
    for i in range(7): add(sc,sphere(.11),f'eyelet_{i}',transform(math.cos(i/7*math.tau)*1.2,1.7+math.sin(i/7*math.tau)*.8,-.15),mat)

def horned_flame(sc,mat,v):
    add(sc,cone(.72,2.45,18),'flame_body',transform(0,1.23,0),mat)
    for s in (-1,1): add(sc,torus(.4,.065),f'horn_{s}',transform(s*.38,2.22,-.05,ry=s*.55),mat)

def stone_colossus(sc,mat,v):
    add(sc,box((1.45,2.15,1.0)),'torso',transform(0,1.4,0),mat); add(sc,box((1,.62,.9)),'head',transform(0,2.72,-.1),mat)
    for s in (-1,1): add(sc,box((.52,1.75,.52)),f'arm_{s}',transform(s*.98,1.35,0),mat)

def living_seal(sc,mat,v):
    for i in range(4): add(sc,torus(.52+i*.2,.05),f'seal_{i}',transform(0,1.55,0,rx=math.pi/2,rz=i*.28),mat)
    for i in range(2): add(sc,box((1.7,.08,.11)),f'cross_{i}',transform(0,1.55,-.08,rz=math.pi/4+i*math.pi/2),mat)

def mask_swarm(sc,mat,v):
    add(sc,cone(.52,2.1,16),'spine',transform(0,1.08,.2),mat)
    for i in range(7):
        a=i/7*math.tau; add(sc,sphere(.23),f'mask_{i}',transform(math.cos(a)*.92,1.5+math.sin(a)*.72,-.25,1.15,.75,.4),mat)

def split_daemon(sc,mat,v):
    for s in (-1,1): add(sc,cone(.46,1.95,15),f'half_{s}',transform(s*.36,1.08,0,rz=s*.08),mat)
    add(sc,sphere(.29),'head_a',transform(-.27,2.2,0),mat); add(sc,sphere(.29),'head_b',transform(.27,2.2,0),mat)

def pillar_judge(sc,mat,v):
    add(sc,cylinder(.5,2.75,18),'pillar',transform(0,1.38,0),mat); add(sc,box((1.45,.27,1.05)),'capital',transform(0,2.85,0),mat)

def clock_maw(sc,mat,v):
    add(sc,torus(.98,.11),'clock',transform(0,1.65,0,rx=math.pi/2),mat); add(sc,sphere(.58),'maw',transform(0,1.65,-.05,1,.7,.6),mat)

def fog_oracle(sc,mat,v):
    for i in range(8): add(sc,sphere(.46),f'cloud_{i}',transform(math.sin(i*1.4)*.62,1.15+(i%4)*.4,math.cos(i*.9)*.26,1.2,.72,.82),mat)

def slag_dragon(sc,mat,v):
    for i in range(8): add(sc,sphere(.33-i*.01),f'segment_{i}',transform(math.sin(i*.7)*.3,.42+i*.29,i*.11,1.15,.72,1.05),mat)
    add(sc,sphere(.52),'head',transform(math.sin(7*.7)*.3,2.62,.5,1.3,.7,1.15),mat)

def rib_tyrant(sc,mat,v):
    add(sc,cylinder(.26,2.3,16),'spine',transform(0,1.3,0),mat)
    for i in range(7): add(sc,torus(.45+i*.03,.038),f'rib_{i}',transform(0,.62+i*.27,0,rx=math.pi/2,sy=.65),mat)

def blind_architect(sc,mat,v):
    add(sc,box((1.3,2.25,.78)),'architect',transform(0,1.38,0),mat)
    for i in range(4): add(sc,box((.28,1.72,.28)),f'measure_{i}',transform((i-1.5)*.52,1.28,.42 if i%2 else -.42),mat)

def coin_throne(sc,mat,v):
    add(sc,box((1.45,2.05,.88)),'throne',transform(0,1.22,.2),mat)
    for i in range(9): add(sc,cylinder(.25,.07,20),f'coin_{i}',transform((i%3-1)*.46,.43+(i//3)*.46,-.53,rx=math.pi/2),mat)

def chorus_mass(sc,mat,v):
    add(sc,sphere(.92,3),'chorus',transform(0,1.5,0,1.1,1.28,.72),mat)
    for i in range(10):
        a=i/10*math.tau; add(sc,sphere(.16),f'mouth_{i}',transform(math.cos(a)*.7,1.5+math.sin(a)*.9,-.54,1.25,.45,.35),mat)

def archive_guardian(sc,mat,v):
    add(sc,box((1.4,2.3,.78)),'archive',transform(0,1.42,0),mat)
    for i in range(8): add(sc,box((1.05,.075,.055)),f'line_{i}',transform(0,.7+i*.24,-.43),mat)

def sevenfold_throne(sc,mat,v):
    add(sc,box((1.6,2.45,1.0)),'throne',transform(0,1.42,.25),mat); add(sc,torus(1.15,.075),'crown',transform(0,1.95,-.35,rx=math.pi/2),mat)
    for i in range(7):
        a=i/7*math.tau; add(sc,sphere(.21),f'authority_{i}',transform(math.cos(a)*1.15,1.95+math.sin(a)*.76,-.45),mat)

BOSS_BUILDERS = {k:globals()[k] for k in ['orbital_eye','horned_flame','stone_colossus','living_seal','mask_swarm','split_daemon','pillar_judge','clock_maw','fog_oracle','slag_dragon','rib_tyrant','blind_architect','coin_throne','chorus_mass','archive_guardian','sevenfold_throne']}


def boss_scene(row: dict) -> trimesh.Scene:
    bid=row['id']; sil=row.get('silhouette','orbital_eye'); seed=seed_for(bid)
    sc=trimesh.Scene(); mat=material(bid,(46+seed%18,36+(seed>>5)%16,27+(seed>>9)%15))
    BOSS_BUILDERS.get(sil, sevenfold_throne)(sc,mat,(seed%1000)/1000*.12)
    add(sc,box((.08+.005*(seed%11),.13,.04)),'identity_seal',transform(.35,1.15,.5,rz=(seed%9)*.08),mat)
    return sc


def stats(sc: trimesh.Scene):
    return sum(len(g.vertices) for g in sc.geometry.values()), sum(len(g.faces) for g in sc.geometry.values())


def export_rows(rows: list[dict], out: Path, kind: str):
    out.mkdir(parents=True, exist_ok=True)
    manifest={}
    for row in rows:
        sc=enemy_scene(row) if kind=='enemy' else boss_scene(row)
        blob=sc.export(file_type='glb')
        path=out/f"{row['id']}.glb"; path.write_bytes(blob)
        vertices,faces=stats(sc); digest=hashlib.sha256(blob).hexdigest()
        manifest[row['id']]={'vertices':vertices,'faces':faces,'bytes':len(blob),'sha256':digest,'silhouette':row.get('visual_profile',{}).get('silhouette',row.get('silhouette',''))}
    (out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')


def main():
    enemies=json.loads(ENEMY_DATA.read_text())
    for row in enemies:
        row['model_path']=f"res://art/generated/enemies/{row['id']}.glb"
    ENEMY_DATA.write_text(json.dumps(enemies,ensure_ascii=False,indent=2)+'\n')
    bosses=json.loads(BOSS_DATA.read_text())
    for row in bosses:
        row['model_path']=f"res://art/generated/bosses/{row['id']}.glb"
    BOSS_DATA.write_text(json.dumps(bosses,ensure_ascii=False,indent=2)+'\n')
    export_rows(enemies,ENEMY_OUT,'enemy'); export_rows(bosses,BOSS_OUT,'boss')
    print(f'generated {len(enemies)} enemy GLBs and {len(bosses)} boss GLBs')

if __name__=='__main__': main()
