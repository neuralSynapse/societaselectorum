extends RefCounted
class_name EnemyFactory

const ENEMY_BASE := preload("res://scenes/enemies/EnemyBase.tscn")
const ENEMY_MODEL_STREAM := preload("res://scripts/content/EnemyModelStream.gd")

static func spawn(enemy_id: StringName, parent: Node, position: Vector3, target: Node3D) -> DataEnemy:
    var data := ContentRegistry.get_enemy(enemy_id)
    if data.is_empty():
        push_error("Unknown enemy: %s" % enemy_id)
        return null
    var enemy := ENEMY_BASE.instantiate() as DataEnemy
    parent.add_child(enemy)
    enemy.position = position
    enemy.configure_from_data(data, target)
    _attach_model(enemy, data)
    return enemy

static func request_model(enemy_id: StringName) -> void:
    var data := ContentRegistry.get_enemy(enemy_id)
    if data.is_empty():
        return
    _request_model_path(_model_path(data))

static func _model_path(data: Dictionary) -> String:
    return String(data.get("model_path", "res://art/generated/enemies/%s.glb" % data.get("id", "enemy")))

static func _request_model_path(model_path: String) -> void:
    if model_path.is_empty() or not ResourceLoader.exists(model_path):
        return
    var status := ResourceLoader.load_threaded_get_status(model_path)
    if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
        return
    ResourceLoader.load_threaded_request(model_path)

static func _attach_model(enemy: DataEnemy, data: Dictionary) -> void:
    var visual := enemy.get_node("Visual") as Node3D
    var model_path := _model_path(data)
    if ResourceLoader.exists(model_path):
        var status := ResourceLoader.load_threaded_get_status(model_path)
        if status == ResourceLoader.THREAD_LOAD_LOADED:
            var resource := ResourceLoader.load_threaded_get(model_path)
            if resource is PackedScene:
                visual.add_child((resource as PackedScene).instantiate())
                return
        _request_model_path(model_path)

    var fallback := _add_fallback(visual, data)
    if ResourceLoader.exists(model_path):
        var streamer := ENEMY_MODEL_STREAM.new() as EnemyModelStream
        streamer.name = "ModelStream_%s" % data.get("id", "enemy")
        visual.add_child(streamer)
        streamer.configure(model_path, visual, fallback, int(enemy.get_instance_id()))

static func _add_fallback(visual: Node3D, data: Dictionary) -> MeshInstance3D:
    var fallback := MeshInstance3D.new()
    fallback.name = "Fallback_%s" % data.get("id", "enemy")
    var silhouette := String(data.get("visual_profile", {}).get("silhouette", data.get("family", "walker")))
    fallback.mesh = _fallback_mesh(silhouette)
    var material := StandardMaterial3D.new()
    material.albedo_color = _fallback_color(String(data.get("visual_profile", {}).get("accent", "ashen")))
    material.roughness = 0.9
    material.emission_enabled = false
    fallback.material_override = material
    fallback.position.y = 0.85
    visual.add_child(fallback)
    return fallback

static func _fallback_mesh(silhouette: String) -> PrimitiveMesh:
    if "eye" in silhouette:
        var mesh := SphereMesh.new(); mesh.radius = 0.48; mesh.height = 0.78; return mesh
    if "serpent" in silhouette or silhouette == "crawler":
        var mesh := CapsuleMesh.new(); mesh.radius = 0.28; mesh.height = 1.2; return mesh
    if "construct" in silhouette or "stone" in silhouette:
        var mesh := BoxMesh.new(); mesh.size = Vector3(0.9, 1.5, 0.7); return mesh
    var mesh := CapsuleMesh.new(); mesh.radius = 0.38; mesh.height = 1.35; return mesh

static func _fallback_color(accent: String) -> Color:
    match accent:
        "violet": return Color(0.23, 0.18, 0.28)
        "copper": return Color(0.28, 0.18, 0.12)
        "old_gold", "cold_gold": return Color(0.32, 0.27, 0.17)
        "ochre": return Color(0.28, 0.23, 0.15)
        _: return Color(0.18, 0.17, 0.15)
