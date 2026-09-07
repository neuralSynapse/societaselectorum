extends Node

const SAVE_VERSION := 1

var run_state: Dictionary = {}

func _ready() -> void:
    if run_state.is_empty():
        reset_run()

func reset_run(seed_value: int = 0) -> void:
    run_state = {
        "save_version": SAVE_VERSION,
        "seed": seed_value,
        "stage_index": 0,
        "cycle": 0,
        "character_id": "harun",
        "resources": {"hp": 100, "max_hp": 100, "focus": 100, "essence": 0, "rupture": 0},
        "stats": {"damage": 1.0, "speed": 1.0, "precision": 0.0, "armor": 0.0},
        "inventory": [],
        "build_tags": [],
        "active_effects": {},
        "visited_rooms": [],
        "discovered_secrets": [],
        "route_id": "",
        "curses": [],
        "blessings": [],
        "transformations": [],
        "completion_marks": {},
        "gauntlet": {},
        "postboss_choice_taken": false,
        "run_events": []
    }

func snapshot_run() -> Dictionary:
    return run_state.duplicate(true)

func restore_run(snapshot: Dictionary) -> bool:
    if int(snapshot.get("save_version", -1)) != SAVE_VERSION:
        return false
    run_state = snapshot.duplicate(true)
    return true

func add_event(event: Dictionary) -> void:
    run_state.get_or_add("run_events", []).append(event.duplicate(true))

func add_build_tag(tag: String) -> void:
    var tags: Array = run_state.get_or_add("build_tags", [])
    if not tags.has(tag):
        tags.append(tag)
