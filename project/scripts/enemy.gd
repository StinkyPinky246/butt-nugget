extends CharacterBody2D

const ART = preload("res://scripts/art.gd")
enum Kind { BLOOD, DEMON, SKULL, SLIME, TRIDENT, KNIGHT, TANK }
const ATTACK_DURATION := 0.70
const STRIKE_TIME := 0.36
const SPAWN_CLEARANCE := 195.0
const KNIGHT_SWING_SPEED := 0.78
const KNIGHT_ATTACKS := [
	[&"sweep", 102.0, 0.25, 3],
	[&"rising_slash", 86.0, 0.42, 3],
	[&"overhead_slam", 122.0, 0.65, 4],
]

var game: Node2D
var sprite := AnimatedSprite2D.new()
var kind := Kind.BLOOD
var knight_boss := false
var hp := 3
var max_hp := 3
var dead := false
var speed := 104.0
var radius := 19.0
var knockback := Vector2.ZERO
var flash: Tween
var spawn_warning := 0.0
var attack_animation: StringName
var attack_range := 0.0
var attack_left := 0.0
var attack_cooldown := 0.0
var attack_direction := Vector2.RIGHT
var attack_duration := ATTACK_DURATION
var strike_time := STRIKE_TIME
var attack_facing := 0.15
var knight_attack_index := 0
var stride := 0.0

func is_boss() -> bool:
	return knight_boss or kind == Kind.SKULL

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 0
	collision_mask = 0
	var body := CollisionShape2D.new()
	var disk := CircleShape2D.new()
	disk.radius = radius
	body.shape = disk
	add_child(body)
	sprite.material = ART.character_outline()
	sprite.sprite_frames = game.enemy_frames[kind]
	var sprite_scale := 2.5
	if knight_boss:
		sprite_scale = 1.90
		prepare_knight_attack()
	elif kind == Kind.SKULL:
		sprite_scale = 4.2
	elif kind >= Kind.SLIME:
		sprite_scale = 0.90 if kind < Kind.KNIGHT else 1.08
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.position.y = -10 if is_boss() else -6
	add_child(sprite)
	if spawn_warning <= 0.0:
		activate()
	else:
		sprite.hide()

func activate() -> void:
	spawn_warning = 0.0
	collision_layer = 2
	sprite.show()
	sprite.play("walk")
	game.burst(position, Color("#d4bc9a"), 5)
	if is_boss():
		game.start_boss(self)

func prepare_knight_attack() -> void:
	var move: Array = KNIGHT_ATTACKS[knight_attack_index]
	attack_animation = move[0]
	attack_range = move[1]
	attack_facing = move[2]
	var frames_per_second := sprite.sprite_frames.get_animation_speed(attack_animation) * KNIGHT_SWING_SPEED
	attack_duration = sprite.sprite_frames.get_frame_count(attack_animation) / frames_per_second
	strike_time = move[3] / frames_per_second

func tick(dt: float, separation: Vector2) -> void:
	if dead:
		return
	if spawn_warning > 0.0:
		spawn_warning -= dt
		if spawn_warning <= 0.0:
			if position.distance_to(game.player.position) < SPAWN_CLEARANCE:
				position = game.waves.spawn_position()
				spawn_warning = game.waves.SPAWN_WARNING
			else:
				activate()
		queue_redraw()
		return

	attack_cooldown = maxf(0.0, attack_cooldown - dt)
	stride += dt
	if attack_left > 0.0:
		tick_attack(dt)
		queue_redraw()
		return

	var to_player: Vector2 = position.direction_to(game.player.position)
	var travel := to_player
	var travel_speed := speed
	if kind == Kind.SLIME:
		travel_speed *= 1.0 + 0.17 * sin(stride * 10.0)
	elif kind == Kind.TRIDENT:
		travel = (to_player + to_player.orthogonal() * sin(stride * 3.8) * 0.48).normalized()
		sprite.position.y = -8.0 + 2.5 * sin(stride * 9.0)
	position = game.arena.clamp_center(position + (travel * travel_speed + separation + knockback) * dt, radius + 1)
	knockback = knockback.move_toward(Vector2.ZERO, 1250 * dt)
	if absf(to_player.x) > 0.02:
		sprite.flip_h = to_player.x < 0
	if not sprite.is_playing():
		sprite.play("walk")
	var distance := position.distance_to(game.player.position)
	if attack_range > 0.0:
		if attack_cooldown <= 0.0 and distance <= attack_range:
			attack_left = attack_duration
			attack_direction = to_player
			sprite.play(attack_animation, KNIGHT_SWING_SPEED if knight_boss else 1.0)
	elif distance < radius + 15:
		game.hurt_player()
	queue_redraw()

func tick_attack(dt: float) -> void:
	var before := attack_left
	attack_left = maxf(0.0, attack_left - dt)
	var moment := attack_duration - strike_time
	if before > moment and attack_left <= moment:
		var offset: Vector2 = game.player.position - position
		if knight_boss:
			game.shake = maxf(game.shake, 3.4 if attack_animation == &"overhead_slam" else 1.7)
			game.sound("knight_swing")
		if offset.length() <= attack_range + (0.0 if knight_boss else 5.0) and (
			offset.is_zero_approx() or attack_direction.dot(offset.normalized()) >= attack_facing
		):
			game.hurt_player()
	if attack_left == 0.0:
		attack_cooldown = 0.44 if knight_boss else 0.65
		if knight_boss:
			knight_attack_index = (knight_attack_index + 1) % KNIGHT_ATTACKS.size()
			prepare_knight_attack()
		sprite.play("walk")

func take_hit(amount: int, direction: Vector2) -> void:
	if dead or spawn_warning > 0.0:
		return
	if attack_left > 0.0 and not knight_boss:
		attack_left = 0.0
		attack_cooldown = 0.65
	hp -= amount
	knockback += direction * (85 if is_boss() else 210)
	game.float_text(position + Vector2(0, -34), str(amount), ART.GOLD if amount > 3 else ART.PAPER)
	game.burst(position, Color("#d4a492"), 4)
	if hp <= 0:
		dead = true
		set_deferred("collision_layer", 0)
		sprite.self_modulate = Color.WHITE
		if flash:
			flash.kill()
		sprite.play("death")
		game.enemy_defeated(self)
		queue_redraw()
		var fade := create_tween()
		fade.tween_interval(0.50 if knight_boss else (0.40 if kind >= Kind.SLIME else 0.22))
		fade.tween_property(self, "modulate:a", 0, 0.17)
		if kind == Kind.SKULL:
			fade.parallel().tween_property(sprite, "scale", sprite.scale * 0.75, 0.17)
		fade.tween_callback(queue_free)
		return
	game.sound("hit")
	if attack_left <= 0.0:
		sprite.play("hurt")
	if flash:
		flash.kill()
	sprite.self_modulate = Color(1.75, 1.75, 1.75) if knight_boss else Color(3.2, 3.2, 3.2)
	flash = create_tween()
	flash.tween_property(sprite, "self_modulate", Color.WHITE, 0.19)

func _draw() -> void:
	if dead:
		return
	if spawn_warning > 0.0:
		var color := Color(1.0, 0.64, 0.36, 0.5 + 0.35 * sin(spawn_warning * 17.0))
		draw_arc(Vector2.ZERO, radius + 8, 0, TAU, 24, color, 2.5)
		draw_line(Vector2(-5, 0), Vector2(5, 0), color, 2.0)
		draw_line(Vector2(0, -5), Vector2(0, 5), color, 2.0)
		return
	if attack_left > attack_duration - strike_time:
		var direction := attack_direction.angle()
		var spread := acos(attack_facing) if knight_boss else 0.85
		var warning := Color(1.0, 0.64, 0.36, 0.82)
		draw_arc(Vector2.ZERO, attack_range, direction - spread, direction + spread, 24, warning, 3.0 if knight_boss else 2.0)
		if knight_boss:
			for edge in [direction - spread, direction + spread]:
				var ray := Vector2.from_angle(edge)
				draw_line(ray * (attack_range - 15), ray * attack_range, warning, 3.0)
	var accent := Color("#ff5c89") if kind == Kind.BLOOD else Color("#ffab65")
	draw_set_transform(Vector2(0, 15), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, radius + 4, Color(0.02, 0.03, 0.08, 0.65))
	draw_set_transform(Vector2.ZERO)
	if hp < max_hp and not is_boss():
		draw_rect(Rect2(-17, -28, 34, 4), Color("#121527"))
		draw_rect(Rect2(-17, -28, 34.0 * hp / max_hp, 4), accent)
