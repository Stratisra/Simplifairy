extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	var is_paused = !get_tree().paused
	visible = is_paused
	get_tree().paused = is_paused

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	hide()

func _on_return_to_title_button_pressed() -> void:
	get_tree().paused = false
	hide()
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
