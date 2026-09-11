extends Node

var _last_signature := ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().node_added.connect(_on_node_added)
    call_deferred("_refresh_all")

func _process(_delta: float) -> void:
    var signature := "%s:%d:%d" % [String(GameState.journey_state), GameState.stage_index, int(GameState.meta_progression.get("degree_current", 0))]
    if signature != _last_signature:
        _last_signature = signature
        _refresh_all()

func _on_node_added(node: Node) -> void:
    if node is HUDController:
        call_deferred("_refresh_hud", node as HUDController)

func _refresh_all() -> void:
    for node in get_tree().get_nodes_in_group("hud"):
        if node is HUDController:
            _refresh_hud(node as HUDController)
    var current := get_tree().current_scene
    if current != null:
        var found := current.find_child("HUD", true, false)
        if found is HUDController:
            _refresh_hud(found as HUDController)

func _refresh_hud(hud: HUDController) -> void:
    if hud == null or not is_instance_valid(hud):
        return
    var realm := hud.get_node_or_null("Root/LoreHeader/Realm") as Label
    var circle := hud.get_node_or_null("Root/LoreHeader/Circle") as Label
    var stage := ContentRegistry.get_current_stage()
    if String(GameState.journey_state) == GameState.JOURNEY_DEGREE:
        var row := InitiaticProgressionService.current_degree_row()
        if realm != null:
            realm.text = "GRAU %s · %s" % [String(row.get("roman", "")), String(row.get("title", ""))]
        if circle != null:
            circle.text = String(row.get("tree", "ARBOR VITAE")).replace("ARBOR_", "ARBOR ")
        hud.player_level.text = "G%s" % String(row.get("roman", "I"))
    elif GameState.stage_index <= 2:
        if realm != null:
            realm.text = "PORTAL 0 · ASPIRANTE"
        if circle != null:
            circle.text = "INITIATIO LUCIFERI · PERGAMINHO %s" % _roman(GameState.stage_index + 1)
        hud.player_level.text = "P0"
    else:
        if realm != null:
            realm.text = "ESTUDANTE"
        if circle != null:
            circle.text = "PERGAMINHO %s · CICLO FORMATIVO" % _roman(GameState.stage_index + 1)
        hud.player_level.text = "E"
    if not stage.is_empty():
        hud.set_objective("%s · %s" % [String(stage.get("title", "JORNADA")), String(stage.get("subtitle", "PROVA"))])

func _roman(value: int) -> String:
    var values := {
        1:"I",2:"II",3:"III",4:"IV",5:"V",6:"VI",7:"VII",8:"VIII",9:"IX",10:"X",
        11:"XI",12:"XII",13:"XIII",14:"XIV",15:"XV",16:"XVI",17:"XVII",18:"XVIII",19:"XIX",20:"XX",
        21:"XXI",22:"XXII",23:"XXIII",24:"XXIV",25:"XXV",26:"XXVI",27:"XXVII",28:"XXVIII",29:"XXIX",30:"XXX",
        31:"XXXI",32:"XXXII",33:"XXXIII"
    }
    return String(values.get(value, value))
