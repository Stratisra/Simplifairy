extends Area2D

@export var speed: float = 400.0
@export var damage: float = 10.0

var has_aoe: bool = true
var aoe_radius: float = 60.0

@onready var sprite: Node2D = $Sprite2D 

var is_exploding: bool = false

func _physics_process(delta: float) -> void:
	if not is_exploding:
		position += transform.x * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# Ignore the player, and prevent multiple enemies triggering this on the exact same frame
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
	queue_redraw() # Draw the orange debug circle
	
	# 1. Math-based AoE (Zero delay, 100% reliable)
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	var hit_count = 0
	
	for enemy in all_enemies:
		# is_instance_valid prevents crashes if an enemy died a millisecond ago
		if is_instance_valid(enemy):
			# If the enemy is within the radius, damage them!
			if global_position.distance_to(enemy.global_position) <= aoe_radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage, global_position, 200.0)
					hit_count += 1
					
	print("Explosion hit ", hit_count, " enemies!")
			
	# 2. Visual Explosion Juice
	if sprite:
		var tween = create_tween()
		tween.set_parallel(true)
		sprite.modulate = Color(4.0, 3.0, 1.0, 1.0)
		
		# Scale up the bullet sprite to look like a blast
		tween.tween_property(sprite, "scale", Vector2(aoe_radius/10.0, aoe_radius/10.0), 0.15)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
		
		tween.set_parallel(false) 
		tween.tween_callback(queue_free)
	else:
		queue_free()

# Debug drawing so you can physically see the blast radius
func _draw():
	if is_exploding:
		draw_circle(Vector2.ZERO, aoe_radius, Color(1.0, 0.5, 0.0, 0.5))
