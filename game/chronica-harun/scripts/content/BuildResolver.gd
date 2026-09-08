extends RefCounted
class_name BuildResolver

const BUILD_CATEGORIES := ["tarot", "pharmaka", "sigilla", "talismans", "instrumenta", "relics", "daimones", "routes", "transformations"]

static func resolve(build: Dictionary) -> Dictionary:
    var out := {"damage_mult":1.0,"speed_mult":1.0,"damage_taken_mult":1.0,"crit_bonus":0.0,"secret_reveal":false,"transformations":[],"synergies":[],"conflicts":[]}
    for relic_id in build.get("relics",[]):
        var relic := ContentRegistry.get_item("relics",StringName(relic_id))
        match String(relic.get("effect_id","")):
            "slow_damage_reduction": out.damage_taken_mult *= .78
            "knockback_immunity_melee": out.damage_mult += .12
            "secret_reveal_hp_hidden": out.secret_reveal = true
    for t_id in build.get("talismans",[]):
        var t := ContentRegistry.get_item("talismans",StringName(t_id))
        if String(t.get("effect_id","")).begins_with("precision"): out.crit_bonus += .06
    out.synergies = active_synergies(build)
    out.conflicts = conflicts(build)
    out.transformations = eligible_transformations(build)
    return out

static func collect_build_tokens(build: Dictionary) -> Array[String]:
    var tokens: Array[String] = []
    var rows := _selected_rows(build)
    for row in rows:
        _append_token(tokens, String(row.get("id", "")))
        _append_token(tokens, String(row.get("effect_id", "")))
        for tag in row.get("tags", []):
            _append_token(tokens, String(tag))
    for mutation_id in build.get("mutations", []):
        _append_token(tokens, String(mutation_id))
        for power in ContentRegistry.all("powers"):
            for mutation in power.get("mutations", []):
                if String(mutation.get("id", "")) == String(mutation_id):
                    _append_token(tokens, String(power.get("id", "")))
                    _append_token(tokens, String(power.get("effect_id", "")))
                    _append_token(tokens, String(mutation.get("effect_id", "")))
    var flags: Dictionary = build.get("flags", {})
    for key in flags:
        if bool(flags[key]): _append_token(tokens, String(key))
    return tokens

static func active_synergies(build: Dictionary) -> Array[Dictionary]:
    var tokens := collect_build_tokens(build)
    var out: Array[Dictionary] = []
    for row in _selected_rows(build):
        for requirement in row.get("synergies", []):
            var token := _reference_token(requirement)
            if not token.is_empty() and tokens.has(token):
                out.append({"source":String(row.get("id", "")), "with":token})
    return out

static func conflicts(build: Dictionary) -> Array[Dictionary]:
    var tokens := collect_build_tokens(build)
    var out: Array[Dictionary] = []
    for row in _selected_rows(build):
        for exclusion in row.get("exclusions", []):
            var token := _reference_token(exclusion)
            if not token.is_empty() and tokens.has(token):
                out.append({"source":String(row.get("id", "")), "with":token})
    return out

static func eligible_transformations(build: Dictionary) -> Array[String]:
    var tokens := collect_build_tokens(build)
    var out: Array[String] = []
    var already: Array = build.get("transformations", [])
    for transformation in ContentRegistry.all("transformations"):
        var id := String(transformation.get("id", ""))
        if already.has(id):
            out.append(id)
            continue
        var requires: Array = transformation.get("requires", transformation.get("effect", {}).get("requires", []))
        if requires.is_empty():
            continue
        var met := true
        for requirement in requires:
            if not tokens.has(String(requirement)):
                met = false
                break
        if met: out.append(id)
    return out

static func _selected_rows(build: Dictionary) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    _append_row(rows, "tarot", build.get("arcana", ""))
    _append_row(rows, "pharmaka", build.get("pharmakon", ""))
    _append_row(rows, "sigilla", build.get("sigillum", ""))
    _append_row(rows, "daimones", build.get("daimon", ""))
    _append_row(rows, "routes", build.get("route", ""))
    var instrument: Dictionary = build.get("instrumentum", {})
    if not instrument.is_empty(): _append_row(rows, "instrumenta", instrument.get("id", ""))
    for id in build.get("talismans", []): _append_row(rows, "talismans", id)
    for id in build.get("relics", []): _append_row(rows, "relics", id)
    for id in build.get("transformations", []): _append_row(rows, "transformations", id)
    return rows

static func _append_row(rows: Array[Dictionary], category: String, id) -> void:
    var token := String(id)
    if token.is_empty(): return
    var row := ContentRegistry.get_item(category, StringName(token))
    if not row.is_empty(): rows.append(row)

static func _append_token(tokens: Array[String], token: String) -> void:
    if not token.is_empty() and not tokens.has(token): tokens.append(token)

static func _reference_token(value) -> String:
    if value is String: return String(value)
    if value is Dictionary:
        for key in ["id", "item_id", "tag", "requires"]:
            if value.has(key) and value[key] is String: return String(value[key])
    return ""
