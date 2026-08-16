extends Camera2D

@export_group("Dynamic Camera")
@export var look_ahead_factor: float = 0.2  # What percentage of the way to the mouse should we go? (0.2 = 20%)
@export var max_distance: float = 150.0     # The absolute maximum pixels the camera can shift
@export var smooth_speed: float = 8.0       # How snappy the camera is (higher = faster)

func _process(delta: float) -> void:
	# 1. Find the distance between the player (parent) and the mouse
	var mouse_pos = get_global_mouse_position()
	var player_pos = get_parent().global_position
	
	var direction_to_mouse = mouse_pos - player_pos
	
	# 2. Calculate where the camera WANTS to be
	var target_offset = direction_to_mouse * look_ahead_factor
	
	# 3. Clamp the distance so the camera doesn't fly infinitely far away
	target_offset = target_offset.limit_length(max_distance)
	
	# 4. Smoothly slide the camera's local position towards that target
	position = position.lerp(target_offset, smooth_speed * delta)
