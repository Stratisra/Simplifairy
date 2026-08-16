extends ProgressBar

@export var delay_before_fade: float = 2.0   # Seconds to wait after taking damage
@export var fade_duration: float = 0.5       # How long the fade animation takes
@export var faded_opacity: float = 0.3       # 0.0 is invisible, 1.0 is fully solid

var fade_timer: Timer
var fade_tween: Tween

func _ready() -> void:
	# 1. Create a timer in code to track how long since we last took damage
	fade_timer = Timer.new()
	fade_timer.one_shot = true
	fade_timer.wait_time = delay_before_fade
	add_child(fade_timer)
	fade_timer.timeout.connect(_on_fade_timer_timeout)
	
	# 2. Tell the bar to listen to its own value changing!
	value_changed.connect(_on_value_changed)
	
	# Start the game with the bar already faded
	modulate.a = faded_opacity

func _on_value_changed(_new_value: float) -> void:
	# WAKE UP! The player took damage!
	
	# 1. Stop any fading that is currently happening
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		
	# 2. Instantly make the bar fully solid and visible
	modulate.a = 1.0
	
	# 3. Restart the countdown timer
	fade_timer.start()

func _on_fade_timer_timeout() -> void:
	# The timer finished, time to go back to sleep.
	
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		
	# Smoothly animate the opacity back down to the faded amount
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", faded_opacity, fade_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
