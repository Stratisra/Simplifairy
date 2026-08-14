extends Area2D

@export var speed: float = 400.0
@export var damage: float = 10.0

func _physics_process(delta: float) -> void:
	# Move forward in the direction the projectile is rotated
	position += transform.x * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Delete the bullet when it leaves the screen
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	
	if body.has_method("take_damage"):
		# Passes: (damage_amount, bullet_position, knockback_force)
		body.take_damage(damage, global_position, 150.0)
	
	queue_free()
