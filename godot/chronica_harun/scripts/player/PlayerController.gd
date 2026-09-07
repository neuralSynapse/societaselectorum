extends CharacterBody3D

@export var move_speed: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 18.0
@onready var neck: Node3D = $Neck

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * mouse_sensitivity)
        neck.rotate_x(-event.relative.y * mouse_sensitivity)
        neck.rotation.x = clampf(neck.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))
    elif event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var local_direction := Vector3(input_vector.x, 0.0, input_vector.y)
    var world_direction := (transform.basis * local_direction).normalized()
    velocity.x = world_direction.x * move_speed
    velocity.z = world_direction.z * move_speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0
    move_and_slide()
