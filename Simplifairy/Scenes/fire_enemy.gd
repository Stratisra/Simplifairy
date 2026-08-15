class_name FireEnemy
extends BaseEnemy

@export_group("Fire Trail")
@export var fire_hazard_scene: PackedScene # Drag fire_hazard.tscn here!
@export var drop_distance: float = 40.0 # Drops fire every 40 pixels moved

var last_drop_position: Vector2 = Vector2.ZERO

func movement(delta: float):
	# 1. Call the exact movement and knockback code from BaseEnemy!
	super.movement(delta) 
	
	# 2. Initialize the drop position on the very first frame
	if last_drop_position == Vector2.ZERO:
		last_drop_position = global_position
		
	# 3. Check if we walked far enough to drop another fire patch
	if global_position.distance_to(last_drop_position) >= drop_distance:
		drop_fire()
		last_drop_position = global_position

func drop_fire():
	if not fire_hazard_scene:
		return
		
	var fire = fire_hazard_scene.instantiate()
	fire.global_position = global_position
	
	# CRITICAL: Add the fire to the main scene, not the enemy.
	# Otherwise, the fire will get dragged along with the enemy when they move!
	get_tree().current_scene.add_child(fire)
