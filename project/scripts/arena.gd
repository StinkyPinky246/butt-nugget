extends Node2D

const TILE_ORIGIN := Vector2(105, 93)
const TILE_COUNTS := Vector2i(45, 25)
const TILE_SIZE := 32
const WALL_RIM := 7.0
const AREA := Rect2(TILE_ORIGIN + Vector2.ONE * WALL_RIM,
	Vector2(TILE_COUNTS * TILE_SIZE) - Vector2.ONE * WALL_RIM * 2.0)
@onready var gate: Node2D = $MultiplierWall

func _ready() -> void:
	make_wall(Rect2(AREA.position - Vector2(40, 40), Vector2(AREA.size.x + 80, 40)))
	make_wall(Rect2(Vector2(AREA.position.x - 40, AREA.end.y), Vector2(AREA.size.x + 80, 40)))
	make_wall(Rect2(Vector2(AREA.position.x - 40, AREA.position.y), Vector2(40, AREA.size.y)))
	make_wall(Rect2(Vector2(AREA.end.x, AREA.position.y), Vector2(40, AREA.size.y)))

func make_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var hit := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	hit.shape = box
	body.position = rect.get_center()
	body.add_child(hit)
	add_child(body)

func clamp_center(point: Vector2, margin: float) -> Vector2:
	return point.clamp(AREA.position + Vector2.ONE * margin, AREA.end - Vector2.ONE * margin)
