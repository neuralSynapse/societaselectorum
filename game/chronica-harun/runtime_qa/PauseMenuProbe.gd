extends Node3D

@onready var main: Node3D = $Main

var pause_active := false

const REQUIRED_LABELS := [
    "RETOMAR",
    "JORNADA / MAPA",
    "BUILD & PODERES",
    "TAROT & PHARMAKA",
    "CODEX",
    "PERSONAGENS / MARCAS",
    "CONTROLES",
    "CONFIGURAÇÕES",
    "REINICIAR RUN",
    "VOLTAR AO TÍTULO",
]

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run_probe")

func _run_probe() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    main.call("_start_new_campaign_from_gate")
    for _frame in range(36):
        await get_tree().process_frame

    pause_active = true
    main.call("set_pause_state", true)
    for _frame in range(6):
        await get_tree().process_frame

    var runtime := get_node_or_null("/root/InitiaticRuntime")
    if runtime == null:
        _fail("InitiaticRuntime autoload is missing", 2)
        return
    var pause_surface := runtime.get("pause_root") as Control
    if pause_surface == null or not pause_surface.visible:
        _fail("Initiatic pause surface is not visible", 3)
        return
    if not get_tree().paused:
        _fail("SceneTree is not paused while pause surface is visible", 4)
        return

    var labels: Array[String] = []
    _collect_button_labels(pause_surface, labels)
    for required in REQUIRED_LABELS:
        if not labels.has(required):
            _fail("Pause navigation is missing: %s" % required, 5)
            return

    var title := runtime.get("pause_title") as Label
    var body := runtime.get("pause_body") as RichTextLabel
    if title == null or body == null or title.text.strip_edges().is_empty() or body.text.strip_edges().is_empty():
        _fail("Pause menu title/body is incomplete", 6)
        return

    var image := get_viewport().get_texture().get_image()
    if image == null or image.is_empty():
        _fail("Pause menu capture is empty", 7)
        return
    DirAccess.make_dir_recursive_absolute("/tmp/chronica-pause")
    image.save_png("/tmp/chronica-pause/pause_menu.png")

    print("PAUSE_MENU_RUNTIME=PASS buttons=%d title=%s" % [labels.size(), title.text])
    pause_active = false
    main.call("set_pause_state", false)
    get_tree().paused = false
    get_tree().quit(0)

func _collect_button_labels(node: Node, labels: Array[String]) -> void:
    if node is Button:
        labels.append((node as Button).text)
    for child in node.get_children():
        _collect_button_labels(child, labels)

func _fail(message: String, code: int) -> void:
    push_error(message)
    pause_active = false
    if main != null and main.has_method("set_pause_state"):
        main.call("set_pause_state", false)
    get_tree().paused = false
    get_tree().quit(code)
