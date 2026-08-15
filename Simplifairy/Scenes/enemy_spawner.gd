extends Node2D

@export_group("Spawning Rules")
# Changed to an Array so you can add multiple different enemies!
@export var enemy_scenes: Array[PackedScene] = [] 
@export var player: Node2D
@export var min_spawn_distance: float = 600.0
@export var max_spawn_distance: float = 800.0

@export_group("Horde Scaling")
@export var base_spawn_count: int = 3       # How many enemies spawn in a single cluster
@export var max_enemies_on_screen: int = 300 # Prevents lag/crashing!
@export var difficulty_scale_rate: float = 0.5 # Adds this many enemies to the spawn count per minute

@onready var spawn_timer: Timer = $SpawnTimer
var time_elapsed: float = 0.0

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _process(delta: float) -> void:
	# Keep track of how long the game has been running to scale difficulty
	time_elapsed += delta

func _on_spawn_timer_timeout() -> void:
	# Check if the player exists and if you've actually added scenes to the array
	if not player or enemy_scenes.is_empty():
		return
		
	# Check if we already have too many enemies to prevent lag
	var current_enemy_count = get_tree().get_nodes_in_group("enemy").size()
	if current_enemy_count >= max_enemies_on_screen:
		return
		
	spawn_enemy_cluster()

func spawn_enemy_cluster() -> void:
	# Calculate how many enemies to spawn based on how long the player has survived
	var current_wave_count = base_spawn_count + int(time_elapsed / 60.0 * difficulty_scale_rate * 10.0)
	
	# 1. Pick ONE random angle for the entire cluster
	var base_angle: float = randf_range(0.0, TAU)
	var base_distance: float = randf_range(min_spawn_distance, max_spawn_distance)
	var cluster_center: Vector2 = player.global_position + (Vector2.RIGHT.rotated(base_angle) * base_distance)
	
	# 2. Spawn multiple enemies around that single point
	for i in range(current_wave_count):
		
		# Pick a random enemy from your list!
		var random_scene = enemy_scenes.pick_random()
		
		# Safety check just in case you have an empty slot in the Inspector array
		if random_scene == null:
			continue
			
		var enemy = random_scene.instantiate()
		
		# Add a small random offset so they don't spawn exactly inside each other
		var random_cluster_offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
		enemy.global_position = cluster_center + random_cluster_offset
		
		# Add them to an "enemy" group so we can count them later!
		enemy.add_to_group("enemy")
		
		get_tree().current_scene.add_child(enemy)
