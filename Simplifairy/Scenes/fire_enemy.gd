class_name FireEnemy
extends BaseEnemy

@export_group("Fire Trail")
@export var fire_hazard_scene: PackedScene 
@export var drop_distance: float = 40.0 

@export_group("Drifting Movement")
@export var slip_factor: float = 2.0 # Lower = more slippery/icy. Higher = tighter turns.
@export var flank_distance: float = 150.0 # How far to the side of the player they run

var last_drop_position: Vector2 = Vector2.ZERO
var flank_direction: int = 1 # Will be 1 (Right) or -1 (Left)

func _ready():
	super._ready()
	# 50/50 chance to be a Left-Flanker or Right-Flanker when they spawn!
	flank_direction = 1 if randf() > 0.5 else -1

func movement(delta: float):
	# ==========================================
	# 1. FLANKING AI (Run next to the player)
	# ==========================================
	# Find the line from the enemy to the player
	var angle_to_player = global_position.direction_to(player.global_position)
	
	# Rotate that line 90 degrees (PI/2) and multiply by our distance to find a spot next to them
	var side_offset = angle_to_player.rotated((PI / 2.0) * flank_direction) * flank_distance
	var target_pos = player.global_position + side_offset
	
	# If the player is running, aim ahead of their path but STILL off to the side
	if "velocity" in player and player.velocity.length() > 20.0:
		target_pos += player.velocity.normalized() * 100.0

	current_direction = global_position.direction_to(target_pos)
	
	# ==========================================
	# 2. SLIPPERY PHYSICS (Acceleration / Drift)
	# ==========================================
	var separation_vector = Vector2.ZERO
	if not is_ghost and has_node("SoftCollision"):
		var soft_collider = $SoftCollision
		for area in soft_collider.get_overlapping_areas():
			if area != soft_collider:
				separation_vector += area.global_position.direction_to(global_position)
		if separation_vector != Vector2.ZERO:
			separation_vector = separation_vector.normalized()
			
	if knockback_velocity.length() > 15.0:
		velocity = knockback_velocity
	else:
		# Calculate where they WANT to go
		var desired_velocity = (current_direction * speed) + (separation_vector * (speed * 1.5))
		
		# --- THE DRIFT EFFECT ---
		# Instead of instantly snapping to the desired velocity, we smoothly blend (lerp) towards it.
		# This creates that awesome feeling of momentum, acceleration, and slipping on ice!
		velocity = velocity.lerp(desired_velocity, slip_factor * delta)
		
		knockback_velocity = Vector2.ZERO 
	
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)
	
	move_and_slide()
	
	# Contact Damage
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
				
	# ==========================================
	# 3. FIRE DROPPING LOGIC
	# ==========================================
	if last_drop_position == Vector2.ZERO:
		last_drop_position = global_position
		
	if global_position.distance_to(last_drop_position) >= drop_distance:
		drop_fire()
		last_drop_position = global_position

func drop_fire():
	if not fire_hazard_scene:
		return
		
	var fire = fire_hazard_scene.instantiate()
	fire.global_position = global_position
	get_tree().current_scene.add_child(fire)
