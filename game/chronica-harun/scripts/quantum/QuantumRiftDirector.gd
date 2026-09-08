extends Node
class_name QuantumRiftDirector

signal lab_opened(definition: Dictionary)
signal superposition_entered(branches: Array)
signal branch_measured(branch: Dictionary)
signal corridor_exited(branch_id: StringName)

const DATA_PATH := "res://data/quantum/quantum_mechanics.json"
var data: Dictionary = {}
var active_branches: Array = []
var measured_branch: Dictionary = {}

func _ready() -> void:
    data = _load_json(DATA_PATH)

func can_open_lab(context: Dictionary = {}) -> bool:
    if data.is_empty(): data = _load_json(DATA_PATH)
    var access: Dictionary = data.get("secret_room", {}).get("access", {})
    var state: Dictionary = GameState.meta_progression.get("quantum", {})
    var fragments := int(context.get("observation_fragments", state.get("observation_fragments", 0)))
    var kinesis: Dictionary = GameState.meta_progression.get("kinesis", {})
    var nodes: Array = kinesis.get("unlocked_nodes", [])
    return fragments >= 3 and "liber_laboratorii_arcani:quantum_lab" in nodes and bool(access.get("hidden", false))

func open_lab(context: Dictionary = {}) -> bool:
    if not can_open_lab(context): return false
    lab_opened.emit(data.get("secret_room", {}))
    return true

func enter_superposition(seed: int, context: Dictionary = {}) -> Array:
    if data.is_empty(): data = _load_json(DATA_PATH)
    var count := int(data.get("branch_corridor", {}).get("doors", 3))
    var rng := RandomNumberGenerator.new(); rng.seed = seed + int(GameState.run_seed)
    active_branches.clear(); measured_branch = {}
    var archetypes := ["combat_shortcut","mentor_echo","eden_fragment","arsenal_vault","future_reward","mortis_debt","timeline_secret"]
    for i in count:
        var kind: String = String(archetypes[rng.randi_range(0, archetypes.size()-1)])
        active_branches.append({"id":"branch_%d" % i,"kind":kind,"weight":rng.randf_range(.7,1.3),"context_echo":context.duplicate(true)})
    GameState.meta_progression["quantum_observations"] = int(GameState.meta_progression.get("quantum_observations", 0)) + 1
    superposition_entered.emit(active_branches.duplicate(true))
    return active_branches.duplicate(true)

func measure_branch(branch_id: StringName) -> Dictionary:
    for branch in active_branches:
        if String(branch.get("id", "")) != String(branch_id): continue
        measured_branch = branch.duplicate(true)
        active_branches.clear()
        var state: Dictionary = GameState.meta_progression.get("quantum", {})
        var measured: Array = state.get("measured_branches", [])
        measured.append(measured_branch.duplicate(true))
        state["measured_branches"] = measured
        GameState.meta_progression["quantum"] = state
        branch_measured.emit(measured_branch)
        return measured_branch
    return {}

func exit_branch_corridor() -> bool:
    if measured_branch.is_empty(): return false
    corridor_exited.emit(StringName(measured_branch.get("id", "")))
    measured_branch = {}
    return true

func _load_json(path: String) -> Dictionary:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null: return {}
    var parsed = JSON.parse_string(f.get_as_text())
    return parsed if parsed is Dictionary else {}
