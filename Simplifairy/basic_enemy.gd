class_name BaseEnemy
extends CharacterBody2D

@export_group("Stats")
@export var speed: float = 90.0
@export var max_health: float = 30.0
@export var damage: float = 10.0 # How much damage this enemy deals to the player
@export var knockback_decay: float = 12.0 # How fast the knockback wears off

@export_group("Animation")
@export var sprite: Node2D 
@export var max_lean_angle: float = 25.0
@export var lean_speed: float = 8.0

var current_health: float
var player: Node2D
var current_direction: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO
var hit_tween: Tween

# Change the path from res://confetti_pop.tscn to res://whimsical_burst.tscn
@export var death_fx: PackedScene = preload("res://Scenes/whimsical_burst.tscn")

func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if not player:
		return
		
	movement(delta)
	animation(delta)

# --- MODULAR FUNCTIONS ---

func movement(delta: float):
	# 1. Figure out which way the player is
	current_direction = global_position.direction_to(player.global_position)
	
	# 2. Check if we are being knocked back
	if knockback_velocity.length() > 15.0:
		# We are stunned! Only apply the knockback movement
		velocity = knockback_velocity
	else:
		# Normal movement: chase the player
		velocity = current_direction * speed
		
		# Ensure knockback goes completely to zero so it doesn't get stuck
		knockback_velocity = Vector2.ZERO 
	
	# 3. Smoothly bleed off the knockback force back to zero
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)
	
	move_and_slide()

func animation(delta: float):
	if sprite:
		if "flip_h" in sprite:
			sprite.flip_h = current_direction.x < 0
			
		var target_rotation_deg = current_direction.x * max_lean_angle
		var target_rotation_rad = deg_to_rad(target_rotation_deg)
		sprite.rotation = lerp_angle(sprite.rotation, target_rotation_rad, lean_speed * delta)

func take_damage(amount: float, source_position: Vector2 = Vector2.ZERO, knockback_force: float = 120.0):
	current_health -= amount
	
	# 1. Apply Knockback
	if source_position != Vector2.ZERO:
		# Pushes directly away from what hit it (bullet or wand tip)
		var knockback_dir = source_position.direction_to(global_position)
		knockback_velocity = knockback_dir * knockback_force
	else:
		# Fallback: knock backwards relative to player
		knockback_velocity = -current_direction * knockback_force

	# 2. Play Hit Flash
	flash_white()
	
	# 3. Health Check
	if current_health <= 0:
		die()

func flash_white():
	if sprite:
		# If it's already flashing from a previous hit, cancel that tween
		if hit_tween and hit_tween.is_valid():
			hit_tween.kill()
		
		hit_tween = create_tween()
		# Boosting color values far above 1.0 creates a brilliant pure-white flash in Godot
		sprite.modulate = Color(8.0, 8.0, 8.0, 1.0)
		hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)


func die():
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	if death_fx:
		var fx = death_fx.instantiate()
		fx.global_position = global_position
		# The root scene handles adding itself and cleanup
		get_tree().current_scene.add_child(fx)
	
	# Optional: Keep the squish tween for extra 'juice'
	if sprite:
		# ... your previous squish/inflate tween code here ...
		# death_tween.tween_property(sprite, "scale", Vector2.ZERO, 0.05)
		# await death_tween.finished
		pass # Remove or comment out pass if you keep the tween
	
	queue_free()
