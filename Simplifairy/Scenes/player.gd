extends CharacterBody2D

@export_group("AOE & Tracking")
@export var wand_has_aoe: bool = true
@export var wand_aoe_radius: float = 60.0
@export var wand_has_tracking: bool = true

@export_group("Movement")
@export var speed: float = 200.0
@export var friction: float = 0.1
@export var acceleration: float = 0.1

@export_group("Dash")
@export var dash_speed: float = 650.0       # Speed during the dash burst
@export var dash_duration: float = 0.15     # How long the dash lasts (in seconds)
@export var dash_cooldown: float = 0.6      # Time before you can dash again

@export_group("Procedural Animation")
@export var sprite: AnimatedSprite2D 
@export var tilt_amount: float = 0.15
@export var tilt_speed: float = 15.0
@export var bounce_amount: float = 4.0
@export var bounce_speed: float = 15.0

@export_group("Combat / Wand")
@export var projectile_scene: PackedScene 
@export var wand_pivot: Node2D
@export var muzzle: Marker2D
@export var wand_sprite: Sprite2D

# --- NEW SHOOTING MODES ---
@export var auto_shoot: bool = true             # True = Vampire Survivors style (uses Timer node)
@export var wand_hold_to_shoot: bool = true     # True = Hold button to shoot, False = Click for every shot
@export var fire_rate: float = 0.25             # Delay between shots when holding the button

var fire_cooldown: float = 0.0
# --------------------------

var time_moving: float = 0.0
var base_sprite_y: float = 0.0

# Wand & recoil memory
var base_wand_pos: Vector2
var shoot_tween: Tween 

# Dash state variables
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

func _ready():
	if sprite:
		base_sprite_y = sprite.position.y
	if wand_sprite:
		base_wand_pos = wand_sprite.position

func get_input():
	var input = Vector2.ZERO
	if Input.is_action_pressed('right'):
		input.x += 1
	if Input.is_action_pressed('left'):
		input.x -= 1
	if Input.is_action_pressed('down'):
		input.y += 1
	if Input.is_action_pressed('up'):
		input.y -= 1
	return input

func _physics_process(delta):
	var direction = get_input()
	
	# 1. Dash Timers & Activation Check
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	var dash_pressed = Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("ui_select")
	if dash_pressed and not is_dashing and dash_cooldown_timer <= 0.0:
		start_dash(direction)

	# 2. Physics & Movement
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * dash_speed
		
		if dash_timer <= 0.0:
			is_dashing = false
	else:
		if direction.length() > 0:
			velocity = velocity.lerp(direction.normalized() * speed, acceleration)
		else:
			velocity = velocity.lerp(Vector2.ZERO, friction)
		
	move_and_slide()
	
	# 3. Aiming, Mouse Flipping, and Depth Sorting
	var mouse_pos = get_global_mouse_position()
	
	if sprite:
		sprite.flip_h = mouse_pos.x < global_position.x
	
	if wand_pivot:
		wand_pivot.look_at(mouse_pos)
		
		if wand_sprite:
			wand_sprite.flip_v = mouse_pos.x < global_position.x
			if mouse_pos.y < global_position.y:
				wand_pivot.z_index = -1
			else:
				wand_pivot.z_index = 1

	# --- 4. MANUAL SHOOTING LOGIC ---
	if fire_cooldown > 0.0:
		fire_cooldown -= delta
		
	if not auto_shoot:
		if wand_hold_to_shoot:
			# HOLD MODE: Uses is_action_pressed (triggers repeatedly while held down)
			if Input.is_action_pressed("shoot") and fire_cooldown <= 0.0:
				shoot()
				fire_cooldown = fire_rate
		else:
			# CLICK MODE: Uses is_action_just_pressed (forces you to click every single time)
			if Input.is_action_just_pressed("shoot") and fire_cooldown <= 0.0:
				shoot()
				fire_cooldown = fire_rate
	# --------------------------------

	# 5. Procedural Movement Animation (Wobble & Bounce)
	if sprite and not is_dashing:
		if velocity.length() > 10.0:
			time_moving += delta
			sprite.rotation = sin(time_moving * tilt_speed) * tilt_amount
			sprite.position.y = base_sprite_y - abs(sin(time_moving * bounce_speed)) * bounce_amount
		else:
			time_moving = 0.0
			sprite.rotation = lerp_angle(sprite.rotation, 0.0, 0.2)
			sprite.position.y = lerp(sprite.position.y, base_sprite_y, 0.2)

func start_dash(input_direction: Vector2):
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	if input_direction != Vector2.ZERO:
		dash_direction = input_direction.normalized()
	else:
		dash_direction = global_position.direction_to(get_global_mouse_position())
		
	if sprite:
		var dash_tween = create_tween()
		sprite.scale = Vector2(1.35 * sprite.scale.x, 0.75 * sprite.scale.y)
		dash_tween.tween_property(sprite, "scale", Vector2.ONE * 4, dash_duration)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func shoot():
	if projectile_scene and muzzle:
		var bullet = projectile_scene.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.rotation = wand_pivot.rotation
		
		# Pass variables to the bullet!
		bullet.set("has_aoe", wand_has_aoe)
		bullet.set("aoe_radius", wand_aoe_radius)
		bullet.set("has_tracking", wand_has_tracking)
		
		get_tree().current_scene.add_child(bullet)
		
		# Visual Feedback (Recoil & Glow)
		if wand_sprite:
			if shoot_tween and shoot_tween.is_valid():
				shoot_tween.kill()
				
			shoot_tween = create_tween()
			shoot_tween.set_parallel(true)
			
			wand_sprite.modulate = Color(3.0, 3.0, 1.5, 1.0)
			shoot_tween.tween_property(wand_sprite, "modulate", Color.WHITE, 0.15)
			
			wand_sprite.position.x = base_wand_pos.x - 8.0
			shoot_tween.tween_property(wand_sprite, "position:x", base_wand_pos.x, 0.15)\
				.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

# This remains here to handle your Vampire Survivors auto-fire Timer!
func _on_shoot_timer_timeout():
	if auto_shoot:
		shoot()
