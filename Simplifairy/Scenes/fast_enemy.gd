class_name FastEnemy
extends BaseEnemy

@export_group("Dash Attack")
@export var dash_range: float = 150.0       # How close they get before stopping to attack
@export var telegraph_duration: float = 0.5 # How long they flash yellow before dashing
@export var dash_speed: float = 700.0       # How fast the dash is
@export var dash_duration: float = 0.35     # How long they dash (700 * 0.35 = 245 pixels. They will overshoot the 150 range!)
@export var dash_cooldown: float = 1.5      # Time before they can dash again

enum State { CHASING, TELEGRAPHING, DASHING, COOLDOWN }
var current_state: State = State.CHASING
var state_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO

var flash_tween: Tween
var afterimage_timer: float = 0.0

func _ready():
	super._ready() # Get the player reference and health from BaseEnemy

func movement(delta: float):
	# 1. Handle Knockback (Always interrupts dashes and telegraphs)
	if knockback_velocity.length() > 15.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)
		move_and_slide()
		check_contact_damage()
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# 2. STATE MACHINE
	match current_state:
		State.CHASING, State.COOLDOWN:
			# Tick down the cooldown timer
			if current_state == State.COOLDOWN:
				state_timer -= delta
				if state_timer <= 0:
					current_state = State.CHASING
			
			# If we are chasing and close enough, start the attack!
			if current_state == State.CHASING and distance_to_player <= dash_range:
				start_telegraph()
				return
				
			# Normal chasing movement
			current_direction = global_position.direction_to(player.global_position)
			velocity = current_direction * speed
			
		State.TELEGRAPHING:
			# Stop perfectly still to aim
			velocity = Vector2.ZERO
			state_timer -= delta
			
			# (Removed the tracking code from here so they stay locked in place!)
			
			if state_timer <= 0:
				start_dash()
				
		State.DASHING:
			# Fly forward in a locked straight line
			velocity = dash_dir * dash_speed
			state_timer -= delta
			
			# Spawn the anime after-images!
			afterimage_timer -= delta
			if afterimage_timer <= 0:
				create_afterimage()
				afterimage_timer = 0.04 # Spawn a ghost every 0.04 seconds
			
			if state_timer <= 0:
				current_state = State.COOLDOWN
				state_timer = dash_cooldown

	move_and_slide()
	check_contact_damage()

func start_telegraph():
	current_state = State.TELEGRAPHING
	state_timer = telegraph_duration
	
	# --- NEW: Lock the aim direction right now! ---
	dash_dir = global_position.direction_to(player.global_position)
	current_direction = dash_dir 
	# ----------------------------------------------
	
	# Create a rapid blinking yellow warning
	if sprite:
		if flash_tween and flash_tween.is_valid():
			flash_tween.kill()
		flash_tween = create_tween().set_loops()
		flash_tween.tween_property(sprite, "modulate", Color.YELLOW, 0.1)
		flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func start_dash():
	current_state = State.DASHING
	state_timer = dash_duration
	afterimage_timer = 0.0
	
	# Stop the blinking and return to normal color
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	if sprite:
		sprite.modulate = Color.WHITE

func check_contact_damage():
	# Loop through everything this enemy just physically bumped into
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# If we hit the player, hurt them!
		if collider and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)

func create_afterimage():
	if not sprite: return
	
	# Create a brand new sprite in code
	var ghost = Sprite2D.new()
	
	# Copy the texture depending on if you are using an AnimatedSprite2D or a regular Sprite2D
	if sprite is AnimatedSprite2D:
		ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	else:
		ghost.texture = sprite.texture
		
	# Match the enemy's exact current look and position
	ghost.global_position = sprite.global_position
	ghost.rotation = sprite.rotation
	ghost.scale = sprite.scale * self.scale
	ghost.flip_h = sprite.get("flip_h")
	
	# Make it yellow and slightly transparent
	ghost.modulate = Color(1.0, 1.0, 0.3, 0.5) 
	
	# Add it to the main world, NOT the enemy, so it stays behind when the enemy moves!
	get_tree().current_scene.add_child(ghost)
	
	# Fade it out smoothly over 0.3 seconds and then delete it
	var fade = create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, 0.3)
	fade.tween_callback(ghost.queue_free)
