extends Node2D

@export var player: CharacterBody2D
@export var enemySpawner: Node2D

# ==========================================
# ⚙️ WAVE BALANCING CONTROL PANEL ⚙️
# Change these in the Godot Inspector!
# ==========================================
@export_group("Wave Balancing")
@export var wave_duration: float = 60.0            # Seconds to survive the wave
@export var base_enemies_per_wave: int = 25        # How many enemies spawn in Wave 1
@export var enemy_growth_multiplier: float = 1.35  # Horde grows by 35% each wave

# --- HUD References ---
@onready var time_label: Label = $HUD/TimerLabel
@onready var kill_label: Label = $HUD/KillLabel
@onready var wave_label: Label = $HUD/WaveLabel # <--- ADDED WAVE LABEL

var enemies_killed: int = 0
var kill_tween: Tween

var current_wave: int = 1
var wave_time_left: float = 60.0
var is_wave_active: bool = false
# ---------------------------

@onready var downgrade_ui: CanvasLayer = $DowngradeUI
@onready var color_rect: ColorRect = $DowngradeUI/ColorRect
@onready var hbox: HBoxContainer = $DowngradeUI/HBoxContainer
@onready var button_1: TextureButton = $DowngradeUI/HBoxContainer/SimplificationCard/Button1
@onready var button_2: TextureButton = $DowngradeUI/HBoxContainer/SimplificationCard2/Button2

var fallback_texture = preload('res://Sprites/Star.png')
var available_downgrades = [
	{"id": "lose_dash", "title": "You don't need shoes", "description": "Increase dash cooldown"},
	{"id": "lose_aoe", "title": "Dull Wand", "description": "Wand loses Area of Effect","texture": preload('res://Sprites/Icons/smaller_aoe.png')},
	{"id": "lose_tracking", "title": "Blind Fire", "description": "Bullets no longer home in","texture": preload("res://Sprites/Icons/no_homing.png")},
	{"id": "manual_shoot", "title": "Jamming", "description": "Disable Auto-Shoot","texture": preload("res://Sprites/Icons/semi_auto.png")},
	{"id": "elite_enemies", "title": "Run out of anti-elite spray", "description": "Elite enemies can now spawn","texture": preload('res://Sprites/elite_enemies.png')},
	{"id": "reload", "title": "Reload needed", "description": "Every 5 shots the wand reloads"}
]

var current_choice_1: Dictionary
var current_choice_2: Dictionary
var hbox_base_y: float
var idle_tween: Tween

func _ready():
	if not player:
		player = get_tree().get_first_node_in_group("player")
		
	button_1.pressed.connect(_on_button_1_pressed)
	button_2.pressed.connect(_on_button_2_pressed)
	
	await get_tree().process_frame
	
	hbox_base_y = hbox.position.y
	button_1.get_parent().pivot_offset = Vector2(100, 150)
	button_2.get_parent().pivot_offset = Vector2(100, 150)
	
	kill_label.text = "Kills: 0"
	kill_label.pivot_offset = kill_label.size / 2.0 
	
	downgrade_ui.hide()
	
	# Start the very first wave!
	start_new_wave()

# --- WAVE TIMER AND WIN CHECK ---
func _process(delta: float):
	if is_wave_active and not get_tree().paused:
		wave_time_left -= delta
		
		# Format wave timer (Countdown)
		var w_minutes = max(0, int(wave_time_left) / 60)
		var w_seconds = max(0, int(wave_time_left) % 60)
		time_label.text = "%02d:%02d" % [w_minutes, w_seconds]
		
		# WIN CONDITION CHECK:
		var enemies_alive = get_tree().get_nodes_in_group("enemy").size()
		var all_spawned = false
		if enemySpawner:
			all_spawned = enemySpawner.enemies_spawned >= enemySpawner.enemies_to_spawn
			
		# End wave if time runs out, OR if every single enemy for this wave is dead!
		if wave_time_left <= 0.0 or (all_spawned and enemies_alive == 0):
			end_wave()

func start_new_wave():
	wave_time_left = wave_duration
	is_wave_active = true
	
	if wave_label:
		wave_label.text = "Wave: " + str(current_wave)
		
	# Calculate how many enemies are allowed to spawn this wave based on the Inspector variables!
	var enemies_this_wave = int(base_enemies_per_wave * pow(enemy_growth_multiplier, current_wave - 1))
	
	# Pass the command to the spawner!
	if enemySpawner and enemySpawner.has_method("start_wave"):
		enemySpawner.start_wave(enemies_this_wave, current_wave)

func end_wave():
	is_wave_active = false
	trigger_downgrade_menu()
# --------------------------------

func add_kill():
	enemies_killed += 1
	kill_label.text = "Kills: " + str(enemies_killed)
	
	if kill_tween and kill_tween.is_valid():
		kill_tween.kill()
		
	kill_tween = create_tween()
	kill_label.scale = Vector2(1.3, 1.3)
	kill_tween.tween_property(kill_label, "scale", Vector2.ONE, 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func trigger_downgrade_menu():
	if available_downgrades.size() < 2:
		print("YOU SURVIVED EVERYTHING!")
		current_wave += 1
		start_new_wave()
		return
		
	available_downgrades.shuffle()
	current_choice_1 = available_downgrades[0]
	current_choice_2 = available_downgrades[1]
	
	button_1.texture_normal = current_choice_1.get("texture", fallback_texture)
	button_2.texture_normal = current_choice_2.get("texture", fallback_texture)
	
	button_1.tooltip_text = current_choice_1.get("title", "") + "\n" + current_choice_1.get("description", "")
	button_2.tooltip_text = current_choice_2.get("title", "") + "\n" + current_choice_2.get("description", "")
	
	color_rect.modulate.a = 0.0   
	hbox.position.y = -600        
	button_1.disabled = false     
	button_2.disabled = false
	
	get_tree().paused = true
	downgrade_ui.show()
	
	var appear_tween = downgrade_ui.create_tween().set_parallel(true)
	appear_tween.tween_property(color_rect, "modulate:a", 1.0, 0.5)
	appear_tween.tween_property(hbox, "position:y", hbox_base_y, 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	appear_tween.chain().tween_callback(start_idle_animation)

func start_idle_animation():
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()
		
	idle_tween = downgrade_ui.create_tween().set_loops()
	idle_tween.tween_property(hbox, "position:y", hbox_base_y - 15.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(hbox, "position:y", hbox_base_y + 15.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_button_1_pressed():
	play_select_animation(button_1, button_2, current_choice_1)

func _on_button_2_pressed():
	play_select_animation(button_2, button_1, current_choice_2)

func play_select_animation(chosen_btn: TextureButton, other_btn: TextureButton, choice: Dictionary):
	chosen_btn.disabled = true
	other_btn.disabled = true
	
	var chosen_card = chosen_btn.get_parent()
	var other_card = other_btn.get_parent()
	
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()
		
	var select_tween = downgrade_ui.create_tween().set_parallel(true)
	select_tween.tween_property(color_rect, "modulate:a", 0.0, 0.4)
	select_tween.tween_property(chosen_card, "scale", Vector2(1.3, 1.3), 0.3)
	select_tween.tween_property(chosen_card, "modulate:a", 0.0, 0.3)
	select_tween.tween_property(other_card, "scale", Vector2.ZERO, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	await select_tween.finished
	
	chosen_card.scale = Vector2.ONE
	other_card.scale = Vector2.ONE
	chosen_card.modulate.a = 1.0
	other_card.modulate.a = 1.0
	
	apply_downgrade(choice)
	available_downgrades.erase(choice)
	resume_game()

func resume_game():
	downgrade_ui.hide()
	get_tree().paused = false
	
	# Increase wave and start again!
	current_wave += 1
	start_new_wave()

func apply_downgrade(downgrade: Dictionary):
	if not player: 
		return
		
	match downgrade["id"]:
		"lose_dash":
			player.dash_cooldown = 0.6
		"lose_aoe":
			player.wand_has_aoe = false
		"lose_tracking":
			player.wand_has_tracking = false
		"manual_shoot":
			player.wand_hold_to_shoot = false
		"slow_speed":
			player.speed *= 0.75
		"elite_enemies":
			enemySpawner.chance_elite = 0.1
			enemySpawner.chance_fast = 0.1
			enemySpawner.chance_shielded = 0.1
			enemySpawner.chance_splitting = 0.1
			enemySpawner.chance_erratic = 0.1
			enemySpawner.chance_ghost = 0.1
		"reload":
			player.reload = true
