extends RefCounted
class_name OccultCreaturePresentation

const FAMILIES := {
    "blind_archon": {"base": Color("21161D"), "emission": Color("C94D20"), "crown": "halo", "shape": "tall"},
    "mirror_wraith": {"base": Color("1D1A2B"), "emission": Color("8B55D9"), "crown": "split", "shape": "thin"},
    "ember_tyrant": {"base": Color("2B120E"), "emission": Color("FF6A1A"), "crown": "horns", "shape": "heavy"},
    "stone_witness": {"base": Color("28231F"), "emission": Color("C99B55"), "crown": "monolith", "shape": "heavy"},
    "hollow_scribe": {"base": Color("17191B"), "emission": Color("D3B56F"), "crown": "glyph", "shape": "thin"},
    "serpentine_authority": {"base": Color("161F1C"), "emission": Color("68BF8C"), "crown": "serpent", "shape": "tall"},
    "abyssal": {"base": Color("0D101A"), "emission": Color("4A63C8"), "crown": "void", "shape": "wide"},
    "draconic": {"base": Color("1D0E16"), "emission": Color("B52FE0"), "crown": "horns", "shape": "wide"},
}

static func family_for_id(content_id: String, fallback: String = "blind_archon") -> String:
    var id := content_id.to_lower()
    if "mirror" in id or "reflex" in id or "specul" in id:
        return "mirror_wraith"
    if "fire" in id or "flame" in id or "impulse" in id or "chama" in id:
        return "ember_tyrant"
    if "stone" in id or "witness" in id or "guard" in id or "pedra" in id:
        return "stone_witness"
    if "scribe" in id or "book" in id or "archive" in id or "name" in id:
        return "hollow_scribe"
    if "serpent" in id or "oph" in id or "dragon" in id:
        return "serpentine_authority"
    if "abyss" in id or "void" in id or "shadow" in id:
        return "abyssal"
    if "dracon" in id or "typhon" in id:
        return "draconic"
    return fallback if FAMILIES.has(fallback) else "blind_archon"

static func decorate(host: Node3D, family: String, boss_phase: int = 0, is_boss: bool = false) -> Node3D:
    if host == null or not is_instance_valid(host):
        return null
    var existing := host.get_node_or_null("OccultPresentation") as Node3D
    if existing != null:
        update_boss_phase(host, boss_phase)
        return existing
    var resolved := family if FAMILIES.has(family) else "blind_archon"
    var profile: Dictionary = FAMILIES[resolved]
    var root := Node3D.new()
    root.name = "OccultPresentation"
    root.set_meta("family", resolved)
    root.set_meta("boss_phase", boss_phase)
    host.add_child(root)

    var scale_factor := 1.35 if is_boss else 0.82
    var body_scale := _body_scale(String(profile.get("shape", "tall")), scale_factor)
    _add_mesh(root, CapsuleMesh.new(), Vector3(0, 1.05 * scale_factor, 0), body_scale, profile, 0.0)
    _add_mesh(root, SphereMesh.new(), Vector3(0, 2.05 * scale_factor, 0), Vector3.ONE * (0.42 * scale_factor), profile, 0.12)
    _add_crown(root, String(profile.get("crown", "halo")), profile, scale_factor)
    _add_rune_core(root, profile, scale_factor)
    _add_limbs(root, profile, scale_factor, String(profile.get("shape", "tall")))
    if is_boss:
        _add_boss_aura(root, profile, scale_factor, boss_phase)
    return root

static func update_boss_phase(host: Node3D, boss_phase: int) -> void:
    if host == null or not is_instance_valid(host):
        return
    var root := host.get_node_or_null("OccultPresentation") as Node3D
    if root == null:
        return
    root.set_meta("boss_phase", boss_phase)
    var intensity := 1.0 + float(maxi(0, boss_phase - 1)) * 0.45
    for node in root.get_children():
        if node is MeshInstance3D:
            var mesh_node := node as MeshInstance3D
            var material := mesh_node.material_override as StandardMaterial3D
            if material != null and material.emission_enabled:
                material.emission_energy_multiplier = 1.4 * intensity
    var aura := root.get_node_or_null("BossAura") as Node3D
    if aura != null:
        aura.scale = Vector3.ONE * (1.0 + 0.08 * float(maxi(0, boss_phase - 1)))

static func _body_scale(shape: String, factor: float) -> Vector3:
    match shape:
        "thin": return Vector3(0.42, 1.15, 0.42) * factor
        "heavy": return Vector3(0.82, 0.95, 0.68) * factor
        "wide": return Vector3(0.9, 0.85, 0.62) * factor
        _: return Vector3(0.56, 1.08, 0.5) * factor

static func _material(profile: Dictionary, emission_boost: float = 0.0) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = profile.get("base", Color("21161D"))
    material.metallic = 0.48
    material.roughness = 0.38
    material.emission_enabled = true
    material.emission = profile.get("emission", Color("C94D20"))
    material.emission_energy_multiplier = 1.25 + emission_boost
    return material

static func _add_mesh(parent: Node3D, mesh: PrimitiveMesh, position: Vector3, scale_value: Vector3, profile: Dictionary, emission_boost: float) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = position
    node.scale = scale_value
    node.material_override = _material(profile, emission_boost)
    parent.add_child(node)
    return node

static func _add_crown(parent: Node3D, crown: String, profile: Dictionary, factor: float) -> void:
    match crown:
        "halo", "glyph", "void":
            var ring := TorusMesh.new()
            ring.inner_radius = 0.34
            ring.outer_radius = 0.43
            var node := _add_mesh(parent, ring, Vector3(0, 2.35 * factor, 0), Vector3.ONE * factor, profile, 0.55)
            node.rotation_degrees = Vector3(78, 0, 0)
        "split":
            for side in [-1.0, 1.0]:
                var ring := TorusMesh.new()
                ring.inner_radius = 0.22
                ring.outer_radius = 0.30
                var node := _add_mesh(parent, ring, Vector3(0.28 * side * factor, 2.28 * factor, 0), Vector3.ONE * factor, profile, 0.5)
                node.rotation_degrees = Vector3(82, 25.0 * side, 0)
        "horns":
            for side in [-1.0, 1.0]:
                var horn := CylinderMesh.new()
                horn.top_radius = 0.02
                horn.bottom_radius = 0.11
                horn.height = 0.72
                var node := _add_mesh(parent, horn, Vector3(0.28 * side * factor, 2.48 * factor, 0), Vector3.ONE * factor, profile, 0.28)
                node.rotation_degrees = Vector3(0, 0, -28.0 * side)
        "monolith":
            _add_mesh(parent, BoxMesh.new(), Vector3(0, 2.48 * factor, 0), Vector3(0.12, 0.42, 0.08) * factor, profile, 0.4)
        "serpent":
            for i in range(4):
                var orb := SphereMesh.new()
                _add_mesh(parent, orb, Vector3(sin(i * 1.2) * 0.34 * factor, (2.25 + i * 0.16) * factor, cos(i * 1.2) * 0.25 * factor), Vector3.ONE * 0.13 * factor, profile, 0.35)

static func _add_rune_core(parent: Node3D, profile: Dictionary, factor: float) -> void:
    var core := SphereMesh.new()
    core.radius = 0.12
    core.height = 0.24
    _add_mesh(parent, core, Vector3(0, 1.28 * factor, -0.42 * factor), Vector3.ONE * factor, profile, 0.9)
    var ring := TorusMesh.new()
    ring.inner_radius = 0.18
    ring.outer_radius = 0.23
    var ring_node := _add_mesh(parent, ring, Vector3(0, 1.28 * factor, -0.43 * factor), Vector3.ONE * factor, profile, 0.7)
    ring_node.rotation_degrees = Vector3(90, 0, 0)

static func _add_limbs(parent: Node3D, profile: Dictionary, factor: float, shape: String) -> void:
    var spread := 0.62 if shape in ["heavy", "wide"] else 0.48
    for side in [-1.0, 1.0]:
        var arm := CylinderMesh.new()
        arm.top_radius = 0.10
        arm.bottom_radius = 0.14
        arm.height = 0.95
        var node := _add_mesh(parent, arm, Vector3(spread * side * factor, 1.25 * factor, 0), Vector3.ONE * factor, profile, 0.08)
        node.rotation_degrees = Vector3(0, 0, 18.0 * side)

static func _add_boss_aura(parent: Node3D, profile: Dictionary, factor: float, boss_phase: int) -> void:
    var aura := Node3D.new()
    aura.name = "BossAura"
    parent.add_child(aura)
    for i in range(3):
        var ring := TorusMesh.new()
        ring.inner_radius = 0.74 + i * 0.17
        ring.outer_radius = 0.79 + i * 0.17
        var node := _add_mesh(aura, ring, Vector3(0, (1.1 + i * 0.34) * factor, 0), Vector3.ONE * factor, profile, 0.8 + boss_phase * 0.2)
        node.rotation_degrees = Vector3(90 + i * 18, i * 35, 0)
