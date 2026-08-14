extends CharacterBody2D

@export_group("Movement")
@export var speed: float = 200.0
@export var friction: float = 0.1
@export var acceleration: float = 0.1

@export_group("Procedural Animation")
@export var sprite: AnimatedSprite2D 
@export var tilt_amount: float = 0.15
@export var tilt_speed: float = 15.0
@export var bounce_amount: float = 4.0
@export var bounce_speed: float = 15.0

@export_group("Combat / Wand")
@export var projectile_scene: PackedScene # Drag magic_bullet.tscn here!
@export var wand_pivot: Node2D
@export var muzzle: Marker2D
@export var wand_sprite: Sprite2D
@export var auto_shoot: bool = true # Toggle between Vampire Survivors auto-fire or click-to-shoot

var time_moving: float = 0.0
var base_sprite_y: float = 0.0

func _ready():
	if sprite:
		base_sprite_y = sprite.position.y

func get_input():
	var input = Vector2.ZERO
	if Input.is_action_pressed('right'):
		input.x += 1
	if Input.is_action_pressed('left'):
		input.x -= 1
	if Input.is_action_pressed('down'):
		input.y += 1
	if Input.is_action_pressed('up'):
		input.y -= 1
	return input

func _physics_process(delta):
	var direction = get_input()
	
	# 1. Physics & Movement
	if direction.length() > 0:
		velocity = velocity.lerp(direction.normalized() * speed, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
		
	move_and_slide()
	
	# 2. Aiming & Mouse Flipping
	var mouse_pos = get_global_mouse_position()
	
	if sprite:
		# Flip character body towards mouse position
		sprite.flip_h = mouse_pos.x < global_position.x
	
	if wand_pivot:
		# Point wand at mouse
		wand_pivot.look_at(mouse_pos)
		
		# Prevent the wand from rendering upside down when aiming left
		if wand_sprite:
			wand_sprite.flip_v = mouse_pos.x < global_position.x

	# 3. Manual Click Shooting (if auto_shoot is turned off)
	if not auto_shoot and Input.is_action_just_pressed("shoot"):
		shoot()

	# 4. Procedural Movement Animation (Wobble & Bounce)
	if sprite:
		if velocity.length() > 10.0:
			time_moving += delta
			sprite.rotation = sin(time_moving * tilt_speed) * tilt_amount
			sprite.position.y = base_sprite_y - abs(sin(time_moving * bounce_speed)) * bounce_amount
		else:
			time_moving = 0.0
			sprite.rotation = lerp_angle(sprite.rotation, 0.0, 0.2)
			sprite.position.y = lerp(sprite.position.y, base_sprite_y, 0.2)

func shoot():
	if projectile_scene and muzzle:
		var bullet = projectile_scene.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.rotation = wand_pivot.rotation
		
		# Add bullet to root scene tree so it moves independently of player
		get_tree().current_scene.add_child(bullet)

# Connect ShootTimer timeout signal here for Vampire Survivors auto-firing
func _on_shoot_timer_timeout():
	if auto_shoot:
		shoot()
