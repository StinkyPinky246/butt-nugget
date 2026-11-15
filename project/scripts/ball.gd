extends CharacterBody2D

const ART = preload("res://scripts/art.gd")
const SPEED := 755.0
const RETURN_SPEED := 620.0
const CATCH_RADIUS := 26.0
const RADIUS := 14.0
const FLIGHT_IMPACTS := 8
const FLIGHT_LIMIT := 7.0
var game: Node2D
var damage := 1
var impacts := 0
var age := 0.0
var has_split := false
var returning := false
var spent := false
var trail := PackedVector2Array()
@onready var visual: AnimatedSprite2D = $Egg
var number: Label
var squash := 0.0
var pop: Tween

func _ready() -> void:
	collision_layer = 0
	collision_mask = 3
	z_index = 5
	var hitbox := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	hitbox.shape = circle
	add_child(hitbox)
	visual.rotation = velocity.angle()
	number = ART.label(str(damage), 22, Color("#382621"))
	number.add_theme_font_override("font", ART.BOLD_FONT)
	number.z_index = 1
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.add_theme_color_override("font_outline_color", Color("#fff0d1"))
	number.add_theme_constant_override("outline_size", 4)
	number.position = Vector2(-30, -19)
	number.size = Vector2(60, 36)
	number.pivot_offset = Vector2(30, 18)
	add_child(number)

func tick(dt: float) -> void:
	if spent:
		return
	age += dt
	squash = move_toward(squash, 0.0, dt * 7.5)
	trail.append(global_position)
	if trail.size() > 5:
		trail.remove_at(0)
	if returning:
		home(dt)
		if spent:
			return
	else:
		collision_mask = 7 if game.multiplier_enabled and game.arena.gate.available else 3
		var remaining := dt * SPEED
		for step in 4:
			var collision := move_and_collide(velocity.normalized() * remaining, false, 0.04)
			if not collision:
				break
			var normal := collision.get_normal()
			remaining = collision.get_remainder().length()
			position += normal * 0.2
			if velocity.dot(normal) >= -0.01:
				break
			var incoming_heading := velocity.angle()
			velocity = velocity.bounce(normal)
			impact(collision, incoming_heading)
			if remaining < 0.1 or returning:
				break
		if impacts >= FLIGHT_IMPACTS or age >= FLIGHT_LIMIT:
			finish_flight()
	visual.rotation = velocity.angle()
	visual.scale = Vector2(3.0 - squash * 0.55, 3.0 + squash * 0.35)
	queue_redraw()

func impact(collision: KinematicCollision2D, incoming_heading: float) -> void:
	impacts += 1
	squash = 1
	var body := collision.get_collider()
	if body.is_in_group("enemies"):
		if not body.dead:
			body.take_hit(damage, -collision.get_normal())
			game.egg_impact(collision.get_position() + collision.get_normal() * 8, incoming_heading)
			game.hit_marker(collision.get_position(), body.dead)
	elif body.is_in_group("multiplier_field"):
		if not has_split and game.arena.gate.available:
			game.split_ball(self, collision.get_normal())
	else:
		damage += 1 + game.upgrade_level(game.Upgrade.BOUNCE_BOOST)
		game.sound("bounce")
		game.shake = maxf(game.shake, minf(damage * 0.18, 1.5))
	game.highest_damage = maxi(game.highest_damage, damage)
	number.text = str(damage)
	if damage >= 4:
		number.add_theme_color_override("font_color", Color("#702513"))
	if pop:
		pop.kill()
	number.scale = Vector2.ONE * 1.22
	pop = create_tween()
	pop.tween_property(number, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func finish_flight() -> void:
	if spent:
		return
	if game.returns_enabled:
		begin_return()
		return
	spent = true
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.12)
	fade.tween_callback(queue_free)

func begin_return() -> void:
	if returning:
		return
	returning = true
	visual.self_modulate = Color(1.28, 1.38, 1.38)

func home(dt: float) -> void:
	var target: Vector2 = game.player.position
	var previous := position
	position = position.move_toward(target, RETURN_SPEED * dt)
	velocity = (position - previous) / dt
	if position.distance_squared_to(target) <= CATCH_RADIUS ** 2:
		spent = true
		game.collect_ball(position)
		queue_free()

func _draw() -> void:
	var tint := ART.ICE if returning else ART.PAPER
	for i in range(0, trail.size(), 2):
		var weight := float(i + 1) / trail.size()
		var point := (trail[i] - global_position).round()
		var size := 2.0 if i == 0 else 4.0
		draw_rect(Rect2(point - Vector2.ONE * (size / 2), Vector2.ONE * size), Color(tint, weight * 0.43))
