extends CanvasLayer

# Variables to hold our code-generated UI elements
var bg_rect: ColorRect
var main_container: VBoxContainer
var title_label: Label
var stats_label: Label
var restart_btn: Button
var quit_btn: Button

func _ready() -> void:
	# 1. SETUP CANVAS LAYER
	# Ensure this draws on top of literally everything, and runs even when the game is paused
	layer = 100 
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 2. CREATE BACKGROUND
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(0.05, 0.0, 0.0, 0.0) # Start fully transparent dark red/black
	add_child(bg_rect)
	
	# 3. CREATE CENTER ALIGNMENT CONTAINER
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# 4. CREATE VERTICAL LAYOUT
	main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 25)
	center.add_child(main_container)
	
	# 5. CREATE TITLE
	title_label = Label.new()
	title_label.text = "YOU DIED"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_settings = LabelSettings.new()
	title_settings.font_size = 64
	title_settings.font_color = Color(1.0, 0.2, 0.2) # Blood red
	title_settings.shadow_color = Color(0, 0, 0, 1)
	title_settings.shadow_size = 6
	title_label.label_settings = title_settings
	main_container.add_child(title_label)
	
	# 6. CREATE STATS TEXT
	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var stats_settings = LabelSettings.new()
	stats_settings.font_size = 32
	stats_settings.font_color = Color.WHITE
	stats_label.label_settings = stats_settings
	main_container.add_child(stats_label)
	
	# 7. CREATE BUTTONS LAYOUT
	var btn_box = HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 30)
	main_container.add_child(btn_box)
	
	restart_btn = Button.new()
	restart_btn.text = " Try Again "
	restart_btn.add_theme_font_size_override("font_size", 32)
	restart_btn.pressed.connect(_on_restart_pressed)
	btn_box.add_child(restart_btn)
	
	quit_btn = Button.new()
	quit_btn.text = " Quit "
	quit_btn.add_theme_font_size_override("font_size", 32)
	quit_btn.pressed.connect(_on_quit_pressed)
	btn_box.add_child(quit_btn)
	
	# Hide everything at start
	hide()

# Call this function to trigger the sequence!
func trigger_game_over(wave: int, time_survived: float, kills: int) -> void:
	# Format the time
	var minutes = int(time_survived) / 60
	var seconds = int(time_survived) % 60
	var time_str = "%02d:%02d" % [minutes, seconds]
	
	# Inject the player's final stats!
	stats_label.text = "Wave Reached: %d\nTime Survived: %s\nEnemies Destroyed: %d" % [wave, time_str, kills]
	
	# Lock the game
	get_tree().paused = true
	show()
	
	# Start UI off-screen/transparent for animation
	main_container.modulate.a = 0.0
	main_container.position.y += 60.0
	
	restart_btn.disabled = true
	quit_btn.disabled = true
	
	# Animate the background fading in, and the text sliding up
	var tween = create_tween().set_parallel(true)
	tween.tween_property(bg_rect, "color:a", 0.9, 1.5) # Heavy dark background fade
	tween.tween_property(main_container, "modulate:a", 1.0, 1.0).set_delay(0.5)
	tween.tween_property(main_container, "position:y", main_container.position.y - 60.0, 1.0)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.5)
	
	# Re-enable buttons when animation finishes
	tween.chain().tween_callback(func():
		restart_btn.disabled = false
		quit_btn.disabled = false
		restart_btn.grab_focus() # Lets the player press 'Space' or 'Enter' to restart instantly!
	)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()
