extends TextureButton # (Change this to 'extends TextureButton' if you are using a TextureButton!)

@export_file("*.tscn") var next_scene_path: String # This creates a folder icon in the inspector to easily pick your game scene!
@onready var click_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var base_scale: Vector2
var anim_tween: Tween

func _ready() -> void:
	# Wait one frame for the UI to lay itself out perfectly
	await get_tree().process_frame
	
	# Set the pivot to the dead center of the button so it scales from the middle!
	pivot_offset = size / 2.0
	base_scale = scale
	
	# Connect the hover and click signals dynamically
	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)
	pressed.connect(_on_pressed)

func _on_hover_in() -> void:
	# Don't play hover animations if we already clicked it!
	if disabled: return
	
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()
		
	anim_tween = create_tween()
	# Scale up by 10%
	anim_tween.tween_property(self, "scale", base_scale * 1.1, 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_hover_out() -> void:
	if disabled: return
	
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()
		
	anim_tween = create_tween()
	# Return to normal size
	anim_tween.tween_property(self, "scale", base_scale, 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_pressed() -> void:
	# 2. Play the "squish" click animation
	if anim_tween and anim_tween.is_valid():
		anim_tween.kill()
		
	anim_tween = create_tween()
	anim_tween.tween_property(self, "scale", base_scale * 0.9, 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 3. Play the sound and wait for it to finish!
	if click_sound and click_sound.stream:
		click_sound.play()
		# This line pauses the script until the audio finishes playing
		await click_sound.finished 
	else:
		# Failsafe: If you forgot to add a sound, just wait 0.2 seconds for the animation to play
		await get_tree().create_timer(0.2).timeout
