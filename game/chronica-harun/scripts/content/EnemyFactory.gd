extends RefCounted
class_name EnemyFactory

const ENEMY_BASE := preload("res://scenes/enemies/EnemyBase.tscn")

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

static func _attach_model(enemy: DataEnemy, data: Dictionary) -> void:
    var visual := enemy.get_node("Visual") as Node3D
    var model_path := String(data.get("model_path", "res://art/generated/enemies/%s.glb" % data.get("id", "enemy")))
    if ResourceLoader.exists(model_path):
        var resource = load(model_path)
        if resource is PackedScene:
            visual.add_child((resource as PackedScene).instantiate())
            return
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
