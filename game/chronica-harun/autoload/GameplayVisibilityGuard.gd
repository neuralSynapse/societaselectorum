extends Node

const MIN_AMBIENT_ENERGY := 1.05
const MIN_EXPOSURE := 1.34
const MAX_FOG_DENSITY := 0.006
const MIN_ROOM_FILL := 3.25
const MIN_ROOM_FILL_RANGE := 10.5
const MIN_KEY_LIGHT := 1.15

var _main: Node = null
var _remaining := 0.0
var _pulse := 0.0
var _diagnostic_announced := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func enforce(main: Node, duration_seconds: float = 5.0) -> void:
    if main == null:
        return
    _main = main
    _remaining = maxf(_remaining, duration_seconds)
    _pulse = 0.0
    _enforce_now(main)

func _process(delta: float) -> void:
    if _remaining <= 0.0 or _main == null or not is_instance_valid(_main):
        return
    _remaining -= delta
    _pulse -= delta
    if _pulse <= 0.0:
        _pulse = 0.20
        _enforce_now(_main)

func _enforce_now(main: Node) -> void:
    var world_root := main.get_node_or_null("WorldRoot") as Node3D
    if world_root != null:
        world_root.visible = true
        world_root.process_mode = Node.PROCESS_MODE_INHERIT
        _enforce_environment(world_root)
        _enforce_world_lights(world_root)

    var stage := main.get_node_or_null("StageDirector") as StageDirector
    if stage != null:
        _enforce_stage(stage)

    var narrative := main.get_node_or_null("NarrativeRuntime")
    if narrative != null:
        _enforce_presentation(narrative)
        var cinematic_stage := narrative.get_node_or_null("CinematicStage") as Node3D
        if cinematic_stage != null and cinematic_stage.has_method("can_take_player_control"):
            if not bool(cinematic_stage.call("can_take_player_control")):
                cinematic_stage.visible = false
                var cinematic_camera := cinematic_stage.get_node_or_null("CameraRig/CinematicCamera") as Camera3D
                if cinematic_camera != null:
                    cinematic_camera.current = false

func _enforce_presentation(narrative: Node) -> void:
    var presentation := narrative.get_node_or_null("Presentation")
    if presentation == null:
        return
    var blackout := presentation.get_node_or_null("Root/Blackout") as ColorRect
    if blackout != null:
        blackout.visible = false
        blackout.color = Color(0, 0, 0, 0)
    var veil := presentation.get_node_or_null("Root/CinematicVeil") as ColorRect
    if veil != null:
        veil.visible = false
        veil.color = Color(0, 0, 0, 0)
    var choice_panel := presentation.get_node_or_null("Root/ChoicePanel") as Control
    var choice_dimmer := presentation.get_node_or_null("Root/ChoiceDimmer") as ColorRect
    if choice_dimmer != null and (choice_panel == null or not choice_panel.visible):
        choice_dimmer.visible = false
        choice_dimmer.color = Color(0, 0, 0, 0)

func _enforce_environment(world_root: Node3D) -> void:
    var world_environment := world_root.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if world_environment == null or world_environment.environment == null:
        return
    var environment := world_environment.environment
    environment.background_energy_multiplier = maxf(environment.background_energy_multiplier, 0.72)
    environment.ambient_light_energy = maxf(environment.ambient_light_energy, MIN_AMBIENT_ENERGY)
    environment.ambient_light_color = _at_least_color(environment.ambient_light_color, Color(0.24, 0.15, 0.10, 1.0))
    environment.tonemap_exposure = maxf(environment.tonemap_exposure, MIN_EXPOSURE)
    if environment.fog_enabled:
        environment.fog_density = minf(environment.fog_density, MAX_FOG_DENSITY)
        environment.fog_light_energy = maxf(environment.fog_light_energy, 0.95)

func _enforce_world_lights(world_root: Node3D) -> void:
    var key := world_root.get_node_or_null("KeyLight") as DirectionalLight3D
    if key != null:
        key.light_energy = maxf(key.light_energy, MIN_KEY_LIGHT)
    var rim := world_root.get_node_or_null("MoonRim") as DirectionalLight3D
    if rim != null:
        rim.light_energy = maxf(rim.light_energy, 0.42)

func _enforce_stage(stage: StageDirector) -> void:
    if stage.floor_instance != null:
        stage.floor_instance.visible = true
        var rooms := stage.floor_instance.get_node_or_null("Rooms")
        if rooms != null:
            for room_value in rooms.get_children():
                if room_value is RoomShell:
                    var room := room_value as RoomShell
                    room.visible = String(room.room_id) == "threshold"
                    if room.visible:
                        _enforce_room(room)
            if OS.has_feature("web") and not _diagnostic_announced:
                _diagnostic_announced = true
                print("WEB_ROOM_ISOLATION_DIAGNOSTIC threshold_only=true")
    if stage.player != null and is_instance_valid(stage.player):
        stage.player.visible = true
        stage.player.process_mode = Node.PROCESS_MODE_INHERIT
        if stage.player.camera != null:
            stage.player.camera.current = true
            stage.player.camera.make_current()
            _install_web_geometry_probe(stage.player.camera)
    if stage.hud != null and is_instance_valid(stage.hud):
        stage.hud.visible = true

func _install_web_geometry_probe(camera: Camera3D) -> void:
    if not OS.has_feature("web") or camera == null or camera.has_node("WebGeometryProbe"):
        return
    var probe := MeshInstance3D.new()
    probe.name = "WebGeometryProbe"
    probe.position = Vector3(0, 0, -1.3)
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.42, 0.42, 0.42)
    probe.mesh = mesh
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color(1.0, 0.0, 0.8, 1.0)
    material.emission_enabled = true
    material.emission = Color(1.0, 0.0, 0.8, 1.0)
    material.emission_energy_multiplier = 2.0
    probe.material_override = material
    camera.add_child(probe)
    print("WEB_GEOMETRY_PROBE installed path=%s" % String(probe.get_path()))

func _enforce_room(room: RoomShell) -> void:
    if room == null or not is_instance_valid(room) or not room.visible:
        return
    var fill := room.get_node_or_null("VisibilityFillLight") as OmniLight3D
    if fill != null:
        fill.light_energy = maxf(fill.light_energy, MIN_ROOM_FILL)
        fill.omni_range = maxf(fill.omni_range, MIN_ROOM_FILL_RANGE)
        fill.light_color = _at_least_color(fill.light_color, Color(0.94, 0.72, 0.50, 1.0))
    var warm := room.get_node_or_null("WarmKeyLight") as OmniLight3D
    if warm != null:
        warm.light_energy = maxf(warm.light_energy, 1.20 if room.room_role == &"threshold" else 1.35)
        warm.omni_range = maxf(warm.omni_range, 7.8)
    var violet := room.get_node_or_null("VioletRimLight") as OmniLight3D
    if violet != null:
        violet.light_energy = maxf(violet.light_energy, 0.50)
        violet.omni_range = maxf(violet.omni_range, 6.4)

func _at_least_color(current: Color, fallback: Color) -> Color:
    var current_luma := current.r * 0.2126 + current.g * 0.7152 + current.b * 0.0722
    var fallback_luma := fallback.r * 0.2126 + fallback.g * 0.7152 + fallback.b * 0.0722
    return fallback if current_luma < fallback_luma else current
