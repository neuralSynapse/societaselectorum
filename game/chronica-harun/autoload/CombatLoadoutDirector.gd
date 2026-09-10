extends Node

signal active_power_changed(power_id: StringName)

var stage_director: StageDirector
var active_power: StringName = &""

func _ready() -> void:
    RogueliteContentService.build_changed.connect(_on_build_changed)
    get_tree().node_added.connect(_on_node_added)
    _on_build_changed(RogueliteContentService.ensure_build())
    call_deferred("_scan_existing")

func _process(_delta: float) -> void:
    _apply_active_power()

func _scan_existing() -> void:
    var scene := get_tree().current_scene
    if scene != null:
        _scan_node(scene)

func _scan_node(node: Node) -> void:
    if node is StageDirector:
        stage_director = node as StageDirector
        _apply_active_power()
        return
    for child in node.get_children():
        _scan_node(child)
        if stage_director != null:
            return

func _on_node_added(node: Node) -> void:
    if node is StageDirector:
        stage_director = node as StageDirector
        call_deferred("_apply_active_power")

func _on_build_changed(build: Dictionary) -> void:
    var next_power := StringName(build.get("active_power", ""))
    if next_power == active_power:
        _apply_active_power()
        return
    active_power = next_power
    _apply_active_power()
    active_power_changed.emit(active_power)

func _apply_active_power() -> void:
    if active_power == &"" or stage_director == null or not is_instance_valid(stage_director):
        return
    if stage_director.current_power_id != active_power:
        stage_director.current_power_id = active_power
