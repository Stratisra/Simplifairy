extends Area2D

@export var speed: float = 400.0
@export var damage: float = 10.0

var has_aoe: bool = true
var aoe_radius: float = 60.0

var has_tracking: bool = true
var tracking_strength: float = 4.0
var tracking_range: float = 500.0
var current_target: Node2D = null

var is_exploding: bool = false
@onready var sprite: Node2D = $Sprite2D

func _physics_process(delta: float) -> void:
	if not is_exploding:
		if has_tracking:
			steer_towards_target(delta)
		position += transform.x * speed * delta

func steer_towards_target(delta: float):
	if not is_instance_valid(current_target):
		current_target = find_closest_forward_enemy()
		
	if is_instance_valid(current_target):
		var direction_to_target = global_position.direction_to(current_target.global_position)
		var target_angle = direction_to_target.angle()
		rotation = lerp_angle(rotation, target_angle, tracking_strength * delta)

func find_closest_forward_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest_enemy = null
	var min_distance = tracking_range
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < min_distance:
				var direction_to_enemy = global_position.direction_to(enemy.global_position)
				if transform.x.dot(direction_to_enemy) > 0.4:
					min_distance = distance
					closest_enemy = enemy
					
	return closest_enemy

# --- COLLISION LOGIC ---
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or is_exploding:
		return
	
	if has_aoe:
		explode()
	else:
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position, 150.0)
		queue_free()

func explode():
	is_exploding = true
	
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			if global_position.distance_to(enemy.global_position) <= aoe_radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage, global_position, 200.0)
			
	if sprite:
		var tween = create_tween()
		tween.set_parallel(true)
		sprite.modulate = Color(4.0, 3.0, 1.0, 1.0)
		tween.tween_property(sprite, "scale", Vector2(aoe_radius/10.0, aoe_radius/10.0), 0.15)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tween.set_parallel(false) 
		tween.tween_callback(queue_free)
	else:
		queue_free()

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	if not is_exploding:
		queue_free()
