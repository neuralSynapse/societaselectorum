extends Node
class_name Health

signal damaged(current: float, maximum: float, amount: float, source_id: StringName)
signal healed(current: float, maximum: float, amount: float)
signal died(source_id: StringName)

@export var max_health := 100.0
@export var invulnerability_time := 0.15
var current_health := 100.0
var invulnerable_for := 0.0
var dead := false

func _ready() -> void:
    current_health = max_health

func _process(delta: float) -> void:
    invulnerable_for = maxf(0.0, invulnerable_for - delta)

func apply_damage(amount: float, source_id: StringName = &"") -> bool:
    if dead or amount <= 0.0 or invulnerable_for > 0.0:
        return false
    var actual := minf(amount, current_health)
    current_health = maxf(0.0, current_health - actual)
    invulnerable_for = invulnerability_time
    damaged.emit(current_health, max_health, actual, source_id)
    if current_health <= 0.0 and not dead:
        dead = true
        died.emit(source_id)
    return true

func heal(amount: float) -> float:
    if dead or amount <= 0.0:
        return current_health
    var before := current_health
    current_health = minf(max_health, current_health + amount)
    var actual := current_health - before
    if actual > 0.0:
        healed.emit(current_health, max_health, actual)
    return current_health

func ratio() -> float:
    if max_health <= 0.0:
        return 0.0
    return current_health / max_health
