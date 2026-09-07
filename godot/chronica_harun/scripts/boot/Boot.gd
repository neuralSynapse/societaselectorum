extends Node3D

func _ready() -> void:
    var saved := SaveService.load_local()
    if saved.is_empty():
        GameState.reset_campaign()
    else:
        GameState.apply_save(saved)
