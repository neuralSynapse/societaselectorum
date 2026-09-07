extends Node

const CATALOG_FILES := {
    "gauntlets": "res://data/roguelite/gauntlets.json",
    "tarot": "res://data/roguelite/tarot.json",
    "sigilla": "res://data/roguelite/sigilla.json",
    "pharmaka": "res://data/roguelite/pharmaka.json",
    "talismans": "res://data/roguelite/talismans.json",
    "instrumenta": "res://data/roguelite/instrumenta.json",
    "powers": "res://data/roguelite/powers.json",
    "mutations": "res://data/roguelite/mutations.json",
    "daimones": "res://data/roguelite/daimones.json",
    "relics": "res://data/roguelite/relics.json",
    "transformations": "res://data/roguelite/transformations.json",
    "curses": "res://data/roguelite/curses.json",
    "blessings": "res://data/roguelite/blessings.json",
    "routes": "res://data/roguelite/routes.json",
    "special_rooms": "res://data/roguelite/special_rooms.json"
}
const REQUIRED_FIELDS := ["id", "name", "rarity", "pool", "eligibility", "effect", "cost", "duration", "stacking", "synergies", "exclusions", "vfx_hook", "sfx_hook", "save_state", "codex", "provenance"]

var catalogs: Dictionary = {}
var by_id: Dictionary = {}
var by_pool: Dictionary = {}
var load_errors: Array[String] = []

func _ready() -> void: load_all()

func load_all() -> bool:
    catalogs.clear(); by_id.clear(); by_pool.clear(); load_errors.clear()
    for catalog_name in CATALOG_FILES:
        var records := _load_json_array(CATALOG_FILES[catalog_name]); catalogs[catalog_name] = records
        for record in records:
            if not _validate_record(record, catalog_name): continue
            var record_id: String = str(record["id"])
            if by_id.has(record_id): load_errors.append("duplicate id: %s" % record_id); continue
            by_id[record_id] = record
            var pool: String = str(record["pool"])
            if not by_pool.has(pool): by_pool[pool] = []
            by_pool[pool].append(record)
    return load_errors.is_empty()

func _load_json_array(path: String) -> Array:
    if not FileAccess.file_exists(path): load_errors.append("missing catalog: %s" % path); return []
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not parsed is Array: load_errors.append("catalog is not an array: %s" % path); return []
    return parsed

func _validate_record(record: Variant, catalog_name: String) -> bool:
    if not record is Dictionary: load_errors.append("%s contains a non-dictionary record" % catalog_name); return false
    for field in REQUIRED_FIELDS:
        if not record.has(field): load_errors.append("%s/%s missing %s" % [catalog_name, record.get("id", "?"), field]); return false
    return true

func get_entry(content_id: String) -> Dictionary: return by_id.get(content_id, {})
func get_pool(pool: String) -> Array: return by_pool.get(pool, []).duplicate()

func eligible_entries(pool: String, context: Dictionary) -> Array:
    var result: Array = []; var context_tags: Array = context.get("tags", []); var stage_index := int(context.get("stage_index", 0)); var cycle := int(context.get("cycle", 0))
    for record in get_pool(pool):
        var eligibility: Dictionary = record.get("eligibility", {})
        if stage_index < int(eligibility.get("min_stage", 0)) or cycle < int(eligibility.get("min_cycle", 0)): continue
        if not _contains_all(context_tags, eligibility.get("requires_tags", [])): continue
        if _contains_any(context_tags, eligibility.get("forbids_tags", [])): continue
        result.append(record)
    return result

func _contains_all(haystack: Array, needles: Array) -> bool:
    for needle in needles:
        if not haystack.has(needle): return false
    return true

func _contains_any(haystack: Array, needles: Array) -> bool:
    for needle in needles:
        if haystack.has(needle): return true
    return false
