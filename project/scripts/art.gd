extends RefCounted

const ICE := Color("#8cdee8")
const GOLD := Color("#f0c77d")
const INK := Color("#111822")
const PAPER := Color("#fff4dc")
const MUTED := Color("#c1b8a8")
const MENU_INK := Color("#fff8ef")
const MENU_MUTED := Color("#e3cfc4")
const STOCK_PANEL = preload("res://art/toffeecraft/retro/panel.png")
const STOCK_CARD = preload("res://art/toffeecraft/retro/card.png")
const STOCK_BUTTON = preload("res://art/toffeecraft/retro/button.png")
const STOCK_HOVER = preload("res://art/toffeecraft/retro/button_hover.png")
const STOCK_PRESSED = preload("res://art/toffeecraft/retro/button_pressed.png")
const STOCK_DISABLED = preload("res://art/toffeecraft/retro/button_disabled.png")
const MENU_FONT = preload("res://art/fonts/barlow/BarlowSemiCondensed-Medium.ttf")
const BOLD_FONT = preload("res://art/fonts/barlow/BarlowSemiCondensed-Bold.ttf")
const OUTLINE = preload("res://art/characters/pixel_outline.gdshader")

static func character_outline() -> ShaderMaterial:
	var shader_material := ShaderMaterial.new()
	shader_material.shader = OUTLINE
	return shader_material

static func character(kind: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for action in ["idle", "walk", "hurt", "death"]:
		var path := "res://art/characters/%s_%s.png" % [kind, action]
		if not ResourceLoader.exists(path):
			continue
		var sheet: Texture2D = load(path)
		frames.add_animation(action)
		frames.set_animation_speed(action, 7 if action == "idle" else 12)
		frames.set_animation_loop(action, action in ["idle", "walk"])
		for i in range(int(sheet.get_width() / 32.0)):
			var cell := AtlasTexture.new()
			cell.atlas = sheet
			cell.region = Rect2(i * 32, 0, 32, 32)
			frames.add_frame(action, cell)
	return frames

static func label(value: String, size: int, tint := PAPER) -> Label:
	var node := Label.new()
	node.text = value
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", tint)
	return node

static func left(value: String, size: int, tint := PAPER) -> Label:
	var node := label(value, size, tint)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return node

static func menu_label(value: String, size: int, align_left := false, muted := false) -> Label:
	var node := label(value, size, MENU_MUTED if muted else MENU_INK)
	if align_left:
		node.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.add_theme_font_override("font", MENU_FONT)
	return node

static func heading(value: String, size: int) -> Label:
	var node := menu_label(value, size, true)
	node.add_theme_font_override("font", BOLD_FONT)
	return node

static func stock_frame(texture: Texture2D, horizontal: float, vertical: float) -> StyleBoxTexture:
	var frame := StyleBoxTexture.new()
	frame.texture = texture
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		frame.set_texture_margin(side, 8.0)
	frame.content_margin_left = horizontal
	frame.content_margin_right = horizontal
	frame.content_margin_top = vertical
	frame.content_margin_bottom = vertical
	return frame

static func panel(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.anti_aliasing = false
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	return style

static func icon_rect(texture: Texture2D, dimensions: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = dimensions
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon

static func button(title: String, primary := false) -> Button:
	var node := Button.new()
	node.text = title
	node.custom_minimum_size = Vector2(240, 52)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", BOLD_FONT)
	node.add_theme_font_size_override("font_size", 22)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		node.add_theme_color_override(state, MENU_INK)
	node.add_theme_color_override("font_disabled_color", Color("#ac9891"))
	var normal_art := STOCK_BUTTON if primary else STOCK_HOVER
	node.add_theme_stylebox_override("normal", stock_frame(normal_art, 14, 7))
	node.add_theme_stylebox_override("hover", stock_frame(STOCK_BUTTON, 14, 7))
	node.add_theme_stylebox_override("pressed", stock_frame(STOCK_PRESSED, 14, 7))
	node.add_theme_stylebox_override("disabled", stock_frame(STOCK_DISABLED, 14, 7))
	node.add_theme_stylebox_override("focus", panel(Color.TRANSPARENT, Color("#eccbb1")))
	return node
