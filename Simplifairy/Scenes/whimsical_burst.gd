extends Node2D

func _ready() -> void:
	# Ensure both children emit once loaded
	if $ConfetiPop: $ConfetiPop.emitting = true
	if $StarPop: $StarPop.emitting = true
	
	# Find the child with the longest lifetime (Confetti is 0.8s)
	# and wait for that before deleting the combined scene.
	var longest_lifetime = 0.0
	for child in get_children():
		if child is CPUParticles2D and child.lifetime > longest_lifetime:
			longest_lifetime = child.lifetime
			
	await get_tree().create_timer(longest_lifetime + 0.1).timeout
	queue_free()
