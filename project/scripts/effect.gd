extends Node2D

var tint: Color
var duration := 0.23
var age := 0.0
var hit_marker := false
var particles := PackedVector2Array()

func _process(dt: float) -> void:
	age += dt
	if age >= duration:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress := age / duration
	var fade := 1.0 - progress
	if hit_marker:
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var start: Vector2 = corner * (4.0 + progress * 5.0)
			var end: Vector2 = corner * (10.0 + progress * 5.0)
			draw_line(start, end, Color(0.04, 0.05, 0.08, fade), 5)
			draw_line(start, end, Color(tint, fade), 2)
	for impulse in particles:
		var point := impulse * progress * (1.6 - 0.6 * progress)
		var width := 1 + floorf(2 * fade)
		draw_rect(Rect2(point.round(), Vector2(width, width)), Color(tint, fade))
