extends CanvasLayer

signal story_finished

@onready var background_dim: ColorRect = $Background
@onready var dialogue_label: Label = $Background/DialogueLabel

# The 4 dialogue lines
@export_multiline var dialogues: Array[String] = [
	"Hello there! I am your trainer, and with me you will acquire your fairy's diploma!",
	"You see, over here at Fairy Academy, we keep things simple.",
	"We have a rule: A real professional fairy needs to be able to survive even when things get tricky, with minimal equipment.",
	"In order to get the paper, survive  all the waves. After each wave, however, you will be given a simplification.",
	"Basically, each time, one of your 'training wheels' will be removed, until you can survive all on your own.",
	"You know the drill: move with wasd/arrow keys, hold down to shoot and press space/shift to dash.",
	"Good luck on becoming a Simplifairy!"
]

@export var characters_per_second: float = 35.0

var current_index: int = 0
var type_tween: Tween
var is_typing: bool = false

func _ready() -> void:
	show_current_dialogue()

func show_current_dialogue() -> void:
	if current_index >= dialogues.size():
		finish_and_fade_out()
		return
	
	var text_to_show = dialogues[current_index]
	dialogue_label.text = text_to_show
	
	# Start with zero visible characters
	dialogue_label.visible_characters = 0
	is_typing = true
	
	# Kill any previous running typewriter tween
	if type_tween and type_tween.is_valid():
		type_tween.kill()
		
	# Calculate duration based on character count
	var duration: float = float(text_to_show.length()) / characters_per_second
	
	# Animate the visible character count property
	type_tween = create_tween()
	type_tween.tween_property(dialogue_label, "visible_characters", text_to_show.length(), duration)
	type_tween.finished.connect(func(): is_typing = false)

func _on_skip_button_pressed() -> void:
	# If text is still typing, finish it instantly on the first click
	if is_typing:
		if type_tween and type_tween.is_valid():
			type_tween.kill()
		dialogue_label.visible_characters = dialogue_label.text.length()
		is_typing = false
		return

	# Move to the next dialogue entry
	current_index += 1
	
	if current_index < dialogues.size():
		show_current_dialogue()
	else:
		finish_and_fade_out()

func finish_and_fade_out() -> void:
	# Disable the button to prevent double clicks during fade
	$Background/SkipButton.disabled = true
	# Smoothly fade out the canvas layer modulate alpha
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "offset:y", -30.0, 0.6).set_trans(Tween.TRANS_SINE) # subtle slide up
	fade_tween.parallel().tween_property(background_dim, "modulate:a", 0.0, 0.6)
	
	# Emit signal and free node when fade finishes
	fade_tween.finished.connect(func():
		story_finished.emit()
		queue_free()
	)
