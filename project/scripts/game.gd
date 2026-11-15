extends Node2D

const ART = preload("res://scripts/art.gd")
const BALL = preload("res://scenes/ball.tscn")
const EGG_IMPACT = preload("res://scenes/egg_impact.tscn")
const EFFECT = preload("res://scripts/effect.gd")
const BOSS_MUSIC = preload("res://art/audio/ritual.mp3")
const SKULL_FRAMES = preload("res://art/characters/skull/skull_boss.tres")
const ARENA_MUSIC_VOLUME := -13.5
const BOSS_MUSIC_VOLUME := -17.0
const UPGRADE_LIMITS := [5, 5, 5, 4]
const UPGRADES_PER_WAVE := 3
const MAX_BALLS := 480
enum Upgrade { EXTRA_BALL, POWER, BOUNCE_BOOST, QUICK_SHOT, PATCH_UP }
const MAX_WAVE_SELECT := 9999
enum State { TITLE, PLAY, CLEAR, UPGRADES, PAUSE, DYING, OVER, WAVE_SELECT }

@export_group("Optional mechanics")
@export var upgrades_enabled := true
@export var returns_enabled := false
@export var multiplier_enabled := false

var state := State.TITLE
var state_before_wave_select := State.TITLE
var overlay_before_wave_select := ""
@onready var world: Node2D = $World
@onready var enemies: Node2D = $World/Enemies
@onready var balls: Node2D = $World/Balls
@onready var effects: Node2D = $World/Effects
@onready var arena: Node2D = $World/Arena
@onready var player: Node2D = $World/Player
@onready var waves: Node = $WaveManager
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $World/Camera2D
var elite: CharacterBody2D
var enemy_frames: Array[SpriteFrames]
var hearts := 3
var levels := [0, 0, 0, 0]
var upgrade_offer: Array[int] = []
var previous_upgrade_offer: Array[int] = []
var kills := 0
var highest_damage := 0
var score := 0
var run_time := 0.0
var cooldown := 0.0
var transition := 0.0
var shake := 0.0
var sounds := {}
var last_played := {}
var audio_pool: Array[AudioStreamPlayer] = []
var audio_index := 0
var arena_music_position := 0.0
var closing := false
@onready var music: AudioStreamPlayer = $Music
@onready var arena_music: AudioStream = music.stream

func _ready() -> void:
	get_tree().auto_accept_quit = false
	camera.position = player.position
	camera.limit_left = int(arena.AREA.position.x - 44)
	camera.limit_top = int(arena.AREA.position.y - 40)
	camera.limit_right = int(arena.AREA.end.x + 44)
	camera.limit_bottom = int(arena.AREA.end.y + 40)
	camera.make_current()
	waves.game = self
	arena.gate.visible = multiplier_enabled
	enemy_frames = [
		ART.character("blood"),
		ART.character("demon"),
		SKULL_FRAMES,
		preload("res://art/characters/mobs/horned_slime/animations.tres"),
		preload("res://art/characters/mobs/flying_trident/animations.tres"),
		preload("res://art/characters/mobs/dark_knight/animations.tres"),
		preload("res://art/characters/mobs/armored_tank/animations.tres"),
	]
	for event in ["shot", "bounce", "split", "hit", "death", "return", "hurt", "upgrade", "clear", "over", "knight_swing"]:
		sounds[event] = load("res://art/audio/%s.wav" % ("buy" if event == "upgrade" else event))
	for i in range(16):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		audio_pool.append(voice)
	hud.game = self
	hud.menu("title")
	if DisplayServer.get_name() != "headless":
		music.play()

func start_boss(enemy: CharacterBody2D) -> void:
	elite = enemy
	hud.boss_label.text = "Dark Knight" if enemy.knight_boss else "Skull Boss"
	arena_music_position = music.get_playback_position()
	play_music(BOSS_MUSIC, BOSS_MUSIC_VOLUME)

func play_music(track: AudioStream, volume: float, from_position := 0.0) -> void:
	if music.stream == track:
		return
	music.stop()
	music.stream = track
	music.volume_db = volume
	if DisplayServer.get_name() != "headless":
		music.play(from_position)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not closing:
		close_game()

func close_game() -> void:
	closing = true
	music.stop()
	for voice in audio_pool:
		voice.stop()
	var tree := get_tree()
	await tree.create_timer(0.12, true, false, true).timeout
	tree.quit()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.is_echo():
		return
	if event.physical_keycode == KEY_F8 or event.keycode == KEY_F8:
		if state == State.WAVE_SELECT:
			close_wave_select()
		elif state != State.DYING and not closing:
			open_wave_select()
		get_viewport().set_input_as_handled()
	elif state == State.WAVE_SELECT and event.is_action_pressed("ui_cancel"):
		close_wave_select()
		get_viewport().set_input_as_handled()

func open_wave_select() -> void:
	state_before_wave_select = state
	overlay_before_wave_select = hud.overlay_kind
	state = State.WAVE_SELECT
	get_tree().paused = true
	hud.menu("wave_select")

func close_wave_select() -> void:
	state = state_before_wave_select
	get_tree().paused = state == State.PAUSE
	if overlay_before_wave_select.is_empty():
		hud.close()
	else:
		hud.menu(overlay_before_wave_select)

func skip_to_wave(wave_number: int) -> void:
	if state == State.WAVE_SELECT and wave_number >= 1 and wave_number <= MAX_WAVE_SELECT:
		restart_at_wave(wave_number)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if state == State.PLAY:
		state = State.PAUSE
		get_tree().paused = true
		hud.menu("pause")
		get_viewport().set_input_as_handled()
	elif state == State.PAUSE:
		resume()
		get_viewport().set_input_as_handled()

func start_run() -> void:
	if state == State.TITLE:
		begin_wave()

func resume() -> void:
	state = State.PLAY
	cooldown = 0.16
	get_tree().paused = false
	hud.close()

func restart() -> void:
	restart_at_wave(1)

func restart_at_wave(wave_number: int) -> void:
	var tree := get_tree()
	tree.paused = false
	state = State.TITLE
	tree.scene_changed.connect(start_reloaded_game.bind(tree, wave_number), CONNECT_ONE_SHOT)
	tree.reload_current_scene()

static func start_reloaded_game(tree: SceneTree, wave_number: int) -> void:
	var game := tree.current_scene
	if is_instance_valid(game):
		game.waves.wave = wave_number - 1
		game.start_run()

func next_wave() -> void:
	if state == State.UPGRADES and upgrade_offer.is_empty():
		begin_wave()

func begin_wave() -> void:
	state = State.PLAY
	cooldown = 0.23
	elite = null
	waves.advance()
	arena.gate.visible = multiplier_enabled
	if multiplier_enabled:
		arena.gate.relocate(player.position, arena.AREA)
	hud.close()

func _physics_process(dt: float) -> void:
	match state:
		State.PLAY:
			run_time += dt
			player.tick(dt, arena)
			if multiplier_enabled:
				arena.gate.tick(dt, player.position, arena.AREA)
			cooldown -= dt
			if cooldown <= 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				shoot()
				cooldown = shot_interval()
			waves.tick(dt)
			move_enemies(dt)
			if state != State.PLAY:
				return
			move_balls(dt)
			if waves.living == 0:
				state = State.CLEAR
				transition = 1.55 if upgrades_enabled else 1.20
				hud.menu("clear")
				sound("clear")
				for ball in balls.get_children():
					ball.finish_flight()
		State.CLEAR:
			player.tick(dt, arena)
			move_balls(dt)
			transition -= dt
			if transition <= 0:
				if returns_enabled and balls.get_child_count() > 0 and transition > -2.0:
					return
				for ball in balls.get_children():
					ball.queue_free()
				if upgrades_enabled:
					state = State.UPGRADES
					roll_upgrade_offer()
					hud.menu("upgrades")
				else:
					begin_wave()
		State.DYING:
			transition -= dt
			if transition <= 0:
				state = State.OVER
				hud.menu("over")
				sound("over")

func _process(dt: float) -> void:
	if state not in [State.PLAY, State.CLEAR, State.DYING]:
		return
	camera.position = camera.position.lerp(player.position, 1.0 - exp(-dt * 8.0))
	shake = move_toward(shake, 0.0, dt * 23)
	camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))

func move_enemies(dt: float) -> void:
	var active := enemies.get_children()
	for enemy in active:
		if enemy.dead:
			continue
		var separation := Vector2.ZERO
		for other in active:
			if other == enemy or other.dead or other.spawn_warning > 0.0:
				continue
			var offset: Vector2 = enemy.position - other.position
			var range_limit: float = enemy.radius + other.radius + 5
			var length_sq := offset.length_squared()
			if length_sq < range_limit * range_limit and length_sq > 0.001:
				separation += offset.normalized() * (range_limit - sqrt(length_sq)) * 5.0
		enemy.tick(dt, separation.limit_length(230))
		if state != State.PLAY:
			break

func move_balls(dt: float) -> void:
	for ball in balls.get_children():
		ball.tick(dt)

func shoot() -> void:
	var direction: Vector2 = player.aim
	player.weapon.aim(direction)
	var muzzle: Vector2 = arena.clamp_center(player.weapon.muzzle.global_position, 17.0)
	if multiplier_enabled:
		muzzle = arena.gate.clear_muzzle(muzzle, direction, 14.0)
	var count: int = 1 + 2 * upgrade_level(Upgrade.EXTRA_BALL)
	for i in count:
		var offset := (i - (count - 1) * 0.5) * minf(0.14, 1.05 / maxi(1, count - 1))
		spawn_ball(muzzle, direction.rotated(offset), 1 + upgrade_level(Upgrade.POWER))
	player.weapon.fire()
	sound("shot")

func spawn_ball(at: Vector2, direction: Vector2, amount: int, hits := 0, already_split := false) -> CharacterBody2D:
	if balls.get_child_count() >= MAX_BALLS:
		return null
	var ball := BALL.instantiate()
	ball.game = self
	ball.position = at
	ball.velocity = direction.normalized() * ball.SPEED
	ball.damage = amount
	ball.impacts = hits
	ball.has_split = already_split
	balls.add_child(ball)
	highest_damage = maxi(highest_damage, amount)
	return ball

func split_ball(ball: CharacterBody2D, normal: Vector2) -> void:
	var angle := ball.velocity.angle()
	var center := normal.angle()
	var relative := wrapf(angle - center, -PI, PI)
	var first := center + clampf(relative - 0.19, -1.46, 1.46)
	var second := center + clampf(relative + 0.19, -1.46, 1.46)
	ball.velocity = Vector2.from_angle(first) * ball.SPEED
	ball.position = arena.clamp_center(ball.position + normal, ball.RADIUS + 0.35)
	ball.has_split = true
	var copy_damage := maxi(1, floori(ball.damage * 0.5))
	var child := spawn_ball(ball.position, Vector2.from_angle(second), copy_damage, ball.impacts, true)
	if child and ball.impacts >= ball.FLIGHT_IMPACTS:
		child.finish_flight()
	arena.gate.consume()
	burst(ball.position, ART.ICE, 7)
	sound("split")
	shake = maxf(shake, 1.4)

func collect_ball(at: Vector2) -> void:
	if not returns_enabled:
		return
	score += 5
	burst(at, ART.ICE, 6)
	sound("return")

func hurt_player() -> void:
	if state != State.PLAY or player.invulnerable > 0:
		return
	hearts -= 1
	player.hurt()
	hud.lose_heart(hearts)
	burst(player.position, Color("#dc8181"), 6)
	sound("hurt")
	shake = 2.8
	if hearts == 0:
		state = State.DYING
		play_music(arena_music, ARENA_MUSIC_VOLUME, arena_music_position)
		transition = 0.63

func enemy_defeated(enemy: CharacterBody2D) -> void:
	if enemy == elite:
		play_music(arena_music, ARENA_MUSIC_VOLUME, arena_music_position)
	kills += 1
	waves.living -= 1
	score += (1500 if enemy.knight_boss else 750) if enemy.is_boss() else 100
	burst(enemy.position, Color("#ffd499"), 14 if enemy.is_boss() else 8)
	sound("death")

func upgrade_level(i: int) -> int:
	return levels[i] if upgrades_enabled else 0

func shot_interval() -> float:
	return 0.28 - upgrade_level(Upgrade.QUICK_SHOT) * 0.028

func upgrade_available(i: int) -> bool:
	if i == Upgrade.PATCH_UP:
		return hearts < 3
	return levels[i] < UPGRADE_LIMITS[i]

func roll_upgrade_offer() -> void:
	var fresh: Array[int] = []
	var recent: Array[int] = []
	var repeats: Array[int] = []
	for i in Upgrade.size():
		if upgrade_available(i):
			if i not in upgrade_offer:
				fresh.append(i)
			elif i in previous_upgrade_offer:
				repeats.append(i)
			else:
				recent.append(i)
	fresh.shuffle()
	recent.shuffle()
	repeats.shuffle()
	fresh.append_array(recent)
	fresh.append_array(repeats)
	var next_offer := fresh.slice(0, UPGRADES_PER_WAVE)
	next_offer.shuffle()
	previous_upgrade_offer = upgrade_offer
	upgrade_offer = next_offer

func choose_upgrade(i: int) -> bool:
	if not upgrades_enabled or state != State.UPGRADES or i not in upgrade_offer:
		return false
	if i == Upgrade.PATCH_UP:
		hud.restore_heart(hearts)
		hearts += 1
	else:
		levels[i] += 1
	sound("upgrade")
	begin_wave()
	return true

func burst(at: Vector2, tint: Color, count: int) -> void:
	if effects.get_child_count() > 145:
		return
	var particles := EFFECT.new()
	particles.position = at
	particles.tint = tint
	particles.z_index = 7
	for i in count:
		particles.particles.append(Vector2.from_angle(randf_range(0, TAU)) * randf_range(8, 29))
	effects.add_child(particles)

func hit_marker(at: Vector2, lethal: bool) -> void:
	if effects.get_child_count() > 145:
		return
	var marker := EFFECT.new()
	marker.position = at
	marker.tint = ART.GOLD if lethal else Color.WHITE
	marker.duration = 0.19
	marker.hit_marker = true
	marker.z_index = 10
	effects.add_child(marker)

func egg_impact(at: Vector2, heading: float) -> void:
	if effects.get_child_count() >= 90:
		return
	var shell := EGG_IMPACT.instantiate() as AnimatedSprite2D
	shell.position = at
	shell.rotation = heading
	effects.add_child(shell)

func float_text(at: Vector2, value: String, tint: Color) -> void:
	if effects.get_child_count() > 145:
		return
	var text := ART.label(value, 24, tint)
	text.add_theme_color_override("font_outline_color", ART.INK)
	text.add_theme_constant_override("outline_size", 5)
	text.position = at - Vector2(29, 12)
	text.size.x = 58
	text.z_index = 9
	effects.add_child(text)
	var tween := text.create_tween().set_parallel()
	tween.tween_property(text, "position:y", at.y - 43, 0.51).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(text, "modulate:a", 0, 0.28).set_delay(0.23)
	tween.chain().tween_callback(text.queue_free)

func sound(event: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var now := Time.get_ticks_msec()
	if now - int(last_played.get(event, -1000)) < (65 if event != "bounce" else 90):
		return
	last_played[event] = now
	var voice := audio_pool[audio_index]
	audio_index = (audio_index + 1) % audio_pool.size()
	voice.stream = sounds[event]
	voice.volume_db = -16 if event in ["bounce", "shot", "hit"] else -8
	voice.pitch_scale = randf_range(0.89, 1.13) if event in ["bounce", "shot", "hit"] else 1.0
	voice.play()
