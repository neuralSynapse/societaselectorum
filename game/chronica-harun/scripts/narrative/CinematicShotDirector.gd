extends Node
class_name CinematicShotDirector

signal sequence_started(sequence_id: StringName, sequence: Dictionary)
signal shot_started(sequence_id: StringName, shot_id: StringName, shot: Dictionary)
signal shot_finished(sequence_id: StringName, shot_id: StringName)
signal sequence_finished(sequence_id: StringName)
signal skip_rejected(sequence_id: StringName)

var sequence: Dictionary = {}
var sequence_id: StringName = &""
var shot_index := -1
var shot_clock := 0.0
var running := false
var allow_skip := false

func begin_sequence(next_sequence: Dictionary, can_skip: bool = false) -> bool:
    var shots: Array = next_sequence.get("shots", [])
    if shots.is_empty():
        return false
    sequence = next_sequence.duplicate(true)
    sequence_id = StringName(sequence.get("id", "cinematic"))
    shot_index = -1
    shot_clock = 0.0
    running = true
    allow_skip = can_skip
    sequence_started.emit(sequence_id, sequence.duplicate(true))
    return advance()

func _process(delta: float) -> void:
    if not running:
        return
    shot_clock -= delta
    if shot_clock <= 0.0:
        advance()

func advance() -> bool:
    if not running:
        return false
    var shots: Array = sequence.get("shots", [])
    if shot_index >= 0 and shot_index < shots.size():
        var previous: Dictionary = shots[shot_index]
        shot_finished.emit(sequence_id, StringName(previous.get("id", "")))
    shot_index += 1
    if shot_index >= shots.size():
        var finished_id := sequence_id
        running = false
        shot_clock = 0.0
        sequence_finished.emit(finished_id)
        return false
    var shot: Dictionary = shots[shot_index]
    # `duration_seconds` and `transition` are explicit production contracts.
    shot_clock = maxf(0.01, float(shot.get("duration_seconds", 0.01)))
    var _transition := String(shot.get("transition", "cut"))
    shot_started.emit(sequence_id, StringName(shot.get("id", "")), shot.duplicate(true))
    return true

func skip_sequence() -> bool:
    if not running:
        return false
    if not allow_skip:
        skip_rejected.emit(sequence_id)
        return false
    var finished_id := sequence_id
    running = false
    shot_clock = 0.0
    shot_index = int(sequence.get("shots", []).size())
    sequence_finished.emit(finished_id)
    return true

func current_shot() -> Dictionary:
    var shots: Array = sequence.get("shots", [])
    if shot_index < 0 or shot_index >= shots.size():
        return {}
    return shots[shot_index].duplicate(true)
