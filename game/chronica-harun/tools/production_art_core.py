from __future__ import annotations

import hashlib
import math
from pathlib import Path

import numpy as np
import trimesh
from trimesh.visual.material import PBRMaterial

PRODUCTION_CLASS = "procedural_production_candidate"
BLENDER_USED = False
GENERATOR_VERSION = "production-art-v1"

PALETTE = {
    "charcoal": dict(rgb=(22, 21, 20), metallic=0.08, roughness=0.90, emission=(0.0, 0.0, 0.0)),
    "burnt_stone": dict(rgb=(58, 54, 50), metallic=0.03, roughness=0.96, emission=(0.0, 0.0, 0.0)),
    "burnt_gold": dict(rgb=(116, 83, 37), metallic=0.48, roughness=0.72, emission=(0.0, 0.0, 0.0)),
    "copper": dict(rgb=(93, 54, 35), metallic=0.42, roughness=0.74, emission=(0.0, 0.0, 0.0)),
    "ritual_red": dict(rgb=(92, 29, 24), metallic=0.05, roughness=0.82, emission=(0.0, 0.0, 0.0)),
    "heated_metal": dict(rgb=(104, 49, 28), metallic=0.28, roughness=0.62, emission=(0.10, 0.025, 0.012)),
    "bone_ash": dict(rgb=(113, 103, 88), metallic=0.02, roughness=0.90, emission=(0.0, 0.0, 0.0)),
    "void": dict(rgb=(11, 11, 12), metallic=0.00, roughness=1.00, emission=(0.0, 0.0, 0.0)),
    "blind_iris": dict(rgb=(78, 45, 31), metallic=0.10, roughness=0.78, emission=(0.05, 0.008, 0.0)),
}


def seed_for(text: str) -> int:
    return int(hashlib.sha256(text.encode("utf-8")).hexdigest()[:16], 16)


def production_material(name: str) -> PBRMaterial:
    spec = PALETTE[name]
    rgb = spec["rgb"]
    return PBRMaterial(
        name=name,
        baseColorFactor=[rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1.0],
        metallicFactor=float(spec["metallic"]),
        roughnessFactor=float(spec["roughness"]),
        emissiveFactor=list(spec["emission"]),
    )


def transform(x=0.0, y=0.0, z=0.0, sx=1.0, sy=1.0, sz=1.0, rx=0.0, ry=0.0, rz=0.0):
    matrix = np.eye(4)
    for angle, axis in ((rx, [1, 0, 0]), (ry, [0, 1, 0]), (rz, [0, 0, 1])):
        if angle:
            matrix = trimesh.transformations.rotation_matrix(angle, axis) @ matrix
    matrix[:3, :3] = matrix[:3, :3] @ np.diag([sx, sy, sz])
    matrix[:3, 3] = [x, y, z]
    return matrix


def add(scene: trimesh.Scene, mesh: trimesh.Trimesh, name: str, matrix, material: PBRMaterial) -> None:
    item = mesh.copy()
    item.visual.material = material
    scene.add_geometry(item, node_name=name, transform=matrix)


def sphere(radius=.5, sub=2):
    return trimesh.creation.icosphere(subdivisions=sub, radius=radius)


def box(extents=(1.0, 1.0, 1.0)):
    return trimesh.creation.box(extents=extents)


def torus(major=.7, minor=.06, sections=24):
    return trimesh.creation.torus(major_radius=major, minor_radius=minor, major_sections=sections, minor_sections=8)


def cylinder(radius=.08, height=1.0, sections=12):
    mesh = trimesh.creation.cylinder(radius=radius, height=height, sections=sections)
    mesh.apply_transform(trimesh.transformations.rotation_matrix(math.pi / 2, [1, 0, 0]))
    return mesh


def cone(radius=.3, height=.8, sections=12):
    mesh = trimesh.creation.cone(radius=radius, height=height, sections=sections)
    mesh.apply_transform(trimesh.transformations.rotation_matrix(math.pi / 2, [1, 0, 0]))
    return mesh


def capsule(radius=.12, height=.5, count=(8, 12)):
    mesh = trimesh.creation.capsule(radius=radius, height=height, count=count)
    mesh.apply_transform(trimesh.transformations.rotation_matrix(math.pi / 2, [1, 0, 0]))
    return mesh


def wedge(extents=(.3, .4, .2)):
    mesh = box(extents)
    shear = np.eye(4)
    shear[0, 1] = .35
    mesh.apply_transform(shear)
    return mesh


def add_eye(sc, name, x, y, z, scale=1.0):
    add(sc, sphere(.12, 2), f"{name}_sclera", transform(x, y, z, sx=1.15*scale, sy=.82*scale, sz=.38*scale), production_material("bone_ash"))
    add(sc, sphere(.06, 2), f"{name}_iris", transform(x, y, z-.08, sx=1.0*scale, sy=.92*scale, sz=.24*scale), production_material("blind_iris"))


def add_horn(sc, name, x, y, z, side, length=.7, thick=.12):
    mat = production_material("bone_ash")
    add(sc, cone(thick*1.25, length*.60, 10), f"{name}_root", transform(x, y, z, rz=side*.72, ry=side*.16), mat)
    add(sc, cone(thick*.86, length*.48, 10), f"{name}_tip", transform(x+side*length*.31, y+length*.24, z, rz=side*1.05, ry=side*.12), mat)


def add_claw(sc, name, x, y, z, side, size=.25):
    add(sc, cone(size*.22, size, 8), name, transform(x, y, z, rz=side*.45), production_material("bone_ash"))


def add_armor_plate(sc, name, x, y, z, sx, sy, sz, rz=0.0, material_name="burnt_stone"):
    add(sc, wedge((sx, sy, sz)), name, transform(x, y, z, rz=rz), production_material(material_name))


def add_rib_arc(sc, name, y, scale, front_z=-.10):
    add(sc, torus(.35*scale, .035*scale, 20), name, transform(0, y, front_z, sy=.72, rx=math.pi/2), production_material("bone_ash"))


def ground_scene(sc: trimesh.Scene) -> trimesh.Scene:
    bounds = sc.bounds
    if bounds is not None:
        sc.apply_transform(trimesh.transformations.translation_matrix([0.0, -float(bounds[0][1]), 0.0]))
    return sc


def scene_metrics(sc: trimesh.Scene) -> dict:
    bounds = np.asarray(sc.bounds, dtype=float)
    extents = bounds[1] - bounds[0]
    vertices = faces = 0
    materials = set()
    for geom in sc.geometry.values():
        vertices += len(geom.vertices)
        faces += len(geom.faces)
        mat = getattr(geom.visual, "material", None)
        if mat is not None and getattr(mat, "name", None):
            materials.add(str(mat.name))
    node_names = sorted(str(n) for n in sc.graph.nodes_geometry)
    payload = "|".join(node_names) + ":" + ",".join(f"{x:.3f}" for x in extents)
    return {
        "geometry_count": len(sc.geometry),
        "vertices": int(vertices),
        "faces": int(faces),
        "min_y": round(float(bounds[0][1]), 5),
        "max_y": round(float(bounds[1][1]), 5),
        "height": round(float(extents[1]), 5),
        "width": round(float(extents[0]), 5),
        "depth": round(float(extents[2]), 5),
        "material_names": sorted(materials),
        "silhouette_signature": hashlib.sha256(payload.encode("utf-8")).hexdigest()[:16],
    }


def max_emission_for_scene(sc: trimesh.Scene) -> float:
    maximum = 0.0
    for geom in sc.geometry.values():
        mat = getattr(geom.visual, "material", None)
        emission = getattr(mat, "emissiveFactor", None) if mat is not None else None
        if emission is not None:
            maximum = max(maximum, *(float(v) for v in emission[:3]))
    return round(maximum, 5)


def export_scene(sc: trimesh.Scene, path: Path) -> dict:
    path.parent.mkdir(parents=True, exist_ok=True)
    blob = sc.export(file_type="glb")
    path.write_bytes(blob)
    metrics = scene_metrics(sc)
    metrics.update({"bytes": len(blob), "sha256": hashlib.sha256(blob).hexdigest(), "max_emission": max_emission_for_scene(sc)})
    return metrics
