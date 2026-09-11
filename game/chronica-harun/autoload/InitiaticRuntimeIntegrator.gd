extends Node

signal pause_action_requested(action: StringName)

var encounter_director: CharacterEncounterDirector
var pause_layer: CanvasLayer
var pause_root: Control
var pause_body: RichTextLabel
var pause_title: Label
var _last_pause_state := false
var _handled_thresholds: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    encounter_director = CharacterEncounterDirector.new()
    encounter_director.name = "CharacterEncounters"
    add_child(encounter_director)
    encounter_director.encounter_started.connect(_on_encounter_started)
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_build_pause_surface")
    call_deferred("_scan_existing_nodes")

func _process(_delta: float) -> void:
    var manual_paused := _manual_pause_active()
    if manual_paused != _last_pause_state:
        _last_pause_state = manual_paused
        _set_pause_surface(manual_paused)
    if manual_paused:
        _hide_legacy_pause_placeholder()
    elif pause_root != null and pause_root.visible:
        pause_root.visible = false

func _manual_pause_active() -> bool:
    var main := get_tree().current_scene
    if main == null:
        return false
    var state = main.get("pause_active")
    return bool(state) if state != null else false

func _scan_existing_nodes() -> void:
    for node in get_tree().get_nodes_in_group("enemies"):
        if node is EnemyBrain:
            _decorate_enemy(node as EnemyBrain)
    for node in get_tree().get_nodes_in_group("bosses"):
        if node is DataBossController:
            _decorate_boss(node as DataBossController)
    for node in get_tree().get_nodes_in_group("rooms"):
        if node is RoomShell:
            _maybe_spawn_threshold(node as RoomShell)

func _on_node_added(node: Node) -> void:
    if node is EnemyBrain:
        call_deferred("_decorate_enemy", node as EnemyBrain)
    elif node is DataBossController:
        call_deferred("_decorate_boss", node as DataBossController)
    elif node is RoomShell:
        call_deferred("_maybe_spawn_threshold", node as RoomShell)

func _decorate_enemy(enemy: EnemyBrain) -> void:
    if enemy == null or not is_instance_valid(enemy) or enemy.has_meta("initiatic_visual_v2"):
        return
    await get_tree().process_frame
    if enemy == null or not is_instance_valid(enemy):
        return
    var stage := ContentRegistry.get_current_stage()
    var fallback := String(stage.get("enemy_family", "blind_archon"))
    var family := OccultCreaturePresentation.family_for_id(String(enemy.enemy_id), fallback)
    OccultCreaturePresentation.decorate(enemy, family, 0, false)
    enemy.set_meta("initiatic_visual_v2", family)

func _decorate_boss(boss: DataBossController) -> void:
    if boss == null or not is_instance_valid(boss) or boss.has_meta("initiatic_visual_v2"):
        return
    await get_tree().process_frame
    if boss == null or not is_instance_valid(boss):
        return
    var stage := ContentRegistry.get_current_stage()
    var fallback := String(stage.get("boss_family", "blind_archon"))
    var family := OccultCreaturePresentation.family_for_id(String(boss.boss_id), fallback)
    OccultCreaturePresentation.decorate(boss, family, boss.current_phase + 1, true)
    boss.set_meta("initiatic_visual_v2", family)
    var callback := Callable(self, "_on_boss_phase_changed").bind(boss)
    if not boss.phase_changed.is_connected(callback):
        boss.phase_changed.connect(callback)

func _on_boss_phase_changed(phase: int, boss: DataBossController) -> void:
    if boss != null and is_instance_valid(boss):
        OccultCreaturePresentation.update_boss_phase(boss, phase)

func _maybe_spawn_threshold(room: RoomShell) -> void:
    if room == null or not is_instance_valid(room):
        return
    await get_tree().process_frame
    if room == null or not is_instance_valid(room):
        return
    if String(room.room_id) != "threshold":
        return
    var key := room.get_instance_id()
    if _handled_thresholds.has(key):
        return
    _handled_thresholds[key] = true
    room.set_meta("character_encounter_spawned", true)
    encounter_director.spawn_encounter(ContentRegistry.get_current_stage(), room)

func _on_encounter_started(_character_id: StringName, display_name: String, line: String) -> void:
    var hud := _current_hud()
    if hud != null:
        hud.show_message("%s\n%s" % [display_name.to_upper(), line], 7.0)

func _build_pause_surface() -> void:
    if pause_layer != null:
        return
    pause_layer = CanvasLayer.new()
    pause_layer.name = "InitiaticPauseLayer"
    pause_layer.layer = 220
    pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(pause_layer)

    pause_root = Control.new()
    pause_root.name = "PauseSurface"
    pause_root.set_anchors_preset(Control.PRESET_FULL_RECT)
    pause_root.mouse_filter = Control.MOUSE_FILTER_STOP
    pause_layer.add_child(pause_root)

    var dim := ColorRect.new()
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0.004, 0.003, 0.006, 0.92)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    pause_root.add_child(dim)

    var frame := Panel.new()
    frame.anchor_left = 0.08
    frame.anchor_top = 0.07
    frame.anchor_right = 0.92
    frame.anchor_bottom = 0.93
    var frame_style := StyleBoxFlat.new()
    frame_style.bg_color = Color(0.016, 0.013, 0.018, 0.985)
    frame_style.border_color = Color(0.64, 0.47, 0.23, 0.9)
    frame_style.set_border_width_all(2)
    frame_style.corner_radius_top_left = 10
    frame_style.corner_radius_top_right = 10
    frame_style.corner_radius_bottom_left = 10
    frame_style.corner_radius_bottom_right = 10
    frame.add_theme_stylebox_override("panel", frame_style)
    pause_root.add_child(frame)

    var header := Label.new()
    header.text = "SOCIETAS ELECTORUM · MUNDUS · CHRONICA HARUN"
    header.position = Vector2(34, 24)
    header.size = Vector2(1200, 28)
    header.add_theme_color_override("font_color", Color("C9933A"))
    header.add_theme_font_size_override("font_size", 15)
    frame.add_child(header)

    pause_title = Label.new()
    pause_title.text = "PAUSA · JORNADA"
    pause_title.position = Vector2(34, 58)
    pause_title.size = Vector2(650, 44)
    pause_title.add_theme_color_override("font_color", Color("F1D18B"))
    pause_title.add_theme_font_size_override("font_size", 28)
    frame.add_child(pause_title)

    var divider := VSeparator.new()
    divider.position = Vector2(316, 112)
    divider.size = Vector2(1, 650)
    frame.add_child(divider)

    var menu := VBoxContainer.new()
    menu.name = "PauseNavigation"
    menu.position = Vector2(34, 120)
    menu.size = Vector2(250, 620)
    menu.add_theme_constant_override("separation", 8)
    frame.add_child(menu)

    var entries := [
        ["RETOMAR", &"resume"],
        ["JORNADA / MAPA", &"journey"],
        ["BUILD & PODERES", &"build"],
        ["TAROT & PHARMAKA", &"inventory"],
        ["CODEX", &"codex"],
        ["PERSONAGENS / MARCAS", &"characters"],
        ["CONTROLES", &"controls"],
        ["CONFIGURAÇÕES", &"settings"],
        ["REINICIAR RUN", &"restart"],
        ["VOLTAR AO TÍTULO", &"title"],
    ]
    for entry in entries:
        var button := Button.new()
        button.text = String(entry[0])
        button.custom_minimum_size = Vector2(250, 46)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.add_theme_font_size_override("font_size", 15)
        button.pressed.connect(_on_pause_action.bind(entry[1]))
        menu.add_child(button)

    pause_body = RichTextLabel.new()
    pause_body.name = "PauseBody"
    pause_body.bbcode_enabled = true
    pause_body.fit_content = false
    pause_body.scroll_active = true
    pause_body.position = Vector2(350, 120)
    pause_body.size = Vector2(1020, 620)
    pause_body.add_theme_color_override("default_color", Color(0.85, 0.81, 0.74, 1))
    pause_body.add_theme_font_size_override("normal_font_size", 17)
    frame.add_child(pause_body)

    pause_root.visible = false
    _render_pause_page(&"journey")

func _set_pause_surface(value: bool) -> void:
    if pause_root == null:
        _build_pause_surface()
    if pause_root != null:
        pause_root.visible = value
        if value:
            _render_pause_page(&"journey")
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _hide_legacy_pause_placeholder() -> void:
    var hud := _current_hud()
    if hud != null and hud.pause_panel != null:
        hud.pause_panel.visible = false

func _current_hud() -> HUDController:
    var candidates := get_tree().get_nodes_in_group("hud")
    for node in candidates:
        if node is HUDController:
            return node as HUDController
    var root := get_tree().current_scene
    if root != null:
        var found := root.find_child("HUD", true, false)
        if found is HUDController:
            return found as HUDController
    return null

func _on_pause_action(action: StringName) -> void:
    pause_action_requested.emit(action)
    match String(action):
        "resume":
            _resume_game()
        "restart":
            get_tree().paused = false
            SaveService.save_campaign(GameState.to_save_data())
            get_tree().reload_current_scene()
        "title":
            get_tree().paused = false
            SaveService.save_campaign(GameState.to_save_data())
            get_tree().reload_current_scene()
        _:
            _render_pause_page(action)

func _resume_game() -> void:
    var main := get_tree().current_scene
    if main != null and main.has_method("set_pause_state"):
        main.call("set_pause_state", false)
    else:
        get_tree().paused = false
    if pause_root != null:
        pause_root.visible = false

func _render_pause_page(page: StringName) -> void:
    if pause_body == null or pause_title == null:
        return
    match String(page):
        "journey":
            pause_title.text = "PAUSA · JORNADA"
            pause_body.text = _journey_text()
        "build":
            pause_title.text = "PAUSA · BUILD & PODERES"
            pause_body.text = _build_text()
        "inventory":
            pause_title.text = "PAUSA · TAROT & PHARMAKA"
            pause_body.text = _inventory_text()
        "codex":
            pause_title.text = "PAUSA · CODEX"
            pause_body.text = _codex_text()
        "characters":
            pause_title.text = "PAUSA · PERSONAGENS / MARCAS"
            pause_body.text = _characters_text()
        "controls":
            pause_title.text = "PAUSA · CONTROLES"
            pause_body.text = _controls_text()
        "settings":
            pause_title.text = "PAUSA · CONFIGURAÇÕES"
            pause_body.text = _settings_text()

func _journey_text() -> String:
    var snap := InitiaticProgressionService.journey_snapshot()
    var lines: Array[String] = []
    lines.append("[font_size=26][color=#F1D18B]%s[/color][/font_size]" % String(snap.get("phase", "JORNADA")))
    lines.append("\n[color=#C9933A]Portal 0 · Aspirante — Initiatio Luciferi → Estudante → I · Peregrinus Ignis[/color]\n")
    lines.append("Portal 0 e Estudante são etapas preparatórias, não Graus.\n")
    var visible: Array = snap.get("visible_degrees", [])
    if visible.is_empty():
        lines.append("[color=#B8AA96]Progressão formal ainda não iniciada.[/color]")
    else:
        lines.append("[b]GRAUS VISÍVEIS[/b]\n")
        for row_value in visible:
            if not (row_value is Dictionary):
                continue
            var row: Dictionary = row_value
            var degree := int(row.get("degree", 0))
            var marker := "●" if degree <= int(snap.get("degree_completed", 0)) else ("◇" if degree == int(snap.get("degree_current", 0)) else "·")
            lines.append("%s %s · %s  [color=#766B5E]%s[/color]" % [marker, String(row.get("roman", "")), String(row.get("title", "")), String(row.get("tree", "")).replace("ARBOR_", "")])
        if visible.size() < 33:
            lines.append("\n[color=#6E626B]Uma terceira arquitetura permanece velada.[/color]")
    return "\n".join(lines)

func _build_text() -> String:
    var build := RogueliteContentService.ensure_build()
    var rows: Array[String] = ["[font_size=24][color=#F1D18B]BUILD ATUAL[/color][/font_size]"]
    for key in ["arcana", "pharmakon", "sigillum", "daimon", "route", "active_power"]:
        rows.append("[b]%s[/b] · %s" % [key.replace("_", " ").to_upper(), String(build.get(key, "—")).replace("_", " ")])
    rows.append("[b]PODERES[/b] · %s" % ", ".join(PackedStringArray(build.get("powers", []))))
    rows.append("[b]MUTAÇÕES[/b] · %s" % ", ".join(PackedStringArray(build.get("mutations", []))))
    rows.append("[b]RELÍQUIAS[/b] · %s" % ", ".join(PackedStringArray(build.get("relics", []))))
    return "\n\n".join(rows)

func _inventory_text() -> String:
    var build := RogueliteContentService.ensure_build()
    var known = GameState.meta_progression.get("known_pharmaka", [])
    return "[font_size=24][color=#F1D18B]ARCANA & SUBSTÂNCIAS[/color][/font_size]\n\nTarot de Thoth no corpus: [b]%d[/b] cartas\nArcano equipado: [b]%s[/b]\nPharmakon equipado: [b]%s[/b]\nPharmaka identificados: [b]%d[/b] de %d\n\n[color=#B8AA96]Arcana, Pharmaka, Instrumenta, Relíquias, Talismãs, Sigilla, Daimones, Blessings, Curses e Transformations participam dos pools de run.[/color]" % [ContentRegistry.all("tarot").size(), String(build.get("arcana", "—")), String(build.get("pharmakon", "—")), known.size(), ContentRegistry.all("pharmaka").size()]

func _codex_text() -> String:
    var story: Dictionary = GameState.meta_progression.get("story", {})
    return "[font_size=24][color=#F1D18B]CODEX DE HARUN[/color][/font_size]\n\nFragmentos e escolhas narrativas são persistidos no save.\nEscolhas registradas: [b]%d[/b]\nEtapas concluídas: [b]%d[/b]\nSalas limpas nesta run: [b]%d[/b]\n\n[color=#B8AA96]O códice cresce com encontros, ecos históricos, teofanias, Pergaminhos e revelações de rota.[/color]" % [Dictionary(story.get("narrative_choices", {})).size(), GameState.completion_marks.size(), int(GameState.run_stats.get("rooms_cleared", 0))]

func _characters_text() -> String:
    var rows: Array[String] = ["[font_size=24][color=#F1D18B]PERSONAGENS CANÔNICOS[/color][/font_size]"]
    for row_value in ContentRegistry.all("characters"):
        if row_value is Dictionary:
            var row: Dictionary = row_value
            rows.append("[b]%s[/b] · %s" % [String(row.get("name", "PRESENÇA")), String(row.get("role", row.get("archetype", "encontro"))).replace("_", " ")])
    return "\n\n".join(rows)

func _controls_text() -> String:
    return "[font_size=24][color=#F1D18B]CONTROLES[/color][/font_size]\n\nWASD · mover\nMouse · olhar\nLMB · ataque primário\nRMB · poder\nQ / botão B · esquiva\n1–3 · Kinesis\nR · Instrumentum\nC · consumir / Arcano contextual\nB · Rupture Charge\nV · alternar câmera\nESC · pausa\n\n[color=#B8AA96]No navegador, clique na cena para recapturar o mouse depois de menus ou escolhas.[/color]"

func _settings_text() -> String:
    return "[font_size=24][color=#F1D18B]CONFIGURAÇÕES[/color][/font_size]\n\nRenderização: [b]Godot 4.3 · GL Compatibility[/b]\nCâmera: alternável em [b]V[/b]\nModo atual: [b]%s[/b]\nSeed da run: [b]%d[/b]\n\n[color=#B8AA96]Ajustes avançados de áudio e vídeo permanecem seguros no preset Web; esta superfície evita alterar o cânone ou o save ao trocar preferências locais.[/color]" % ["WEB" if OS.has_feature("web") else "DESKTOP", GameState.run_seed]
