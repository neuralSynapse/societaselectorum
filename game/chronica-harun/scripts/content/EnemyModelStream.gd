extends Node
class_name EnemyModelStream

const STAGGER_BUCKETS := 6

var model_path := ""
var visual: Node3D
var fallback: Node
var stagger_slot := 0
var frame_index := 0

func configure(next_model_path: String, next_visual: Node3D, next_fallback: Node, seed: int) -> void:
    model_path = next_model_path
    visual = next_visual
    fallback = next_fallback
    stagger_slot = posmod(seed, STAGGER_BUCKETS)
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process(true)

func _process(_delta: float) -> void:
    frame_index += 1
    if frame_index < 2 or frame_index % STAGGER_BUCKETS != stagger_slot:
        return
    if model_path.is_empty() or visual == null or not is_instance_valid(visual):
        queue_free()
        return
    var status := ResourceLoader.load_threaded_get_status(model_path)
    if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        return
    if status != ResourceLoader.THREAD_LOAD_LOADED:
        queue_free()
        return
    var resource := ResourceLoader.load_threaded_get(model_path)
    if resource is PackedScene:
        var instance := (resource as PackedScene).instantiate()
        visual.add_child(instance)
        if is_instance_valid(fallback):
            fallback.queue_free()
    queue_free()
