extends Node2D
class_name DropShadow

@export var shadow_width: float = 30.0
@export var squash_amount: float = 0.35      # 1.0 is a perfect circle, lower is a flatter oval
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.4) # Semi-transparent black
@export var vertical_offset: float = 20.0    # Pushes the shadow down to the feet

func _ready() -> void:
	# 1. Force the shadow behind the parent sprite
	show_behind_parent = true
	
	# 2. Force the shadow onto the "floor" layer so it never renders over other objects!
	z_index = -1
	z_as_relative = false
	
	# 3. Apply the vertical push down
	position.y += vertical_offset

func _draw() -> void:
	# Squashes the canvas vertically to make the circle an oval
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, squash_amount))
	
	# Draw the actual circle
	draw_circle(Vector2.ZERO, shadow_width, shadow_color)

# This allows the shadow to update in the editor if you change variables
func _set(property: StringName, value: Variant) -> bool:
	if property in ["shadow_width", "squash_amount", "shadow_color", "vertical_offset"]:
		queue_redraw()
	return false
