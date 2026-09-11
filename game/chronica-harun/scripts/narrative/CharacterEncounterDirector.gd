extends Node
class_name CharacterEncounterDirector

signal encounter_started(character_id: StringName, display_name: String, message: String)

const LEGACY_ENCOUNTERS := {
    "o_olho":"aspect_thoth",
    "a_chama":"caim",
    "a_obra_fundacao":"seth",
    "autoelection":"lilith",
    "autorresponsabilidade":"caim",
    "verdadeira_vontade":"aspect_sophia",
    "carater":"seth",
    "disciplina":"aspect_horus",
    "clareza":"aspect_thoth",
    "transmutacao":"baphometic_hermaphrodite",
    "corpo_energia":"aspect_belial",
    "obra":"sabaoth",
    "fortuna":"aspect_paimon",
    "influencia":"nadir",
    "legado":"nadir",
    "initiation_chamber":"caim"
}

const ENCOUNTER_LINES := {
    "caim":"A Marca não responde por você. Ela apenas impede que esqueça o preço da escolha.",
    "lilith":"Uma porta fechada não transforma a noite em erro. Continue andando.",
    "nadir":"Eu vim procurar respostas. Harun me ensinou primeiro a formular a pergunta.",
    "seth":"Linhagem é memória em movimento. Quem a congela transforma herança em prisão.",
    "sabaoth":"Autoridade também pode romper com a autoridade que a produziu.",
    "aspect_sophia":"Criar não absolve a criação de consequência. Sabedoria aprende também com a borda.",
    "aspect_thoth":"Nomeie o que viu. Depois separe o que viu daquilo que concluiu.",
    "aspect_horus":"Precisão não é hesitação. É força que conhece a própria janela.",
    "aspect_belial":"Permaneça de pé antes de tentar governar aquilo que se move.",
    "aspect_paimon":"Influência que depende de fascínio não é domínio. É empréstimo.",
    "baphometic_hermaphrodite":"Opostos integrados deixam de disputar o centro e começam a produzir forma."
}

var roster_by_id: Dictionary = {}
var active_echoes: Array[Node3D] = []

func _ready() -> void:
    _index_roster()

func _index_roster() -> void:
    roster_by_id.clear()
    for row_value in ContentRegistry.all("characters"):
        if row_value is Dictionary:
            var row: Dictionary = row_value
            roster_by_id[String(row.get("id", ""))] = row

func encounter_id_for_stage(stage_data: Dictionary) -> String:
    var explicit := String(stage_data.get("character_encounter", ""))
    if not explicit.is_empty():
        return explicit
    return String(LEGACY_ENCOUNTERS.get(String(stage_data.get("id", "")), ""))

func spawn_encounter(stage_data: Dictionary, room: Node3D) -> Dictionary:
    if room == null:
        return {}
    if roster_by_id.is_empty():
        _index_roster()
    var character_id := encounter_id_for_stage(stage_data)
    if character_id.is_empty() or not roster_by_id.has(character_id):
        return {}
    clear_encounters()
    var data: Dictionary = roster_by_id[character_id]
    var echo := _build_echo(data, stage_data)
    room.add_child(echo)
    echo.position = Vector3(1.45, 0.0, -3.8)
    echo.scale = Vector3.ONE * 0.78
    active_echoes.append(echo)
    var display_name := String(data.get("name", character_id))
    var line := String(ENCOUNTER_LINES.get(character_id, "Uma presença reconhece a passagem de Harun."))
    encounter_started.emit(StringName(character_id), display_name, line)
    return {"id":character_id, "name":display_name, "line":line, "node":echo}

func clear_encounters() -> void:
    for node in active_echoes:
        if node != null and is_instance_valid(node):
            node.queue_free()
    active_echoes.clear()

func _build_echo(data: Dictionary, stage_data: Dictionary) -> Node3D:
    var character_id := String(data.get("id", "presence"))
    if character_id == "aspect_thoth":
        return _build_thoth_echo(data, stage_data)

    var root := Node3D.new()
    root.name = "Encounter_%s" % character_id
    root.add_to_group("narrative_encounter")
    root.set_meta("character_id", character_id)
    root.set_meta("stage_id", String(stage_data.get("id", "")))

    var palette := _palette_for(character_id)
    var material := StandardMaterial3D.new()
    material.albedo_color = palette[0]
    material.metallic = 0.34
    material.roughness = 0.44
    material.emission_enabled = true
    material.emission = palette[1]
    material.emission_energy_multiplier = 0.75

    var body := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.34
    body_mesh.height = 1.45
    body.mesh = body_mesh
    body.position = Vector3(0, 1.05, 0)
    body.material_override = material
    root.add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.3
    head_mesh.height = 0.6
    head.mesh = head_mesh
    head.position = Vector3(0, 2.0, 0)
    head.material_override = material
    root.add_child(head)

    var halo := MeshInstance3D.new()
    var halo_mesh := TorusMesh.new()
    halo_mesh.inner_radius = 0.38
    halo_mesh.outer_radius = 0.45
    halo.mesh = halo_mesh
    halo.position = Vector3(0, 2.28, 0)
    halo.rotation_degrees = Vector3(82, 0, 0)
    var halo_material := material.duplicate() as StandardMaterial3D
    halo_material.emission_energy_multiplier = 1.7
    halo.material_override = halo_material
    root.add_child(halo)

    _add_identity_details(root, character_id, halo_material)

    var label := Label3D.new()
    label.text = String(data.get("name", "PRESENÇA")).to_upper()
    label.position = Vector3(0, 2.72, 0)
    label.font_size = 28
    label.outline_size = 8
    label.modulate = Color(0.92, 0.82, 0.65, 1.0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    root.add_child(label)

    var light := OmniLight3D.new()
    light.light_color = palette[1]
    light.light_energy = 0.85
    light.omni_range = 4.2
    light.position = Vector3(0, 1.5, 0)
    light.shadow_enabled = false
    root.add_child(light)
    return root

func _build_thoth_echo(data: Dictionary, stage_data: Dictionary) -> Node3D:
    var root := Node3D.new()
    root.name = "Encounter_aspect_thoth"
    root.add_to_group("narrative_encounter")
    root.set_meta("character_id", "aspect_thoth")
    root.set_meta("stage_id", String(stage_data.get("id", "")))
    root.set_meta("presentation", "ibis_scribe_manifestation")

    var midnight := StandardMaterial3D.new()
    midnight.albedo_color = Color("09141B")
    midnight.metallic = 0.46
    midnight.roughness = 0.34
    midnight.emission_enabled = true
    midnight.emission = Color("17485B")
    midnight.emission_energy_multiplier = 0.42

    var lapis := StandardMaterial3D.new()
    lapis.albedo_color = Color("123244")
    lapis.metallic = 0.58
    lapis.roughness = 0.28
    lapis.emission_enabled = true
    lapis.emission = Color("2D93AE")
    lapis.emission_energy_multiplier = 0.72

    var gold := StandardMaterial3D.new()
    gold.albedo_color = Color("A86F25")
    gold.metallic = 0.78
    gold.roughness = 0.22
    gold.emission_enabled = true
    gold.emission = Color("C9933A")
    gold.emission_energy_multiplier = 0.8

    var ivory := StandardMaterial3D.new()
    ivory.albedo_color = Color("C9C1AC")
    ivory.metallic = 0.12
    ivory.roughness = 0.42
    ivory.emission_enabled = true
    ivory.emission = Color("7FC7D6")
    ivory.emission_energy_multiplier = 0.35

    var robe_mesh := CylinderMesh.new()
    robe_mesh.top_radius = 0.31
    robe_mesh.bottom_radius = 0.56
    robe_mesh.height = 1.55
    _mesh_node(root, "ThothRobe", robe_mesh, Vector3(0, 0.82, 0), Vector3.ONE, midnight)

    var collar_mesh := TorusMesh.new()
    collar_mesh.inner_radius = 0.28
    collar_mesh.outer_radius = 0.43
    var collar := _mesh_node(root, "ThothCollar", collar_mesh, Vector3(0, 1.57, 0), Vector3.ONE, gold)
    collar.rotation_degrees = Vector3(90, 0, 0)

    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.27
    head_mesh.height = 0.54
    _mesh_node(root, "IbisHead", head_mesh, Vector3(0, 1.94, -0.02), Vector3(0.86, 0.95, 0.82), lapis)

    var beak_mesh := CylinderMesh.new()
    beak_mesh.top_radius = 0.015
    beak_mesh.bottom_radius = 0.12
    beak_mesh.height = 0.72
    var beak := _mesh_node(root, "IbisBeak", beak_mesh, Vector3(0, 1.91, -0.48), Vector3.ONE, ivory)
    beak.rotation_degrees = Vector3(-90, 0, 0)

    for side in [-1.0, 1.0]:
        var eye_mesh := SphereMesh.new()
        eye_mesh.radius = 0.035
        eye_mesh.height = 0.07
        _mesh_node(root, "IbisEye%s" % ("L" if side < 0.0 else "R"), eye_mesh, Vector3(0.18 * side, 2.02, -0.205), Vector3.ONE, gold)

    var disk_mesh := SphereMesh.new()
    disk_mesh.radius = 0.37
    disk_mesh.height = 0.74
    _mesh_node(root, "LunarDisk", disk_mesh, Vector3(0, 2.43, 0.10), Vector3(1.0, 1.0, 0.12), gold)

    var halo_mesh := TorusMesh.new()
    halo_mesh.inner_radius = 0.46
    halo_mesh.outer_radius = 0.51
    var halo := _mesh_node(root, "LunarHalo", halo_mesh, Vector3(0, 2.43, 0.10), Vector3.ONE, lapis)
    halo.rotation_degrees = Vector3(90, 0, 0)

    for side in [-1.0, 1.0]:
        var arm_mesh := CylinderMesh.new()
        arm_mesh.top_radius = 0.075
        arm_mesh.bottom_radius = 0.105
        arm_mesh.height = 0.92
        var arm := _mesh_node(root, "ScribeArm%s" % ("L" if side < 0.0 else "R"), arm_mesh, Vector3(0.43 * side, 1.20, -0.02), Vector3.ONE, midnight)
        arm.rotation_degrees = Vector3(0, 0, 13.0 * side)

    var tablet_mesh := BoxMesh.new()
    tablet_mesh.size = Vector3(0.52, 0.68, 0.08)
    var tablet := _mesh_node(root, "ScribeTablet", tablet_mesh, Vector3(-0.54, 1.08, -0.30), Vector3.ONE, gold)
    tablet.rotation_degrees = Vector3(-8, 12, -7)

    for row in range(4):
        var glyph_mesh := BoxMesh.new()
        glyph_mesh.size = Vector3(0.31 - float(row) * 0.025, 0.018, 0.014)
        _mesh_node(root, "TabletGlyph%d" % row, glyph_mesh, Vector3(-0.54, 1.25 - row * 0.115, -0.346), Vector3.ONE, ivory)

    var staff_mesh := CylinderMesh.new()
    staff_mesh.top_radius = 0.035
    staff_mesh.bottom_radius = 0.045
    staff_mesh.height = 2.10
    _mesh_node(root, "StaffOfThoth", staff_mesh, Vector3(0.58, 1.02, 0.03), Vector3.ONE, gold)

    var staff_ring_mesh := TorusMesh.new()
    staff_ring_mesh.inner_radius = 0.14
    staff_ring_mesh.outer_radius = 0.18
    var staff_ring := _mesh_node(root, "StaffCrescent", staff_ring_mesh, Vector3(0.58, 2.11, 0.03), Vector3.ONE, lapis)
    staff_ring.rotation_degrees = Vector3(90, 0, 0)

    var label := Label3D.new()
    label.name = "ThothPresenceLabel"
    label.text = "ASPECTO DE THOTH · PERCEPÇÃO"
    label.position = Vector3(0, 2.92, 0)
    label.font_size = 27
    label.outline_size = 9
    label.modulate = Color("E7D6AC")
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    root.add_child(label)

    var key_light := OmniLight3D.new()
    key_light.name = "ThothLapisLight"
    key_light.light_color = Color("5EB7CE")
    key_light.light_energy = 0.72
    key_light.omni_range = 4.8
    key_light.position = Vector3(0, 1.75, 0.35)
    key_light.shadow_enabled = false
    root.add_child(key_light)

    var gold_light := OmniLight3D.new()
    gold_light.name = "ThothGoldLight"
    gold_light.light_color = Color("D39C45")
    gold_light.light_energy = 0.48
    gold_light.omni_range = 3.2
    gold_light.position = Vector3(-0.45, 1.15, -0.25)
    gold_light.shadow_enabled = false
    root.add_child(gold_light)

    return root

func _mesh_node(parent: Node3D, node_name: String, mesh: PrimitiveMesh, position: Vector3, scale_value: Vector3, material: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = node_name
    node.mesh = mesh
    node.position = position
    node.scale = scale_value
    node.material_override = material
    parent.add_child(node)
    return node

func _add_identity_details(root: Node3D, character_id: String, material: StandardMaterial3D) -> void:
    if character_id in ["caim", "aspect_horus"]:
        var mark := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.42, 0.05, 0.05)
        mark.mesh = mesh
        mark.position = Vector3(0, 2.02, -0.29)
        mark.rotation_degrees.z = 45.0
        mark.material_override = material
        root.add_child(mark)
    elif character_id in ["lilith", "aspect_sophia"]:
        for side in [-1.0, 1.0]:
            var wing := MeshInstance3D.new()
            var mesh := PrismMesh.new()
            mesh.size = Vector3(0.65, 1.1, 0.18)
            wing.mesh = mesh
            wing.position = Vector3(0.48 * side, 1.35, 0.18)
            wing.rotation_degrees = Vector3(0, 0, -22.0 * side)
            wing.material_override = material
            root.add_child(wing)
    elif character_id in ["aspect_belial", "sabaoth", "baphometic_hermaphrodite"]:
        for side in [-1.0, 1.0]:
            var horn := MeshInstance3D.new()
            var mesh := CylinderMesh.new()
            mesh.top_radius = 0.01
            mesh.bottom_radius = 0.09
            mesh.height = 0.52
            horn.mesh = mesh
            horn.position = Vector3(0.24 * side, 2.35, 0)
            horn.rotation_degrees.z = -26.0 * side
            horn.material_override = material
            root.add_child(horn)

func _palette_for(character_id: String) -> Array[Color]:
    match character_id:
        "caim": return [Color("231615"), Color("D4562D")]
        "lilith": return [Color("1E1124"), Color("A24ED8")]
        "nadir": return [Color("1B1B22"), Color("D6B25C")]
        "seth": return [Color("171F1B"), Color("72B98B")]
        "sabaoth": return [Color("251419"), Color("E05B43")]
        "aspect_sophia": return [Color("28241A"), Color("F1C976")]
        "aspect_thoth": return [Color("111D24"), Color("4BB7D8")]
        "aspect_horus": return [Color("2A1E12"), Color("E9A33F")]
        "aspect_belial": return [Color("1B1713"), Color("A96F38")]
        "aspect_paimon": return [Color("21162A"), Color("C77AE8")]
        "baphometic_hermaphrodite": return [Color("17141C"), Color("D18CDB")]
        _: return [Color("18161B"), Color("C5954C")]
