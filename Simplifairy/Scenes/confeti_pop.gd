extends CPUParticles2D

func _ready() -> void:
	emitting = true
	# Wait for the particles to finish falling, then delete the node
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()
