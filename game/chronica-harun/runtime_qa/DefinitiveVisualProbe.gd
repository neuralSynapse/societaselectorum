extends Node3D

const BOSS_SCENE := preload("res://scenes/bosses/BossBase.tscn")

@onready var main: Node3D = $Main

func _ready() -> void:
    call_deferred("_prepare_capture")

func _prepare_capture() -> void:
    await get_tree().process_frame
    await get_tree().process_frame

    # The public game now waits at the canonical SOCIETAS campaign gate.
    # QA explicitly starts a fresh campaign so capture still exercises the live runtime.
    main.call("_start_new_campaign_from_gate")
    await get_tree().process_frame
    await get_tree().process_frame

    var stage := main.get_node_or_null("StageDirector") as StageDirector
    if stage == null or stage.player == null or stage.hud == null or stage.floor_instance == null:
        push_error("Definitive visual probe could not resolve live StageDirector runtime")
        get_tree().quit(2)
        return

    var narrative := main.get_node_or_null("NarrativeRuntime")
    if narrative != null:
        narrative.process_mode = Node.PROCESS_MODE_DISABLED
        var presentation := narrative.get_node_or_null("Presentation")
        if presentation != null:
            presentation.set("visible", false)
        var cinematic_stage := narrative.get_node_or_null("CinematicStage") as Node3D
        if cinematic_stage != null:
            cinematic_stage.visible = false

    main.call("_set_gameplay_enabled", true)
    stage.player.rotation = Vector3.ZERO
    stage.player.pitch = 0.0
    stage.player.head.rotation = Vector3.ZERO

    var room := stage.floor_instance.get_node_or_null("Rooms/combat_1") as RoomShell
    if room == null:
        push_error("Definitive visual probe could not resolve combat_1")
        get_tree().quit(3)
        return
    var trigger := room.get_node_or_null("EncounterTrigger") as Area3D
    if trigger != null:
        trigger.monitoring = false
        trigger.monitorable = false

    stage.player.global_position = room.global_position + Vector3(0, 0.15, 2.8)
    stage.player.rotation = Vector3.ZERO

    var boss := BOSS_SCENE.instantiate() as DataBossController
    var boss_id := StringName(stage.stage_data.get("boss_id", "blind_observer"))
    boss.configure(boss_id, stage.player)
    room.add_child(boss)
    boss.position = Vector3(0, 0.1, -3.8)
    boss.current_attack_name = "OLHO DA FORMA"
    boss.process_mode = Node.PROCESS_MODE_DISABLED
    stage.hud.track_enemy(boss, true)
    stage.hud.show_boss(boss.display_name, 0.78, 2, boss.combat_level, boss.current_attack_name)

    var enemy_ids: Array = stage.stage_data.get("common_enemy_ids", [])
    var positions := [Vector3(-2.15, 0.15, -1.75), Vector3(2.15, 0.15, -1.75)]
    for index in range(mini(2, enemy_ids.size())):
        var enemy := EnemyFactory.spawn(StringName(enemy_ids[index]), room, positions[index], stage.player)
        if enemy == null:
            continue
        enemy.process_mode = Node.PROCESS_MODE_DISABLED
        if index == 1:
            enemy.role = &"elite"
            enemy.combat_level += 2
        stage.hud.track_enemy(enemy)

    stage.hud.set_objective("O OLHO · PERCEPÇÃO")
    stage.hud.show_message("A FORMA CEGA OBSERVA. HARUN RESPONDE.", 8.0)
    stage.hud.show_power_acquired("OLHO REVELATÓRIO", "O oculto se torna legível.")
    stage.hud.push_reward("+ 3 ESSÊNCIA")
    stage.hud.push_reward("FORMA II · VISÃO DE PROJÉTEIS")

    for _frame in range(16):
        await get_tree().process_frame

    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        push_error("Definitive visual probe produced an empty viewport image")
        get_tree().quit(4)
        return

    DirAccess.make_dir_recursive_absolute("/tmp/chronica-definitive")
    var output := "/tmp/chronica-definitive/definitive_visual.png"
    var error := image.save_png(output)
    if error != OK:
        push_error("Definitive visual probe failed saving PNG: %s" % error)
        get_tree().quit(5)
        return

    print("DEFINITIVE_VISUAL_CAPTURE=PASS path=%s size=%dx%d" % [output, image.get_width(), image.get_height()])
    get_tree().quit(0)
