extends Node2D

@export var player: CharacterBody2D

@onready var downgrade_ui: CanvasLayer = $DowngradeUI
@onready var color_rect: ColorRect = $DowngradeUI/ColorRect
@onready var hbox: HBoxContainer = $DowngradeUI/HBoxContainer
@onready var button_1: TextureButton = $DowngradeUI/HBoxContainer/SimplificationCard/Button1
@onready var button_2: TextureButton = $DowngradeUI/HBoxContainer/SimplificationCard2/Button2
@onready var timer: Timer = $DowngradeTimer

var fallback_texture = preload('res://Sprites/Star.png')

var available_downgrades = [
	{"id": "lose_dash", "title": "Broken Legs", "description": "Lose the ability to Dash"},
	{"id": "lose_aoe", "title": "Dull Wand", "description": "Wand loses Area of Effect","texture": preload('res://Sprites/Icons/smaller_aoe.png')},
	{"id": "lose_tracking", "title": "Blind Fire", "description": "Bullets no longer home in","texture": preload("res://Sprites/Icons/no_homing.png")},
	{"id": "manual_shoot", "title": "Jamming", "description": "Disable Auto-Shoot","texture": preload("res://Sprites/Icons/semi_auto.png")},
	{"id": "slow_speed", "title": "Exhaustion", "description": "Move 25% slower"}
]

var current_choice_1: Dictionary
var current_choice_2: Dictionary

# Animation variables
var hbox_base_y: float
var idle_tween: Tween

func _ready():
	if not player:
		player = get_tree().get_first_node_in_group("player")
		
	timer.timeout.connect(_on_timer_timeout)
	
	# Connect buttons
	button_1.pressed.connect(_on_button_1_pressed)
	button_2.pressed.connect(_on_button_2_pressed)
	
	# We have to wait one frame for the UI to arrange itself before we grab its position
	await get_tree().process_frame
	
	hbox_base_y = hbox.position.y
	
	# --- FIX: Set the pivot points to the center of the CARDS (the parent nodes), not the buttons! ---
	button_1.get_parent().pivot_offset = Vector2(100, 150)
	button_2.get_parent().pivot_offset = Vector2(100, 150)
	
	downgrade_ui.hide()

func _on_timer_timeout():
	if available_downgrades.size() < 2:
		print("YOU SURVIVED!")
		return
		
	available_downgrades.shuffle()
	current_choice_1 = available_downgrades[0]
	current_choice_2 = available_downgrades[1]
	
	button_1.texture_normal = current_choice_1.get("texture", fallback_texture)
	button_2.texture_normal = current_choice_2.get("texture", fallback_texture)
	
	button_1.tooltip_text = current_choice_1.get("title", "") + "\n" + current_choice_1.get("description", "")
	button_2.tooltip_text = current_choice_2.get("title", "") + "\n" + current_choice_2.get("description", "")
	
	# --- 1. SETUP APPEAR ANIMATION ---
	color_rect.modulate.a = 0.0   # Make background invisible
	hbox.position.y = -600        # Move cards way above the screen
	button_1.disabled = false     # Make sure buttons are clickable
	button_2.disabled = false
	
	get_tree().paused = true
	downgrade_ui.show()
	
	var appear_tween = downgrade_ui.create_tween().set_parallel(true)
	# Slowly dim the background over 0.5 seconds
	appear_tween.tween_property(color_rect, "modulate:a", 1.0, 0.5)
	# Slam the cards down with a bouncy "Back" easing
	appear_tween.tween_property(hbox, "position:y", hbox_base_y, 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Start the idle float when the slam finishes
	appear_tween.chain().tween_callback(start_idle_animation)

func start_idle_animation():
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()
		
	idle_tween = downgrade_ui.create_tween().set_loops()
	# Float up 15 pixels, then float down 15 pixels infinitely
	idle_tween.tween_property(hbox, "position:y", hbox_base_y - 15.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(hbox, "position:y", hbox_base_y + 15.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_button_1_pressed():
	play_select_animation(button_1, button_2, current_choice_1)

func _on_button_2_pressed():
	play_select_animation(button_2, button_1, current_choice_2)

func play_select_animation(chosen_btn: TextureButton, other_btn: TextureButton, choice: Dictionary):
	# Immediately prevent the player from clicking again while it animates
	chosen_btn.disabled = true
	other_btn.disabled = true
	
	# --- FIX: Grab the actual Card Nodes (parents) so we animate the whole thing ---
	var chosen_card = chosen_btn.get_parent()
	var other_card = other_btn.get_parent()
	
	if idle_tween and idle_tween.is_valid():
		idle_tween.kill()
		
	var select_tween = downgrade_ui.create_tween().set_parallel(true)
	
	# 1. Fade the background out
	select_tween.tween_property(color_rect, "modulate:a", 0.0, 0.4)
	
	# 2. The chosen card flashes white, gets slightly bigger, and fades out
	select_tween.tween_property(chosen_card, "scale", Vector2(1.3, 1.3), 0.3)
	select_tween.tween_property(chosen_card, "modulate:a", 0.0, 0.3)
	
	# 3. The card they DID NOT choose shrinks to nothing
	select_tween.tween_property(other_card, "scale", Vector2.ZERO, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# WAIT for the animation to completely finish before resuming the game!
	await select_tween.finished
	
	# Reset the cards back to normal so they are ready for the NEXT wave
	chosen_card.scale = Vector2.ONE
	other_card.scale = Vector2.ONE
	chosen_card.modulate.a = 1.0
	other_card.modulate.a = 1.0
	
	# Apply logic and resume
	apply_downgrade(choice)
	available_downgrades.erase(choice)
	resume_game()

func resume_game():
	downgrade_ui.hide()
	get_tree().paused = false
	timer.start()

func apply_downgrade(downgrade: Dictionary):
	if not player: 
		return
		
	match downgrade["id"]:
		"lose_dash":
			player.dash_cooldown = 9999.0
		"lose_aoe":
			player.wand_has_aoe = false
		"lose_tracking":
			player.wand_has_tracking = false
		"manual_shoot":
			player.wand_hold_to_shoot = false
		"slow_speed":
			player.speed *= 0.75
