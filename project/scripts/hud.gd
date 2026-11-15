extends CanvasLayer

const ART = preload("res://scripts/art.gd")
const HEART = preload("res://art/kenney/heart_pixel.png")
const EMPTY_HEART = preload("res://art/kenney/heart_empty_pixel.png")
const UPGRADE_MENU = preload("res://scenes/upgrade_menu.tscn")
const RETICLE = preload("res://art/kenney/crosshair.png")
const SCORE_FONT = preload("res://art/fonts/pixelify/PixelifySans.ttf")
var game: Node2D
var root := Control.new()
var status := Control.new()
var overlay: Control
var hearts: Array[TextureRect] = []
var score_readout: Label
var wave: Label
var wave_detail: Label
var boss: VBoxContainer
var boss_label: Label
var boss_bar: ProgressBar
var tip: Label
var overlay_kind := ""
var upgrade_menu: Control
var crosshair := Sprite2D.new()

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_status()
	for i in range(3):
		var heart := TextureRect.new()
		heart.texture = HEART
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart.position = Vector2(2 + i * 48, 0)
		heart.size = Vector2(64, 64)
		heart.pivot_offset = heart.size * 0.5
		var slot: TextureRect = heart.duplicate()
		slot.texture = EMPTY_HEART
		slot.modulate.a = 0.58
		status.add_child(slot)
		status.add_child(heart)
		hearts.append(heart)
	wave = ART.label("Wave 1", 25)
	wave.position = Vector2(520, 17)
	wave.size.x = 240
	status.add_child(wave)
	wave_detail = ART.label("", 15, ART.MUTED)
	wave_detail.position = Vector2(520, 49)
	wave_detail.size.x = 240
	status.add_child(wave_detail)
	score_readout = ART.label("0 PTS", 32, ART.GOLD)
	score_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_readout.add_theme_font_override("font", SCORE_FONT)
	status.add_child(score_readout)
	score_readout.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	score_readout.offset_left = -230
	score_readout.offset_right = -12
	score_readout.offset_top = 12
	for readout in [wave, wave_detail, score_readout]:
		readout.add_theme_color_override("font_outline_color", ART.INK)
		readout.add_theme_constant_override("outline_size", 5)
	boss = VBoxContainer.new()
	boss.position = Vector2(490, 80)
	boss.custom_minimum_size.x = 300
	boss_label = ART.label("", 19, Color("#ffc1a0"))
	boss_label.add_theme_color_override("font_outline_color", ART.INK)
	boss_label.add_theme_constant_override("outline_size", 5)
	boss.add_child(boss_label)
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.custom_minimum_size.y = 8
	boss_bar.add_theme_stylebox_override("background", ART.panel(Color("#241c35"), Color("#a46e91")))
	boss_bar.add_theme_stylebox_override("fill", ART.panel(Color("#e76b78"), Color("#ffb48f")))
	boss.add_child(boss_bar)
	status.add_child(boss)
	boss.hide()
	tip = ART.label("Every wall bounce adds 1 damage.", 16, ART.MUTED)
	tip.size.x = 1280
	tip.position.y = 674
	tip.add_theme_color_override("font_outline_color", ART.INK)
	tip.add_theme_constant_override("outline_size", 6)
	status.add_child(tip)
	crosshair.texture = RETICLE
	crosshair.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	crosshair.z_index = 20
	crosshair.hide()
	add_child(crosshair)

func add_status() -> void:
	root.add_child(status)
	status.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_dt: float) -> void:
	if not is_instance_valid(game):
		return
	score_readout.text = "%d PTS" % game.score
	wave.text = "Wave %d" % maxi(1, game.waves.wave)
	wave_detail.text = "%d left" % game.waves.living
	boss.visible = game.state == game.State.PLAY and is_instance_valid(game.elite) and not game.elite.dead
	if boss.visible:
		boss_bar.max_value = game.elite.max_hp
		boss_bar.value = game.elite.hp
	tip.text = "Bank shots for damage. Returning balls earn points." if game.returns_enabled else "Every wall bounce adds 1 damage."
	tip.visible = game.waves.wave == 1 and game.state == game.State.PLAY and game.run_time < 17
	var aiming: bool = game.state == game.State.PLAY
	status.visible = aiming or game.state == game.State.DYING
	crosshair.visible = aiming
	if aiming:
		crosshair.position = get_viewport().get_mouse_position().round()
	var mouse_mode := Input.MOUSE_MODE_HIDDEN if aiming else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != mouse_mode:
		Input.mouse_mode = mouse_mode

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func restore_heart(i: int) -> void:
	hearts[i].show()

func lose_heart(i: int) -> void:
	var original := hearts[i]
	var ghost: TextureRect = original.duplicate()
	ghost.z_index = 12
	root.add_child(ghost)
	original.hide()
	var start := ghost.position
	var drop := create_tween()
	drop.tween_property(ghost, "position", start + Vector2(12, -12), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	drop.parallel().tween_property(ghost, "rotation", 0.24, 0.12)
	drop.tween_property(ghost, "position", start + Vector2(34, 67), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.parallel().tween_property(ghost, "rotation", 0.74, 0.24)
	drop.tween_property(ghost, "position", start + Vector2(43, 55), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	drop.tween_property(ghost, "position", start + Vector2(53, 67), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.parallel().tween_property(ghost, "scale", Vector2.ONE * 0.55, 0.13)
	drop.parallel().tween_property(ghost, "modulate:a", 0, 0.13)
	drop.tween_callback(ghost.queue_free)

func close() -> void:
	if is_instance_valid(overlay):
		overlay.hide()
		overlay.queue_free()
	overlay = null
	upgrade_menu = null
	overlay_kind = ""

func backdrop(kind: String) -> VBoxContainer:
	close()
	overlay_kind = kind
	var dim := ColorRect.new()
	dim.color = Color("#11131ad0")
	overlay = dim
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	dim.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	if kind == "upgrades":
		center.add_child(content)
	else:
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", ART.stock_frame(ART.STOCK_PANEL, 31, 26))
		center.add_child(frame)
		frame.add_child(content)
	dim.modulate.a = 0
	create_tween().tween_property(dim, "modulate:a", 1, 0.21)
	return content

func menu(kind: String) -> void:
	var content := backdrop(kind)
	match kind:
		"title":
			content.custom_minimum_size.x = 415
			content.add_child(ART.menu_label(ProjectSettings.get_setting("application/config/name"), 62))
			content.add_child(ART.menu_label("Bank your eggs off walls for more damage.", 17, false, true))
			var start := menu_button(content, "Start run", game.start_run, true)
			start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			content.add_child(ART.menu_label("WASD / Arrows Move  ·  Mouse Aim  ·  Hold click Fire  ·  F8 Wave select", 15, false, true))
			content.add_child(ART.menu_label("Boss music: Ritual by Of Far Different Nature", 14, false, true))
			start.grab_focus()
		"wave_select":
			build_wave_select(content)
		"clear":
			content.add_child(ART.menu_label("Wave %d cleared" % game.waves.wave, 46))
			if not game.upgrades_enabled:
				content.add_child(ART.menu_label("Wave %d up next" % (game.waves.wave + 1), 22, false, true))
		"upgrades":
			upgrade_menu = UPGRADE_MENU.instantiate()
			upgrade_menu.game = game
			content.add_child(upgrade_menu)
		"pause":
			content.custom_minimum_size.x = 296
			content.add_child(ART.heading("Paused", 46))
			menu_button(content, "Resume", game.resume, true).grab_focus()
			menu_button(content, "Restart run", game.restart)
		"over":
			content.custom_minimum_size.x = 395
			content.add_child(ART.heading("Run over", 47))
			for entry in [["Score", game.score], ["Wave reached", game.waves.wave],
					["Enemies defeated", game.kills], ["Best egg damage", game.highest_damage]]:
				var row := HBoxContainer.new()
				var description := ART.menu_label(entry[0], 19, true, true)
				description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(description)
				row.add_child(ART.menu_label(str(entry[1]), 21))
				content.add_child(row)
			menu_button(content, "Play again", game.restart, true).grab_focus()

func build_wave_select(content: VBoxContainer) -> void:
	content.custom_minimum_size.x = 375
	content.add_child(ART.heading("Wave Select", 42))
	var hint := ART.menu_label("Start a fresh run on any wave.", 18, true, true)
	content.add_child(hint)
	var field := LineEdit.new()
	field.name = "WaveNumber"
	field.placeholder_text = "Wave number"
	field.text = str(maxi(1, game.waves.wave))
	field.max_length = str(game.MAX_WAVE_SELECT).length()
	field.custom_minimum_size.y = 49
	field.add_theme_font_override("font", ART.BOLD_FONT)
	field.add_theme_font_size_override("font_size", 24)
	field.add_theme_stylebox_override("normal", ART.panel(Color("#251d1c"), Color("#96766a")))
	content.add_child(field)

	var submit := func(value: String):
		var text := value.strip_edges()
		if text.is_valid_int() and text.to_int() >= 1 and text.to_int() <= game.MAX_WAVE_SELECT:
			game.skip_to_wave(text.to_int())
		else:
			hint.text = "Enter a whole number from 1 to %d." % game.MAX_WAVE_SELECT
			field.grab_focus()
			field.select_all()
	field.text_submitted.connect(submit)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	content.add_child(buttons)
	var confirm := ART.button("Go to wave", true)
	confirm.custom_minimum_size.x = 0
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(confirm)
	confirm.pressed.connect(func(): submit.call(field.text))
	var cancel := ART.button("Cancel")
	cancel.custom_minimum_size.x = 105
	buttons.add_child(cancel)
	cancel.pressed.connect(game.close_wave_select)
	field.grab_focus()
	field.select_all()

func menu_button(content: VBoxContainer, label: String, action: Callable, primary := false) -> Button:
	var button := ART.button(label, primary)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.add_child(button)
	button.pressed.connect(action)
	return button
