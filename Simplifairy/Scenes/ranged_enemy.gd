class_name RangedEnemy
extends BaseEnemy

@export_group("Ranged Attack")
@export var enemy_projectile: PackedScene # Drag enemy_bullet.tscn here!
@export var shoot_range: float = 350.0    # How close it needs to be to shoot
@export var fire_rate: float = 2.0        # Seconds between shots

var fire_cooldown: float = 0.0

func _physics_process(delta):
	if not player:
		return
		
	# 1. Run the base physics (movement, animation, and modifiers from BaseEnemy!)
	super._physics_process(delta) 
	
	# 2. Add the shooting logic on top of the normal movement
	fire_cooldown -= delta
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# If close enough and ready to fire
	if distance_to_player <= shoot_range and fire_cooldown <= 0.0:
		shoot()
		fire_cooldown = fire_rate

func shoot():
	if enemy_projectile:
		var bullet = enemy_projectile.instantiate()
		bullet.global_position = global_position
		
		# Point the bullet directly at the player
		bullet.rotation = global_position.direction_to(player.global_position).angle()
		
		# Add bullet to the main scene tree, not the enemy, so it moves independently
		get_tree().current_scene.add_child(bullet)
