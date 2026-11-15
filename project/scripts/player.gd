extends Node2D

@onready var sprite: AnimatedSprite2D = $Character
@onready var weapon: Node2D = $Weapon
var velocity := Vector2.ZERO
var aim := Vector2.RIGHT
var invulnerable := 0.0

func _ready() -> void:
	sprite.play("idle")

func tick(dt: float, arena: Node2D) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = velocity.move_toward(direction * 400, dt * (3600 if direction != Vector2.ZERO else 4600))
	position = arena.clamp_center(position + velocity * dt, 24)
	var target := global_position.direction_to(get_global_mouse_position())
	if target != Vector2.ZERO:
		aim = target
	if absf(direction.x) > 0:
		sprite.flip_h = direction.x < 0
	elif direction == Vector2.ZERO:
		sprite.flip_h = aim.x < 0
	weapon.aim(aim)
	invulnerable = maxf(0, invulnerable - dt)
	if sprite.animation != "hurt" or not sprite.is_playing():
		sprite.play("walk" if velocity.length_squared() > 800 else "idle")
	sprite.modulate.a = 0.48 if invulnerable > 0 and int(invulnerable * 16) % 2 == 0 else 1.0
	queue_redraw()

func hurt() -> void:
	invulnerable = 1.15
	sprite.play("hurt")
	var tint := create_tween()
	sprite.self_modulate = Color(2.8, 2.8, 2.8)
	tint.tween_property(sprite, "self_modulate", Color.WHITE, 0.23)

func _draw() -> void:
	draw_set_transform(Vector2(0, 18), 0, Vector2(1, 0.37))
	draw_circle(Vector2.ZERO, 23, Color(0.02, 0.03, 0.09, 0.8))
