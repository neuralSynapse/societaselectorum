class_name MetaRunDirector
extends RefCounted

const ROUTE_COUNT := 8
var route_state: Dictionary = {}

func reset_run() -> void:
    route_state = {}

func set_route_flag(key: String, value: Variant) -> void:
    route_state[key] = value
