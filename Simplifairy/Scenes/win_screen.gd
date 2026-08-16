extends CanvasLayer

var bg_rect: ColorRect
var main_container: VBoxContainer
var title_label: Label
var stats_label: Label
var restart_btn: Button
var quit_btn: Button

func _ready() -> void:
	layer = 100 
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(1.0, 0.84, 0.0, 0.0) # Transparent Gold
	add_child(bg_rect)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 25)
	center.add_child(main_container)
	
	title_label = Label.new()
	title_label.text = "VICTORY"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_settings = LabelSettings.new()
	title_settings.font_size = 72
	title_settings.font_color = Color(1.0, 0.9, 0.2) # Bright Gold
	title_settings.shadow_color = Color(0, 0, 0, 1)
	title_settings.shadow_size = 8
	title_label.label_settings = title_settings
	main_container.add_child(title_label)
	
	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var stats_settings = LabelSettings.new()
	stats_settings.font_size = 32
	stats_settings.font_color = Color.WHITE
	stats_label.label_settings = stats_settings
	main_container.add_child(stats_label)
	
	var btn_box = HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 30)
	main_container.add_child(btn_box)
	
	restart_btn = Button.new()
	restart_btn.text = " Play Again "
	restart_btn.add_theme_font_size_override("font_size", 32)
	restart_btn.pressed.connect(_on_restart_pressed)
	btn_box.add_child(restart_btn)
	
	quit_btn = Button.new()
	quit_btn.text = " Quit "
	quit_btn.add_theme_font_size_override("font_size", 32)
	quit_btn.pressed.connect(_on_quit_pressed)
	btn_box.add_child(quit_btn)
	
	hide()

func trigger_win(time_survived: float, kills: int) -> void:
	var minutes = int(time_survived) / 60
	var seconds = int(time_survived) % 60
	
	stats_label.text = "You are officialy a Simplefairy!\nTime: %02d:%02d\nEnemies Destroyed: %d" % [minutes, seconds, kills]
	
	get_tree().paused = true
	show()
	
	main_container.modulate.a = 0.0
	main_container.position.y += 60.0
	restart_btn.disabled = true
	quit_btn.disabled = true
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(bg_rect, "color:a", 0.3, 1.5) 
	tween.tween_property(main_container, "modulate:a", 1.0, 1.0).set_delay(0.5)
	tween.tween_property(main_container, "position:y", main_container.position.y - 60.0, 1.0)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.5)
	
	tween.chain().tween_callback(func():
		restart_btn.disabled = false
		quit_btn.disabled = false
		restart_btn.grab_focus()
	)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()
