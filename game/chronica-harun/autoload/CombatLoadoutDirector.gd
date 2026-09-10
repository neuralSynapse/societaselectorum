extends Node

signal active_power_changed(power_id: StringName)

var active_power: StringName = &""

func _ready() -> void:
    RogueliteContentService.build_changed.connect(_on_build_changed)
    _on_build_changed(RogueliteContentService.ensure_build())

func _on_build_changed(build: Dictionary) -> void:
    var next_power := StringName(build.get("active_power", ""))
    if next_power == active_power:
        return
    active_power = next_power
    active_power_changed.emit(active_power)

func activate_known_power(power_id: StringName) -> bool:
    if power_id == &"":
        return false
    var build := RogueliteContentService.ensure_build()
    var known: Array = build.get("powers", [])
    if not known.has(String(power_id)):
        return false
    if StringName(build.get("active_power", "")) == power_id:
        return true
    build["active_power"] = String(power_id)
    RogueliteContentService.build_changed.emit(build.duplicate(true))
    return true
