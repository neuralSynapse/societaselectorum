extends Node
class_name DaimonRuntime
signal daimon_action(effect_id: StringName, payload: Dictionary)
var cooldown := 0.0

func tick(delta: float, context: Dictionary = {}) -> void:
    cooldown = maxf(0.0,cooldown-delta)
    var effect := _effect()
    if effect == "reveal_secret" and cooldown <= 0.0:
        cooldown = 2.0; daimon_action.emit(&"reveal_secret",{"radius":8.0,"context":context})
    elif effect == "execute_bite" and cooldown <= 0.0 and float(context.get("nearest_hp_ratio",1.0)) <= .3:
        cooldown = 2.4; daimon_action.emit(&"execute_bite",context)
    elif effect == "attack_echo" and cooldown <= 0.0:
        cooldown = 1.5; daimon_action.emit(&"attack_echo",{"power":.35,"context":context})

func on_enemy_killed(context: Dictionary = {}) -> void:
    if _effect() == "corpse_essence": daimon_action.emit(&"corpse_essence",{"essence":1,"context":context})

func on_arcana_used(card_id: StringName, context: Dictionary = {}) -> void:
    if _effect() == "arcana_echo": daimon_action.emit(&"arcana_echo",{"card_id":String(card_id),"power":.5,"context":context})

func on_player_attacked(context: Dictionary = {}) -> bool:
    if _effect() == "projectile_intercept" and cooldown <= 0.0:
        cooldown = 14.0; daimon_action.emit(&"projectile_intercept",context); return true
    return false

func on_floor_started(context: Dictionary = {}) -> void:
    if _effect() == "curse_purge": daimon_action.emit(&"curse_purge",{"context":context})

func _effect() -> String:
    var id := StringName(GameState.run_build.get("daimon",""))
    if id == &"": return ""
    return String(ContentRegistry.get_item("daimones",id).get("effect_id",""))
