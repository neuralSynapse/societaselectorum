extends Node3D

@onready var main: Node3D = $Main

func _ready() -> void:
    call_deferred("_run_probe")

func _run_probe() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame

    main.call("_start_new_campaign_from_gate")
    for _frame in range(48):
        await get_tree().process_frame

    var world_root := main.get_node_or_null("WorldRoot") as Node3D
    var stage := main.get_node_or_null("StageDirector") as StageDirector
    if world_root == null or stage == null or stage.player == null or stage.hud == null:
        push_error("Boot visibility probe could not resolve live gameplay runtime")
        get_tree().quit(2)
        return
    if not world_root.visible:
        push_error("Boot visibility probe found hidden WorldRoot")
        get_tree().quit(3)
        return
    if stage.player.camera == null or not stage.player.camera.current:
        push_error("Boot visibility probe found no current gameplay camera")
        get_tree().quit(4)
        return

    var narrative := main.get_node_or_null("NarrativeRuntime")
    if narrative != null:
        var presentation := narrative.get_node_or_null("Presentation")
        if presentation != null:
            var blackout := presentation.get_node_or_null("Root/Blackout") as ColorRect
            var veil := presentation.get_node_or_null("Root/CinematicVeil") as ColorRect
            if blackout != null and blackout.visible and blackout.color.a > 0.02:
                push_error("Boot visibility probe found stale narrative blackout")
                get_tree().quit(5)
                return
            if veil != null and veil.visible and veil.color.a > 0.28:
                push_error("Boot visibility probe found excessive cinematic veil")
                get_tree().quit(6)
                return

    var encounter_nodes := get_tree().get_nodes_in_group("narrative_encounter")
    if encounter_nodes.is_empty():
        push_error("Boot visibility probe found no canonical narrative encounter")
        get_tree().quit(7)
        return
    var encounter := encounter_nodes[0] as Node3D
    if encounter == null:
        push_error("Boot visibility probe could not resolve encounter as Node3D")
        get_tree().quit(8)
        return
    var camera := stage.player.camera
    var encounter_center := encounter.global_position + Vector3(0.0, 1.35 * encounter.scale.y, 0.0)
    if camera.is_position_behind(encounter_center):
        push_error("Boot encounter spawned behind gameplay camera")
        get_tree().quit(9)
        return
    var camera_space := camera.global_transform.affine_inverse() * encounter_center
    var depth := -camera_space.z
    var screen_position := camera.unproject_position(encounter_center)
    var viewport_size := get_viewport().get_visible_rect().size
    var min_screen_x := viewport_size.x * 0.14
    var max_screen_x := viewport_size.x * 0.86
    if depth < 2.8 or encounter.scale.x > 0.86 or screen_position.x < min_screen_x or screen_position.x > max_screen_x:
        push_error("Boot encounter staging obstructs gameplay: depth=%.3f scale=%.3f screen_x=%.1f viewport_x=%.1f" % [depth, encounter.scale.x, screen_position.x, viewport_size.x])
        get_tree().quit(10)
        return
    print("BOOT_ENCOUNTER_STAGING=PASS depth=%.3f scale=%.3f screen_x=%.1f" % [depth, encounter.scale.x, screen_position.x])

    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        push_error("Boot visibility probe produced an empty viewport image")
        get_tree().quit(11)
        return

    var mean_luminance := _sample_mean_luminance(image)
    var visible_ratio := _sample_visible_ratio(image)
    if mean_luminance < 0.028 or visible_ratio < 0.12:
        push_error("Boot gameplay is too dark: mean_luminance=%.4f visible_ratio=%.4f" % [mean_luminance, visible_ratio])
        _save_capture(image)
        get_tree().quit(12)
        return

    _save_capture(image)
    print("BOOT_GAMEPLAY_VISIBILITY=PASS mean_luminance=%.4f visible_ratio=%.4f" % [mean_luminance, visible_ratio])
    get_tree().quit(0)

func _sample_mean_luminance(image: Image) -> float:
    var width := image.get_width()
    var height := image.get_height()
    var x0 := int(width * 0.16)
    var x1 := int(width * 0.84)
    var y0 := int(height * 0.16)
    var y1 := int(height * 0.76)
    var step_x := maxi(1, int((x1 - x0) / 48.0))
    var step_y := maxi(1, int((y1 - y0) / 30.0))
    var total := 0.0
    var count := 0
    for y in range(y0, y1, step_y):
        for x in range(x0, x1, step_x):
            var color := image.get_pixel(x, y)
            total += color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
            count += 1
    return total / maxf(1.0, float(count))

func _sample_visible_ratio(image: Image) -> float:
    var width := image.get_width()
    var height := image.get_height()
    var x0 := int(width * 0.16)
    var x1 := int(width * 0.84)
    var y0 := int(height * 0.16)
    var y1 := int(height * 0.76)
    var step_x := maxi(1, int((x1 - x0) / 48.0))
    var step_y := maxi(1, int((y1 - y0) / 30.0))
    var visible := 0
    var count := 0
    for y in range(y0, y1, step_y):
        for x in range(x0, x1, step_x):
            var color := image.get_pixel(x, y)
            var luma := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
            if luma >= 0.035:
                visible += 1
            count += 1
    return float(visible) / maxf(1.0, float(count))

func _save_capture(image: Image) -> void:
    DirAccess.make_dir_recursive_absolute("/tmp/chronica-boot")
    image.save_png("/tmp/chronica-boot/boot_visibility.png")
