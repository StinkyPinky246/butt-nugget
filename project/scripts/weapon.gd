extends Node2D

@onready var sprite: AnimatedSprite2D = $Launcher
@onready var muzzle: Marker2D = $Muzzle
var recoil: Tween

func _ready() -> void:
	sprite.animation_finished.connect(func(): sprite.play("idle"))
	sprite.play("idle")

func aim(direction: Vector2) -> void:
	position = direction * 24 + Vector2(0, -4)
	rotation = direction.angle()
	if absf(direction.x) > 0.13:
		sprite.flip_v = direction.x < 0

func fire() -> void:
	sprite.stop()
	sprite.play("shot")
	if recoil:
		recoil.kill()
	sprite.position.x = -3.0
	recoil = create_tween()
	recoil.tween_property(sprite, "position:x", 0.0, 0.10).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
