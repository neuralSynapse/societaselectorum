extends RefCounted
class_name EnigmaDirector

const ENIGMAS := [
    {
        "id":"perception_without_conclusion",
        "stages":["o_olho"],
        "prompt":"O selo mostra duas sombras e um único corpo. O que deve ser preservado antes da conclusão?",
        "options":["A observação, mesmo incompleta", "A explicação mais confortável", "A primeira memória que surgir"],
        "correct_index":0,
        "reward":{"essence":3,"focus":12},
        "penalty":{"damage":18,"focus":8},
        "narrative":"O Olho não premia certeza. Premia a capacidade de não falsificar o que foi visto."
    },
    {
        "id":"flame_under_rule",
        "stages":["a_chama"],
        "prompt":"A chama cresce quando é alimentada. Quando ela se torna poder e deixa de ser impulso?",
        "options":["Quando queima mais rápido", "Quando obedece a uma direção escolhida", "Quando nenhum medo permanece"],
        "correct_index":1,
        "reward":{"essence":3,"focus":14},
        "penalty":{"damage":20,"focus":10},
        "narrative":"A Chama sem regência é apenas incêndio. Força começa quando o impulso aceita forma."
    },
    {
        "id":"foundation_bears_weight",
        "stages":["a_obra_fundacao"],
        "prompt":"Três pedras sustentam o arco. Uma é bela, uma é antiga e uma suporta o peso. Qual permanece?",
        "options":["A mais antiga", "A que suporta o peso", "A que melhor representa o construtor"],
        "correct_index":1,
        "reward":{"essence":4,"focus":10},
        "penalty":{"damage":22,"focus":10},
        "narrative":"A Obra não pergunta qual pedra parece sagrada. Pergunta qual delas não cede."
    },
    {
        "id":"door_that_listens",
        "stages":[],
        "prompt":"Uma porta responde ao primeiro golpe, mas abre apenas para quem percebe o segundo som. O que fazer?",
        "options":["Golpear até ceder", "Esperar, observar o padrão e agir na abertura", "Recuar e procurar outra porta"],
        "correct_index":1,
        "reward":{"essence":3,"focus":9},
        "penalty":{"damage":18,"focus":12},
        "narrative":"Nem toda resistência é uma parede. Algumas coisas estão testando se você sabe escutar."
    },
    {
        "id":"mirror_debt",
        "stages":[],
        "prompt":"O espelho oferece uma vantagem em troca de esconder uma fraqueza. O que ele está comprando?",
        "options":["Sua aparência", "Sua capacidade de corrigir o próprio erro", "Seu nome"],
        "correct_index":1,
        "reward":{"essence":4,"focus":8},
        "penalty":{"damage":24,"focus":6},
        "narrative":"Aquilo que você se recusa a ver não desaparece. Apenas aprende a atacar sem ser nomeado."
    },
    {
        "id":"fear_as_instrument",
        "stages":[],
        "prompt":"A presença quer que você corra antes de mostrar o ataque. Qual é a primeira arma dela?",
        "options":["O dano", "A distância", "A antecipação do medo"],
        "correct_index":2,
        "reward":{"essence":4,"focus":11},
        "penalty":{"damage":20,"focus":14},
        "narrative":"Terror eficaz começa antes do golpe. Reconhecer isso devolve uma parte do tempo ao jogador."
    }
]

func build_enigma(stage_id: StringName, room_id: StringName, seed: int) -> Dictionary:
    var stage_key := String(stage_id)
    var eligible: Array[Dictionary] = []
    for value in ENIGMAS:
        var row: Dictionary = value
        var stages: Array = row.get("stages", [])
        if stages.is_empty() or stages.has(stage_key):
            eligible.append(row)
    if eligible.is_empty():
        return {}
    var index: int = int(abs(seed + stage_key.hash() * 17 + String(room_id).hash() * 31)) % eligible.size()
    var result: Dictionary = eligible[index].duplicate(true)
    result["stage_id"] = stage_key
    result["room_id"] = String(room_id)
    result["seed"] = seed
    return result

func is_correct(enigma: Dictionary, selected_index: int) -> bool:
    return selected_index == int(enigma.get("correct_index", -1))
