class_name VisionDirector
extends RefCounted

var pending_events: Array[Dictionary] = []

func queue_event(event: Dictionary) -> void:
    pending_events.append(event.duplicate(true))

func pop_event() -> Dictionary:
    if pending_events.is_empty():
        return {}
    return pending_events.pop_front()
