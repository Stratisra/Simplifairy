extends Node2D

@export var enemy_scene: PackedScene
@export var player: Node2D

# Distance outside the player's view
@export var min_spawn_distance: float = 800.0
@export var max_spawn_distance: float = 800.0

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout() -> void:
	if not player or not enemy_scene:
		return
	spawn_enemy()

func spawn_enemy() -> void:
	# 1. Pick a random angle around the full circle
	var random_angle: float = randf_range(0.0, TAU) # TAU = 2 * PI
	
	# 2. Pick a random distance beyond the screen edge
	var random_distance: float = randf_range(min_spawn_distance, max_spawn_distance)
	
	# 3. Calculate position relative to player
	var spawn_offset: Vector2 = Vector2.RIGHT.rotated(random_angle) * random_distance
	var spawn_position: Vector2 = player.global_position + spawn_offset
	
	# 4. Instantiate and add to tree (at the root level so it moves independently)
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	get_tree().current_scene.add_child(enemy)
