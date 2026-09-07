class_name BuildResolver
extends RefCounted

static func merge(base: Dictionary, patch: Dictionary) -> Dictionary:
    var resolved := base.duplicate(true)
    for key in patch:
        resolved[key] = patch[key]
    return resolved
