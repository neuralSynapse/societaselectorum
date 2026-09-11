extends Node

const FILES := {
    "journey":"res://data/stages/student_journey.json",
    "characters":"res://data/characters/playable_roster.json",
    "enemies":"res://data/enemies/student_enemies.json",
    "bosses":"res://data/bosses/student_bosses.json",
    "tarot":"res://data/roguelite/tarot_thoth.json",
    "sigilla":"res://data/roguelite/sigilla_goetia.json",
    "pharmaka":"res://data/roguelite/pharmaka.json",
    "talismans":"res://data/roguelite/talismans_decanic.json",
    "instrumenta":"res://data/roguelite/instrumenta.json",
    "powers":"res://data/roguelite/powers.json",
    "daimones":"res://data/roguelite/daimones.json",
    "relics":"res://data/roguelite/relics.json",
    "transformations":"res://data/roguelite/transformations.json",
    "curses":"res://data/roguelite/curses.json",
    "blessings":"res://data/roguelite/blessings.json",
    "routes":"res://data/roguelite/routes.json",
    "special_rooms":"res://data/roguelite/special_rooms.json",
    "theophanies":"res://data/roguelite/theophanies.json",
    "historical_echoes":"res://data/roguelite/historical_echoes.json",
    "gauntlets":"res://data/roguelite/gauntlets.json"
}

const OBJECT_FILES := {
    "initiatic_path":"res://data/progression/initiatic_path.json"
}

var _cache: Dictionary = {}
var _object_cache: Dictionary = {}

func _ready() -> void:
    for category in FILES:
        _cache[category] = _load_array(FILES[category])
    for category in OBJECT_FILES:
        _object_cache[category] = _load_object(OBJECT_FILES[category])

func _load_array(path: String) -> Array:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return []
    var parsed = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Array else []

func _load_object(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Dictionary else {}

func all(category: String) -> Array:
    if not _cache.has(category):
        _cache[category] = _load_array(FILES.get(category, ""))
    return _cache.get(category, [])

func all_ids(category: String) -> Array:
    return all(category).map(func(row): return String(row.get("id", "")))

func get_item(category: String, id: StringName) -> Dictionary:
    for row in all(category):
        if String(row.get("id")) == String(id):
            return row
    return {}

func get_object(category: String) -> Dictionary:
    if not _object_cache.has(category):
        _object_cache[category] = _load_object(OBJECT_FILES.get(category, ""))
    return _object_cache.get(category, {})

func get_initiatic_path() -> Dictionary:
    return get_object("initiatic_path")

func get_base_student_journey() -> Array:
    return all("journey")

func get_student_journey() -> Array:
    if Engine.has_singleton("GameState"):
        return get_base_student_journey()
    if typeof(GameState) != TYPE_NIL and String(GameState.journey_state) == "DEGREE":
        var degree_stages: Array = []
        for degree in range(1, 34):
            degree_stages.append(InitiaticProgressionService.build_degree_stage_data(degree))
        return degree_stages
    return get_base_student_journey()

func get_enemy(id: StringName) -> Dictionary:
    return get_item("enemies", id)

func get_boss(id: StringName) -> Dictionary:
    return get_item("bosses", id)

func get_power(id: StringName) -> Dictionary:
    return get_item("powers", id)
