class_name BaseEnemy
extends CharacterBody2D

@export_group("Stats")
@export var speed: float = 90.0
@export var max_health: float = 30.0
@export var damage: float = 10.0
@export var knockback_decay: float = 12.0

@export_group("Animation")
@export var sprite: Node2D 
@export var max_lean_angle: float = 25.0
@export var lean_speed: float = 8.0

# --- MODIFIER FLAGS ---
var is_exploding: bool = false
var is_splitting: bool = false
var is_erratic: bool = false
var is_ghost: bool = false
var erratic_timer: float = 0.0 # Used to calculate the zig-zag
# ----------------------

var current_health: float
var player: Node2D
var current_direction: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO
var hit_tween: Tween

@export var death_fx: PackedScene = preload("res://Scenes/whimsical_burst.tscn")

func _ready():
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	
	# Randomize the erratic timer so multiple erratic enemies don't move in perfectly synchronized waves
	erratic_timer = randf_range(0.0, 10.0)

func _physics_process(delta):
	if not player:
		return
		
	movement(delta)
	animation(delta)

# --- MODULAR FUNCTIONS ---

func movement(delta: float):
	current_direction = global_position.direction_to(player.global_position)
	
	# MODIFIER: ERRATIC
	if is_erratic:
		erratic_timer += delta * 8.0
		current_direction = current_direction.rotated(sin(erratic_timer) * 1.2)
	
	# MODIFIER: GHOST
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
		velocity = (current_direction * speed) + (separation_vector * (speed * 1.5))
		knockback_velocity = Vector2.ZERO 
	
	if knockback_velocity != Vector2.ZERO:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)
	
	move_and_slide()
	
	# --- CONTACT DAMAGE ---
	# Loop through everything this enemy just physically bumped into
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# If the thing we touched is the player, hurt them!
		if collider and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)

func animation(delta: float):
	if sprite:
		if "flip_h" in sprite:
			sprite.flip_h = current_direction.x < 0
			
		var target_rotation_deg = current_direction.x * max_lean_angle
		var target_rotation_rad = deg_to_rad(target_rotation_deg)
		sprite.rotation = lerp_angle(sprite.rotation, target_rotation_rad, lean_speed * delta)

func take_damage(amount: float, source_position: Vector2 = Vector2.ZERO, knockback_force: float = 120.0):
	current_health -= amount
	
	if source_position != Vector2.ZERO:
		var knockback_dir = source_position.direction_to(global_position)
		knockback_velocity = knockback_dir * knockback_force
	else:
		knockback_velocity = -current_direction * knockback_force

	flash_white()
	
	if current_health <= 0:
		die(source_position)

func flash_white():
	if sprite:
		if hit_tween and hit_tween.is_valid():
			hit_tween.kill()
		
		hit_tween = create_tween()
		sprite.modulate = Color(8.0, 8.0, 8.0, 1.0)
		hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func die(source_position: Vector2 = Vector2.ZERO):
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# --- NEW: UPDATE THE KILL SCORE ---
	if get_tree().current_scene.has_method("add_kill"):
		get_tree().current_scene.add_kill()
	# ----------------------------------
	
	if sprite:
		var fling_dir = Vector2.UP
		if source_position != Vector2.ZERO:
			fling_dir = source_position.direction_to(global_position)
		elif current_direction != Vector2.ZERO:
			fling_dir = -current_direction
			
		fling_dir = fling_dir.rotated(randf_range(-0.4, 0.4))
		
		var flight_distance = randf_range(60.0, 110.0)
		var target_pos = global_position + (fling_dir * flight_distance)
		
		if hit_tween and hit_tween.is_valid():
			hit_tween.kill()
			
		var death_tween = create_tween()
		var fly_time = 0.5
		
		death_tween.set_parallel(true)
		death_tween.tween_property(self, "global_position", target_pos, fly_time).set_trans(Tween.TRANS_LINEAR)
		
		var spin_amount = TAU * 2.5 * (1 if fling_dir.x > 0 else -1)
		death_tween.tween_property(sprite, "rotation", sprite.rotation + spin_amount, fly_time)
		
		var jump_height = randf_range(-40.0, -80.0)
		death_tween.tween_property(sprite, "position:y", jump_height, fly_time / 2.0)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		death_tween.tween_property(sprite, "position:y", 0.0, fly_time / 2.0)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(fly_time / 2.0)
			
		death_tween.tween_property(sprite, "scale", Vector2(1.5, 0.2), 0.1).set_delay(fly_time)
		
		await death_tween.finished
	
	if death_fx:
		var fx = death_fx.instantiate()
		fx.global_position = global_position
		get_tree().current_scene.add_child(fx)
	
	# --- MODIFIER ON-DEATH TRIGGERS ---
	if is_exploding:
		trigger_explosion()
		
	if is_splitting:
		trigger_split()
	# ----------------------------------
	
	queue_free()

func trigger_explosion():
	var explosion_radius = 120.0
	var explosion_damage = 25.0
	
	# Hurt the player if they are too close when the corpse lands
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= explosion_radius:
		if player.has_method("take_damage"):
			player.take_damage(explosion_damage)
			
	# Optional: Hurt other enemies in the blast radius!
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and e != self:
			if global_position.distance_to(e.global_position) <= explosion_radius:
				if e.has_method("take_damage"):
					e.take_damage(explosion_damage * 2.0, global_position, 300.0)

func trigger_split():
	# Load whatever scene this enemy currently is (works for ranged, melee, etc.)
	var current_scene_path = scene_file_path
	var loaded_scene = load(current_scene_path)
	if not loaded_scene:
		return
		
	for i in range(2):
		var mini_enemy = loaded_scene.instantiate()
		
		# Offset them slightly so they don't spawn perfectly inside each other
		mini_enemy.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		
		# Scale down stats and size
		mini_enemy.scale = self.scale * 0.6
		mini_enemy.max_health = self.max_health * 0.4
		mini_enemy.damage = self.damage * 0.5
		mini_enemy.speed = self.speed * 1.2 # Make the little ones faster!
		
		# VERY IMPORTANT: Turn off splitting so they don't infinitely multiply
		mini_enemy.is_splitting = false 
		
		# Inherit the color of the parent
		mini_enemy.modulate = self.modulate 
		
		# Add to scene safely
		get_tree().current_scene.call_deferred("add_child", mini_enemy)
		mini_enemy.add_to_group("enemy")
