class_name DaimonRuntime
extends RefCounted

var active_daimon_id: String = ""

func activate(id: String) -> void:
    active_daimon_id = id

func clear() -> void:
    active_daimon_id = ""
