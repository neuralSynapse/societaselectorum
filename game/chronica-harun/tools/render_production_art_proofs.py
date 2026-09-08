#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import trimesh
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
PRODUCTION_DIR = ROOT / "art/production"
PROOF_DIR = PRODUCTION_DIR / "proofs"
MANIFEST_PATH = PRODUCTION_DIR / "production_art_manifest.json"

BG = (13, 13, 14)
FILL = (91, 70, 45)
EDGE = (178, 131, 62)
TEXT = (220, 208, 180)
MUTED = (148, 137, 119)


def scene_mesh(path: Path) -> trimesh.Trimesh:
    scene = trimesh.load(path, force="scene")
    if not isinstance(scene, trimesh.Scene) or not scene.geometry:
        raise RuntimeError(f"cannot render proof for {path}")
    meshes = []
    for name in scene.graph.nodes_geometry:
        transform, geom_name = scene.graph.get(name)
        geom = scene.geometry[geom_name].copy()
        geom.apply_transform(transform)
        meshes.append(geom)
    return trimesh.util.concatenate(meshes)


def project(mesh: trimesh.Trimesh, axes: tuple[int, int], size=(220, 220)) -> Image.Image:
    width, height = size
    canvas = Image.new("RGB", size, BG)
    draw = ImageDraw.Draw(canvas)
    vertices = np.asarray(mesh.vertices, dtype=float)[:, list(axes)]
    mn = vertices.min(axis=0); mx = vertices.max(axis=0)
    span = np.maximum(mx-mn, 1e-6)
    scale = min((width-26)/span[0], (height-26)/span[1])
    center = (mn+mx)/2
    pts = np.empty_like(vertices)
    pts[:,0] = (vertices[:,0]-center[0])*scale + width/2
    pts[:,1] = height/2 - (vertices[:,1]-center[1])*scale
    faces = np.asarray(mesh.faces, dtype=int)
    centroids = mesh.triangles_center
    order = np.argsort(centroids[:,2])
    for idx in order:
        poly = [tuple(pts[v]) for v in faces[idx]]
        draw.polygon(poly, fill=FILL)
    for edge in mesh.edges_unique:
        a, b = tuple(pts[edge[0]]), tuple(pts[edge[1]])
        draw.line([a,b], fill=EDGE, width=1)
    return canvas


def title(draw: ImageDraw.ImageDraw, xy, text: str, fill=TEXT):
    draw.text(xy, text, fill=fill)


def triptych(path: Path, asset_id: str, display_name: str) -> Image.Image:
    mesh = scene_mesh(path)
    views = [((0,1),"FRONT"), ((2,1),"SIDE"), ((0,2),"TOP")]
    output = Image.new("RGB", (680, 270), BG)
    draw = ImageDraw.Draw(output)
    title(draw,(14,8),display_name)
    title(draw,(14,26),asset_id, MUTED)
    for i,(axes,label) in enumerate(views):
        panel = project(mesh, axes)
        x=10+i*224
        output.paste(panel,(x,44))
        title(draw,(x+8,246),label,MUTED)
    return output


def contact_sheet(images: list[tuple[str,Image.Image]], columns: int, heading: str) -> Image.Image:
    thumb_w, thumb_h = 340, 135
    rows = (len(images)+columns-1)//columns
    out = Image.new("RGB", (columns*thumb_w, 42+rows*thumb_h), BG)
    draw = ImageDraw.Draw(out)
    title(draw,(14,10),heading)
    for idx,(label,img) in enumerate(images):
        img = img.resize((thumb_w,135))
        x=(idx%columns)*thumb_w; y=42+(idx//columns)*thumb_h
        out.paste(img,(x,y))
        title(draw,(x+10,y+8),label,TEXT)
    return out


def local_glb(kind: str, asset_id: str) -> Path:
    plural = "enemies" if kind == "enemy" else "bosses"
    return ROOT / f"art/generated/{plural}/{asset_id}.glb"


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    PROOF_DIR.mkdir(parents=True, exist_ok=True)
    priority_entries = []

    archon_order = ["ram_archon","asinine_archon","hyena_archon","seven_head_serpent","draconic_archon","simian_archon","fire_face"]
    archon_images = []
    for builder in archon_order:
        matches = [(aid,e) for aid,e in manifest["enemies"].items() if e["builder"] == builder]
        if not matches:
            continue
        aid,e = matches[0]
        img = triptych(local_glb("enemy",aid), aid, str(e["display_name"]))
        filename = f"enemy_{aid}.png"; img.save(PROOF_DIR/filename)
        archon_images.append((builder,img))
        priority_entries.append({"kind":"enemy","id":aid,"builder":builder,"file":filename})

    boss_images = []
    for bid in ("blind_observer","impulse_archon","inert_stone_guardian"):
        e = manifest["bosses"][bid]
        img = triptych(local_glb("boss",bid), bid, str(e["display_name"]))
        filename = f"boss_{bid}.png"; img.save(PROOF_DIR/filename)
        boss_images.append((bid,img))
        priority_entries.append({"kind":"boss","id":bid,"builder":e["builder"],"file":filename})

    archon_sheet = contact_sheet(archon_images,2,"SEVEN ARCHONTIC SILHOUETTES · PROCEDURAL PRODUCTION CANDIDATES")
    archon_sheet.save(PROOF_DIR/"archons_contact_sheet.png")
    boss_sheet = contact_sheet(boss_images,1,"FIRST THREE BOSSES · PROCEDURAL PRODUCTION CANDIDATES")
    boss_sheet.save(PROOF_DIR/"bosses_contact_sheet.png")

    index = {
        "schema":1,
        "production_class":manifest["production_class"],
        "blender_used":manifest["blender_used"],
        "final_art_claimed":False,
        "views":["front","side","top"],
        "entries":priority_entries,
        "contact_sheets":["archons_contact_sheet.png","bosses_contact_sheet.png"],
    }
    (PROOF_DIR/"proof_index.json").write_text(json.dumps(index,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(f"rendered {len(priority_entries)} proof triptychs + 2 contact sheets")


if __name__ == "__main__":
    main()
