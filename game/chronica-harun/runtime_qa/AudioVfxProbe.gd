extends Node

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
    var phase_feedback := VFXDirector.emit_feedback(&"boss_phase", Vector3.ZERO)
    await get_tree().process_frame
    if not boss_phase_seen:
        failures.append("boss phase feedback did not fire")
    if is_instance_valid(phase_feedback):
        phase_feedback.queue_free()

    # Runtime travel is validated on the projectile script itself. The packed scene's
    # visible core and GPU trail are parsed during strict import and asserted by pytest;
    # instantiating GPUParticles3D under Godot's dummy headless renderer produces a
    # renderer-only null-mesh diagnostic unrelated to gameplay.
    var projectile := ReadableProjectile.new()
    add_child(projectile)
    projectile.configure({"speed":10.0, "damage":1.0, "emission":0.4, "lifetime":2.0}, Vector3.ZERO, Vector3.FORWARD, &"probe")
    var before := projectile.global_position
    projectile._physics_process(0.1)
    if projectile.global_position.distance_to(before) <= 0.5:
        failures.append("projectile did not physically travel")
    projectile.queue_free()

    AudioDirector.play_3d(&"enemy_windup", Vector3.ZERO)
    AudioDirector.play_3d(&"enemy_shot", Vector3.ZERO)
    AudioDirector.play_3d(&"player_hit", Vector3.ZERO)
    AudioDirector.play_3d(&"boss_phase", Vector3.ZERO)
    await get_tree().create_timer(0.55).timeout

    if failures.is_empty():
        print("AUDIO_VFX_RUNTIME_PROBE=PASS")
        get_tree().quit(0)
        return
    for failure in failures:
        push_error("AUDIO_VFX_PROBE: %s" % failure)
    print("AUDIO_VFX_RUNTIME_PROBE=FAIL")
    get_tree().quit(1)

func _on_feedback(event_id: StringName, _position: Vector3) -> void:
    if event_id == &"boss_phase":
        boss_phase_seen = true
