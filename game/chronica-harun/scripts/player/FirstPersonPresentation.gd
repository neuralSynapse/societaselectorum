extends Node3D

@onready var player: PlayerController = get_node("../../..") as PlayerController
@onready var left_gauntlet: Node3D = $LeftGauntlet
@onready var right_gauntlet: Node3D = $RightGauntlet
@onready var left_outer: MeshInstance3D = $LeftGauntlet/LeftSigilRoot/LeftSigilRingOuter
@onready var left_inner: MeshInstance3D = $LeftGauntlet/LeftSigilRoot/LeftSigilRingInner
@onready var right_orb: MeshInstance3D = $RightGauntlet/RightVoidOrb
@onready var right_outer: MeshInstance3D = $RightGauntlet/RightOrbRingOuter
@onready var right_inner: MeshInstance3D = $RightGauntlet/RightOrbRingInner
@onready var left_light: OmniLight3D = $LeftGauntlet/LeftPowerLight
@onready var right_light: OmniLight3D = $RightGauntlet/RightPowerLight

var root_rest_position := Vector3.ZERO
var root_rest_rotation := Vector3.ZERO
var left_rest_position := Vector3.ZERO
var right_rest_position := Vector3.ZERO
var idle_clock := 0.0
var primary_ready_at := 0
var power_ready_at := 0

func _ready() -> void:
    root_rest_position = position
    root_rest_rotation = rotation
    left_rest_position = left_gauntlet.position
    right_rest_position = right_gauntlet.position
    if player != null:
        player.primary_attack_requested.connect(_on_primary_attack)
        player.power_requested.connect(_on_power_requested)
        player.dodge_started.connect(_on_dodge)
        player.damaged.connect(_on_damaged)
    if not DefinitivePowerRuntime.power_activated.is_connected(_on_power):
        DefinitivePowerRuntime.power_activated.connect(_on_power)

func _process(delta: float) -> void:
    idle_clock += delta
    left_outer.rotate_z(delta * 1.18)
    left_inner.rotate_z(-delta * 1.86)
    right_outer.rotate_z(-delta * 1.42)
    right_inner.rotate_z(delta * 2.12)
    left_light.light_energy = 2.05 + sin(idle_clock * 3.4) * 0.16
    right_light.light_energy = 1.88 + sin(idle_clock * 4.1 + 1.2) * 0.18

func _on_primary_attack() -> void:
    var now := Time.get_ticks_msec()
    if now < primary_ready_at:
        return
    primary_ready_at = now + 250
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(left_gauntlet, "position", left_rest_position + Vector3(0.055, 0.035, -0.18), 0.065)
    tween.parallel().tween_property(left_outer, "scale", Vector3.ONE * 1.20, 0.065)
    tween.parallel().tween_property(left_inner, "scale", Vector3.ONE * 1.14, 0.065)
    tween.tween_property(left_gauntlet, "position", left_rest_position, 0.17)
    tween.parallel().tween_property(left_outer, "scale", Vector3.ONE, 0.17)
    tween.parallel().tween_property(left_inner, "scale", Vector3.ONE, 0.17)

func _on_power_requested() -> void:
    _animate_right_power()

func _on_power(_power_id: StringName, _effect_id: StringName) -> void:
    _animate_right_power()

func _animate_right_power() -> void:
    var now := Time.get_ticks_msec()
    if now < power_ready_at:
        return
    power_ready_at = now + 180
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(right_gauntlet, "position", right_rest_position + Vector3(-0.13, 0.08, -0.10), 0.10)
    tween.parallel().tween_property(right_orb, "scale", Vector3.ONE * 1.86, 0.10)
    tween.parallel().tween_property(right_outer, "scale", Vector3.ONE * 1.38, 0.10)
    tween.parallel().tween_property(right_inner, "scale", Vector3.ONE * 1.28, 0.10)
    tween.tween_property(right_gauntlet, "position", right_rest_position, 0.24)
    tween.parallel().tween_property(right_orb, "scale", Vector3.ONE, 0.24)
    tween.parallel().tween_property(right_outer, "scale", Vector3.ONE, 0.24)
    tween.parallel().tween_property(right_inner, "scale", Vector3.ONE, 0.24)

    var flare := create_tween()
    flare.tween_property(right_light, "omni_range", 3.45, 0.08)
    flare.tween_property(right_light, "omni_range", 1.9, 0.26)

func _on_dodge(_perfect_window: float) -> void:
    var lateral := 1.0
    if player != null and absf(player.velocity.x) > 0.05:
        lateral = signf(player.velocity.x)
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "position", root_rest_position + Vector3(0.03 * lateral, -0.075, 0.06), 0.07)
    tween.parallel().tween_property(self, "rotation", root_rest_rotation + Vector3(0.035, 0.0, -0.085 * lateral), 0.07)
    tween.tween_property(self, "position", root_rest_position, 0.20)
    tween.parallel().tween_property(self, "rotation", root_rest_rotation, 0.20)

func _on_damaged(_amount: float, _source_id: StringName) -> void:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.tween_property(self, "position", root_rest_position + Vector3(0.018, -0.012, 0.025), 0.035)
    tween.tween_property(self, "position", root_rest_position + Vector3(-0.018, 0.008, 0.012), 0.035)
    tween.tween_property(self, "position", root_rest_position, 0.06)
