extends Node

const PROJECTILE_SCENE := preload("res://scenes/vfx/Projectile.tscn")
const REQUIRED_AUDIO := [
    &"player_primary", &"player_power", &"kinesis", &"instrumenta", &"tarot_activate",
    &"player_hit", &"enemy_windup", &"enemy_shot", &"projectile_impact", &"enemy_hit",
    &"enemy_death", &"boss_windup", &"boss_attack", &"boss_phase", &"boss_death",
    &"pickup", &"secret_break", &"special_room_activate"
]

var failures: Array[String] = []
var boss_phase_seen := false

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    for event_id in REQUIRED_AUDIO:
        if not AudioDirector.has_event(event_id):
            failures.append("missing audio %s" % event_id)
        if AudioDirector.event_status(event_id) == "missing":
            failures.append("missing fallback status %s" % event_id)
    if VFXDirector.effect_emission(&"enemy_telegraph") > VFXDirector.TELEGRAPH_MAX_EMISSION:
        failures.append("enemy telegraph emission cap exceeded")
    if VFXDirector.effect_emission(&"boss_phase") > VFXDirector.MAX_EMISSION:
        failures.append("boss phase emission cap exceeded")
    VFXDirector.feedback_emitted.connect(_on_feedback)
    VFXDirector.emit_feedback(&"boss_phase", Vector3.ZERO)
    await get_tree().process_frame
    if not boss_phase_seen:
        failures.append("boss phase feedback did not fire")
    var projectile := PROJECTILE_SCENE.instantiate() as ReadableProjectile
    add_child(projectile)
    projectile.configure({"speed":10.0, "damage":1.0, "emission":0.4, "lifetime":2.0}, Vector3.ZERO, Vector3.FORWARD, &"probe")
    var mesh := projectile.get_node_or_null("Mesh") as MeshInstance3D
    var trail := projectile.get_node_or_null("Trail") as GPUParticles3D
    if mesh == null or mesh.mesh == null or not mesh.visible:
        failures.append("projectile core not visible")
    if trail == null or trail.draw_pass_1 == null:
        failures.append("projectile trail has no draw pass")
    var before := projectile.global_position
    projectile._physics_process(0.1)
    if projectile.global_position.distance_to(before) <= 0.5:
        failures.append("projectile did not physically travel")
    projectile.queue_free()
    AudioDirector.play_3d(&"enemy_windup", Vector3.ZERO)
    AudioDirector.play_3d(&"enemy_shot", Vector3.ZERO)
    AudioDirector.play_3d(&"player_hit", Vector3.ZERO)
    AudioDirector.play_3d(&"boss_phase", Vector3.ZERO)
    await get_tree().process_frame
    if failures.is_empty():
        print("AUDIO_VFX_RUNTIME_PROBE=PASS")
        get_tree().quit(0)
    for failure in failures:
        push_error("AUDIO_VFX_PROBE: %s" % failure)
    print("AUDIO_VFX_RUNTIME_PROBE=FAIL")
    get_tree().quit(1)

func _on_feedback(event_id: StringName, _position: Vector3) -> void:
    if event_id == &"boss_phase":
        boss_phase_seen = true
