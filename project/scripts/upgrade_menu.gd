extends Control

const ART = preload("res://scripts/art.gd")
const NAMES := ["Extra Ball", "Power", "Bounce Boost", "Quick Shot", "Patch Up"]
const EFFECTS := [
	"+2 balls per shot",
	"+1 starting damage",
	"+1 damage per wall hit",
	"Shoot more often",
	"Restore 1 heart",
]

var game: Node2D
var buttons: Array[Button] = []

func _ready() -> void:
	custom_minimum_size = Vector2(760, 344)
	var stack := VBoxContainer.new()
	add_child(stack)
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.add_theme_constant_override("separation", 14)
	var has_offer: bool = not game.upgrade_offer.is_empty()
	var title := "Choose one upgrade" if has_offer else "No upgrades available"
	stack.add_child(ART.heading(title, 44))
	if has_offer:
		stack.add_child(ART.menu_label("Wave %d starts after you choose." % (game.waves.wave + 1), 21, true, true))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	stack.add_child(row)
	for i in game.upgrade_offer:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(244, 214)
		card.add_theme_stylebox_override("panel", ART.stock_frame(ART.STOCK_CARD, 14, 16))
		row.add_child(card)

		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 8)
		card.add_child(content)
		var name_label := ART.heading(NAMES[i], 28)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(name_label)
		content.add_child(ART.menu_label(EFFECTS[i], 20))
		var healing: bool = i == game.Upgrade.PATCH_UP
		var progress: String
		if healing:
			progress = "%d / 3 hearts" % game.hearts
		else:
			progress = "Level %d / %d" % [game.levels[i], game.UPGRADE_LIMITS[i]]
		content.add_child(ART.menu_label(progress, 18, false, true))
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(spacer)

		var button := ART.button("Choose")
		button.custom_minimum_size = Vector2(0, 48)
		buttons.append(button)
		content.add_child(button)
		button.pressed.connect(game.choose_upgrade.bind(i))

	if not has_offer:
		var next := ART.button("Start next wave", true)
		next.size_flags_horizontal = Control.SIZE_SHRINK_END
		stack.add_child(next)
		next.pressed.connect(game.next_wave)
