class_name StageFloorBuilder
extends RefCounted

func foundation_sequence(cycle: int = 0) -> Array[Dictionary]:
    var rooms: Array[Dictionary] = [
        {"type": "threshold", "combat": false},
        {"type": "combat", "combat": true},
        {"type": "reward_or_special", "combat": false},
        {"type": "combat", "combat": true},
        {"type": "sanctuary", "combat": false},
        {"type": "combat", "combat": true},
        {"type": "trial", "combat": cycle > 0},
        {"type": "herald", "combat": true},
        {"type": "boss", "combat": true},
        {"type": "post_boss", "combat": false},
    ]
    return rooms
