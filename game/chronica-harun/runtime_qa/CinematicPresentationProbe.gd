extends Node

var failures: Array[String] = []

func fail(label: String) -> void:
    failures.append(label)
    push_error("CINEMATIC_PROBE_FAIL " + label)

func _ready() -> void:
    call_deferred("run")

func run() -> void:
    var packed := load("res://scenes/boot/Main.tscn") as PackedScene
    if packed == null:
        fail("main_scene_missing")
        finish()
        return
    var main := packed.instantiate()
    add_child(main)
    await get_tree().process_frame
    await get_tree().process_frame
    var runtime := main.get_node_or_null("NarrativeRuntime")
    if runtime == null:
        fail("narrative_runtime_missing")
        finish()
        return
    var presentation := runtime.get_node_or_null("Presentation")
    var stage := runtime.get_node_or_null("CinematicStage")
    var camera := runtime.get_node_or_null("CinematicStage/CameraRig/CinematicCamera") as Camera3D
    var proxy_root := runtime.get_node_or_null("CinematicStage/ProxyRoot")
    var world_root := main.get_node_or_null("WorldRoot") as Node3D
    if presentation == null: fail("presentation_missing")
    if stage == null: fail("cinematic_stage_missing")
    if camera == null: fail("cinematic_camera_missing")
    if presentation == null:
        finish()
        return

    # Player-facing safety contract: placeholder/proxy cinematics must never seize
    # first-run gameplay or replace the player's view with debug geometry.
    if not bool(main.get("gameplay_enabled")):
        fail("proxy_entry_disabled_gameplay")
    if world_root == null or not world_root.visible or world_root.process_mode == Node.PROCESS_MODE_DISABLED:
        fail("proxy_entry_disabled_world")
    if camera != null and camera.current:
        fail("proxy_entry_seized_camera")
    if proxy_root != null and proxy_root.get_child_count() > 0:
        fail("proxy_geometry_visible_to_player")

    if not presentation.has_method("show_title_reveal"): fail("title_reveal_method_missing")
    if not presentation.has_method("show_fragment_progress"): fail("fragment_method_missing")
    if not presentation.has_method("show_command_reveal"): fail("command_reveal_method_missing")
    if not presentation.has_method("enter_final_black"): fail("final_black_method_missing")
    if presentation.has_method("show_fragment_progress"):
        presentation.show_fragment_progress(&"broken_map", 5, 5)
    if presentation.has_method("show_title_reveal"):
        presentation.show_title_reveal("GRIMORIUM ASCENSIONIS")
    if presentation.has_method("show_command_reveal"):
        presentation.show_command_reveal(&"VER", 0)
    await get_tree().process_frame
    await get_tree().process_frame
    var reveal_image := get_viewport().get_texture().get_image()
    var reveal_err := reveal_image.save_png("res://evidence/cinematic-runtime.png")
    if reveal_err != OK: fail("screenshot_save_failed")
    if presentation.has_method("enter_final_black"):
        presentation.enter_final_black("LUCIFER")
        await get_tree().create_timer(1.7, true).timeout
        var blackout := presentation.get_node_or_null("Root/Blackout") as ColorRect
        var reveal := presentation.get_node_or_null("Root/RevealLabel") as Label
        if blackout == null or not blackout.visible or blackout.color.a < 0.99:
            fail("final_black_not_opaque")
        if reveal == null or reveal.visible:
            fail("lucifer_not_cut_to_black")
        var black_image := get_viewport().get_texture().get_image()
        var black_err := black_image.save_png("res://evidence/cinematic-final-black.png")
        if black_err != OK: fail("final_black_screenshot_save_failed")
    finish()

func finish() -> void:
    if failures.is_empty():
        print("CINEMATIC_PRESENTATION_RUNTIME_PASS")
        get_tree().quit(0)
    else:
        print("CINEMATIC_PRESENTATION_RUNTIME_FAILURES=", failures)
        get_tree().quit(1)
