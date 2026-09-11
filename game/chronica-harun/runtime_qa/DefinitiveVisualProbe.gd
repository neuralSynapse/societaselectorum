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

    # The canonical gate can leave the tree paused during narrative handoff.
    # Directional QA must exercise the same unpaused state used during live combat.
    get_tree().paused = false
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

    if not await _verify_primary_direction(stage.player):
        get_tree().quit(6)
        return

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

func _verify_primary_direction(player: PlayerController) -> bool:
    var camera := player.camera
    var muzzle := player.get_node_or_null("Head/Camera3D/ViewModelRoot/LeftGauntlet/PrimaryMuzzle") as Node3D
    if camera == null or muzzle == null:
        push_error("Primary direction probe missing camera or PrimaryMuzzle")
        return false
    var forward := (-camera.global_transform.basis.z).normalized()
    VFXDirector._primary_ready_at = 0
    VFXDirector._on_primary_requested(player)
    await get_tree().process_frame
    var effect := VFXDirector.get_node_or_null("VFX_player_primary") as Node3D
    if effect == null:
        push_error("Primary direction probe did not create player_primary VFX")
        return false
    var origin := effect.global_position
    var camera_to_origin := origin - camera.global_position
    var effect_direction: Vector3 = effect.get_meta("direction", Vector3.ZERO)
    if camera_to_origin.dot(forward) <= 0.25:
        push_error("Primary VFX spawned behind/inside camera plane")
        return false
    if effect_direction.normalized().dot(forward) < 0.995:
        push_error("Primary VFX direction diverged from camera forward")
        return false
    await get_tree().create_timer(0.07).timeout
    if not is_instance_valid(effect):
        push_error("Primary VFX expired before travel could be verified")
        return false
    var displacement := effect.global_position - origin
    if displacement.dot(forward) <= 0.25:
        push_error("Primary VFX did not travel away from camera")
        return false
    print("PRIMARY_DIRECTION_RUNTIME=PASS ahead=%.3f travel=%.3f alignment=%.4f" % [camera_to_origin.dot(forward), displacement.dot(forward), effect_direction.normalized().dot(forward)])
    return true
