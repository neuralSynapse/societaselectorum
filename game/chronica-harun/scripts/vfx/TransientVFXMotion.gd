extends Node3D
class_name TransientVFXMotion

const MAX_SIMULATION_STEP := 1.0 / 24.0
const MIN_FRAMES_ALIVE := 6

var velocity := Vector3.ZERO
var lifetime := 0.18
var elapsed := 0.0
var start_scale_value := 0.45
var end_scale_value := 2.0
var frames_alive := 0

func configure(direction: Vector3, travel: float, duration: float, start_scale: float, end_scale: float) -> void:
    lifetime = maxf(duration, 0.001)
    start_scale_value = start_scale
    end_scale_value = end_scale
    scale = Vector3.ONE * start_scale_value
    velocity = Vector3.ZERO
    elapsed = 0.0
    frames_alive = 0
    if travel > 0.0 and direction.length_squared() > 0.001:
        velocity = direction.normalized() * (travel / lifetime)
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process(true)

func _process(delta: float) -> void:
    if delta <= 0.0:
        return
    frames_alive += 1
    # A browser frame can stall while shaders/assets compile. Never let one long
    # frame consume the entire visual lifetime or teleport the projectile back
    # into a one-frame flash at the camera.
    var safe_delta := minf(delta, MAX_SIMULATION_STEP)
    if velocity.length_squared() > 0.0:
        position += velocity * safe_delta
    elapsed += safe_delta
    var ratio := clampf(elapsed / lifetime, 0.0, 1.0)
    var scale_value := lerpf(start_scale_value, end_scale_value, ratio)
    scale = Vector3.ONE * scale_value
    if elapsed >= lifetime and frames_alive >= MIN_FRAMES_ALIVE:
        queue_free()
