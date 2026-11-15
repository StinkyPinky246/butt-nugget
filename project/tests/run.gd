extends SceneTree

var game: Node2D
var errors := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		errors += 1
		push_error(description)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame

func button_named(node: Node, title: String) -> Button:
	if node is Button and node.text.to_lower().begins_with(title.to_lower()):
		return node
	for child in node.get_children():
		var button := button_named(child, title)
		if button:
			return button
	return null

func press_key(code: Key) -> void:
	var key := InputEventKey.new()
	key.keycode = code
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()

func screenshot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/bounce-%s.png" % name)

func verify_arcade_mode() -> void:
	check(game.upgrades_enabled and not game.returns_enabled and not game.multiplier_enabled,
		"The upgrade picker is enabled by default.")
	game.upgrades_enabled = false
	check(not game.arena.gate.visible, "The disabled multiplier is absent from the room.")
	game.start_run()
	check(game.waves.living == 15 and game.waves.pending.has(3) and game.waves.pending.has(4),
		"Wave one includes fifteen enemies, with Horned Slimes and Flying Tridents.")
	game.waves.timer = 99.0
	var gate: Vector2 = game.arena.gate.position
	var pass_through: CharacterBody2D = game.spawn_ball(gate + Vector2(0, 30), Vector2.UP, 1)
	await frames(15)
	check(game.balls.get_child_count() == 1 and pass_through.position.y < gate.y and pass_through.damage == 1,
		"Shots pass through the former multiplier location.")
	pass_through.queue_free()
	await frames(2)
	game.multiplier_enabled = true
	game.spawn_ball(gate + Vector2(0, 27), Vector2.UP, 4, 7)
	await frames(7)
	check(game.balls.get_child_count() == 2 and game.balls.get_children().all(
		func(orb): return orb.spent and not orb.returning),
		"An eighth-impact split still expires if only the multiplier is enabled.")
	game.multiplier_enabled = false
	await frames(18)

	var area: Rect2 = game.arena.AREA
	var bank: CharacterBody2D = game.spawn_ball(Vector2(area.position.x + 27, 435), Vector2.LEFT, 1, 7)
	await frames(7)
	check(bank.number.text == "2" and bank.number.get_theme_font_size("font_size") >= 22
		and bank.number.get_theme_constant("outline_size") >= 4,
		"The ball displays live damage in large outlined type.")
	check(bank.spent and not bank.returning, "An exhausted shot fades without returning.")
	await frames(18)
	check(not is_instance_valid(bank) and game.score == 0, "An expired shot awards no points.")

	game.waves.timer = 0.0
	await frames(2)
	check(game.enemies.get_child_count() == 3, "The wave spawns its first group together.")
	var victim: CharacterBody2D = game.enemies.get_child(0)
	var player_start: Vector2 = game.player.position
	var safe_spawns: bool = game.enemies.get_children().all(func(unit):
		return unit.spawn_warning > 0.0 and unit.collision_layer == 0 and unit.position.distance_to(player_start) >= game.waves.SAFE_DISTANCE
	)
	check(safe_spawns, "Spawn markers start at least 410 pixels away and have no collision.")
	game.player.position = victim.position
	victim.tick(1.0, Vector2.ZERO)
	check(victim.spawn_warning > 0.0 and victim.collision_layer == 0
		and victim.position.distance_to(game.player.position) >= game.waves.SAFE_DISTANCE,
		"A spawn relocates if the player approaches before it activates.")
	game.player.position = player_start
	for unit in game.enemies.get_children():
		unit.speed = 0
		unit.position = Vector2(1300, 720)
		unit.activate()
	victim.position = Vector2(800, 460)
	await frames(2)
	var shot: CharacterBody2D = game.spawn_ball(Vector2(740, 460), Vector2.RIGHT, 1)
	await frames(9)
	check(victim.hp == victim.max_hp - 1 and game.effects.get_children().any(
		func(effect): return effect.get("hit_marker") == true),
		"An enemy collision damages the mob and displays a hit marker.")
	shot.queue_free()
	while not game.waves.pending.is_empty():
		game.waves.tick(1.0)
	for unit in game.enemies.get_children():
		if unit.spawn_warning > 0.0:
			unit.activate()
		unit.take_hit(999, Vector2.ZERO)
	await frames(150)
	check(game.waves.wave == 2 and game.state == game.State.PLAY and not is_instance_valid(game.hud.upgrade_menu),
		"Wave two starts automatically when upgrades are off.")
	check(game.waves.living == 21 and game.score == 1500,
		"Wave two adds six more mobs and kills award score.")
	check(not game.choose_upgrade(0), "Upgrades cannot be selected while disabled.")

func run() -> void:
	if not ResourceLoader.exists("res://scenes/game.tscn"):
		push_error("The playable main scene is missing.")
		quit(1)
		return
	seed(124818)
	change_scene_to_file("res://scenes/game.tscn")
	await scene_changed
	game = current_scene
	press_key(KEY_F8)
	await frames(2)
	check(paused and game.state == game.State.WAVE_SELECT, "F8 opens Wave Select from the title screen.")
	var wave_field: LineEdit = game.hud.overlay.find_child("WaveNumber", true, false)
	wave_field.text_submitted.emit("0")
	check(game.state == game.State.WAVE_SELECT, "An invalid wave keeps Wave Select open.")
	press_key(KEY_ESCAPE)
	await frames(2)
	check(not paused and game.state == game.State.TITLE and game.hud.overlay_kind == "title",
		"Esc returns to the title without starting a run.")
	await verify_arcade_mode()
	change_scene_to_file("res://scenes/game.tscn")
	await scene_changed
	game = current_scene
	game.upgrades_enabled = true
	game.returns_enabled = true
	game.multiplier_enabled = true
	seed(124818)
	await create_timer(0.30).timeout
	await screenshot("title")
	button_named(game.hud.overlay, "START RUN").pressed.emit()
	check(game.state == game.State.PLAY and game.waves.wave == 1, "Title button starts wave one.")
	await frames(2)
	check(game.hud.crosshair.visible, "Pixel crosshair appears in combat.")
	var launcher: SpriteFrames = game.player.weapon.sprite.sprite_frames
	check(launcher.get_frame_texture("idle", 0).resource_path.contains("/chicken/")
		and launcher.get_frame_count("shot") == 8, "The chicken launcher uses all eight supplied firing frames.")
	check(game.player.sprite.sprite_frames.get_frame_texture("idle", 0).resource_path.contains("/mushroom/")
		and game.player.sprite.sprite_frames.get_frame_count("walk") == 2, "The mushroom uses both supplied character frames.")
	for direction in [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]:
		game.player.aim = direction
		game.shoot()
		var egg: CharacterBody2D = game.balls.get_child(-1)
		check(egg.global_position.is_equal_approx(game.player.weapon.muzzle.global_position)
			and egg.velocity.normalized().is_equal_approx(direction)
			and game.player.weapon.transform.x.is_equal_approx(direction),
			"The chicken aims like the launcher and fires from the tail toward %s." % str(direction))
		egg.free()
	check(game.music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Chip music is configured to loop.")
	game.waves.timer = 99.0

	var movement := InputEventKey.new()
	movement.physical_keycode = KEY_D
	movement.keycode = KEY_D
	movement.pressed = true
	var old_position: Vector2 = game.player.position
	Input.parse_input_event(movement)
	await frames(19)
	movement = movement.duplicate()
	movement.pressed = false
	Input.parse_input_event(movement)
	check(game.player.position.x > old_position.x + 25.0, "WASD accelerates the player.")
	old_position = game.player.position
	movement = InputEventKey.new()
	movement.keycode = KEY_DOWN
	movement.pressed = true
	Input.parse_input_event(movement)
	await frames(19)
	movement = movement.duplicate()
	movement.pressed = false
	Input.parse_input_event(movement)
	check(game.player.position.y > old_position.y + 25.0, "The arrow keys also move the player.")
	await frames(34)

	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await frames(65)
	mouse = mouse.duplicate()
	mouse.pressed = false
	Input.parse_input_event(mouse)
	check(game.balls.get_child_count() >= 2, "Holding fire launches concurrent balls.")
	for active in game.balls.get_children():
		active.queue_free()
	await frames(2)

	var area: Rect2 = game.arena.AREA
	var tiles: TileMapLayer = game.arena.get_node("DungeonTiles")
	check(tiles.get_cell_atlas_coords(Vector2i.ZERO) == Vector2i(1, 1)
		and not tiles.collision_enabled and tiles.position + Vector2(7, 7) == area.position,
		"Mossvault corner artwork aligns with the continuous wall colliders.")
	var ball: CharacterBody2D = game.spawn_ball(Vector2(area.position.x + 27, 460), Vector2(-1, 0.31), 1)
	await frames(7)
	check(ball.damage == 2 and ball.velocity.x > 0 and ball.velocity.y > 0 and ball.number.text == "2",
		"Normal wall reflects the angle and updates the live damage label.")
	var ball_art := ball.get_node_or_null("Egg") as AnimatedSprite2D
	check(ball_art != null and is_equal_approx(ball_art.rotation, ball.velocity.angle()),
		"The egg's front follows the reflected flight direction during squash.")
	var egg_image := ball_art.sprite_frames.get_frame_texture("flight", 0).get_image()
	var egg_bounds := egg_image.get_used_rect()
	var edge_widths := [0, 0]
	for y in range(egg_bounds.position.y, egg_bounds.end.y):
		edge_widths[0] += int(egg_image.get_pixel(egg_bounds.position.x + 2, y).a > 0.5)
		edge_widths[1] += int(egg_image.get_pixel(egg_bounds.end.x - 3, y).a > 0.5)
	check(edge_widths[1] > edge_widths[0], "The leading side of the flight frame is wider than the tail.")
	check(ball_art.animation == &"flight" and game.effects.find_children("*", "AnimatedSprite2D", false, false).is_empty(),
		"A wall ricochet keeps the egg intact without showing a shell crack.")
	ball.queue_free()
	await frames(2)
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.RIGHT]:
		var reach := (area.size.x if direction.x != 0 else area.size.y) * 0.5 - 27.0
		var shot: CharacterBody2D = game.spawn_ball(area.get_center() + direction * reach, direction, 1)
		await frames(6)
		check(shot.damage == 2 and shot.velocity.dot(direction) < 0,
			"The %s rim reflects the shot at its inside edge." % str(direction))
		shot.queue_free()
		await frames(2)
	var gate: Vector2 = game.arena.gate.position
	check(area.grow(-140).has_point(gate) and gate.distance_to(game.player.position) > 160,
		"Multiplier field spawns inside the room, clear of the player and walls.")
	var clear: Vector2 = game.arena.gate.clear_muzzle(gate, Vector2.UP, 14.0)
	check(clear.y < gate.y - 17.0, "A shot fired from inside the field starts outside its collider.")
	await screenshot("field")
	var split: CharacterBody2D = game.spawn_ball(gate + Vector2(0, 28), Vector2.UP, 4)
	await frames(17)
	var children: Array[Node] = game.balls.get_children()
	check(children.size() == 2, "Gate makes exactly two balls without immediately retriggering.")
	if children.size() == 2:
		check(children[0].damage == 4 and children[1].damage == 2 and
			children[0].velocity.y > 0 and children[1].velocity.y > 0 and
			children[0].velocity.x * children[1].velocity.x < 0, "The original keeps its damage and the split copy deals half.")
	for active in children:
		active.queue_free()
	await frames(2)

	game.spawn_ball(gate + Vector2(0, -28), Vector2.DOWN, 4)
	await frames(17)
	children = game.balls.get_children()
	check(children.size() == 1 and children[0].velocity.y > 0,
		"The depleted field lets the next shot pass through.")
	for active in children:
		active.queue_free()
	await frames(2)
	game.arena.gate.tick(game.arena.gate.RECHARGE_SECONDS, game.player.position, area)
	await frames(2)
	var recharged: Vector2 = game.arena.gate.position
	check(recharged.distance_to(gate) > 180 and game.arena.gate.available,
		"The field recharges in a different spot.")
	game.spawn_ball(recharged + Vector2(0, -28), Vector2.DOWN, 4)
	await frames(17)
	children = game.balls.get_children()
	check(children.size() == 2 and children.all(func(orb): return orb.velocity.y < 0),
		"The multiplier works from the opposite side.")
	for active in children:
		active.queue_free()
	await frames(2)
	game.arena.gate.tick(game.arena.gate.RECHARGE_SECONDS, game.player.position, area)
	var idle_position: Vector2 = game.arena.gate.position
	game.arena.gate.tick(game.arena.gate.ACTIVE_SECONDS, game.player.position, area)
	gate = game.arena.gate.position
	check(gate.distance_to(idle_position) > 180, "An unused field relocates during combat.")
	game.player.position = gate + Vector2(0, 90)
	var cross: CharacterBody2D = game.spawn_ball(gate + Vector2(0, -42), Vector2.DOWN, 2)
	cross.begin_return()
	await frames(14)
	check(game.balls.get_child_count() == 1 and is_instance_valid(cross) and cross.position.y > gate.y,
		"A returning ball passes through the field without splitting.")
	if is_instance_valid(cross):
		cross.queue_free()
	game.arena.gate.position = area.end - Vector2(155, 155)
	await frames(2)

	game.player.position = Vector2(500, 440)
	var before: int = game.score
	var returning: CharacterBody2D = game.spawn_ball(Vector2(area.position.x + 27, 430), Vector2.LEFT, 3, 7)
	await frames(7)
	check(returning.returning and returning.impacts == 8, "Eighth bounce puts the ball in return mode.")
	await frames(138)
	check(not is_instance_valid(returning) and game.score == before + 5, "Returning ball is absorbed for five points.")

	before = game.score
	var following: CharacterBody2D = game.spawn_ball(Vector2(150, 440), Vector2.RIGHT, 3)
	following.begin_return()
	await frames(52)
	game.player.position = Vector2(500, 555)
	await frames(90)
	check(not is_instance_valid(following) and game.score == before + 5,
		"Returning shots follow a moving target and can still be collected.")
	game.player.position = Vector2(500, 440)

	game.waves.timer = 0.0
	await frames(2)
	var enemy: CharacterBody2D = game.enemies.get_child(0)
	enemy.activate()
	enemy.speed = 0.0
	enemy.position = Vector2(800, 450)
	var homing: CharacterBody2D = game.spawn_ball(Vector2(940, 450), Vector2.LEFT, 50)
	homing.begin_return()
	await frames(43)
	check(enemy.hp == enemy.max_hp, "Returning balls cannot damage enemies.")
	enemy.position = Vector2(800, 460)
	var attack: CharacterBody2D = game.spawn_ball(Vector2(740, 460), Vector2.RIGHT, 1)
	await frames(10)
	check(enemy.hp == enemy.max_hp - 1 and attack.velocity.x < 0, "Enemy impact deals damage and reflects the ball.")
	var shell := game.effects.get_node_or_null("EggImpact") as AnimatedSprite2D
	check(is_instance_valid(shell) and shell.sprite_frames.get_frame_count("impact") == 5,
		"An enemy hit plays the five-frame shell crack.")
	await screenshot("combat")
	for active in game.balls.get_children():
		active.queue_free()
	await frames(26)
	check(not is_instance_valid(shell), "The shell crack cleans itself up after playback.")

	for expected_wave in range(1, 7):
		check(game.waves.wave == expected_wave, "Reached wave %d." % expected_wave)
		if expected_wave > 1:
			var parked := area.end - Vector2(155, 155)
			check(game.arena.gate.position.distance_to(parked) > 140,
				"The field gets a new location for wave %d." % expected_wave)
			game.arena.gate.position = parked
			await frames(2)
		while not game.waves.pending.is_empty():
			game.waves.spawn(game.waves.pending.pop_front())
		await frames(2)
		var fleet: Array[Node] = game.enemies.get_children()
		for mob in fleet:
			if mob.spawn_warning > 0.0:
				mob.activate()
		if expected_wave == 3:
			var new_kinds := {}
			for mob in fleet:
				if mob.kind >= 3 and mob.sprite.sprite_frames.get_frame_count("walk") == 8 and mob.sprite.sprite_frames.has_animation(mob.attack_animation):
					new_kinds[mob.kind] = true
			check(new_kinds.size() == 4, "By wave three all four new mobs spawn with their walk and attack animations.")
		if expected_wave in [3, 4]:
			check(fleet.any(func(unit): return unit.kind == 1), "Mixed wave includes fast enemies.")
		if expected_wave == 5:
			check(is_instance_valid(game.elite) and game.hud.boss.visible, "Wave five Skull Boss and health bar appear.")
			check(game.elite.sprite.sprite_frames.get_frame_count("walk") == 7,
				"The Skull Boss uses all seven supplied flight frames.")
			check(game.music.stream == game.BOSS_MUSIC and game.BOSS_MUSIC.loop,
				"Ritual becomes the looping music when the boss spawns.")
			game.hearts = 2
			game.hud.lose_heart(2)
		for unit in fleet:
			if is_instance_valid(unit) and not unit.dead:
				for other in fleet:
					if is_instance_valid(other) and not other.dead:
						other.speed = 0
						other.knockback = Vector2.ZERO
						other.position = Vector2(1350, 820)
				unit.speed = 0
				unit.position = Vector2(800, 460)
				await frames(3)
				game.spawn_ball(Vector2(740, 460), Vector2.RIGHT, unit.hp)
				await frames(14)
		for i in range(450):
			if game.state == game.State.UPGRADES:
				break
			await physics_frame
		if expected_wave == 5:
			check(game.music.stream == game.arena_music, "The arena soundtrack returns after the boss is defeated.")
		check(game.state == game.State.UPGRADES and game.waves.living == 0, "Clearing wave %d opens the upgrade picker." % expected_wave)
		if game.state != game.State.UPGRADES:
			print("Wave not clear. State: ", game.state, ", living: ", game.waves.living, ", timer: ", game.transition)
			quit(1)
			return
		var menu: Control = game.hud.upgrade_menu
		var pick: int = [game.Upgrade.EXTRA_BALL, game.Upgrade.POWER, game.Upgrade.BOUNCE_BOOST,
			game.Upgrade.QUICK_SHOT, game.Upgrade.PATCH_UP, game.Upgrade.EXTRA_BALL][expected_wave - 1]
		if expected_wave == 1:
			await create_timer(0.24).timeout
			await screenshot("shop")
			check(menu.buttons.size() == 3 and menu.buttons.all(func(button): return not button.disabled),
				"The menu offers three eligible choices.")
			check(not game.choose_upgrade(-1), "An invalid upgrade is rejected.")
			check(game.Upgrade.PATCH_UP not in game.upgrade_offer, "Patch Up stays out of the draw at full health.")
			for option in [game.Upgrade.EXTRA_BALL, game.Upgrade.POWER, game.Upgrade.BOUNCE_BOOST, game.Upgrade.QUICK_SHOT]:
				if option not in game.upgrade_offer:
					check(not game.choose_upgrade(option), "An eligible upgrade outside the offer cannot be selected.")
			game.next_wave()
			check(game.state == game.State.UPGRADES, "You must choose an upgrade before the next wave.")
		if pick not in game.upgrade_offer:
			game.upgrade_offer[-1] = pick
			game.hud.menu("upgrades")
			menu = game.hud.upgrade_menu
		var saved_levels: Array = game.levels.duplicate()
		menu.buttons[game.upgrade_offer.find(pick)].pressed.emit()
		var choice_applied: bool = game.hearts == 3 if pick == game.Upgrade.PATCH_UP else game.levels[pick] == saved_levels[pick] + 1
		check(game.state == game.State.PLAY and game.waves.wave == expected_wave + 1 and choice_applied,
			"Choosing an upgrade applies it and starts the next wave.")
		if expected_wave == 1:
			check(not game.choose_upgrade(game.Upgrade.POWER) and game.levels[game.Upgrade.POWER] == 0,
				"A second choice is rejected for the same wave.")
		if expected_wave in [2, 6]:
			game.shoot()
			var shot_count := 3 if expected_wave == 2 else 5
			check(game.balls.get_child_count() == shot_count and game.balls.get_child(0).damage == 2,
				"Extra Ball adds two shots each time and Power increases their damage.")
		if expected_wave == 3:
			var boosted: CharacterBody2D = game.spawn_ball(Vector2(area.position.x + 27, 460), Vector2.LEFT, 2)
			await frames(7)
			check(boosted.damage == 4, "Bounce Boost increases damage gained per wall bounce.")
		if expected_wave == 4:
			check(is_equal_approx(game.shot_interval(), 0.252), "Quick Shot shortens the firing interval.")
		if expected_wave == 5:
			check(game.hud.hearts[2].visible, "Patch Up restores the missing HUD heart.")
		if expected_wave < 6:
			await frames(2)
	check(game.waves.wave == 7, "The run continues beyond the elite and wave six.")

	await frames(2)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	Input.flush_buffered_events()
	await frames(2)
	check(paused and game.state == game.State.PAUSE, "Esc pauses the game.")
	await frames(2)
	check(not game.hud.crosshair.visible, "Crosshair clears while the pause menu is open.")
	button_named(game.hud.overlay, "RESUME").pressed.emit()
	check(not paused and game.state == game.State.PLAY, "Resume restores gameplay.")

	game.waves.spawn(0)
	var contact: CharacterBody2D = game.enemies.get_child(game.enemies.get_child_count() - 1)
	contact.position = game.player.position
	await frames(4)
	check(game.hearts == 2 and not game.hud.hearts[2].visible, "Contact removes a HUD heart.")
	await frames(24)
	check(game.hearts == 2, "Invincibility blocks repeated immediate contact damage.")
	game.player.invulnerable = 0
	contact.position = game.player.position
	await frames(3)
	game.player.invulnerable = 0
	contact.position = game.player.position
	await frames(3)
	await create_timer(0.91).timeout
	check(game.hearts == 0 and game.state == game.State.OVER, "Third hit opens game over.")
	await screenshot("over")
	button_named(game.hud.overlay, "PLAY AGAIN").pressed.emit()
	await scene_changed
	await process_frame
	game = current_scene
	check(game.hearts == 3 and game.score == 0 and game.kills == 0 and game.levels == [0, 0, 0, 0] and
		game.waves.wave == 1 and game.state == game.State.PLAY, "Play Again starts a clean wave-one run.")
	game.hearts = 1
	game.score = 350
	press_key(KEY_F8)
	await frames(2)
	check(paused and game.state == game.State.WAVE_SELECT, "F8 pauses an active run and opens Wave Select.")
	wave_field = game.hud.overlay.find_child("WaveNumber", true, false)
	wave_field.text_submitted.emit("5")
	await scene_changed
	await process_frame
	game = current_scene
	check(not paused and game.waves.wave == 5 and game.hearts == 3 and game.score == 0,
		"Submitting Wave Select starts a fresh run on the chosen wave.")
	await frames(180)
	check(is_instance_valid(game.elite) and game.music.stream == game.BOSS_MUSIC,
		"Skipping to wave five spawns the Skull Boss and starts Ritual.")
	check(game.upgrade_offer.is_empty() and game.previous_upgrade_offer.is_empty(),
		"A fresh run has no upgrade offer history.")
	game.hearts = 2
	var two_rounds_ago: Array[int] = []
	var last_round: Array[int] = []
	var varied_offers := {}
	var valid_draws := true
	var streak_free := true
	for round in 24:
		game.roll_upgrade_offer()
		var offer: Array[int] = game.upgrade_offer
		valid_draws = valid_draws and offer.size() == 3 and offer.all(func(option): return offer.count(option) == 1)
		streak_free = streak_free and offer.all(func(option): return option not in last_round or option not in two_rounds_ago)
		var sorted_offer := offer.duplicate()
		sorted_offer.sort()
		varied_offers[str(sorted_offer)] = true
		two_rounds_ago = last_round
		last_round = offer
	check(valid_draws and varied_offers.size() > 2, "Drafts offer three distinct upgrades and vary across waves.")
	check(streak_free, "With five eligible choices, an upgrade never appears in three consecutive drafts.")
	game.hearts = 3
	game.previous_upgrade_offer.assign([game.Upgrade.EXTRA_BALL, game.Upgrade.POWER, game.Upgrade.QUICK_SHOT])
	game.upgrade_offer.assign([game.Upgrade.EXTRA_BALL, game.Upgrade.POWER, game.Upgrade.BOUNCE_BOOST])
	game.roll_upgrade_offer()
	check(game.upgrade_offer.size() == 3 and game.Upgrade.QUICK_SHOT in game.upgrade_offer
		and game.Upgrade.BOUNCE_BOOST in game.upgrade_offer, "With four choices, the draft only repeats as much as needed.")
	game.levels = [5, 5, 5, 0]
	game.roll_upgrade_offer()
	check(game.upgrade_offer == [game.Upgrade.QUICK_SHOT], "Only an eligible choice appears when the pool runs low.")
	game.levels = [5, 5, 5, 4]
	game.roll_upgrade_offer()
	check(game.upgrade_offer.is_empty(), "The draft is empty when all upgrades are capped and health is full.")
	game.state = game.State.UPGRADES
	game.hud.menu("upgrades")
	button_named(game.hud.overlay, "START NEXT WAVE").pressed.emit()
	check(game.state == game.State.PLAY and game.waves.wave == 6,
		"The player can continue when no upgrades are available.")
	game.restart_at_wave(10)
	await scene_changed
	game = current_scene
	check(game.waves.living == 69 and game.waves.pending.count(preload("res://scripts/enemy.gd").Kind.KNIGHT) == 1
		and preload("res://scripts/enemy.gd").Kind.SKULL not in game.waves.pending,
		"Wave ten queues a single Dark Knight and no Skull Boss.")
	await frames(180)
	var knight: CharacterBody2D = game.elite
	check(is_instance_valid(knight) and knight.kind == knight.Kind.KNIGHT and game.hud.boss.visible,
		"Wave ten introduces the Dark Knight as the boss.")
	if not is_instance_valid(knight) or not knight.knight_boss:
		quit(1)
		return
	check(game.music.stream == game.BOSS_MUSIC and game.hud.boss_label.text == "Dark Knight"
		and game.hud.boss_bar.max_value == 230, "The Dark Knight has a named health bar and starts Ritual.")
	game.waves.timer = 99.0
	for unit in game.enemies.get_children():
		if unit != knight:
			unit.position = Vector2(1320, 785)
			unit.speed = 0.0
			unit.attack_range = 0.0
	knight.position = Vector2(850, 480)
	knight.speed = 0.0
	game.player.position = knight.position + Vector2(68, 0)
	await frames(2)
	check(knight.sprite.animation == &"sweep" and knight.attack_left > 0.0, "The Knight telegraphs its sweep.")
	knight.take_hit(7, Vector2.LEFT)
	check(knight.hp == 223 and knight.sprite.animation == &"sweep",
		"Damage during a windup reduces health while the sword animation continues.")
	game.player.position = knight.position + Vector2(-68, 0)
	await frames(50)
	check(game.hearts == 3, "Dodging behind the Knight makes the telegraphed sweep miss.")
	game.player.position = knight.position + Vector2(68, 0)
	await frames(136)
	check(knight.sprite.animation == &"rising_slash" and game.hearts == 2,
		"The rising slash deals damage when the player stays in range.")
	await frames(159)
	check(knight.sprite.animation == &"overhead_slam" and game.hearts == 1,
		"The overhead slam follows the rising slash and lands on its own strike frame.")
	await screenshot("dark-knight")
	var before_boss_score: int = game.score
	knight.take_hit(knight.hp, Vector2.RIGHT)
	await frames(2)
	check(knight.sprite.animation == &"death" and game.score == before_boss_score + 1500,
		"The Knight plays its death animation and awards the boss score.")
	check(not game.hud.boss.visible and game.music.stream == game.arena_music,
		"Defeating the Knight clears the boss HUD and resumes arena music.")
	while not game.waves.pending.is_empty():
		game.waves.spawn(game.waves.pending.pop_front())
	for unit in game.enemies.get_children():
		if not unit.dead:
			unit.activate()
			unit.take_hit(unit.hp, Vector2.RIGHT)
	await frames(205)
	check(game.state == game.State.UPGRADES and game.waves.living == 0,
		"Clearing the Knight and the remaining enemies opens the wave ten upgrade draft.")
	if game.state == game.State.UPGRADES:
		game.hud.upgrade_menu.buttons[0].pressed.emit()
	check(game.waves.wave == 11 and game.state == game.State.PLAY,
		"Picking a wave ten upgrade begins wave eleven.")
	if DisplayServer.get_name() != "headless":
		game.music.stop()
		for voice in game.audio_pool:
			voice.stop()
		await create_timer(0.15).timeout
	print("Butt Nugget integration checks finished with %d failures." % errors)
	quit(1 if errors else 0)
