extends Area2D

@export var tick_rate: float = 0.5
@export var lifetime: float = 4.0

var tick_timer: Timer

func _ready():
	# 1. Setup Damage Tick Timer
	tick_timer = Timer.new()
	tick_timer.wait_time = tick_rate
	tick_timer.autostart = true
	add_child(tick_timer)
	tick_timer.timeout.connect(_on_tick)
	
	# 2. Setup visual fade out (burns bright, then fades the last 1 second)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, lifetime - 1.0)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func _on_tick():
	# get_overlapping_bodies() handles players standing inside the fire perfectly
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			# We will hook this up to player health later!
			print("Player is burning!")
