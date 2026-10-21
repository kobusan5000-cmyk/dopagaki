extends Node2D

# DOPAGAKI v0.8 — companion + visible HP + larger camera world + cooking breaks.
# Solo prototype; network/4-player functionality is NOT implemented.
# Compatible with Godot 4.3–4.7; one runnable Node2D scene.

const SIZE := Vector2(1152, 648)
const ARENA := Rect2(40, 105, 2540, 1590)
const CAMP_STATIONS := [Vector2(1170, 842), Vector2(2020, 1175)]
const CAMP_RADIUS := 178.0
const COMBAT_SECONDS := 48.0
const REST_SECONDS := 26.0
const PREP_SECONDS := 25.0
const WOLF_WALK: Texture2D = preload("res://assets/ookami_walk.png")
const WOLF_ATTACK: Texture2D = preload("res://assets/ookami_attack.png")
const PIERO_WALK: Texture2D = preload("res://assets/piero_walk.png")
const STORM_BRUTE: Texture2D = preload("res://assets/storm_brute_walk.png")
const NIGHT_REAPER: Texture2D = preload("res://assets/night_reaper_walk.png")
const MINT_SPRITE: Texture2D = preload("res://assets/mint_companion_walk.png")
const ARMOR_VISUALS := [
	[preload("res://assets/armor_head_0.png"), preload("res://assets/armor_head_1.png"), preload("res://assets/armor_head_2.png"), preload("res://assets/armor_head_3.png")],
	[preload("res://assets/armor_chest_0.png"), preload("res://assets/armor_chest_1.png"), preload("res://assets/armor_chest_2.png"), preload("res://assets/armor_chest_3.png")],
	[preload("res://assets/armor_leggings_0.png"), preload("res://assets/armor_leggings_1.png"), preload("res://assets/armor_leggings_2.png"), preload("res://assets/armor_leggings_3.png")],
	[preload("res://assets/armor_arms_0.png"), preload("res://assets/armor_arms_1.png"), preload("res://assets/armor_arms_2.png"), preload("res://assets/armor_arms_3.png")]
]
const WEAPONS := ["PISTOL", "BOW", "SWORD", "GREATSWORD", "REPEATING CROSSBOW", "ARCANE STAFF", "HEALING STAFF"]
const CLASS_NAMES := ["WARRIOR", "ARCHER", "CROSSBOWMAN", "MAGE", "BERSERKER", "HEALER"]
const CLASS_DESC := ["Balanced swordfighter", "Piercing arrows / fast feet", "Burst of repeating bolts", "Piercing magic projectiles", "Heavy strikes / high HP", "Heal and ranged support"]
const CLASS_WEAPONS := [2, 1, 4, 5, 3, 6]
const WOLF_PALETTES := [Color("ffffff"), Color("ffe4c0"), Color("bce4ff"), Color("edc4ff"), Color("d3ffbe"), Color("ffc6da")]
const PALETTE_NAMES := ["ORIGINAL", "GOLD", "ICE", "LILAC", "MINT", "ROSE"]
const ACCESSORY_NAMES := ["NONE", "STAR", "CROWN", "SPARK"]
const FARM_PLOTS := [Vector2(1320, 745), Vector2(1390, 745), Vector2(1460, 745), Vector2(1320, 817), Vector2(1390, 817), Vector2(1460, 817), Vector2(2130, 1090), Vector2(2200, 1090), Vector2(2130, 1160), Vector2(2200, 1160)]
const GROW_SECONDS := 10.0
const RARITIES := ["COMMON", "RARE", "EPIC", "LEGENDARY"]
const ARMOR_SLOTS := ["HEAD", "CHEST", "LEGGINGS", "ARMS"]
const ARMOR_BASE_DEF := [2, 5, 3, 2]
const ARMOR_PREFIX := ["WORN", "GUARDED", "ENCHANTED", "MYTHIC"]
const ARMOR_RARITY_MULT := [1.0, 1.6, 2.3, 3.5]
const BAG_CAPACITY := 5
const RARITY_COLORS := [Color("d0e2f1"), Color("59cdff"), Color("d493ff"), Color("ffd568")]
const RARITY_DAMAGE := [1.0, 1.38, 1.88, 2.85]
const RARITY_RATE := [1.0, 1.06, 1.13, 1.22]
const RARE_NAMES := ["GILDED PISTOL", "HUNTER'S BOW", "MOON SWORD", "IRON CLEAVER", "SWIFT REPEATER", "RUNE WAND", "BLESSED STAFF"]
const EPIC_NAMES := ["STORM PISTOL", "PHANTOM BOW", "SOLAR SABER", "TITAN BLADE", "THUNDER REPEATER", "ASTRAL STAFF", "LIFEBLOOM"]
const LEGEND_NAMES := ["STARFALL", "CELESTIAL BOW", "FATEBREAKER", "WORLDENDER", "INFINITE SALVO", "VOIDCALLER", "SUNHEALER"]
const UPGRADES := ["MAX HP +25", "HEAL +35", "MOVE SPEED +15%", "DAMAGE +25%", "ATTACK SPEED +15%", "PROJECTILE SPEED +20%"]
const AUDIO_PISTOL: AudioStream = preload("res://audio/pistol.wav")
const AUDIO_BOW: AudioStream = preload("res://audio/bow.wav")
const AUDIO_SLASH: AudioStream = preload("res://audio/slash.wav")
const AUDIO_HEAVY: AudioStream = preload("res://audio/heavy.wav")
const AUDIO_IMPACT: AudioStream = preload("res://audio/impact.wav")
const AUDIO_PICKUP: AudioStream = preload("res://audio/pickup.wav")
const AUDIO_RARE: AudioStream = preload("res://audio/rare.wav")
const AUDIO_EPIC: AudioStream = preload("res://audio/epic.wav")
const AUDIO_LEGEND: AudioStream = preload("res://audio/legendary.wav")
const AUDIO_DEFEAT: AudioStream = preload("res://audio/enemy_defeat.wav")

var rng := RandomNumberGenerator.new()
var state := "choose" # choose, playing, upgrade, dead
var class_id := 0
var palette_id := 0
var accessory_id := 0
var character_name := "Ookami"
var base_class_speed := 262.0
var seeds := 8
var carrots := 2
var mushrooms := 1
var stew_meals := 0
var broth_meals := 0
var wave := 0
var combat_elapsed := 0.0
var phase := "prep" # prep, combat, rest
var phase_clock := PREP_SECONDS
var reaper_spawned_this_wave := false
var scenery: Array[Dictionary] = []
var camera: Camera2D
var companion := Vector2(1200, 875)
var companion_hp := 90.0
var companion_max_hp := 90.0
var companion_attack_clock := 0.0
var companion_meal_clock := 4.0
var companion_heal_clock := 5.0
var companion_walk_clock := 0.0
var companion_down_clock := 0.0
var companion_was_moving := false
var hostile_orbs: Array[Dictionary] = []
var farm_plots: Array[Dictionary] = []
var cooking_open := false
var food_buff_clock := 0.0
var heal_spell_clock := 0.0
var player := Vector2(1208, 870)
var hp := 100.0
var max_hp := 100.0
var move_speed := 262.0
var damage_mult := 1.0
var attack_speed_mult := 1.0
var projectile_speed_mult := 1.0
var equipped: Dictionary = {"type": "weapon", "kind": 0, "rarity": 0, "name": "PISTOL"}
var backpack: Array[Dictionary] = []
var armor_equipped: Array[Dictionary] = [{}, {}, {}, {}]
var inventory_open := false
var inventory_message := ""
var enemy_sound_cooldown := 0.0
var armor_test_slot := 0
var brute_flash_clock := 0.0
var kills := 0
var level := 1
var xp := 0
var xp_needed := 5
var elapsed := 0.0
var spawn_clock := 0.55
var fire_clock := 0.0
var hurt_clock := 0.0
var walk_clock := 0.0
var attack_clock := 0.0
var attack_duration := 0.20
var aim_angle := 0.0
var enemy_serial := 0
var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var upgrades: Array[int] = []
var banner_clock := 0.0
var legendary_glow_clock := 0.0
var screen_shake := 0.0
var muted := false
var audio_players: Array[AudioStreamPlayer] = []
var audio_index := 0

var hud: Label
var help: Label
var player_hp_bar: ProgressBar
var companion_hp_bar: ProgressBar
var player_hp_text: Label
var companion_hp_text: Label
var phase_label: Label
var hp_bar_color_state := -1
var pickup_hint: Label
var banner: Label
var choose_panel: PanelContainer
var class_buttons: Array[Button] = []
var name_input: LineEdit
var palette_button: Button
var accessory_button: Button
var character_preview: Label
var cooking_panel: PanelContainer
var cooking_info: Label
var upgrade_panel: PanelContainer
var upgrade_buttons: Array[Button] = []
var dead_panel: PanelContainer
var dead_label: Label
var legendary_hint: Label
var inventory_panel: PanelContainer
var inventory_buttons: Array[Button] = []
var discard_buttons: Array[Button] = []
var armor_buttons: Array[Button] = []
var defense_label: Label
var inventory_status: Label

func _ready() -> void:
	rng.randomize()
	for i in range(12):
		var sfx := AudioStreamPlayer.new()
		sfx.volume_db = -8.0
		add_child(sfx)
		audio_players.append(sfx)
	build_ui()
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.5
	camera.limit_left = int(ARENA.position.x)
	camera.limit_top = int(ARENA.position.y)
	camera.limit_right = int(ARENA.end.x)
	camera.limit_bottom = int(ARENA.end.y)
	add_child(camera)
	reset_game()

func make_style(fill: Color, border: Color, radius: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style

func make_label(value: String, font_size: int, tint: Color, center: bool = false) -> Label:
	var text_label := Label.new()
	text_label.text = value
	text_label.add_theme_font_size_override("font_size", font_size)
	text_label.add_theme_color_override("font_color", tint)
	if center:
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return text_label

func make_panel(pos: Vector2, min_size: Vector2, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", make_style(Color("111d31"), border))
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 25)
	padding.add_theme_constant_override("margin_right", 25)
	padding.add_theme_constant_override("margin_top", 22)
	padding.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(padding)
	return panel

func make_button(text_value: String, color: Color, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", Color("f4faff"))
	b.add_theme_stylebox_override("normal", make_style(Color("21324c"), color, 9))
	b.add_theme_stylebox_override("hover", make_style(Color("344a68"), Color.WHITE, 9))
	b.add_theme_stylebox_override("pressed", make_style(Color("44627e"), color, 9))
	return b

func make_health_bar(pos: Vector2, dims: Vector2, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.custom_minimum_size = dims
	bar.size = dims
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", make_style(Color("1d2637"), Color("7c9bba"), 5))
	bar.add_theme_stylebox_override("fill", make_style(fill_color, fill_color, 5))
	return bar

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = make_label("", 17, Color("eaf6ff"))
	hud.position = Vector2(48, 8)
	layer.add_child(hud)
	player_hp_bar = make_health_bar(Vector2(48, 39), Vector2(297, 26), Color("58e7a0"))
	layer.add_child(player_hp_bar)
	player_hp_text = make_label("", 17, Color.WHITE, true)
	player_hp_text.position = Vector2(48, 41)
	player_hp_text.custom_minimum_size = Vector2(297, 24)
	layer.add_child(player_hp_text)
	companion_hp_bar = make_health_bar(Vector2(362, 39), Vector2(235, 26), Color("69ddea"))
	layer.add_child(companion_hp_bar)
	companion_hp_text = make_label("", 15, Color.WHITE, true)
	companion_hp_text.position = Vector2(362, 43)
	companion_hp_text.custom_minimum_size = Vector2(235, 23)
	layer.add_child(companion_hp_text)
	phase_label = make_label("", 17, Color("ffe69b"))
	phase_label.position = Vector2(617, 41)
	phase_label.custom_minimum_size = Vector2(480, 24)
	layer.add_child(phase_label)
	help = make_label("", 13, Color("aac6e3"))
	help.position = Vector2(48, 74)
	layer.add_child(help)
	pickup_hint = make_label("", 18, Color("ffe998"), true)
	pickup_hint.position = Vector2(245, 575)
	pickup_hint.custom_minimum_size = Vector2(664, 40)
	layer.add_child(pickup_hint)
	banner = make_label("", 31, Color("ffd568"), true)
	banner.position = Vector2(145, 117)
	banner.custom_minimum_size = Vector2(860, 64)
	layer.add_child(banner)

	# Character creation is intentionally a single menu, with six class archetypes.
	choose_panel = make_panel(Vector2(112, 100), Vector2(928, 448), Color("42cfd5"))
	layer.add_child(choose_panel)
	var choose_box := VBoxContainer.new()
	choose_box.add_theme_constant_override("separation", 7)
	choose_panel.get_child(0).add_child(choose_box)
	choose_box.add_child(make_label("DOPAGAKI  /  CREATE YOUR HERO", 29, Color("7de9f0"), true))
	choose_box.add_child(make_label("v0.8 SOLO  |  MINT COMPANION  |  4-PLAYER ONLINE PLANNED", 14, Color("d0dcf3"), true))
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 13)
	choose_box.add_child(name_row)
	name_row.add_child(make_label("HERO NAME", 17, Color("ddf5f9")))
	name_input = LineEdit.new()
	name_input.text = character_name
	name_input.max_length = 16
	name_input.custom_minimum_size = Vector2(220, 34)
	name_input.placeholder_text = "Your hero name"
	name_row.add_child(name_input)
	palette_button = make_button("COLOR: ORIGINAL", Color("58c8e2"), Vector2(180, 34))
	palette_button.add_theme_font_size_override("font_size", 14)
	palette_button.pressed.connect(cycle_palette)
	name_row.add_child(palette_button)
	accessory_button = make_button("HAT: NONE", Color("f2c07d"), Vector2(178, 34))
	accessory_button.add_theme_font_size_override("font_size", 14)
	accessory_button.pressed.connect(cycle_accessory)
	name_row.add_child(accessory_button)
	choose_box.add_child(make_label("CHOOSE YOUR CLASS", 18, Color("e6c98d"), true))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	choose_box.add_child(grid)
	for i in range(CLASS_NAMES.size()):
		var btn := make_button("%d  %s\n%s" % [i + 1, CLASS_NAMES[i], CLASS_DESC[i]], Color("45cad3"), Vector2(269, 77))
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(select_class.bind(i))
		grid.add_child(btn)
		class_buttons.append(btn)
	choose_box.add_child(make_label("[1-6] SELECT CLASS   |   Pick appearance above before starting", 15, Color("adc6e1"), true))
	choose_box.add_child(make_label("Battle waves alternate with safe breaks. Prepare meals; MINT fights and eats!", 16, Color("86eac5"), true))
	# A compact cooking menu with recipe buttons and resource counter.
	cooking_panel = make_panel(Vector2(311, 168), Vector2(530, 311), Color("f6b970"))
	layer.add_child(cooking_panel)
	var cook_box := VBoxContainer.new()
	cook_box.add_theme_constant_override("separation", 12)
	cooking_panel.get_child(0).add_child(cook_box)
	cook_box.add_child(make_label("CAMP KITCHEN", 28, Color("ffd5a0"), true))
	cooking_info = make_label("", 18, Color("b6e8ce"), true)
	cook_box.add_child(cooking_info)
	var soup := make_button("[1] PREPARE STEW (2 carrots)   ->  +40 HP [H]", Color("ffd39f"), Vector2(461, 50))
	soup.pressed.connect(cook_recipe.bind(0))
	cook_box.add_child(soup)
	var broth := make_button("[2] PREPARE BROTH (carrot + mushroom)\n+25 HP / 30s speed boost [J]", Color("ffd39f"), Vector2(461, 70))
	broth.add_theme_font_size_override("font_size", 15)
	broth.pressed.connect(cook_recipe.bind(1))
	cook_box.add_child(broth)
	var exit_cook := make_button("CLOSE [C / ESC]", Color("f6b970"), Vector2(461, 37))
	exit_cook.pressed.connect(toggle_cooking)
	cook_box.add_child(exit_cook)
	cooking_panel.hide()

	upgrade_panel = make_panel(Vector2(225, 168), Vector2(702, 312), Color("93a8ff"))
	layer.add_child(upgrade_panel)
	var upgrade_box := VBoxContainer.new()
	upgrade_box.add_theme_constant_override("separation", 12)
	upgrade_panel.get_child(0).add_child(upgrade_box)
	upgrade_box.add_child(make_label("LEVEL UP!  CHOOSE YOUR POWER", 29, Color("95d8ff"), true))
	upgrade_box.add_child(make_label("Press 1 - 3 or click", 16, Color("c4d4ef"), true))
	for i in range(3):
		var btn := make_button("", Color("82a2ff"), Vector2(570, 45))
		btn.pressed.connect(select_upgrade.bind(i))
		upgrade_buttons.append(btn)
		upgrade_box.add_child(btn)

	dead_panel = make_panel(Vector2(300, 195), Vector2(552, 250), Color("fb758e"))
	layer.add_child(dead_panel)
	var dead_box := VBoxContainer.new()
	dead_box.add_theme_constant_override("separation", 18)
	dead_panel.get_child(0).add_child(dead_box)
	dead_box.add_child(make_label("GAME OVER", 36, Color("ffa3b1"), true))
	dead_label = make_label("", 22, Color("f6fbff"), true)
	dead_box.add_child(dead_label)
	dead_box.add_child(make_label("Press R to create a hero and retry", 18, Color("b7ddfb"), true))
	# Inventory panel is built once. Equipment and backpack are refreshed per game.
	inventory_panel = make_panel(Vector2(659, 69), Vector2(461, 554), Color("5ab9ed"))
	layer.add_child(inventory_panel)
	var inv_padding: MarginContainer = inventory_panel.get_child(0)
	inv_padding.add_theme_constant_override("margin_left", 18)
	inv_padding.add_theme_constant_override("margin_right", 18)
	inv_padding.add_theme_constant_override("margin_top", 12)
	inv_padding.add_theme_constant_override("margin_bottom", 12)
	var inv_box := VBoxContainer.new()
	inv_box.add_theme_constant_override("separation", 6)
	inv_padding.add_child(inv_box)
	inv_box.add_child(make_label("BACKPACK  /  5 SLOTS", 24, Color("87edff"), true))
	inv_box.add_child(make_label("Click an item to equip. Click armor below to remove.", 13, Color("adc6e1"), true))
	for i in range(BAG_CAPACITY):
		var item_row := HBoxContainer.new()
		item_row.add_theme_constant_override("separation", 5)
		var button := make_button("", Color("5b7a9f"), Vector2(331, 36))
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(use_backpack_slot.bind(i))
		inventory_buttons.append(button)
		item_row.add_child(button)
		var drop_button := make_button("DROP", Color("f3958a"), Vector2(78, 36))
		drop_button.add_theme_font_size_override("font_size", 13)
		drop_button.pressed.connect(drop_backpack_slot.bind(i))
		discard_buttons.append(drop_button)
		item_row.add_child(drop_button)
		inv_box.add_child(item_row)
	inv_box.add_child(make_label("EQUIPMENT  /  4 ARMOR PARTS", 17, Color("eac88e"), true))
	for i in range(ARMOR_SLOTS.size()):
		var button := make_button("", Color("5b7a9f"), Vector2(414, 33))
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(unequip_armor.bind(i))
		armor_buttons.append(button)
		inv_box.add_child(button)
	defense_label = make_label("", 17, Color("97edc2"), true)
	inv_box.add_child(defense_label)
	inventory_status = make_label("", 13, Color("ffdf99"), true)
	inv_box.add_child(inventory_status)
	var close_button := make_button("CLOSE BAG [I / ESC]", Color("5ab9ed"), Vector2(414, 34))
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.pressed.connect(toggle_inventory)
	inv_box.add_child(close_button)
	inventory_panel.hide()
	choose_panel.hide()
	cooking_panel.hide()
	upgrade_panel.hide()
	dead_panel.hide()

func reset_game() -> void:
	state = "choose"
	class_id = 0
	player = Vector2(1208, 870)
	camera.position = player
	seeds = 8
	carrots = 2
	mushrooms = 1
	stew_meals = 0
	broth_meals = 0
	wave = 0
	combat_elapsed = 0.0
	phase = "prep"
	phase_clock = PREP_SECONDS
	reaper_spawned_this_wave = false
	companion = player + Vector2(-59, 14)
	companion_hp = companion_max_hp
	companion_attack_clock = 0.5
	companion_meal_clock = 4.0
	companion_heal_clock = 7.0
	companion_walk_clock = 0.0
	companion_down_clock = 0.0
	companion_was_moving = false
	hostile_orbs.clear()
	hp_bar_color_state = -1
	generate_scenery()
	farm_plots.clear()
	for plot_pos in FARM_PLOTS:
		farm_plots.append({"pos": plot_pos, "progress": -1.0})
	cooking_open = false
	food_buff_clock = 0.0
	heal_spell_clock = 0.0
	cooking_panel.hide()
	hp = 100.0
	max_hp = 100.0
	move_speed = 262.0
	damage_mult = 1.0
	attack_speed_mult = 1.0
	projectile_speed_mult = 1.0
	equipped = {"type": "weapon", "kind": 0, "rarity": 0, "name": "PISTOL"}
	backpack.clear()
	for i in range(BAG_CAPACITY):
		backpack.append({})
	armor_equipped = [{}, {}, {}, {}]
	inventory_open = false
	inventory_message = ""
	enemy_sound_cooldown = 0.0
	armor_test_slot = 0
	brute_flash_clock = 0.0
	inventory_panel.hide()
	kills = 0
	level = 1
	xp = 0
	xp_needed = 5
	elapsed = 0.0
	spawn_clock = 0.65
	fire_clock = 0.3
	hurt_clock = 0.0
	walk_clock = 0.0
	attack_clock = 0.0
	aim_angle = 0.0
	enemy_serial = 0
	enemies.clear()
	projectiles.clear()
	drops.clear()
	particles.clear()
	upgrades.clear()
	banner_clock = 0.0
	legendary_glow_clock = 0.0
	screen_shake = 0.0
	choose_panel.show()
	name_input.text = character_name
	palette_button.text = "COLOR: %s" % PALETTE_NAMES[palette_id]
	accessory_button.text = "HAT: %s" % ACCESSORY_NAMES[accessory_id]
	upgrade_panel.hide()
	dead_panel.hide()
	banner.hide()
	pickup_hint.text = ""
	refresh_inventory_ui()
	update_hud()
	queue_redraw()

func cycle_palette() -> void:
	if state != "choose":
		return
	palette_id = (palette_id + 1) % WOLF_PALETTES.size()
	palette_button.text = "COLOR: %s" % PALETTE_NAMES[palette_id]
	play_sound(AUDIO_PICKUP, -19.0)
	queue_redraw()

func cycle_accessory() -> void:
	if state != "choose":
		return
	accessory_id = (accessory_id + 1) % ACCESSORY_NAMES.size()
	accessory_button.text = "HAT: %s" % ACCESSORY_NAMES[accessory_id]
	play_sound(AUDIO_PICKUP, -19.0)
	queue_redraw()

func select_class(index: int) -> void:
	if state != "choose" or index < 0 or index >= CLASS_NAMES.size():
		return
	class_id = index
	character_name = name_input.text.strip_edges().substr(0, 16)
	if character_name.is_empty():
		character_name = "Ookami"
	equipped = {"type": "weapon", "kind": CLASS_WEAPONS[index], "rarity": 0, "name": WEAPONS[CLASS_WEAPONS[index]]}
	match index:
		0: # Warrior: balanced, begins with slightly better defense.
			hp = 115.0
			max_hp = 115.0
		1: # Archer: agile marksman.
			move_speed = 297.0
		2: # Crossbowman: strong burst, a little less mobile.
			move_speed = 245.0
		3: # Mage: heavy staff damage, fragile.
			max_hp = 85.0
			hp = 85.0
			damage_mult = 1.15
		4: # Berserker: toughest start, strongest weapon.
			max_hp = 140.0
			hp = 140.0
			move_speed = 235.0
		5: # Healer: low damage, repeatable self-heal in this solo prototype.
			max_hp = 115.0
			hp = 115.0
	base_class_speed = move_speed
	state = "playing"
	fire_clock = 0.25
	choose_panel.hide()
	show_status("%s  /  %s   PREPARE AT CAMP!" % [character_name.to_upper(), CLASS_NAMES[index]], Color("90e7ed"))
	play_sound(AUDIO_PICKUP, -10.0)

func nearest_plot_index() -> int:
	var best := -1
	var dmin := 75.0
	for i in range(farm_plots.size()):
		var d: float = player.distance_to(farm_plots[i]["pos"])
		if d < dmin:
			best = i
			dmin = d
	return best

func farm_interact() -> void:
	var plot_i := nearest_plot_index()
	if plot_i < 0:
		show_status("Stand near a farm plot (right side).", Color("bbdcc8"))
		return
	var plot: Dictionary = farm_plots[plot_i]
	var progress := float(plot["progress"])
	if progress < 0.0:
		if seeds <= 0:
			show_status("No seeds! Defeat clowns for more.", Color("ffc18a"))
			return
		seeds -= 1
		plot["progress"] = 0.0
		show_status("Seed planted! Wait %.0f seconds." % GROW_SECONDS, Color("b3f6b1"))
		play_sound(AUDIO_PICKUP, -17.0)
	elif progress >= GROW_SECONDS:
		carrots += 2
		plot["progress"] = -1.0
		show_status("HARVEST! +2 carrots. Cook them at the campfire!", Color("b3f6b1"))
		burst(plot["pos"], Color("ffa766"), 14)
		play_sound(AUDIO_PICKUP, -11.0)
	else:
		show_status("Growing... %d seconds left" % int(ceil(GROW_SECONDS - progress)), Color("b3f6b1"))

func toggle_cooking() -> void:
	if state != "playing":
		return
	if not cooking_open and nearest_camp_index() < 0:
		show_status("Stand near a glowing campfire to cook.", Color("ffd7a2"))
		return
	cooking_open = not cooking_open
	cooking_panel.visible = cooking_open
	if cooking_open:
		inventory_open = false
		inventory_panel.hide()
		refresh_cooking_ui()
		pickup_hint.text = ""

func refresh_cooking_ui() -> void:
	cooking_info.text = "CARROTS %d   MUSHROOMS %d   SEEDS %d\nPREPARED: STEW %d [H]  /  BROTH %d [J]" % [carrots, mushrooms, seeds, stew_meals, broth_meals]

func cook_recipe(which: int) -> void:
	if state != "playing" or not cooking_open:
		return
	if which == 0:
		if carrots < 2:
			show_status("Need 2 carrots for stew!", Color("ffbbaa"))
			return
		carrots -= 2
		stew_meals += 1
		show_status("COOKED CARROT STEW! [H] EAT  |  MINT CAN EAT TOO", Color("95ffae"))
	else:
		if carrots < 1 or mushrooms < 1:
			show_status("Need 1 carrot + 1 mushroom!", Color("ffbbaa"))
			return
		carrots -= 1
		mushrooms -= 1
		broth_meals += 1
		show_status("COOKED HUNTER BROTH! [J] EAT  |  MINT CAN EAT TOO", Color("95ffae"))
	refresh_cooking_ui()
	play_sound(AUDIO_RARE, -16.0)
	burst(CAMP_STATIONS[maxi(0, nearest_camp_index())], Color("ffc782"), 24)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_M:
		muted = not muted
		for sound in audio_players:
			sound.volume_db = -80.0 if muted else -8.0
		return
	if state == "choose":
		# Do not steal numeric input while entering a character name.
		if name_input.has_focus():
			return
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			select_class(event.keycode - KEY_1)
		return
	if state == "upgrade":
		if event.keycode >= KEY_1 and event.keycode <= KEY_3:
			select_upgrade(event.keycode - KEY_1)
		return
	if state == "dead":
		if event.keycode == KEY_R:
			reset_game()
		return
	if state == "playing":
		if cooking_open:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_C:
				toggle_cooking()
			elif event.keycode == KEY_1:
				cook_recipe(0)
			elif event.keycode == KEY_2:
				cook_recipe(1)
			return
		if event.keycode == KEY_I or (inventory_open and event.keycode == KEY_ESCAPE):
			toggle_inventory()
			return
		if inventory_open:
			return
		if event.keycode == KEY_E:
			pickup_nearby()
		elif event.keycode == KEY_G:
			farm_interact()
		elif event.keycode == KEY_C:
			toggle_cooking()
		elif event.keycode == KEY_H:
			eat_meal(false)
		elif event.keycode == KEY_J:
			eat_meal(true)
		elif event.keycode == KEY_F6:
			spawn_brute_test()
		elif event.keycode == KEY_F7:
			# Always cycle HEAD -> CHEST -> LEGGINGS -> ARMS for easy visual testing.
			spawn_armor_drop(player + Vector2(72, 0), 1, armor_test_slot)
			armor_test_slot = (armor_test_slot + 1) % ARMOR_SLOTS.size()
		elif event.keycode == KEY_F8:
			# Debug: guarantee a legendary item without grinding.
			spawn_drop(player + Vector2(72, -20), 3)
		elif event.keycode == KEY_F9:
			spawn_reaper((player + Vector2(300, -140)).clamp(ARENA.position + Vector2(80, 80), ARENA.end - Vector2(80, 80)))
		elif event.keycode == KEY_F10:
			companion_take_damage(56.0)
			show_status("TEST: MINT IS HURT! PREPARE STEW TO SEE THEM EAT.", Color("bdfce5"))

func play_sound(sound: AudioStream, db: float = -8.0, pitch: float = 1.0) -> void:
	if muted:
		return
	var channel: AudioStreamPlayer = audio_players[audio_index]
	for item in audio_players:
		if not item.playing:
			channel = item
			break
	channel.stop()
	channel.stream = sound
	channel.volume_db = db
	channel.pitch_scale = pitch
	channel.play()
	audio_index = (audio_index + 1) % audio_players.size()

func _process(delta: float) -> void:
	if banner_clock > 0.0:
		banner_clock = maxf(0.0, banner_clock - delta)
		banner.visible = banner_clock > 0.0
	if legendary_glow_clock > 0.0:
		legendary_glow_clock = maxf(0.0, legendary_glow_clock - delta)
	if screen_shake > 0.0:
		screen_shake = maxf(0.0, screen_shake - delta)
	if brute_flash_clock > 0.0:
		brute_flash_clock = maxf(0.0, brute_flash_clock - delta)
	attack_clock = maxf(0.0, attack_clock - delta)
	enemy_sound_cooldown = maxf(0.0, enemy_sound_cooldown - delta)
	if state != "playing" or inventory_open or cooking_open:
		update_hud()
		queue_redraw()
		return
	elapsed += delta
	food_buff_clock = maxf(0.0, food_buff_clock - delta)
	heal_spell_clock = maxf(0.0, heal_spell_clock - delta)
	for plot in farm_plots:
		if float(plot["progress"]) >= 0.0 and float(plot["progress"]) < GROW_SECONDS:
			plot["progress"] = minf(GROW_SECONDS, float(plot["progress"]) + delta)
	phase_clock -= delta
	if phase_clock <= 0.0:
		advance_phase()
	fire_clock -= delta
	hurt_clock = maxf(0.0, hurt_clock - delta)
	var movement := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): movement.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): movement.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): movement.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): movement.y += 1.0
	if movement.length_squared() > 0.1:
		walk_clock += delta * 10.0
		player += movement.normalized() * move_speed * (1.25 if food_buff_clock > 0.0 else 1.0) * delta
	else:
		walk_clock = 0.0
	player = player.clamp(ARENA.position + Vector2(35, 45), ARENA.end - Vector2(35, 35))
	camera.position = player
	var aim: Vector2 = get_global_mouse_position() - player
	if aim.length() > 3.0:
		aim_angle = aim.angle()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fire_clock <= 0.0 and phase == "combat":
		attack()
	if phase == "combat":
		combat_elapsed += delta
		spawn_clock -= delta
		if spawn_clock <= 0.0:
			spawn_enemy()
			spawn_clock = maxf(0.53, 1.55 - float(wave) * 0.10 - combat_elapsed * 0.0025)
		if wave >= 3 and not reaper_spawned_this_wave and phase_clock < COMBAT_SECONDS - 7.0 and not boss_alive():
			reaper_spawned_this_wave = true
			spawn_reaper(random_spawn_edge())
			show_status("NIGHT REAPER HAS ARRIVED!", Color("ff839e"))
	update_companion(delta)
	update_projectiles(delta)
	if phase == "combat":
		update_enemies(delta)
		update_hostile_orbs(delta)
		cleanup_defeated_enemies()
	update_particles(delta)
	update_drops(delta)
	if state == "playing" and xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 4 + level * 3
		start_upgrade()
	update_hud()
	queue_redraw()

func advance_phase() -> void:
	if phase == "combat":
		phase = "rest"
		phase_clock = REST_SECONDS
		enemies.clear()
		projectiles.clear()
		hostile_orbs.clear()
		seeds += 2
		mushrooms += 1
		companion_hp = minf(companion_max_hp, companion_hp + 25.0)
		show_status("CAMP BREAK! %ds SAFE  |  +2 SEEDS +1 MUSHROOM" % int(REST_SECONDS), Color("a8f6bd"))
		play_sound(AUDIO_PICKUP, -12.0)
	else:
		phase = "combat"
		wave += 1
		reaper_spawned_this_wave = false
		phase_clock = COMBAT_SECONDS
		spawn_clock = 1.0
		show_status("WAVE %d  -  SURVIVE!  (NEXT BREAK IN 48s)" % wave, Color("ffb8a0"))
		play_sound(AUDIO_HEAVY, -20.0)

func boss_alive() -> bool:
	for enemy in enemies:
		if bool(enemy["boss"]) and float(enemy["hp"]) > 0.0:
			return true
	return false

func nearest_camp_index() -> int:
	for i in range(CAMP_STATIONS.size()):
		if player.distance_to(CAMP_STATIONS[i]) < 115.0:
			return i
	return -1

func eat_meal(is_broth: bool) -> void:
	if is_broth:
		if broth_meals < 1:
			show_status("No broth! Cook [C] at a campfire.", Color("ffbfa7"))
			return
		broth_meals -= 1
		hp = minf(max_hp, hp + 25.0)
		food_buff_clock = 30.0
		show_status("HUNTER BROTH! +25 HP +SPEED", Color("a4ffbc"))
	else:
		if stew_meals < 1:
			show_status("No stew! Cook [C] at a campfire.", Color("ffbfa7"))
			return
		stew_meals -= 1
		hp = minf(max_hp, hp + 40.0)
		show_status("CARROT STEW! +40 HP", Color("a4ffbc"))
	burst(player, Color("adffca"), 20)
	play_sound(AUDIO_PICKUP, -12.0)

func update_companion(delta: float) -> void:
	if companion_hp <= 0.0:
		companion_down_clock = maxf(0.0, companion_down_clock - delta)
		if companion_down_clock <= 0.0:
			companion_hp = companion_max_hp * 0.75
			companion = player + Vector2(-65, 22)
			show_status("MINT IS BACK TO HELP!", Color("a7ffee"))
		return
	companion_attack_clock -= delta
	companion_meal_clock -= delta
	companion_heal_clock -= delta
	var follow_pos := player + Vector2(-58, 32)
	var dist := companion.distance_to(follow_pos)
	companion_was_moving = dist > 12.0
	if dist > 600.0:
		companion = follow_pos
	elif dist > 12.0:
		companion += (follow_pos - companion).normalized() * minf(dist, 300.0 * delta)
	if companion_was_moving:
		companion_walk_clock += 10.0 * delta
	else:
		companion_walk_clock = 0.0
	# Ally shares cooked meals from the kitchen stock when injured.
	if companion_hp < companion_max_hp * 0.64 and companion_meal_clock <= 0.0:
		if stew_meals > 0:
			stew_meals -= 1
			companion_hp = minf(companion_max_hp, companion_hp + 42.0)
			companion_meal_clock = 6.0
			show_status("MINT ATE CARROT STEW! +42 HP", Color("c0ffe2"))
			burst(companion, Color("9fffc1"), 18)
			play_sound(AUDIO_PICKUP, -14.0)
		elif broth_meals > 0:
			broth_meals -= 1
			companion_hp = minf(companion_max_hp, companion_hp + 28.0)
			companion_meal_clock = 6.0
			show_status("MINT ATE HUNTER BROTH! +28 HP", Color("c0ffe2"))
			burst(companion, Color("9fffc1"), 18)
			play_sound(AUDIO_PICKUP, -14.0)
	if phase != "combat":
		return
	if hp < max_hp * 0.48 and companion_heal_clock <= 0.0 and player.distance_to(companion) < 200.0:
		hp = minf(max_hp, hp + 12.0)
		companion_heal_clock = 13.0
		burst(player, Color("9fffe0"), 12)
		show_status("MINT HEALED YOU +12 HP", Color("9fffe0"))
	if companion_attack_clock <= 0.0:
		var best: Dictionary = {}
		var near := 355.0
		for enemy in enemies:
			if float(enemy["hp"]) <= 0.0:
				continue
			var d: float = companion.distance_to(enemy["pos"])
			if d < near:
				near = d
				best = enemy
		if not best.is_empty():
			var direction := ((best["pos"] as Vector2) - companion).normalized()
			projectiles.append({"pos": companion + direction * 27.0, "vel": direction * 720.0, "dmg": 3.6 + minf(3.0, wave * 0.35), "radius": 5.0, "pierce": 1, "kind": "magic", "tint": Color("8bffe1"), "life": 1.1, "hit_ids": []})
			companion_attack_clock = 0.85
			play_sound(AUDIO_BOW, -27.0, 1.4)

func update_hostile_orbs(delta: float) -> void:
	for i in range(hostile_orbs.size() - 1, -1, -1):
		var orb: Dictionary = hostile_orbs[i]
		orb["pos"] = (orb["pos"] as Vector2) + (orb["vel"] as Vector2) * delta
		orb["life"] = float(orb["life"]) - delta
		var gone := float(orb["life"]) <= 0.0 or not ARENA.has_point(orb["pos"])
		if not gone and player.distance_to(orb["pos"]) < 20.0:
			hp -= maxf(2.0, 14.0 * (1.0 - calculate_damage_reduction()))
			hurt_clock = 0.24
			burst(player, Color("ff6393"), 13)
			gone = true
			if hp <= 0.0:
				player_died()
		if not gone and companion_hp > 0.0 and companion.distance_to(orb["pos"]) < 19.0:
			companion_take_damage(11.0)
			gone = true
		if gone:
			hostile_orbs.remove_at(i)

func companion_take_damage(amount: float) -> void:
	if companion_hp <= 0.0:
		return
	companion_hp = maxf(0.0, companion_hp - amount)
	burst(companion, Color("9de9fc"), 7)
	if companion_hp <= 0.0:
		companion_down_clock = 24.0
		show_status("MINT IS DOWN! RETURNS IN 24s", Color("fcb7b9"))

func player_died() -> void:
	state = "dead"
	dead_panel.show()
	dead_label.text = "WAVE %d   KILLS %d   LEVEL %d" % [wave, kills, level]

func generate_scenery() -> void:
	scenery.clear()
	var decor_rng := RandomNumberGenerator.new()
	decor_rng.seed = 802411
	for i in range(155):
		var pos := Vector2(decor_rng.randf_range(105.0, ARENA.end.x - 85.0), decor_rng.randf_range(175.0, ARENA.end.y - 68.0))
		var close_to_camp := false
		for station in CAMP_STATIONS:
			if pos.distance_to(station) < 255.0:
				close_to_camp = true
		if close_to_camp:
			continue
		scenery.append({"pos": pos, "kind": decor_rng.randi_range(0, 2), "size": decor_rng.randf_range(0.8, 1.4)})

func attack() -> void:
	var kind: int = int(equipped["kind"])
	var tier: int = int(equipped["rarity"])
	var power: float = RARITY_DAMAGE[tier] * damage_mult
	var speed: float = RARITY_RATE[tier] * attack_speed_mult
	attack_clock = 0.21
	attack_duration = 0.21
	match kind:
		0: # pistol
			fire_clock = 0.29 / speed
			launch_projectile(aim_angle, 850.0, 3.5 * power, 4.0, 1, Color("ffe4a3"), "bullet")
			play_sound(AUDIO_PISTOL, -14.0)
			burst(player + Vector2.RIGHT.rotated(aim_angle) * 38.0, Color("ffe4a3"), 3)
		1: # bow: slower, accurate, can pierce two targets
			fire_clock = 0.65 / speed
			launch_projectile(aim_angle, 740.0, 5.3 * power, 5.0, 2, Color("8be2c1"), "arrow")
			play_sound(AUDIO_BOW, -13.0)
		2: # sword: close, quick 105 degree sweep
			fire_clock = 0.34 / speed
			melee_hit(110.0, 1.05, 4.6 * power, 18.0)
			play_sound(AUDIO_SLASH, -12.0)
		3: # greatsword: much larger slow cleave
			fire_clock = 0.85 / speed
			attack_clock = 0.33
			attack_duration = 0.33
			melee_hit(155.0, 1.3, 9.0 * power, 42.0)
			play_sound(AUDIO_HEAVY, -10.0)
			burst(player + Vector2.RIGHT.rotated(aim_angle) * 85.0, Color("e6b7ff"), 12)
		4: # Repeating crossbow: triple burst
			fire_clock = 0.63 / speed
			for offset in [-0.11, 0.0, 0.11]:
				launch_projectile(aim_angle + offset, 835.0, 2.5 * power, 3.5, 1, Color("fcd68b"), "arrow")
			play_sound(AUDIO_BOW, -14.0, 1.3)
		5: # Mage staff: magic piercing orb
			fire_clock = 0.74 / speed
			launch_projectile(aim_angle, 610.0, 8.4 * power, 9.0, 3, Color("bb96ff"), "magic")
			play_sound(AUDIO_EPIC, -24.0, 1.35)
		6: # Healing staff: modest ranged attack and periodic self-heal.
			fire_clock = 0.62 / speed
			launch_projectile(aim_angle, 680.0, 3.2 * power, 7.0, 2, Color("a5ffcc"), "magic")
			if heal_spell_clock <= 0.0:
				hp = minf(max_hp, hp + 8.0)
				heal_spell_clock = 3.0
				burst(player, Color("a4ffce"), 10)
			play_sound(AUDIO_BOW, -19.0, 1.6)

func launch_projectile(angle: float, speed: float, dmg: float, radius: float, pierce: int, tint: Color, kind: String) -> void:
	var velocity := Vector2.RIGHT.rotated(angle) * speed * projectile_speed_mult
	projectiles.append({"pos": player + Vector2.RIGHT.rotated(angle) * 37.0, "vel": velocity, "dmg": dmg, "radius": radius, "pierce": pierce, "kind": kind, "tint": tint, "life": 1.35, "hit_ids": []})

func melee_hit(radius: float, half_angle: float, dmg: float, knockback: float) -> void:
	var direction := Vector2.RIGHT.rotated(aim_angle)
	for enemy in enemies:
		var diff: Vector2 = enemy["pos"] - player
		if diff.length() > radius + 16.0:
			continue
		if diff.length() > 1.0 and absf(wrapf(diff.angle() - aim_angle, -PI, PI)) > half_angle:
			continue
		enemy["hp"] = float(enemy["hp"]) - dmg
		enemy["pos"] = (enemy["pos"] as Vector2) + direction * knockback
		enemy["hurt"] = 0.17
		burst(enemy["pos"], Color("f2c6ff"), 6)

func random_spawn_edge() -> Vector2:
	# Enemies arrive beyond the current camera view, not from the distant world border.
	for tries in range(22):
		var angle := rng.randf_range(0.0, TAU)
		var d := rng.randf_range(570.0, 710.0)
		var result := (player + Vector2.RIGHT.rotated(angle) * d).clamp(ARENA.position + Vector2(55, 55), ARENA.end - Vector2(55, 55))
		if result.distance_to(player) > 475.0:
			return result
	return (player + Vector2(450, 300)).clamp(ARENA.position + Vector2(55, 55), ARENA.end - Vector2(55, 55))

func spawn_enemy() -> void:
	if enemies.size() >= 65:
		return
	var elite_chance := 0.16 if wave >= 2 else 0.05
	if rng.randf() < elite_chance:
		spawn_brute(random_spawn_edge())
		return
	var fast := rng.randf() < 0.25
	var total_hp := (6.5 if fast else 8.5) + float(wave) * 1.35
	enemy_serial += 1
	enemies.append({"id": enemy_serial, "pos": random_spawn_edge(), "hp": total_hp, "max_hp": total_hp,
		"speed": 159.0 if fast else 106.0, "fast": fast, "elite": false, "boss": false,
		"touch": 0.0, "hurt": 0.0, "walk": rng.randf() * 4.0, "target_ally": rng.randf() < 0.28,
		"windup": 0.0, "charge": 0.0, "charge_cd": 0.0, "charge_dir": Vector2.ZERO, "orb_cd": 0.0})

func spawn_brute(pos: Vector2) -> void:
	if enemies.size() >= 75:
		return
	var total_hp := 28.0 + float(wave) * 4.0
	enemy_serial += 1
	enemies.append({"id": enemy_serial, "pos": pos, "hp": total_hp, "max_hp": total_hp,
		"speed": 79.0, "fast": false, "elite": true, "boss": false, "target_ally": rng.randf() < 0.32,
		"touch": 0.45, "hurt": 0.0, "walk": rng.randf() * 4.0,
		"windup": 0.0, "charge": 0.0, "charge_cd": 0.0, "charge_dir": Vector2.ZERO, "orb_cd": 0.0})
	burst(pos, Color("aa91ff"), 19)

func spawn_reaper(pos: Vector2) -> void:
	if enemies.size() >= 65:
		return
	var total_hp := 100.0 + float(wave) * 18.0
	enemy_serial += 1
	enemies.append({"id": enemy_serial, "pos": pos, "hp": total_hp, "max_hp": total_hp,
		"speed": 112.0, "fast": false, "elite": true, "boss": true, "target_ally": rng.randf() < 0.22,
		"touch": 0.7, "hurt": 0.0, "walk": rng.randf() * 4.0,
		"windup": 0.0, "charge": 0.0, "charge_cd": 0.0, "charge_dir": Vector2.ZERO, "orb_cd": 2.4})
	burst(pos, Color("fa5687"), 28)

func spawn_brute_test() -> void:
	# F6: spawn a single elite visibly near the player, away from the HUD.
	var target := (player + Vector2(215, -70)).clamp(ARENA.position + Vector2(40, 75), ARENA.end - Vector2(40, 35))
	spawn_brute(target)
	show_status("STORM BRUTE!  Watch out for the charge attack!", Color("cba3ff"))

func update_enemies(delta: float) -> void:
	for enemy in enemies:
		if float(enemy["hp"]) <= 0.0:
			continue
		var target_ally: bool = bool(enemy["target_ally"]) and companion_hp > 0.0
		var target_pos: Vector2 = companion if target_ally else player
		var toward: Vector2 = target_pos - enemy["pos"]
		var elite: bool = bool(enemy["elite"])
		var boss: bool = bool(enemy["boss"])
		enemy["touch"] = maxf(0.0, float(enemy["touch"]) - delta)
		enemy["charge_cd"] = maxf(0.0, float(enemy["charge_cd"]) - delta)
		enemy["hurt"] = maxf(0.0, float(enemy["hurt"]) - delta)
		if boss:
			enemy["orb_cd"] = maxf(0.0, float(enemy["orb_cd"]) - delta)
			# Keeps closing in while firing, so melee heroes can reach it and its touch attack is live.
			if toward.length() > 60.0:
				enemy["pos"] = (enemy["pos"] as Vector2) + toward.normalized() * float(enemy["speed"]) * delta
			if float(enemy["orb_cd"]) <= 0.0 and toward.length() < 420.0:
				enemy["orb_cd"] = 3.2
				for rot in [-0.22, 0.0, 0.22]:
					var aim_vec := toward.normalized().rotated(rot)
					hostile_orbs.append({"pos": enemy["pos"], "vel": aim_vec * 280.0, "life": 2.0})
				burst(enemy["pos"], Color("ff5c96"), 14)
			enemy["walk"] = float(enemy["walk"]) + delta * 7.0
		elif elite:
			var windup: float = float(enemy["windup"])
			var charge: float = float(enemy["charge"])
			if windup > 0.0:
				enemy["windup"] = windup - delta
				if float(enemy["windup"]) <= 0.0:
					enemy["charge"] = 0.42
			elif charge > 0.0:
				enemy["pos"] = (enemy["pos"] as Vector2) + (enemy["charge_dir"] as Vector2) * 295.0 * delta
				enemy["charge"] = charge - delta
			elif toward.length() < 195.0 and float(enemy["charge_cd"]) <= 0.0:
				enemy["windup"] = 0.55
				enemy["charge_dir"] = toward.normalized()
				enemy["charge_cd"] = 2.5
				brute_flash_clock = 0.15
			elif toward.length_squared() > 0.1:
				enemy["pos"] = (enemy["pos"] as Vector2) + toward.normalized() * float(enemy["speed"]) * delta
			enemy["walk"] = float(enemy["walk"]) + delta * 6.0
		else:
			if toward.length_squared() > 0.1:
				enemy["pos"] = (enemy["pos"] as Vector2) + toward.normalized() * float(enemy["speed"]) * delta
			enemy["walk"] = float(enemy["walk"]) + delta * (12.0 if enemy["fast"] else 8.0)
		enemy["pos"] = (enemy["pos"] as Vector2).clamp(ARENA.position + Vector2(22, 40), ARENA.end - Vector2(22, 25))
		var hit_radius := 46.0 if boss else (42.0 if elite else 33.0)
		var raw_damage := 24.0 if boss else (18.0 if elite else (11.0 if enemy["fast"] else 9.0))
		if target_pos.distance_to(enemy["pos"]) < hit_radius and float(enemy["touch"]) <= 0.0:
			if target_ally:
				companion_take_damage(raw_damage * 0.85)
			else:
				hp -= maxf(1.0, raw_damage * (1.0 - calculate_damage_reduction()))
				hurt_clock = 0.24
				burst(player, Color("ff568c") if boss else Color("ac91ff") if elite else Color("fc728e"), 16)
				play_sound(AUDIO_IMPACT, -12.0, 0.66 if boss else 1.0)
				if hp <= 0.0:
					player_died()
					return
			enemy["touch"] = 1.2 if elite else 0.76

func update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var bullet: Dictionary = projectiles[i]
		bullet["pos"] = (bullet["pos"] as Vector2) + (bullet["vel"] as Vector2) * delta
		bullet["life"] = float(bullet["life"]) - delta
		var exhausted := float(bullet["life"]) <= 0.0 or not ARENA.grow(20.0).has_point(bullet["pos"])
		if not exhausted:
			for enemy in enemies:
				if float(enemy["hp"]) <= 0.0:
					continue
				var hit_ids: Array = bullet["hit_ids"]
				if hit_ids.has(enemy["id"]):
					continue
				if (enemy["pos"] as Vector2).distance_to(bullet["pos"]) <= 18.0 + float(bullet["radius"]):
					enemy["hp"] = float(enemy["hp"]) - float(bullet["dmg"])
					enemy["hurt"] = 0.15
					hit_ids.append(enemy["id"])
					bullet["pierce"] = int(bullet["pierce"]) - 1
					burst(bullet["pos"], bullet["tint"], 5)
					if int(bullet["pierce"]) <= 0:
						exhausted = true
						break
		if exhausted:
			projectiles.remove_at(i)

func cleanup_defeated_enemies() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		if float(enemy["hp"]) > 0.0:
			continue
		var death_spot: Vector2 = enemy["pos"]
		var elite: bool = bool(enemy["elite"])
		burst(death_spot, Color("a1cbff") if elite else Color("ff7c9b"), 24 if elite else 12)
		enemies.remove_at(i)
		kills += 1
		var boss: bool = bool(enemy["boss"])
		xp += 9 if boss else (3 if elite else 1)
		# Distinct satisfying enemy-defeat effect with small random pitch changes.
		if enemy_sound_cooldown <= 0.0:
			play_sound(AUDIO_DEFEAT, -11.0, rng.randf_range(0.92, 1.10))
			enemy_sound_cooldown = 0.07
		if boss:
			# A dangerous rare boss still guarantees a meaningful reward.
			var tier := maxi(2, roll_brute_rarity())
			if rng.randf() < 0.5:
				spawn_armor_drop(death_spot, tier)
			else:
				spawn_drop(death_spot, tier)
		elif elite:
			# Brutes used to guarantee drops. Now only 35% drop rare gear.
			if rng.randf() < 0.35:
				var tier := roll_brute_rarity()
				if rng.randf() < 0.5:
					spawn_armor_drop(death_spot, tier)
				else:
					spawn_drop(death_spot, tier)
		else:
			# Normal equipment drop: just 8% total (previously ~28.7%).
			if rng.randf() < 0.12:
				seeds += 1
			if rng.randf() < 0.06:
				mushrooms += 1
			var equipment_roll := rng.randf()
			if equipment_roll < 0.045:
				spawn_drop(death_spot, roll_loot_rarity())
			elif equipment_roll < 0.08:
				spawn_armor_drop(death_spot, roll_loot_rarity())

func build_drop_name(kind: int, rarity: int) -> String:
	match rarity:
		1: return RARE_NAMES[kind]
		2: return EPIC_NAMES[kind]
		3: return LEGEND_NAMES[kind]
	return WEAPONS[kind]

func roll_loot_rarity() -> int:
	var draw := rng.randf()
	if draw >= 0.95:
		return 3
	if draw >= 0.77:
		return 2
	return 1

func roll_brute_rarity() -> int:
	var draw := rng.randf()
	if draw < 0.08:
		return 3
	if draw < 0.40:
		return 2
	return 1

func spawn_drop(pos: Vector2, rarity: int) -> void:
	var kind := rng.randi_range(0, WEAPONS.size() - 1)
	var name := build_drop_name(kind, rarity)
	drops.append({"type": "weapon", "pos": pos, "rarity": rarity, "kind": kind, "name": name, "life": 30.0 if rarity == 3 else 22.0, "phase": rng.randf() * TAU})
	celebrate_loot(pos, rarity, name)

func spawn_armor_drop(pos: Vector2, rarity: int, forced_slot: int = -1) -> void:
	var slot := forced_slot if forced_slot >= 0 else rng.randi_range(0, ARMOR_SLOTS.size() - 1)
	var defense := maxi(1, roundi(float(ARMOR_BASE_DEF[slot]) * ARMOR_RARITY_MULT[rarity]))
	var name := "%s %s" % [ARMOR_PREFIX[rarity], ARMOR_SLOTS[slot]]
	drops.append({"type": "armor", "pos": pos, "rarity": rarity, "slot": slot, "name": name, "defense": defense, "life": 30.0 if rarity == 3 else 22.0, "phase": rng.randf() * TAU})
	celebrate_loot(pos, rarity, name)

func celebrate_loot(pos: Vector2, rarity: int, name: String) -> void:
	var c: Color = RARITY_COLORS[rarity]
	burst(pos, c, 24 if rarity == 3 else 9)
	if rarity == 3:
		# Dedicated musical cue, banner and dramatic visual flash.
		play_sound(AUDIO_LEGEND, -6.0)
		banner.text = "★ LEGENDARY DROP!  %s ★" % name
		banner.add_theme_color_override("font_color", c)
		banner_clock = 4.2
		legendary_glow_clock = 2.4
		screen_shake = 0.26
	elif rarity == 2:
		play_sound(AUDIO_EPIC, -10.0)
		banner.text = "EPIC DROP!  %s" % name
		banner.add_theme_color_override("font_color", c)
		banner_clock = 2.4
	else:
		play_sound(AUDIO_RARE, -14.0)
		banner.text = "RARE DROP!  %s" % name
		banner.add_theme_color_override("font_color", c)
		banner_clock = 1.8
	banner.show()

func free_backpack_slot() -> int:
	for i in range(backpack.size()):
		if backpack[i].is_empty():
			return i
	return -1

func to_inventory_item(drop: Dictionary) -> Dictionary:
	var item: Dictionary = {"type": str(drop["type"]), "rarity": int(drop["rarity"]), "name": str(drop["name"])}
	if str(drop["type"]) == "weapon":
		item["kind"] = int(drop["kind"])
	else:
		item["slot"] = int(drop["slot"])
		item["defense"] = int(drop["defense"])
	return item

func item_description(item: Dictionary) -> String:
	if item.is_empty():
		return "-- EMPTY --"
	var rarity := str(RARITIES[int(item["rarity"])])
	if str(item["type"]) == "armor":
		return "%s  [+%d DEF]  (%s)" % [item["name"], int(item["defense"]), rarity]
	return "%s  [WEAPON]  (%s)" % [item["name"], rarity]

func pickup_nearby() -> void:
	var closest := -1
	var distance := 92.0
	for i in range(drops.size()):
		var check: float = player.distance_to(drops[i]["pos"])
		if check < distance:
			closest = i
			distance = check
	if closest < 0:
		return
	var empty_slot := free_backpack_slot()
	if empty_slot < 0:
		show_status("BACKPACK FULL!  Open [I] and manage your items.", Color("ff9d9d"))
		play_sound(AUDIO_IMPACT, -23.0)
		return
	var item: Dictionary = to_inventory_item(drops[closest])
	backpack[empty_slot] = item
	var color: Color = RARITY_COLORS[int(item["rarity"])]
	burst(player, color, 16)
	play_sound(AUDIO_PICKUP, -10.0)
	drops.remove_at(closest)
	show_status("STORED [%d/5]: %s   |   [I] BAG TO EQUIP" % [empty_slot + 1, item["name"]], color)
	refresh_inventory_ui()

func show_status(message: String, color: Color = Color("ffe998")) -> void:
	banner.text = message
	banner.add_theme_color_override("font_color", color)
	banner_clock = 2.7
	banner.show()

func toggle_inventory() -> void:
	if state != "playing":
		return
	inventory_open = not inventory_open
	if inventory_open:
		cooking_open = false
		cooking_panel.hide()
	inventory_message = ""
	inventory_panel.visible = inventory_open
	if inventory_open:
		refresh_inventory_ui()
		pickup_hint.text = ""

func use_backpack_slot(index: int) -> void:
	if not inventory_open or index < 0 or index >= backpack.size():
		return
	var item: Dictionary = backpack[index]
	if item.is_empty():
		inventory_message = "Nothing in this slot."
		refresh_inventory_ui()
		return
	if str(item["type"]) == "weapon":
		var previous_weapon: Dictionary = equipped.duplicate(true)
		equipped = item.duplicate(true)
		backpack[index] = previous_weapon
		inventory_message = "Weapon equipped: %s" % item["name"]
	else:
		var slot := int(item["slot"])
		var previous_armor: Dictionary = armor_equipped[slot].duplicate(true)
		armor_equipped[slot] = item.duplicate(true)
		backpack[index] = previous_armor
		inventory_message = "Armor equipped: %s (+%d DEF) | LOOK UPDATED!" % [item["name"], int(item["defense"])]
	play_sound(AUDIO_PICKUP, -13.0)
	refresh_inventory_ui()
	update_hud()

func drop_backpack_slot(index: int) -> void:
	if not inventory_open or index < 0 or index >= backpack.size():
		return
	if backpack[index].is_empty():
		return
	var item: Dictionary = backpack[index].duplicate(true)
	item["pos"] = player + Vector2(47, -8)
	item["life"] = 35.0
	item["phase"] = 0.0
	drops.append(item)
	backpack[index] = {}
	inventory_message = "Dropped %s on the ground." % item["name"]
	play_sound(AUDIO_PICKUP, -18.0)
	refresh_inventory_ui()
	update_hud()

func unequip_armor(slot: int) -> void:
	if not inventory_open or slot < 0 or slot >= armor_equipped.size():
		return
	if armor_equipped[slot].is_empty():
		inventory_message = "No armor equipped in this slot."
		refresh_inventory_ui()
		return
	var free := free_backpack_slot()
	if free < 0:
		inventory_message = "Backpack full! Cannot remove armor."
		refresh_inventory_ui()
		return
	backpack[free] = armor_equipped[slot].duplicate(true)
	armor_equipped[slot] = {}
	inventory_message = "Armor moved to backpack slot %d." % (free + 1)
	play_sound(AUDIO_PICKUP, -14.0)
	refresh_inventory_ui()
	update_hud()

func total_defense() -> int:
	var total := 0
	for item in armor_equipped:
		if not item.is_empty():
			total += int(item["defense"])
	return total

func calculate_damage_reduction() -> float:
	# Diminishing returns; armor helps, but enemies always remain dangerous.
	var defense := float(total_defense())
	return minf(0.75, defense / (defense + 25.0))

func refresh_inventory_ui() -> void:
	if inventory_buttons.is_empty():
		return
	for i in range(BAG_CAPACITY):
		var item: Dictionary = backpack[i]
		inventory_buttons[i].text = "[%d]  %s" % [i + 1, item_description(item)]
		inventory_buttons[i].disabled = item.is_empty()
		discard_buttons[i].disabled = item.is_empty()
		var c: Color = Color("628aa7") if item.is_empty() else RARITY_COLORS[int(item["rarity"])]
		inventory_buttons[i].add_theme_color_override("font_color", c)
	for i in range(ARMOR_SLOTS.size()):
		var item: Dictionary = armor_equipped[i]
		armor_buttons[i].text = "%s: %s" % [ARMOR_SLOTS[i], "-- EMPTY --" if item.is_empty() else item_description(item)]
		armor_buttons[i].disabled = item.is_empty()
		var c: Color = Color("628aa7") if item.is_empty() else RARITY_COLORS[int(item["rarity"])]
		armor_buttons[i].add_theme_color_override("font_color", c)
	defense_label.text = "TOTAL DEF %d  |  DAMAGE REDUCTION %d%%" % [total_defense(), roundi(calculate_damage_reduction() * 100.0)]
	inventory_status.text = inventory_message

func update_drops(delta: float) -> void:
	for i in range(drops.size() - 1, -1, -1):
		drops[i]["life"] = float(drops[i]["life"]) - delta
		drops[i]["phase"] = float(drops[i]["phase"]) + delta * 2.5
		if float(drops[i]["life"]) <= 0.0:
			drops.remove_at(i)
	pickup_hint.text = ""
	var nearest := 92.0
	if nearest_plot_index() >= 0:
		pickup_hint.text = "[G] PLANT / HARVEST   |   SEEDS %d" % seeds
	if nearest_camp_index() >= 0:
		pickup_hint.text = "[C] COOK  |  CARROTS %d MUSHROOMS %d  |  [H] STEW %d [J] BROTH %d" % [carrots, mushrooms, stew_meals, broth_meals]
	for d in drops:
		var dist: float = player.distance_to(d["pos"])
		if dist < nearest:
			nearest = dist
			# Free-space notification is shown when all five slots are occupied.
			if free_backpack_slot() < 0:
				pickup_hint.text = "BAG FULL (5/5)  |  [I] OPEN BAG"
			else:
				pickup_hint.text = "[E] TAKE  %s  |  [I] BAG" % d["name"]
			pickup_hint.add_theme_color_override("font_color", RARITY_COLORS[int(d["rarity"])])

func update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
		p["life"] = float(p["life"]) - delta
		if float(p["life"]) <= 0.0:
			particles.remove_at(i)

func burst(pos: Vector2, color: Color, amount: int) -> void:
	for i in range(amount):
		var angle := rng.randf_range(0.0, TAU)
		var speed := rng.randf_range(35.0, 150.0)
		var life := rng.randf_range(0.20, 0.67)
		particles.append({"pos": pos, "vel": Vector2.RIGHT.rotated(angle) * speed, "life": life, "total": life, "color": color})

func start_upgrade() -> void:
	state = "upgrade"
	upgrades.clear()
	while upgrades.size() < 3:
		var pick := rng.randi_range(0, UPGRADES.size() - 1)
		if not upgrades.has(pick):
			upgrades.append(pick)
	for i in range(3):
		upgrade_buttons[i].text = "[%d]   %s" % [i + 1, UPGRADES[upgrades[i]]]
	upgrade_panel.show()
	play_sound(AUDIO_RARE, -15.0)

func select_upgrade(index: int) -> void:
	if state != "upgrade" or index < 0 or index >= upgrades.size():
		return
	match upgrades[index]:
		0:
			max_hp += 25.0
			hp += 25.0
		1: hp = minf(max_hp, hp + 35.0)
		2: move_speed *= 1.15
		3: damage_mult *= 1.25
		4: attack_speed_mult *= 1.15
		5: projectile_speed_mult *= 1.20
	upgrade_panel.hide()
	state = "playing"
	play_sound(AUDIO_PICKUP, -13.0)

func count_empty_bag_slots() -> int:
	var count := 0
	for item in backpack:
		if item.is_empty():
			count += 1
	return count

func update_hud() -> void:
	var current_rarity: int = int(equipped["rarity"])
	hud.text = "%s / %s    LV %d   KILLS %d   DEF %d   BAG %d/5   |   %s [%s]" % [character_name, CLASS_NAMES[class_id], level, kills, total_defense(), BAG_CAPACITY - count_empty_bag_slots(), str(equipped["name"]), RARITIES[current_rarity]]
	hud.add_theme_color_override("font_color", RARITY_COLORS[current_rarity] if state == "playing" else Color("eaf6ff"))
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = maxf(0.0, hp)
	player_hp_text.text = "YOU  HP %d / %d" % [maxi(0, roundi(hp)), roundi(max_hp)]
	var new_state := 0 if hp < max_hp * 0.3 else (1 if hp < max_hp * 0.6 else 2)
	if hp_bar_color_state != new_state:
		hp_bar_color_state = new_state
		var hp_color := Color("f06477") if new_state == 0 else (Color("f5cc65") if new_state == 1 else Color("58e7a0"))
		player_hp_bar.add_theme_stylebox_override("fill", make_style(hp_color, hp_color, 5))
	companion_hp_bar.max_value = companion_max_hp
	companion_hp_bar.value = maxf(0.0, companion_hp)
	companion_hp_text.text = "MINT  %s" % ("DOWN %ds" % ceili(companion_down_clock) if companion_hp <= 0.0 else "%d / %d" % [roundi(companion_hp), roundi(companion_max_hp)])
	phase_label.text = ("PREP %ds" % ceili(phase_clock)) if phase == "prep" else ("REST %ds  |  WAVE %d" % [ceili(phase_clock), wave] if phase == "rest" else "WAVE %d   BREAK IN %ds" % [wave, ceili(phase_clock)])
	phase_label.add_theme_color_override("font_color", Color("a1ffc4") if phase != "combat" else Color("ffc39b"))
	help.text = "WASD MOVE | LMB FIGHT | E LOOT | I BAG | G FARM | C COOK | H/J EAT | F6/F9 BOSSES | F10 MINT TEST"

func draw_character(sheet: Texture2D, pos: Vector2, frame: int, right_side: bool, scale_factor: float, tint: Color, tilt: float = 0.0) -> void:
	# Original art faces left. Mirroring horizontally lets the character face the aim.
	var facing := -1.0 if right_side else 1.0
	draw_set_transform(pos, tilt, Vector2(scale_factor * facing, scale_factor))
	draw_texture_rect_region(sheet, Rect2(Vector2(-16, -25), Vector2(32, 40)), Rect2(Vector2(float(frame * 32), 0.0), Vector2(32, 40)), tint)
	draw_set_transform(Vector2.ZERO)

func draw_player_with_armor(sheet: Texture2D, pos: Vector2, frame: int, right_side: bool, scale_factor: float, tint: Color, tilt: float = 0.0) -> void:
	# Draw all layers in the *same* character-space transform for perfect alignment.
	# This also mirrors head/chest/leggings/arms when the wolf faces right.
	var facing := -1.0 if right_side else 1.0
	var texture_frame := mini(frame, 3)
	draw_set_transform(pos, tilt, Vector2(scale_factor * facing, scale_factor))
	draw_texture_rect_region(sheet, Rect2(-16, -25, 32, 40), Rect2(texture_frame * 32, 0, 32, 40), tint)
	# Render layers from back to front: legs, chest, arms, then helmet.
	for slot in [2, 1, 3, 0]:
		var armor: Dictionary = armor_equipped[slot]
		if armor.is_empty():
			continue
		var tier := clampi(int(armor["rarity"]), 0, 3)
		var overlay: Texture2D = ARMOR_VISUALS[slot][tier]
		draw_texture_rect_region(overlay, Rect2(-16, -25, 32, 40), Rect2(texture_frame * 32, 0, 32, 40), Color.WHITE)
	draw_set_transform(Vector2.ZERO)

func draw_brute(enemy: Dictionary) -> void:
	var pos: Vector2 = enemy["pos"]
	var frame := int(float(enemy["walk"])) % 4
	var face_right: bool = (player.x - pos.x) > 0.0
	var facing := -1.0 if face_right else 1.0
	var tilt := -0.045 if float(enemy["windup"]) > 0.0 else 0.0
	var tint := Color("ffa8a8") if float(enemy["hurt"]) > 0.0 else Color.WHITE
	draw_circle(pos + Vector2(0, 16), 26, Color(0, 0, 0, 0.4))
	draw_set_transform(pos, tilt, Vector2(facing * 1.75, 1.75))
	draw_texture_rect_region(STORM_BRUTE, Rect2(-20, -30, 40, 48), Rect2(frame * 40, 0, 40, 48), tint)
	draw_set_transform(Vector2.ZERO)
	if float(enemy["windup"]) > 0.0:
		# Highly visible warning circle before the charge.
		var telegraph := Color("ff85ad", 0.4 + 0.35 * absf(sin(elapsed * 19.0)))
		draw_arc(pos, 51.0, 0.0, TAU, 32, telegraph, 4.0)
		draw_line(pos, pos + (enemy["charge_dir"] as Vector2) * 75.0, telegraph, 4.0)
	elif float(enemy["charge"]) > 0.0:
		draw_circle(pos, 40, Color("a38bff", 0.16))
	draw_rect(Rect2(pos + Vector2(-28, -52), Vector2(56, 6)), Color("211b34"))
	draw_rect(Rect2(pos + Vector2(-28, -52), Vector2(56.0 * maxf(0.0, float(enemy["hp"]) / float(enemy["max_hp"])), 6)), Color("bf83ff"))
	# Label only for elite, makes its danger recognizable even at a distance.
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos + Vector2(-25, -57), "BRUTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("eadbff"))

func draw_reaper(enemy: Dictionary) -> void:
	var pos: Vector2 = enemy["pos"]
	var f := int(float(enemy["walk"])) % 4
	var tint := Color("fff2cf") if float(enemy["hurt"]) > 0.0 else Color.WHITE
	draw_circle(pos + Vector2(0, 22), 33, Color(0, 0, 0, 0.36))
	draw_set_transform(pos, 0.0, Vector2((-1.0 if player.x > pos.x else 1.0) * 1.9, 1.9))
	draw_texture_rect_region(NIGHT_REAPER, Rect2(-20, -31, 40, 48), Rect2(f * 40, 0, 40, 48), tint)
	draw_set_transform(Vector2.ZERO)
	draw_arc(pos, 47.0 + 5.0 * sin(elapsed * 4.0), 0.0, TAU, 40, Color("eb598e", 0.38), 3.0)
	draw_rect(Rect2(pos + Vector2(-40, -63), Vector2(80, 9)), Color("351d35"))
	draw_rect(Rect2(pos + Vector2(-40, -63), Vector2(80.0 * maxf(0.0, float(enemy["hp"]) / float(enemy["max_hp"])), 9)), Color("ff6587"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-42, -70), "NIGHT REAPER", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe1e5"))

func draw_companion() -> void:
	if companion_hp <= 0.0:
		return
	var pos := companion
	var frame := int(companion_walk_clock) % 4
	draw_circle(pos + Vector2(0, 15), 17, Color(0, 0, 0, 0.28))
	draw_character(MINT_SPRITE, pos, frame, player.x > pos.x, 1.62, Color.WHITE)
	draw_rect(Rect2(pos + Vector2(-22, -44), Vector2(44, 5)), Color("172c39"))
	draw_rect(Rect2(pos + Vector2(-22, -44), Vector2(44.0 * companion_hp / companion_max_hp, 5)), Color("7df2d8"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-21, -51), "MINT", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("bdfff0"))

func draw_loot(d: Dictionary) -> void:
	var pos: Vector2 = d["pos"]
	var rarity: int = int(d["rarity"])
	var c: Color = RARITY_COLORS[rarity]
	var phase: float = d["phase"]
	var height := sin(phase) * 4.0
	var center := pos + Vector2(0, -height)
	draw_circle(pos + Vector2(0, 12), 15, Color(0, 0, 0, 0.30))
	draw_circle(center, 17.0 + sin(phase * 2.0) * 3.0, Color(c, 0.23))
	var corners: PackedVector2Array
	if str(d["type"]) == "armor":
		# Shield icon for armor; weapon drops retain the familiar diamond.
		corners = PackedVector2Array([center + Vector2(-13, -11), center + Vector2(13, -11), center + Vector2(11, 6), center + Vector2(0, 17), center + Vector2(-11, 6)])
	else:
		corners = PackedVector2Array([center + Vector2(0, -13), center + Vector2(12, 0), center + Vector2(0, 13), center + Vector2(-12, 0)])
	draw_colored_polygon(corners, c)
	var outline := corners.duplicate()
	outline.append(corners[0])
	draw_polyline(outline, Color("fff9e6"), 2.0)
	if rarity == 3:
		draw_line(center + Vector2(0, -145), center + Vector2(0, -23), Color(c, 0.25), 15.0)
		draw_line(center + Vector2(0, -145), center + Vector2(0, -23), Color(c, 0.72), 4.0)
		for i in range(8):
			var a := phase + i * TAU / 8.0
			var radial := Vector2.RIGHT.rotated(a)
			draw_line(center + radial * 22.0, center + radial * 32.0, c, 2.5)

func draw_farm_and_kitchen() -> void:
	# All coordinates are in world-space. Farm plots work without inventories or UI scenes.
	for plot in farm_plots:
		var center: Vector2 = plot["pos"]
		var progress := float(plot["progress"])
		var box := Rect2(center + Vector2(-27, -22), Vector2(54, 46))
		draw_rect(box, Color("65452e"))
		draw_rect(box, Color("c9a36d"), false, 2.0)
		for line_n in range(3):
			draw_line(center + Vector2(-17, -11 + line_n * 12), center + Vector2(18, -11 + line_n * 12), Color("9a6742"), 2.0)
		if progress >= 0.0:
			var height := 7.0 + 16.0 * minf(1.0, progress / GROW_SECONDS)
			draw_line(center + Vector2(0, 12), center + Vector2(0, 12 - height), Color("70de73"), 4.0)
			draw_circle(center + Vector2(-8, 5 - height * 0.52), 6.0, Color("5dcb75"))
			draw_circle(center + Vector2(8, 5 - height * 0.52), 6.0, Color("a0e681"))
			if progress >= GROW_SECONDS:
				draw_circle(center + Vector2(0, 5), 7.0, Color("ff9b48"))
				draw_arc(center, 34, 0.0, TAU, 24, Color("ffdd8e"), 2.0)
	for station in CAMP_STATIONS:
		var f: Vector2 = station
		draw_circle(f + Vector2(0, 11), 28.0, Color("101821"))
		for k in range(9):
			var a := TAU * float(k) / 9.0
			draw_circle(f + Vector2.RIGHT.rotated(a) * 21.0, 7.0, Color("87949a"))
		draw_colored_polygon(PackedVector2Array([f + Vector2(-13, 8), f + Vector2(-5, -24), f + Vector2(4, -10), f + Vector2(10, -29), f + Vector2(17, 11)]), Color("ff963e"))
		draw_circle(f + Vector2(0, 3), 9.0, Color("ffeb9e"))
		draw_string(ThemeDB.fallback_font, f + Vector2(-43, 49), "COOK [C]", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffdda4"))
	draw_string(ThemeDB.fallback_font, Vector2(1323, 700), "FARM [G]", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b8f1ba"))
	draw_string(ThemeDB.fallback_font, Vector2(2129, 1044), "FARM [G]", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b8f1ba"))

func draw_accessory(pos: Vector2) -> void:
	var c := Color("ffdc81")
	if accessory_id == 1:
		# small four-point star above head
		draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -59), pos + Vector2(4, -52), pos + Vector2(12, -49), pos + Vector2(4, -46), pos + Vector2(0, -39), pos + Vector2(-4, -46), pos + Vector2(-12, -49), pos + Vector2(-4, -52)]), c)
	elif accessory_id == 2:
		# simple crown marker, independent of the equipped helmet
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-17, -41), pos + Vector2(-18, -56), pos + Vector2(-8, -49), pos + Vector2(0, -60), pos + Vector2(8, -49), pos + Vector2(18, -56), pos + Vector2(17, -41)]), c)
	elif accessory_id == 3:
		for i in range(5):
			var a := float(i) * TAU / 5.0 + elapsed * 1.4
			draw_circle(pos + Vector2.RIGHT.rotated(a) * 43.0, 3.0, Color("a4dfff"))

func _draw() -> void:
	draw_rect(ARENA.grow(120.0), Color("0a1020"))
	draw_rect(ARENA, Color("172b30"))
	for x in range(int(ARENA.position.x) + 14, int(ARENA.end.x), 64):
		draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), Color("284448", 0.47), 1.0)
	for y in range(int(ARENA.position.y) + 12, int(ARENA.end.y), 64):
		draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), Color("284448", 0.47), 1.0)
	for prop in scenery:
		var p: Vector2 = prop["pos"]
		var rad: float = 18.0 * float(prop["size"])
		if int(prop["kind"]) == 0:
			draw_circle(p + Vector2(7, 15), rad + 4.0, Color(0, 0, 0, 0.23))
			draw_circle(p, rad + 5.0, Color("244c43"))
			draw_circle(p + Vector2(-6, -6), rad * 0.7, Color("3b7a5d"))
		elif int(prop["kind"]) == 1:
			draw_circle(p, rad * 0.7, Color("566471"))
			draw_circle(p + Vector2(-5, -5), rad * 0.37, Color("849ba0"))
		else:
			draw_circle(p, rad * 0.4, Color("519780"))
			draw_circle(p + Vector2(8, 3), rad * 0.26, Color("7ebb92"))
	for station in CAMP_STATIONS:
		draw_circle(station, CAMP_RADIUS, Color("a3d2a4", 0.07 if phase == "combat" else 0.15))
		draw_arc(station, CAMP_RADIUS, 0.0, TAU, 80, Color("90dba9", 0.3 if phase == "combat" else 0.6), 3.0)
	draw_rect(ARENA, Color("5d8798"), false, 5.0)
	draw_farm_and_kitchen()
	for d in drops:
		draw_loot(d)
	for enemy in enemies:
		if bool(enemy["boss"]):
			draw_reaper(enemy)
			continue
		if bool(enemy["elite"]):
			draw_brute(enemy)
			continue
		var pos: Vector2 = enemy["pos"]
		draw_circle(pos + Vector2(4, 13), 17.0, Color(0, 0, 0, 0.28))
		var facing_right: bool = (player.x - pos.x) > 0.0
		var tint := Color("ffb9b9") if enemy["fast"] else Color.WHITE
		if float(enemy["hurt"]) > 0.0:
			tint = Color("ffe0ad")
		var frame := int(float(enemy["walk"])) % 4
		draw_character(PIERO_WALK, pos, frame, facing_right, 1.62, tint)
		draw_rect(Rect2(pos + Vector2(-20, -38), Vector2(40, 5)), Color("3e344a"))
		draw_rect(Rect2(pos + Vector2(-20, -38), Vector2(40.0 * maxf(0.0, float(enemy["hp"]) / float(enemy["max_hp"])), 5)), Color("8af4a2"))
	for orb in hostile_orbs:
		var p: Vector2 = orb["pos"]
		draw_circle(p, 13, Color("fd4479", 0.25))
		draw_circle(p, 7, Color("ff6c95"))
		for a in range(4):
			draw_line(p + Vector2.RIGHT.rotated(float(a) * PI / 2.0) * 12.0, p + Vector2.RIGHT.rotated(float(a) * PI / 2.0) * 18.0, Color("ffd3e5"), 2.0)
	for bullet in projectiles:
		var pos: Vector2 = bullet["pos"]
		var c: Color = bullet["tint"]
		if bullet["kind"] == "arrow":
			var arrow_dir: Vector2 = (bullet["vel"] as Vector2).normalized()
			draw_line(pos - arrow_dir * 13.0, pos + arrow_dir * 10.0, c, 3.5)
			draw_colored_polygon(PackedVector2Array([pos + arrow_dir * 14.0, pos - arrow_dir.rotated(0.5) * 9.0, pos - arrow_dir.rotated(-0.5) * 9.0]), Color("ecfff4"))
		else:
			draw_circle(pos, float(bullet["radius"]) + 5.0, Color(c, 0.20))
			draw_circle(pos, float(bullet["radius"]), c)
	for p in particles:
		var alpha := clampf(float(p["life"]) / float(p["total"]), 0.0, 1.0)
		draw_circle(p["pos"], 2.0 + 3.0 * alpha, Color(p["color"], alpha))
	draw_companion()
	var player_center := player
	if screen_shake > 0.0:
		player_center += Vector2(rng.randf_range(-3.0, 3.0), rng.randf_range(-3.0, 3.0))
	var fighting := attack_clock > 0.0
	var character_frame := int(walk_clock) % 4
	var sprite: Texture2D = WOLF_WALK
	var lean := 0.0
	if fighting:
		sprite = WOLF_ATTACK
		character_frame = mini(2, int(3.0 * (1.0 - attack_clock / maxf(attack_duration, 0.01))))
		lean = -0.075 if cos(aim_angle) < 0.0 else 0.075
	var walk_bob := -absf(sin(walk_clock * 1.5708)) * 2.0 if walk_clock > 0.0 else 0.0
	draw_circle(player + Vector2(3, 15), 21, Color(0, 0, 0, 0.30))
	draw_player_with_armor(sprite, player_center + Vector2(0, walk_bob), character_frame, cos(aim_angle) > 0.0, 1.82, Color("ff8585") if hurt_clock > 0.0 else WOLF_PALETTES[palette_id], lean)
	draw_accessory(player_center + Vector2(0, walk_bob))
	if state == "playing":
		var muzzle := player + Vector2.RIGHT.rotated(aim_angle) * 39.0
		var wtype: int = int(equipped["kind"])
		var rarity: int = int(equipped["rarity"])
		var color: Color = RARITY_COLORS[rarity]
		match wtype:
			0:
				draw_line(player + Vector2(0, 3), muzzle, Color("aab6c9"), 5.0)
				draw_circle(muzzle, 4.0, color)
			1, 4:
				draw_arc(muzzle - Vector2.RIGHT.rotated(aim_angle) * 18.0, 19.0, aim_angle - 1.0, aim_angle + 1.0, 12, color, 2.6)
			5, 6:
				draw_line(player, muzzle, Color("b6a3ff") if wtype == 5 else Color("adffd0"), 6.0)
				draw_circle(muzzle, 8.0, Color("e4b6ff") if wtype == 5 else Color("cdffe2"))
			2, 3:
				var length := 45.0 if wtype == 2 else 65.0
				draw_line(player + Vector2(0, 0), player + Vector2.RIGHT.rotated(aim_angle) * length, color, 5.0 if wtype == 2 else 9.0)
		if fighting and wtype >= 2:
			var radius := 85.0 if wtype == 2 else 129.0
			var sweep := 0.95 if wtype == 2 else 1.21
			var opacity := clampf(attack_clock / attack_duration, 0.0, 1.0)
			draw_arc(player, radius, aim_angle - sweep, aim_angle + sweep, 35, Color(color, opacity), 11.0 if wtype == 3 else 7.0)
			draw_arc(player, radius - 12.0, aim_angle - sweep, aim_angle + sweep, 35, Color("ffffff", opacity * 0.6), 2.0)
	if brute_flash_clock > 0.0:
		draw_rect(ARENA, Color("ad6bff", minf(0.14, brute_flash_clock * 0.5)))
	if legendary_glow_clock > 0.0:
		var opacity := minf(0.25, legendary_glow_clock * 0.10)
		draw_rect(ARENA, Color("ffd568", opacity))
	# XP ring around wolf is world-space so it follows the camera.
	if state == "playing":
		draw_arc(player, 52.0, -PI / 2.0, -PI / 2.0 + TAU * float(xp) / float(xp_needed), 28, Color("71c4ff"), 3.0)
	# Health is also visible directly above the main character.
	draw_rect(Rect2(player + Vector2(-38, -62), Vector2(76, 10)), Color("1b2634"))
	draw_rect(Rect2(player + Vector2(-38, -62), Vector2(76.0 * maxf(0.0, hp / max_hp), 10)), Color("ef6377") if hp / max_hp < 0.3 else Color("7dec9e"))
	draw_rect(Rect2(player + Vector2(-38, -62), Vector2(76, 10)), Color("d2e6e9"), false, 1.0)
	if state != "playing":
		draw_rect(ARENA, Color(0.02, 0.04, 0.09, 0.67))
