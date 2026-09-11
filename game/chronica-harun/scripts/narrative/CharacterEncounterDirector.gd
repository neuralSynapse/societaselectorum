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
    echo.position = Vector3(2.4, 0.0, -1.7)
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
    var root := Node3D.new()
    root.name = "Encounter_%s" % String(data.get("id", "presence"))
    root.add_to_group("narrative_encounter")
    root.set_meta("character_id", String(data.get("id", "")))
    root.set_meta("stage_id", String(stage_data.get("id", "")))

    var palette := _palette_for(String(data.get("id", "")))
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

    _add_identity_details(root, String(data.get("id", "")), halo_material)

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
    elif character_id == "aspect_thoth":
        var beak := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.02
        mesh.bottom_radius = 0.12
        mesh.height = 0.55
        beak.mesh = mesh
        beak.position = Vector3(0, 1.98, -0.48)
        beak.rotation_degrees = Vector3(90, 0, 0)
        beak.material_override = material
        root.add_child(beak)
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
