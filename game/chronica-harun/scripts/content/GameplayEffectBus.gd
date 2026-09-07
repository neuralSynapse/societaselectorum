extends Node

signal effect_requested(content_id: String, effect: Dictionary, context: Dictionary)
signal gameplay_event(event_name: String, payload: Dictionary)
signal room_event(event_name: String, payload: Dictionary)
signal build_changed(snapshot: Dictionary)

func request_effect(content_id: String, effect: Dictionary, context: Dictionary = {}) -> void:
    effect_requested.emit(content_id, effect.duplicate(true), context.duplicate(true))

func emit_gameplay(event_name: String, payload: Dictionary = {}) -> void:
    gameplay_event.emit(event_name, payload.duplicate(true))

func emit_room(event_name: String, payload: Dictionary = {}) -> void:
    room_event.emit(event_name, payload.duplicate(true))

func emit_build(snapshot: Dictionary) -> void:
    build_changed.emit(snapshot.duplicate(true))
