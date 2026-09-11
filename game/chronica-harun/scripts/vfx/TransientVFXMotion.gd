extends Node3D
class_name TransientVFXMotion

var velocity := Vector3.ZERO
var lifetime := 0.18
var elapsed := 0.0
var start_scale_value := 0.45
var end_scale_value := 2.0

func configure(direction: Vector3, travel: float, duration: float, start_scale: float, end_scale: float) -> void:
    lifetime = maxf(duration, 0.001)
    start_scale_value = start_scale
    end_scale_value = end_scale
    scale = Vector3.ONE * start_scale_value
    velocity = Vector3.ZERO
    if travel > 0.0 and direction.length_squared() > 0.001:
        velocity = direction.normalized() * (travel / lifetime)
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process(true)

func _process(delta: float) -> void:
    if delta <= 0.0:
        return
    if velocity.length_squared() > 0.0:
        position += velocity * delta
    elapsed += delta
    var ratio := clampf(elapsed / lifetime, 0.0, 1.0)
    var scale_value := lerpf(start_scale_value, end_scale_value, ratio)
    scale = Vector3.ONE * scale_value
    if elapsed >= lifetime:
        queue_free()
