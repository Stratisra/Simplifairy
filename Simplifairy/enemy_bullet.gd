extends Area2D

@export var speed: float = 250.0
@export var damage: float = 10.0

func _physics_process(delta: float) -> void:
	# Move forward based on its rotation
	position += transform.x * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# Ignore other enemies! Only hit the player.
	if body.is_in_group("enemy"):
		return
		
	# If it hits the player, hurt them
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		
	# Delete the bullet on impact with a wall or player
	queue_free()

# (Optional) Connect a VisibleOnScreenNotifier2D 'screen_exited' signal here to delete it when it goes off-screen!
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
