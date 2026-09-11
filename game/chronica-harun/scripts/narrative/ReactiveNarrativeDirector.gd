extends Node
class_name ReactiveNarrativeDirector

var hud: HUDController
var stage_data: Dictionary = {}
var event_cooldowns := {
    "room_entered": 2.5,
    "enemy_identified": 3.5,
    "enemy_killed": 5.5,
    "room_cleared": 2.5,
    "secret_opened": 1.0,
    "acquisition": 0.5,
    "boss_phase": 1.0,
}
var _last_event_msec: Dictionary = {}
var _event_counts: Dictionary = {}

func configure(next_hud: HUDController, next_stage_data: Dictionary) -> void:
    hud = next_hud
    stage_data = next_stage_data.duplicate(true)

func narrate_event(event: StringName, context: Dictionary = {}) -> String:
    var key := String(event)
    if not event_cooldowns.has(key):
        return ""
    var now := Time.get_ticks_msec()
    var last := int(_last_event_msec.get(key, -100000))
    var count := int(_event_counts.get(key, 0)) + 1
    _event_counts[key] = count
    var bypass := key in ["acquisition", "secret_opened", "boss_phase"] or (key == "enemy_killed" and count == 1)
    if not bypass and now - last < int(float(event_cooldowns[key]) * 1000.0):
        return ""
    _last_event_msec[key] = now
    var line := _line_for(key, context, count)
    if line.is_empty():
        return ""
    if hud != null and is_instance_valid(hud):
        hud.show_message(line, maxf(3.2, NarratorDirector.estimate_duration(line) + 0.35))
    NarratorDirector.speak(line, &"reactive", false)
    return line

func _line_for(event: String, context: Dictionary, count: int) -> String:
    var stage_title := String(stage_data.get("title", "A JORNADA")).to_upper()
    var stage_subtitle := String(stage_data.get("subtitle", "PROVA"))
    match event:
        "room_entered":
            var room_id := String(context.get("room_id", "sala"))
            if room_id == "boss":
                return "%s fecha as saídas. O que está adiante não quer ser atravessado sem custo." % stage_title
            if room_id == "trial":
                return "A prova muda de forma. Aqui, força sem leitura vira alimento para a sala."
            if room_id in ["secret", "super_secret"]:
                return "Uma fenda respondeu. Segredo não significa segurança; significa que alguém tentou esconder a regra."
            if room_id.begins_with("combat_"):
                return "PASSAGENS SELADAS. %s exige que as presenças desta sala caiam antes que a saída volte a abrir. Leia os padrões; repetição cega será punida." % stage_title
        "enemy_identified":
            var name := String(context.get("name", "A PRESENÇA")).to_upper()
            var attack := String(context.get("attack", "um padrão ainda não lido"))
            var seal := String(context.get("seal", "none"))
            var seal_text := _seal_hint(seal)
            return "%s revela o próprio método: %s. %s" % [name, attack, seal_text]
        "enemy_killed":
            var enemy_name := String(context.get("name", "a presença")).to_upper()
            if count == 1:
                return "%s caiu. Não confunda a primeira vitória com domínio: a sala já aprendeu como você atacou." % enemy_name
            if bool(context.get("elite", false)):
                return "%s cedeu, mas deixou uma regra para trás. Elites morrem; padrões permanecem." % enemy_name
            return "Uma presença a menos. %s continua exigindo leitura, não repetição." % stage_subtitle
        "room_cleared":
            var damage_taken := bool(context.get("damage_taken", false))
            if damage_taken:
                return "A sala foi vencida, mas cobrou sangue. O caminho registra tanto o acerto quanto o preço."
            return "A sala cedeu sem tocar Harun. Precisão também é uma forma de conhecimento."
        "secret_opened":
            return "A parede mentiu sobre ser parede. Agora a questão é por que esta passagem precisava permanecer invisível."
        "acquisition":
            var item_name := String(context.get("name", "RECOMPENSA")).to_upper()
            var purpose := String(context.get("purpose", "uma função ainda não compreendida"))
            return "%s foi incorporado. Não é troféu: %s" % [item_name, purpose]
        "boss_phase":
            var boss_name := String(context.get("name", "A PRESENÇA")).to_upper()
            var phase := int(context.get("phase", 1))
            return "%s mudou de regra. Fase %d. O padrão anterior não é mais suficiente." % [boss_name, phase]
    return ""

func _seal_hint(seal: String) -> String:
    match seal:
        "revelation": return "Enquanto permanecer oculto, recebe menos dano. Revelação e timing quebram o selo."
        "fracture": return "A estrutura endurece fora das janelas de ataque. O instante de abertura importa."
        "observation": return "O telegraph não é aviso decorativo; é a janela em que a defesa cai."
        "counterstep": return "Ele pune repetição frontal. Ataque quando o próprio movimento abrir a guarda."
        "pressure": return "Não possui uma única fraqueza, mas acelera se você permitir que dite a distância."
        _: return "Leia o movimento antes de tentar impor força."
