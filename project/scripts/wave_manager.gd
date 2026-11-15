extends Node

const ENEMY = preload("res://scenes/enemy.tscn")
const KIND = preload("res://scripts/enemy.gd").Kind
const MAX_ACTIVE := 42
const SPAWN_WARNING := 0.72
const SAFE_DISTANCE := 410.0
const ROSTERS := [
	[KIND.BLOOD, KIND.SLIME, KIND.BLOOD, KIND.DEMON, KIND.SLIME, KIND.TRIDENT],
	[KIND.SLIME, KIND.DEMON, KIND.TRIDENT, KIND.BLOOD, KIND.KNIGHT, KIND.BLOOD],
	[KIND.SLIME, KIND.TRIDENT, KIND.KNIGHT, KIND.DEMON, KIND.TANK, KIND.BLOOD],
]
var game: Node2D
var wave := 0
var living := 0
var pending: Array[int] = []
var timer := 0.0

func advance() -> void:
	wave += 1
	timer = 0.24
	var count := mini(15 + (wave - 1) * 6, 84)
	var roster: Array = ROSTERS[mini(wave - 1, ROSTERS.size() - 1)]
	for i in count:
		var kind: int = roster[i % roster.size()]
		if wave == 10:
			if i == 4:
				kind = KIND.KNIGHT
			elif kind == KIND.KNIGHT:
				kind = KIND.TANK if i % 4 == 0 else KIND.TRIDENT
		elif wave % 5 == 0 and i == 4:
			kind = KIND.SKULL
		pending.append(kind)
	living = pending.size()

func tick(dt: float) -> void:
	if pending.is_empty():
		return
	timer -= dt
	var slots := MAX_ACTIVE - (living - pending.size())
	if timer <= 0 and slots > 0:
		for i in mini(3 if wave < 3 else 4, mini(slots, pending.size())):
			spawn(pending.pop_front(), SPAWN_WARNING)
		timer = 0.59 if wave == 1 else 0.44

func spawn(kind: int, warning := 0.0) -> void:
	var enemy := ENEMY.instantiate()
	enemy.game = game
	enemy.kind = kind
	enemy.spawn_warning = warning
	var bonus := maxi(0, wave - 1) + maxi(0, wave - 3)
	match kind:
		KIND.BLOOD:
			enemy.hp = 3 + bonus
			enemy.speed = 121 + minf(wave * 5, 87)
		KIND.DEMON:
			enemy.hp = 2 + bonus
			enemy.speed = 192 + minf(wave * 6, 83)
		KIND.SKULL:
			enemy.hp = 96 + (wave - 5) * 8
			enemy.speed = 143 + minf(wave * 3, 52)
			enemy.radius = 34
		KIND.SLIME:
			enemy.hp = 2 + bonus
			enemy.speed = 112 + minf(wave * 5, 58)
			enemy.radius = 16
			enemy.attack_animation = &"attack_01"
			enemy.attack_range = 45.0
		KIND.TRIDENT:
			enemy.hp = 2 + bonus
			enemy.speed = 147 + minf(wave * 5, 63)
			enemy.radius = 17
			enemy.attack_animation = &"attack_01"
			enemy.attack_range = 52.0
		KIND.KNIGHT:
			enemy.knight_boss = wave == 10
			enemy.hp = 230 if enemy.knight_boss else 5 + bonus
			enemy.speed = 215.0 if enemy.knight_boss else 111 + minf(wave * 5, 64)
			enemy.radius = 34.0 if enemy.knight_boss else 21.0
			enemy.attack_animation = &"sweep"
			enemy.attack_range = 65.0
		KIND.TANK:
			enemy.hp = 11 + bonus
			enemy.speed = 82 + minf(wave * 4, 57)
			enemy.radius = 25
			enemy.attack_animation = &"attack_02"
			enemy.attack_range = 60.0
	enemy.max_hp = enemy.hp
	enemy.position = spawn_position()
	game.enemies.add_child(enemy)

func spawn_position() -> Vector2:
	var area: Rect2 = game.arena.AREA.grow(-66)
	var player_position: Vector2 = game.player.position
	var velocity: Vector2 = game.player.velocity
	var forward: Vector2 = velocity.normalized() if velocity.length_squared() > 3600.0 else game.player.aim
	var future_position: Vector2 = game.arena.clamp_center(player_position + velocity * 0.55, 25.0)
	var active: Array[Node] = game.enemies.get_children()
	var corners := [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]
	var best: Vector2 = corners[0]
	for corner: Vector2 in corners:
		if corner.distance_squared_to(player_position) > best.distance_squared_to(player_position):
			best = corner
	var best_score := -INF
	for i in range(28):
		var point: Vector2
		if i < corners.size():
			point = corners[i]
		else:
			var x := randf_range(area.position.x, area.end.x)
			var y := randf_range(area.position.y, area.end.y)
			match i % 4:
				0: point = Vector2(x, area.position.y + randf_range(0, 160))
				1: point = Vector2(area.end.x - randf_range(0, 160), y)
				2: point = Vector2(x, area.end.y - randf_range(0, 160))
				_: point = Vector2(area.position.x + randf_range(0, 160), y)
		var offset := point - player_position
		var distance := offset.length()
		if distance < SAFE_DISTANCE or point.distance_to(future_position) < 330.0:
			continue
		var front := forward.dot(offset / distance)
		if front > 0.75 and distance < 620.0:
			continue
		var spacing := 108.0
		for other in active:
			if not other.dead:
				spacing = minf(spacing, point.distance_to(other.position))
		var score := spacing - absf(distance - 475.0) * 0.26 - maxf(front, 0.0) * 95.0 + randf_range(0, 34)
		if score > best_score:
			best = point
			best_score = score
	return best
