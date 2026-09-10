extends Node

var stage_director: StageDirector
var _bound_room_director_id := 0
var _bootstrapped_stage := ""

func _ready() -> void:
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_scan_existing")

func _process(_delta: float) -> void:
    _ensure_runtime_bindings()

func _scan_existing() -> void:
    var scene := get_tree().current_scene
    if scene != null:
        _scan_node(scene)

func _scan_node(node: Node) -> void:
    if node is StageDirector:
        stage_director = node as StageDirector
        return
    for child in node.get_children():
        _scan_node(child)
        if stage_director != null:
            return

func _on_node_added(node: Node) -> void:
    if node is StageDirector:
        stage_director = node as StageDirector

func _ensure_runtime_bindings() -> void:
    if stage_director == null or not is_instance_valid(stage_director):
        return
    if stage_director.stage_data.is_empty() or stage_director.room_director == null or stage_director.hud == null or stage_director.player == null:
        return

    var room_id := stage_director.room_director.get_instance_id()
    if room_id != _bound_room_director_id:
        _bound_room_director_id = room_id
        if not stage_director.room_director.room_cleared.is_connected(_on_room_cleared):
            stage_director.room_director.room_cleared.connect(_on_room_cleared)

    var stage_key := String(stage_director.stage_data.get("id", GameState.current_stage_id))
    if stage_key != _bootstrapped_stage:
        _bootstrapped_stage = stage_key
        _ensure_stage_power()

func _ensure_stage_power() -> void:
    if stage_director == null or stage_director.stage_data.is_empty():
        return
    var power_id := StringName(stage_director.stage_data.get("power_id", ""))
    if power_id == &"":
        return
    var build := RogueliteContentService.ensure_build()
    var known: Array = build.get("powers", [])
    if not known.has(String(power_id)):
        RogueliteContentService.add_power(power_id)
    else:
        CombatLoadoutDirector.activate_known_power(power_id)
    SaveService.save_campaign(GameState.to_save_data())

func _on_room_cleared(room_id: StringName) -> void:
    if room_id != &"trial":
        return
    if bool(GameState.run_stats.get("mutation_offer_presented", false)):
        return
    GameState.run_stats["mutation_offer_presented"] = true
    call_deferred("_offer_stage_mutations")

func _offer_stage_mutations() -> void:
    if stage_director == null or stage_director.hud == null or stage_director.stage_data.is_empty():
        return
    var power_id := StringName(stage_director.stage_data.get("power_id", ""))
    var power := ContentRegistry.get_power(power_id)
    if power.is_empty():
        return
    var owned: Array = RogueliteContentService.ensure_build().get("mutations", [])
    var available: Array[Dictionary] = []
    for mutation_value in power.get("mutations", []):
        if not mutation_value is Dictionary:
            continue
        var mutation: Dictionary = mutation_value
        var mutation_id := String(mutation.get("id", ""))
        if mutation_id.is_empty() or owned.has(mutation_id):
            continue
        available.append(mutation)
    if available.is_empty():
        stage_director.hud.push_reward("MATRIZ COMPLETA · %s" % String(power.get("name", power_id)).to_upper())
        return

    var labels: Array[String] = []
    for mutation in available:
        var tier := int(mutation.get("tier", 1))
        var effect := String(mutation.get("effect_id", mutation.get("id", "FORMA"))).replace("_", " ").to_upper()
        labels.append("FORMA %s · %s" % [_roman(tier), effect])
    stage_director.hud.show_choice(
        "MUTAÇÃO · %s" % String(power.get("name", power_id)).to_upper(),
        labels,
        Callable(self, "_choose_mutation").bind(available)
    )

func _choose_mutation(index: int, available: Array) -> void:
    if index < 0 or index >= available.size():
        return
    var mutation: Dictionary = available[index]
    var mutation_id := StringName(mutation.get("id", ""))
    if mutation_id == &"":
        return
    if RogueliteContentService.add_mutation(mutation_id):
        SaveService.save_campaign(GameState.to_save_data())

func _roman(value: int) -> String:
    match value:
        1: return "I"
        2: return "II"
        3: return "III"
        _: return str(value)
