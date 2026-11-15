@tool
extends StaticBody2D

const ART = preload("res://scripts/art.gd")
const GEM = preload("res://art/toffeecraft/blue_gem.png")
const STRIP := Rect2(-56, -3, 112, 6)
const ACTIVE_SECONDS := 8.0
const RECHARGE_SECONDS := 3.5
var available := true
var remaining := ACTIVE_SECONDS
var mark: Label

func _ready() -> void:
	mark = ART.label("×2", 16, Color("#c7e2e5"))
	mark.add_theme_color_override("font_outline_color", ART.INK)
	mark.add_theme_constant_override("outline_size", 4)
	mark.position = Vector2(-20, -27)
	mark.size.x = 40
	add_child(mark)

func tick(dt: float, player_position: Vector2, bounds: Rect2) -> void:
	remaining -= dt
	if remaining <= 0.0:
		relocate(player_position, bounds)
	if remaining < 0.6:
		queue_redraw()

func relocate(player_position: Vector2, bounds: Rect2) -> void:
	var safe := bounds.grow(-145)
	var candidates: Array[Vector2] = []
	var farthest := safe.get_center()
	for i in 30:
		var trial := Vector2(randf_range(safe.position.x, safe.end.x), randf_range(safe.position.y, safe.end.y))
		if trial.distance_squared_to(position) > farthest.distance_squared_to(position):
			farthest = trial
		var distance := trial.distance_to(player_position)
		if distance > 205.0 and distance < 550.0 and trial.distance_to(position) > 190.0:
			candidates.append(trial)
	position = (candidates.pick_random() if not candidates.is_empty() else farthest).round()
	available = true
	remaining = ACTIVE_SECONDS
	mark.show()
	queue_redraw()

func clear_muzzle(point: Vector2, aim: Vector2, radius: float) -> Vector2:
	var local := point - position
	var protected := STRIP.grow(radius + 1)
	if not available or not protected.has_point(local):
		return point
	var side := signf(aim.y)
	if absf(aim.y) < 0.10:
		side = 1.0 if local.y >= 0.0 else -1.0
	return Vector2(point.x, position.y + side * protected.end.y)

func consume() -> void:
	available = false
	remaining = RECHARGE_SECONDS
	mark.hide()
	queue_redraw()

func _draw() -> void:
	if not available:
		return
	var opacity := lerpf(0.3, 1.0, clampf(remaining / 0.6, 0, 1))
	for x in range(-48, 49, 8):
		draw_rect(Rect2(x, -1, 5, 2), Color(0.66, 0.81, 0.80, opacity * 0.82))
	for x: float in [-56.0, 56.0]:
		draw_texture_rect(GEM, Rect2(x - 9, -9, 18, 18), false, Color(1, 1, 1, opacity))
