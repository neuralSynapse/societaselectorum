extends Node
class_name VisionDirector

signal vision_requested(entry: Dictionary)
signal narrative_echo(entry: Dictionary)
signal vision_or_patron(entry: Dictionary)

func eligible_theophanies(context: Dictionary) -> Array:
    return ContentRegistry.all("theophanies").filter(func(row): return _conditions_met(row.get("conditions",{}),context))

func eligible_historical_echoes(context: Dictionary) -> Array:
    return ContentRegistry.all("historical_echoes").filter(func(row): return _conditions_met(row.get("conditions",{}),context))

func trigger_theophany(id: StringName, context: Dictionary = {}) -> bool:
    var row := ContentRegistry.get_item("theophanies",id)
    if row.is_empty() or not _conditions_met(row.get("conditions",{}),context): return false
    GameState.meta_progression["theophanies_seen"] = int(GameState.meta_progression.get("theophanies_seen",0)) + 1
    GameState.meta_progression["last_theophany"] = String(id)
    vision_requested.emit(row)
    vision_or_patron.emit(row)
    return true

func trigger_historical_echo(id: StringName, context: Dictionary = {}) -> bool:
    var row := ContentRegistry.get_item("historical_echoes",id)
    if row.is_empty() or not _conditions_met(row.get("conditions",{}),context): return false
    var seen: Array = GameState.meta_progression.get("historical_echoes_seen",[])
    if not seen.has(String(id)): seen.append(String(id)); GameState.meta_progression["historical_echoes_seen"] = seen
    vision_requested.emit(row)
    narrative_echo.emit(row)
    return true

func _conditions_met(conditions: Dictionary, context: Dictionary) -> bool:
    for key in conditions:
        var expected = conditions[key]
        var actual = context.get(key,GameState.meta_progression.get(key,null))
        if expected is Array:
            if not expected.has(actual): return false
        elif expected is bool:
            if bool(actual) != expected: return false
        elif expected is int or expected is float:
            if actual == null or float(actual) < float(expected): return false
        else:
            if String(actual) != String(expected): return false
    return true
