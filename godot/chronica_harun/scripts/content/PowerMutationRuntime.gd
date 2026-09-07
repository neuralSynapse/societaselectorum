class_name PowerMutationRuntime
extends RefCounted

var active_mutations: Array[String] = []

func set_active(ids: Array[String]) -> void:
    active_mutations = ids.duplicate()

func has_mutation(id: String) -> bool:
    return id in active_mutations
