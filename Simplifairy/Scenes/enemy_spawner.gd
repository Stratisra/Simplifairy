extends Node2D

@export_group("Spawning Rules")
@export var enemy_scenes: Array[PackedScene] = [] 
@export var boss_scene: PackedScene # <--- NEW: Boss Slot!
@export var player: Node2D
@export var min_spawn_distance: float = 600.0
@export var max_spawn_distance: float = 800.0

@export_group("Horde Scaling")
@export var max_enemies_on_screen: int = 300 

@export_group("Modifier Stacking")
@export var max_modifiers: int = 1
@export var multiple_mod_chance: float = 0.25 

@export_group("Modifier Chances (0.0 to 1.0)")
@export var chance_elite: float = 0.0
@export var chance_fast: float = 0.0 
@export var chance_shielded: float = 0.0
@export var chance_exploding: float = 0.0
@export var chance_splitting: float = 0.0
@export var chance_erratic: float = 0.0
@export var chance_ghost: float = 0.0

@onready var spawn_timer: Timer = $SpawnTimer

var enemies_to_spawn: int = 0
var enemies_spawned: int = 0
var current_wave: int = 1
var climax_triggered: bool = false 

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func start_wave(amount: int, wave_num: int):
	enemies_to_spawn = amount
	enemies_spawned = 0
	current_wave = wave_num
	climax_triggered = false 
	
	if spawn_timer.is_stopped():
		spawn_timer.start()

# --- NEW: BOSS SPAWN LOGIC ---
func start_boss_wave():
	enemies_to_spawn = 1
	enemies_spawned = 1
	current_wave = 6
	spawn_timer.stop() # Stop normal timer spawns
	
	if boss_scene and player:
		var boss = boss_scene.instantiate()
		# Spawn boss directly above the player just off-screen
		boss.global_position = player.global_position + Vector2(0, -600)
		boss.add_to_group("enemy")
		get_tree().current_scene.call_deferred("add_child", boss)
	else:
		print("ERROR: Boss scene missing in Spawner Inspector!")
# -----------------------------

func _on_spawn_timer_timeout() -> void:
	if not player or enemy_scenes.is_empty():
		return
		
	var current_enemy_count = get_tree().get_nodes_in_group("enemy").size()
	if current_enemy_count >= max_enemies_on_screen:
		return
		
	spawn_enemy_cluster()

func spawn_enemy_cluster() -> void:
	if enemies_spawned >= enemies_to_spawn:
		return

	if enemies_spawned >= int(enemies_to_spawn * 0.85) and not climax_triggered:
		climax_triggered = true
		spawn_circle_trap()
		return

	var burst_size = max(1, int(enemies_to_spawn / 15.0))
	var num_clusters = randi_range(1, 3)
	var enemies_per_cluster = max(1, burst_size / num_clusters)
	
	for c in range(num_clusters):
		var base_angle: float = randf_range(0.0, TAU)
		
		if player.velocity.length() > 50.0 and randf() < 0.40:
			var player_move_angle = player.velocity.angle()
			base_angle = player_move_angle + randf_range(-0.5, 0.5)
			
		var base_distance: float = randf_range(min_spawn_distance, max_spawn_distance)
		var cluster_center: Vector2 = player.global_position + (Vector2.RIGHT.rotated(base_angle) * base_distance)
		
		for i in range(enemies_per_cluster):
			if enemies_spawned >= enemies_to_spawn:
				return
				
			var random_scene = enemy_scenes.pick_random()
			if random_scene == null: continue
				
			var enemy = random_scene.instantiate()
			apply_random_modifiers(enemy)
			
			var spread = 40.0 + (enemies_per_cluster * 3.0) 
			var random_cluster_offset = Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
			enemy.global_position = cluster_center + random_cluster_offset
			
			enemy.add_to_group("enemy")
			get_tree().current_scene.call_deferred("add_child", enemy)
			
			enemies_spawned += 1

func spawn_circle_trap():
	var enemies_left = enemies_to_spawn - enemies_spawned
	if enemies_left <= 0: return
	
	var angle_step = TAU / float(enemies_left)
	
	for i in range(enemies_left):
		var random_scene = enemy_scenes.pick_random()
		if random_scene == null: continue
		
		var enemy = random_scene.instantiate()
		apply_random_modifiers(enemy)
		
		var ring_distance = max_spawn_distance - 100.0
		var spawn_pos = player.global_position + (Vector2.RIGHT.rotated(i * angle_step) * ring_distance)
		
		enemy.global_position = spawn_pos
		enemy.add_to_group("enemy")
		get_tree().current_scene.call_deferred("add_child", enemy)
		
		enemies_spawned += 1

func apply_random_modifiers(enemy: Node2D):
	var available_mods = {
		"elite": chance_elite, "fast": chance_fast, "shielded": chance_shielded,
		"exploding": chance_exploding, "splitting": chance_splitting,
		"erratic": chance_erratic, "ghost": chance_ghost
	}
	var mod_names = available_mods.keys()
	mod_names.shuffle()
	
	var mods_applied = 0
	for mod in mod_names:
		if mods_applied >= max_modifiers: break
		if mods_applied > 0 and randf() > multiple_mod_chance: break
		if randf() < available_mods[mod]:
			apply_single_mod(enemy, mod)
			mods_applied += 1

func apply_single_mod(enemy: Node2D, mod_name: String):
	var target_color = Color.WHITE
	
	match mod_name:
		"elite":
			enemy.scale *= 1.4
			if "max_health" in enemy: enemy.max_health *= 3.0
			if "damage" in enemy: enemy.damage *= 2.0
			target_color = Color(1.0, 0.3, 0.3) 
		"fast":
			enemy.scale *= 0.8
			if "speed" in enemy: enemy.speed *= 1.8
			target_color = Color(1.0, 1.0, 0.3) 
		"shielded":
			if "max_health" in enemy: enemy.max_health *= 4.0
			if "speed" in enemy: enemy.speed *= 0.6
			if "knockback_decay" in enemy: enemy.knockback_decay *= 3.0 
			target_color = Color(0.4, 0.6, 1.0) 
		"exploding":
			enemy.set("is_exploding", true) 
			target_color = Color(1.0, 0.5, 0.0) 
		"splitting":
			enemy.set("is_splitting", true)
			target_color = Color(0.8, 0.3, 1.0) 
		"erratic":
			enemy.set("is_erratic", true)
			if "speed" in enemy: enemy.speed *= 1.2
			target_color = Color(0.3, 1.0, 0.3) 
		"ghost":
			enemy.set("is_ghost", true)
			target_color = Color(0.8, 0.8, 0.8) 
			enemy.modulate.a = 0.5 
			
	if "current_health" in enemy and "max_health" in enemy:
		enemy.current_health = enemy.max_health
		
	if enemy.modulate == Color.WHITE:
		enemy.modulate = target_color
	else:
		enemy.modulate = enemy.modulate.lerp(target_color, 0.5)
