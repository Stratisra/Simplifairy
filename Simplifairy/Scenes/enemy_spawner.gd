extends Node2D

@export_group("Spawning Rules")
@export var enemy_scenes: Array[PackedScene] = [] 
@export var player: Node2D
@export var min_spawn_distance: float = 600.0
@export var max_spawn_distance: float = 800.0

@export_group("Horde Scaling")
@export var base_spawn_count: int = 3       
@export var max_enemies_on_screen: int = 300 
@export var difficulty_scale_rate: float = 0.5 

# --- MODIFIER ENGINE SETTINGS ---
@export_group("Modifier Stacking")
@export var max_modifiers: int = 1            # Set to 2 or 3 to allow Double/Triple effects!
@export var multiple_mod_chance: float = 0.25 # 25% chance to KEEP rolling for another mod if they already got one

@export_group("Modifier Chances (0.0 to 1.0)")
@export var chance_elite: float = 0.05       # 5% chance
@export var chance_fast: float = 0.15        # 15% chance
@export var chance_shielded: float = 0.10    # 10% chance
@export var chance_exploding: float = 0.08   # 8% chance
@export var chance_splitting: float = 0.05   # 5% chance
@export var chance_erratic: float = 0.12     # 12% chance (Weird movement)
@export var chance_ghost: float = 0.05       # 5% chance (Intangible)
# --------------------------------

@onready var spawn_timer: Timer = $SpawnTimer
var time_elapsed: float = 0.0

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _process(delta: float) -> void:
	time_elapsed += delta

func _on_spawn_timer_timeout() -> void:
	if not player or enemy_scenes.is_empty():
		return
		
	var current_enemy_count = get_tree().get_nodes_in_group("enemy").size()
	if current_enemy_count >= max_enemies_on_screen:
		return
		
	spawn_enemy_cluster()

func spawn_enemy_cluster() -> void:
	var current_wave_count = base_spawn_count + int(time_elapsed / 60.0 * difficulty_scale_rate * 10.0)
	
	var base_angle: float = randf_range(0.0, TAU)
	var base_distance: float = randf_range(min_spawn_distance, max_spawn_distance)
	var cluster_center: Vector2 = player.global_position + (Vector2.RIGHT.rotated(base_angle) * base_distance)
	
	for i in range(current_wave_count):
		var random_scene = enemy_scenes.pick_random()
		if random_scene == null:
			continue
			
		var enemy = random_scene.instantiate()
		
		# Apply the dynamic effects before adding it to the world
		apply_random_modifiers(enemy)
		
		var random_cluster_offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
		enemy.global_position = cluster_center + random_cluster_offset
		
		enemy.add_to_group("enemy")
		get_tree().current_scene.add_child(enemy)

# ==========================================
# MODIFIER ENGINE
# ==========================================
func apply_random_modifiers(enemy: Node2D):
	# 1. Package all chances into a dictionary
	var available_mods = {
		"elite": chance_elite,
		"fast": chance_fast,
		"shielded": chance_shielded,
		"exploding": chance_exploding,
		"splitting": chance_splitting,
		"erratic": chance_erratic,
		"ghost": chance_ghost
	}
	
	# 2. Shuffle the names so the engine doesn't always check "elite" first
	var mod_names = available_mods.keys()
	mod_names.shuffle()
	
	var mods_applied = 0
	
	# 3. Roll the dice for every modifier
	for mod in mod_names:
		if mods_applied >= max_modifiers:
			break
			
		# If we already applied a mod, roll a chance to see if we are allowed to stack another one
		if mods_applied > 0 and randf() > multiple_mod_chance:
			break
			
		# Roll against this specific modifier's chance
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
			target_color = Color(1.0, 0.3, 0.3) # Crimson Red
			
		"fast":
			enemy.scale *= 0.8
			if "speed" in enemy: enemy.speed *= 1.8
			target_color = Color(1.0, 1.0, 0.3) # Bright Yellow
			
		"shielded":
			if "max_health" in enemy: enemy.max_health *= 4.0
			if "speed" in enemy: enemy.speed *= 0.6
			if "knockback_decay" in enemy: enemy.knockback_decay *= 3.0 # Unstoppable tank
			target_color = Color(0.4, 0.6, 1.0) # Ice Blue
			
		"exploding":
			# .set() forces the variable onto the enemy even if it's not declared yet
			enemy.set("is_exploding", true) 
			target_color = Color(1.0, 0.5, 0.0) # Orange
			
		"splitting":
			enemy.set("is_splitting", true)
			target_color = Color(0.8, 0.3, 1.0) # Purple
			
		"erratic":
			enemy.set("is_erratic", true)
			if "speed" in enemy: enemy.speed *= 1.2
			target_color = Color(0.3, 1.0, 0.3) # Toxic Green
			
		"ghost":
			enemy.set("is_ghost", true)
			target_color = Color(0.8, 0.8, 0.8) # Pale Gray
			enemy.modulate.a = 0.5 # Translucent
			
	# Ensure current health updates to match new max health
	if "current_health" in enemy and "max_health" in enemy:
		enemy.current_health = enemy.max_health
		
	# Blend colors if the enemy got multiple modifiers!
	if enemy.modulate == Color.WHITE:
		enemy.modulate = target_color
	else:
		# lerp blends the previous color with the new color 50/50
		enemy.modulate = enemy.modulate.lerp(target_color, 0.5)
