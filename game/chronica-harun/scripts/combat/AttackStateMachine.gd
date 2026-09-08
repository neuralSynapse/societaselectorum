extends Node
class_name AttackStateMachine

signal state_changed(state: StringName)
signal telegraph_started(payload: Dictionary)
signal emission_requested(payload: Dictionary)
signal impact_window_started(payload: Dictionary)
signal attack_finished

const STATES: Array[StringName] = [
    &"idle", &"acquire_target", &"windup", &"telegraph", &"cast",
    &"active", &"impact", &"recovery"
]

var state: StringName = &"idle"
var definition: Dictionary = {}
var target: Node3D
var elapsed := 0.0
var busy := false

func _ready() -> void:
    _sync_telegraph_visual()

func begin_attack(next_definition: Dictionary, next_target: Node3D) -> bool:
    if busy or next_definition.is_empty() or next_target == null:
        return false
    definition = next_definition.duplicate(true)
    target = next_target
    elapsed = 0.0
    busy = true
    _set_state(&"acquire_target")
    return true

func cancel() -> void:
    busy = false
    definition.clear()
    target = null
    elapsed = 0.0
    _set_state(&"idle")

func _process(delta: float) -> void:
    if not busy:
        return
    elapsed += delta
    match state:
        &"acquire_target":
            _advance(&"windup")
        &"windup":
            if elapsed >= float(definition.get("windup", 0.35)):
                _advance(&"telegraph")
                telegraph_started.emit(_payload())
        &"telegraph":
            if elapsed >= float(definition.get("telegraph_time", 0.25)):
                _advance(&"cast")
                emission_requested.emit(_payload())
        &"cast":
            _advance(&"active")
        &"active":
            if elapsed >= float(definition.get("active", 0.18)):
                _advance(&"impact")
                impact_window_started.emit(_payload())
        &"impact":
            _advance(&"recovery")
        &"recovery":
            if elapsed >= float(definition.get("recovery", 0.55)):
                busy = false
                definition.clear()
                target = null
                _set_state(&"idle")
                attack_finished.emit()

func _advance(next_state: StringName) -> void:
    elapsed = 0.0
    _set_state(next_state)

func _set_state(next_state: StringName) -> void:
    if not STATES.has(next_state):
        push_error("Unknown attack state: %s" % next_state)
        return
    state = next_state
    _sync_telegraph_visual()
    state_changed.emit(state)

func _sync_telegraph_visual() -> void:
    var host := get_parent()
    if host == null:
        return
    var visual := host.get_node_or_null("TelegraphVisual") as GeometryInstance3D
    if visual:
        visual.visible = state == &"telegraph"

func _payload() -> Dictionary:
    return {"definition": definition.duplicate(true), "target": target, "state": state}
