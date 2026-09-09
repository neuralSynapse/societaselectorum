extends CanvasLayer
class_name PauseController

@onready var overlay: Control = $Overlay
@onready var resume_button: Button = $Overlay/Center/Panel/Margin/VBox/ResumeButton
@onready var quit_button: Button = $Overlay/Center/Panel/Margin/VBox/QuitButton

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    overlay.visible = false
    resume_button.pressed.connect(resume_game)
    quit_button.pressed.connect(_quit_game)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if get_tree().paused:
            resume_game()
        else:
            pause_game()
        get_viewport().set_input_as_handled()

func pause_game() -> void:
    overlay.visible = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_tree().paused = true
    resume_button.grab_focus()

func resume_game() -> void:
    get_tree().paused = false
    overlay.visible = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _quit_game() -> void:
    get_tree().paused = false
    get_tree().quit()
