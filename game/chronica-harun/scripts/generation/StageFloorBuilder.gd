extends RefCounted
class_name StageFloorBuilder

var special_room_director := SpecialRoomDirector.new()

func build_floor(stage_context: Dictionary, layout: Dictionary) -> Dictionary:
    var secret_capacity := int(layout.get("secret_capacity", 0))
    var seed_value := int(stage_context.get("seed", 1))
    var special := special_room_director.build_floor_rooms(stage_context, secret_capacity, seed_value)
    var sequence: Array = [
        {"slot":"threshold","required":true},{"slot":"combat","required":true},
        {"slot":"reward_or_special","required":true},{"slot":"combat","required":true},
        {"slot":"sanctuary_or_ritual","required":true},{"slot":"combat","required":true},
        {"slot":"trial_or_elite","required":false},{"slot":"herald","required":true},
        {"slot":"boss","required":true},{"slot":"postboss","required":true}
    ]
    return {"sequence":sequence,"special_rooms":special["special_rooms"],"secret_rooms":special["secret_rooms"],"postboss_rooms":special["postboss_rooms"],"secret_count":special["secret_count"],"seed":seed_value}
