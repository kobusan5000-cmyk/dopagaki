extends Node2D

# DOPAGAKI v0.12.2 — clear-to-advance waves, merchant, crops, status enemies, Celtic BGM.
# Solo prototype; network/4-player functionality is NOT implemented.
# Compatible with Godot 4.3–4.7; one runnable Node2D scene.

const SIZE := Vector2(1152, 648)
const ARENA := Rect2(40, 105, 3600, 2380)
const CAMP_STATIONS := [Vector2(1170, 842), Vector2(2020, 1175)]
const CAMP_RADIUS := 178.0
const CAMP_ENEMY_MARGIN := 27.0
const MAX_ENEMIES := 78
const REST_PLAYER_HEAL_FRACTION := 0.24
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
const CLASS_NAMES := ["戦士", "弓兵", "連弩士", "メイジ", "バーサーカー", "ヒーラー"]
const CLASS_DESC := ["剣と防御のバランス型", "弓で遠距離攻撃", "連射する弩で攻撃", "知力で魔法を強化", "大剣の高火力と高HP", "回復と遠距離支援"]
const CLASS_WEAPONS := [2, 1, 4, 5, 3, 6]
const WOLF_PALETTES := [Color("ffffff"), Color("ffe4c0"), Color("bce4ff"), Color("edc4ff"), Color("d3ffbe"), Color("ffc6da")]
const PALETTE_NAMES := ["オリジナル", "ゴールド", "アイス", "ライラック", "ミント", "ローズ"]
const ACCESSORY_NAMES := ["なし", "星", "王冠", "光"]
const FARM_PLOTS := [Vector2(1320, 745), Vector2(1390, 745), Vector2(1460, 745), Vector2(1320, 817), Vector2(1390, 817), Vector2(1460, 817), Vector2(2130, 1090), Vector2(2200, 1090), Vector2(2130, 1160), Vector2(2200, 1160), Vector2(1710, 1160), Vector2(1780, 1160), Vector2(1850, 1160)]
const GROW_SECONDS := 10.0
const RARITIES := ["COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC"]
const ARMOR_SLOTS := ["HEAD", "CHEST", "LEGGINGS", "ARMS"]
const ARMOR_BASE_DEF := [2, 5, 3, 2]
const ARMOR_PREFIX := ["WORN", "GUARDED", "ENCHANTED", "MYTHIC", "DIVINE"]
const ARMOR_RARITY_MULT := [1.0, 1.6, 2.3, 3.5, 5.0]
const BAG_CAPACITY := 5
const SLOT_COST := 25
const SLOT_POS := Vector2(1310, 900)
const REVIVE_SHRINE := Vector2(3060, 1860)
const MERCHANT_POS := Vector2(1780, 985)
const WEAPON_TRAITS := ["烈火", "氷霜", "猛毒", "星光", "疾風"]
const TRAIT_COLORS := [Color("ff985a"), Color("9be6ff"), Color("9eff9b"), Color("ffe68b"), Color("c5a2ff")]
const CROP_NAMES := ["ニンジン", "メロン", "スイカ"]
const CROP_GROW := [10.0, 22.0, 35.0]
const CROP_COLORS := [Color("ffa665"), Color("aaff8d"), Color("79d7b0")]
const WEAPON_SHORT := ["銃", "弓", "剣", "大剣", "連弩", "魔杖", "癒杖"]
const ARMOR_SHORT := ["頭", "胴", "脚", "腕"]
const WEAPON_ICONS := [
	preload("res://assets/item_icons/weapon_0.png"),
	preload("res://assets/item_icons/weapon_1.png"),
	preload("res://assets/item_icons/weapon_2.png"),
	preload("res://assets/item_icons/weapon_3.png"),
	preload("res://assets/item_icons/weapon_4.png"),
	preload("res://assets/item_icons/weapon_5.png"),
	preload("res://assets/item_icons/weapon_6.png")
]
# Original pixel art provided by the game creator. Sword kind=2 uses tier-specific art.
# MYTHIC currently shares the legendary sprite with a unique magenta aura.
const SWORD_RARITY_ART := [
	preload("res://assets/item_icons/sword_common.png"),
	preload("res://assets/item_icons/sword_rare.png"),
	preload("res://assets/item_icons/sword_epic.png"),
	preload("res://assets/item_icons/sword_legendary.png")
]
const ARMOR_ICONS := [
	preload("res://assets/item_icons/armor_0.png"),
	preload("res://assets/item_icons/armor_1.png"),
	preload("res://assets/item_icons/armor_2.png"),
	preload("res://assets/item_icons/armor_3.png")
]
const RARITY_COLORS := [Color("d0e2f1"), Color("59cdff"), Color("d493ff"), Color("ffd568"), Color("ff91d9")]
const RARITY_DAMAGE := [1.0, 1.38, 1.88, 2.85, 4.4]
const RARITY_RATE := [1.0, 1.06, 1.13, 1.22, 1.33]
const RARE_NAMES := ["GILDED PISTOL", "HUNTER'S BOW", "MOON SWORD", "IRON CLEAVER", "SWIFT REPEATER", "RUNE WAND", "BLESSED STAFF"]
const EPIC_NAMES := ["STORM PISTOL", "PHANTOM BOW", "SOLAR SABER", "TITAN BLADE", "THUNDER REPEATER", "ASTRAL STAFF", "LIFEBLOOM"]
const LEGEND_NAMES := ["STARFALL", "CELESTIAL BOW", "FATEBREAKER", "WORLDENDER", "INFINITE SALVO", "VOIDCALLER", "SUNHEALER"]
const MYTHIC_NAMES := ["神銃・天雷", "神弓・暁", "神剣・星砕", "神斧・終焉", "神連弩・無限", "神杖・深淵", "神杖・聖樹"]
const STAT_NAMES := ["力", "スピード", "体力", "MP", "器用", "知力"]
const STAT_DESCRIPTIONS := ["物理攻撃力 +8%", "移動 +4% / 攻撃速度 +2%", "最大HP +15 / HP回復", "最大MP +10 / MP自然回復", "命中率 +3% / 射撃 +7% / 会心率 +2.5%", "魔法攻撃力 +9%"]
const SKILL_NAMES := ["鉄壁の構え", "五連矢", "連弩乱射", "魔力爆発", "狂戦士の怒り", "癒やしの波動"]
const SKILL_DESCRIPTIONS := ["被ダメージを8秒間軽減", "狙った方向に5本の矢", "狙った方向に8本の矢", "周囲の敵に魔法ダメージ", "10秒間、攻撃力と速度を上昇", "自分とミントを回復"]
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
const AUDIO_COUNTDOWN: AudioStream = preload("res://audio/countdown.wav")
const AUDIO_CRITICAL: AudioStream = preload("res://audio/critical.wav")
const AUDIO_WAVE_CLEAR: AudioStream = preload("res://audio/wave_clear.wav")
const AUDIO_BGM_REST: AudioStream = preload("res://audio/celtic_rest.wav")
const AUDIO_BGM_BATTLE: AudioStream = preload("res://audio/celtic_battle.wav")

var rng := RandomNumberGenerator.new()
var ui_font: SystemFont
var state := "choose" # choose, playing, upgrade, dead
var class_id := 0
var palette_id := 0
var accessory_id := 0
var character_name := "Ookami"
var base_class_speed := 262.0
var coins := 0
var coin_drops: Array[Dictionary] = []
var mint_soul_on_ground := false
var mint_soul_carried := false
var mint_soul_pos := Vector2.ZERO
var slot_open := false
var slot_spin_clock := 0.0
var slot_roll := 0.0
var slot_reel_step := 0.0
var jump_clock := 0.0
var jump_cooldown := 0.0
var jump_direction := Vector2.RIGHT
var seeds := 8
var carrots := 2
var mushrooms := 1
var stew_meals := 0
var broth_meals := 0
var wave := 0
var combat_elapsed := 0.0
var wave_target := 0
var wave_spawned := 0
var wave_clear_clock := -1.0
var countdown_last := -1
var current_bgm := ""
var bgm_player: AudioStreamPlayer
var crop_selection := 0
var melon_seeds := 0
var watermelon_seeds := 0
var melons := 0
var watermelons := 0
var melon_meals := 0
var watermelon_meals := 0
var crop_drops: Array[Dictionary] = []
var merchant_open := false
var merchant_panel: PanelContainer
var merchant_info: Label
var merchant_buttons: Array[Button] = []
var countdown_label: Label
var direction_label: Label
var damage_numbers: Array[Dictionary] = []
var hit_flash_clock := 0.0
var poison_clock := 0.0
var burn_clock := 0.0
var freeze_clock := 0.0
var freeze_lock_clock := 0.0
var status_tick := 0.0
var combo_count := 0
var combo_clock := 0.0
var wave_damage_taken := 0.0
var crit_sound_clock := 0.0
var phase := "prep" # prep, combat, rest
var phase_clock := PREP_SECONDS
var first_reaper_spawned := false
var scenery: Array[Dictionary] = []
var camera: Camera2D
var companion := Vector2(1200, 875)
var companion_hp := 90.0
var companion_max_hp := 90.0
var companion_level := 1
var companion_xp := 0
var companion_xp_needed := 18
var companion_damage := 3.6
var companion_attack_clock := 0.0
var companion_meal_clock := 4.0
var companion_heal_clock := 5.0
var companion_walk_clock := 0.0
var companion_down_clock := 0.0
var companion_was_moving := false
var companion_mode := "巡回"
var companion_goal := Vector2(1170, 842)
var companion_decision_clock := 0.0
var companion_work_clock := 0.0
var companion_patrol_index := 0
var companion_skill_clock := 0.0
var companion_stats: Array[int] = [0, 0, 0, 0, 0, 0]
var hero_stats: Array[int] = [0, 0, 0, 0, 0, 0]
var pending_hero_points := 0
var pending_mint_points := 0
var upgrade_target := "hero"
var mp := 30.0
var max_mp := 30.0
var skill_buff_clock := 0.0
var skill_guard_clock := 0.0
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
var companion_xp_text: Label
var mp_text: Label
var skill_text: Label
var stat_summary: Label
var upgrade_heading: Label
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
var hotbar_container: HBoxContainer
var hotbar_buttons: Array[Button] = []
var hotbar_currency: Label
var slot_panel: PanelContainer
var slot_info: Label
var slot_result: Label
var slot_prize_icon: TextureRect
var equipped_icon: TextureRect
var slot_spin_button: Button
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
	for music_stream in [AUDIO_BGM_REST, AUDIO_BGM_BATTLE]:
		var wav_stream: AudioStreamWAV = music_stream as AudioStreamWAV
		if wav_stream != null:
			wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -17.0
	add_child(bgm_player)
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Yu Gothic", "Meiryo", "Noto Sans CJK JP", "Arial"])
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
	text_label.add_theme_font_override("font", ui_font)
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
	b.add_theme_font_override("font", ui_font)
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
	hud = make_label("", 15, Color("eaf6ff"))
	hud.position = Vector2(48, 8)
	layer.add_child(hud)
	# Always show the currently equipped weapon, not just the contents of the backpack.
	equipped_icon = TextureRect.new()
	equipped_icon.position = Vector2(1072, 6)
	equipped_icon.custom_minimum_size = Vector2(60, 60)
	equipped_icon.size = Vector2(60, 60)
	equipped_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	equipped_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	equipped_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	equipped_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(equipped_icon)
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
	companion_xp_text = make_label("", 13, Color("93e5d5"))
	companion_xp_text.position = Vector2(364, 67)
	companion_xp_text.custom_minimum_size = Vector2(240, 17)
	layer.add_child(companion_xp_text)
	mp_text = make_label("", 15, Color("b6a4ff"))
	mp_text.position = Vector2(48, 68)
	layer.add_child(mp_text)
	skill_text = make_label("", 13, Color("ffda94"))
	skill_text.position = Vector2(617, 65)
	layer.add_child(skill_text)
	phase_label = make_label("", 17, Color("ffe69b"))
	phase_label.position = Vector2(617, 41)
	phase_label.custom_minimum_size = Vector2(480, 24)
	layer.add_child(phase_label)
	countdown_label = make_label("", 70, Color("ffe69c"), true)
	countdown_label.position = Vector2(390, 160)
	countdown_label.custom_minimum_size = Vector2(370, 110)
	layer.add_child(countdown_label)
	direction_label = make_label("", 13, Color("d0b9ff"))
	direction_label.position = Vector2(787, 88)
	direction_label.custom_minimum_size = Vector2(345, 25)
	layer.add_child(direction_label)
	help = make_label("", 13, Color("aac6e3"))
	help.position = Vector2(48, 89)
	layer.add_child(help)
	pickup_hint = make_label("", 18, Color("ffe998"), true)
	pickup_hint.position = Vector2(245, 508)
	pickup_hint.custom_minimum_size = Vector2(664, 40)
	layer.add_child(pickup_hint)
	banner = make_label("", 31, Color("ffd568"), true)
	banner.position = Vector2(145, 117)
	banner.custom_minimum_size = Vector2(860, 64)
	layer.add_child(banner)

	# Character creation is intentionally a single menu, with six class archetypes.
	choose_panel = make_panel(Vector2(112, 91), Vector2(928, 464), Color("42cfd5"))
	layer.add_child(choose_panel)
	var choose_box := VBoxContainer.new()
	choose_box.add_theme_constant_override("separation", 7)
	choose_panel.get_child(0).add_child(choose_box)
	choose_box.add_child(make_label("DOPAGAKI  /  キャラクター作成", 29, Color("7de9f0"), true))
	choose_box.add_child(make_label("v0.12.2  |  4段階のオリジナル剣・装備プレビュー", 14, Color("d0dcf3"), true))
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 13)
	choose_box.add_child(name_row)
	name_row.add_child(make_label("名前", 17, Color("ddf5f9")))
	name_input = LineEdit.new()
	name_input.text = character_name
	name_input.add_theme_font_override("font", ui_font)
	name_input.max_length = 16
	name_input.custom_minimum_size = Vector2(220, 34)
	name_input.placeholder_text = "主人公の名前"
	name_row.add_child(name_input)
	palette_button = make_button("カラー: オリジナル", Color("58c8e2"), Vector2(180, 34))
	palette_button.add_theme_font_size_override("font_size", 14)
	palette_button.pressed.connect(cycle_palette)
	name_row.add_child(palette_button)
	accessory_button = make_button("帽子: なし", Color("f2c07d"), Vector2(178, 34))
	accessory_button.add_theme_font_size_override("font_size", 14)
	accessory_button.pressed.connect(cycle_accessory)
	name_row.add_child(accessory_button)
	choose_box.add_child(make_label("職業を選択", 18, Color("e6c98d"), true))
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
	choose_box.add_child(make_label("[1〜6] 職業を選択  /  先に名前・色・帽子を設定", 15, Color("adc6e1"), true))
	choose_box.add_child(make_label("敵を全滅でWAVEクリア！ 商人で買い物・レア作物の栽培・ミントの蘇生", 16, Color("86eac5"), true))
	# A compact cooking menu with recipe buttons and resource counter.
	cooking_panel = make_panel(Vector2(311, 106), Vector2(530, 440), Color("f6b970"))
	layer.add_child(cooking_panel)
	var cook_box := VBoxContainer.new()
	cook_box.add_theme_constant_override("separation", 12)
	cooking_panel.get_child(0).add_child(cook_box)
	cook_box.add_child(make_label("キャンプの料理", 28, Color("ffd5a0"), true))
	cooking_info = make_label("", 18, Color("b6e8ce"), true)
	cook_box.add_child(cooking_info)
	var soup := make_button("[1] ニンジンシチュー（ニンジン2）  HP+40 [H]", Color("ffd39f"), Vector2(461, 50))
	soup.pressed.connect(cook_recipe.bind(0))
	cook_box.add_child(soup)
	var broth := make_button("[2] ハンタースープ（ニンジン1・キノコ1）\nHP+25 / 30秒間移動速度アップ [J]", Color("ffd39f"), Vector2(461, 70))
	broth.add_theme_font_size_override("font_size", 15)
	broth.pressed.connect(cook_recipe.bind(1))
	cook_box.add_child(broth)
	var melon_button := make_button("[3] メロンジュース（メロン1）  HP+30 / MP+25 [K]", Color("c1e88d"), Vector2(461, 43))
	melon_button.add_theme_font_size_override("font_size", 15)
	melon_button.pressed.connect(cook_recipe.bind(2))
	cook_box.add_child(melon_button)
	var watermelon_button := make_button("[4] スイカパフェ（スイカ1）  HP+60 [L]", Color("a3e7c4"), Vector2(461, 43))
	watermelon_button.add_theme_font_size_override("font_size", 15)
	watermelon_button.pressed.connect(cook_recipe.bind(3))
	cook_box.add_child(watermelon_button)
	var exit_cook := make_button("閉じる [E / Esc]", Color("f6b970"), Vector2(461, 37))
	exit_cook.pressed.connect(toggle_cooking)
	cook_box.add_child(exit_cook)
	cooking_panel.hide()

	upgrade_panel = make_panel(Vector2(182, 110), Vector2(788, 448), Color("93a8ff"))
	layer.add_child(upgrade_panel)
	var upgrade_box := VBoxContainer.new()
	upgrade_box.add_theme_constant_override("separation", 9)
	upgrade_panel.get_child(0).add_child(upgrade_box)
	upgrade_heading = make_label("レベルアップ！ 能力値を選択", 26, Color("95d8ff"), true)
	upgrade_box.add_child(upgrade_heading)
	stat_summary = make_label("", 14, Color("c4d4ef"), true)
	upgrade_box.add_child(stat_summary)
	var stat_grid := GridContainer.new()
	stat_grid.columns = 2
	stat_grid.add_theme_constant_override("h_separation", 12)
	stat_grid.add_theme_constant_override("v_separation", 9)
	upgrade_box.add_child(stat_grid)
	for i in range(6):
		var btn := make_button("", Color("82a2ff"), Vector2(348, 77))
		btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(select_upgrade.bind(i))
		upgrade_buttons.append(btn)
		stat_grid.add_child(btn)
	upgrade_box.add_child(make_label("[1〜6] キー またはクリックで選択  |  ミントも育成可能", 15, Color("a6ffdf"), true))

	dead_panel = make_panel(Vector2(300, 195), Vector2(552, 250), Color("fb758e"))
	layer.add_child(dead_panel)
	var dead_box := VBoxContainer.new()
	dead_box.add_theme_constant_override("separation", 18)
	dead_panel.get_child(0).add_child(dead_box)
	dead_box.add_child(make_label("ゲームオーバー", 36, Color("ffa3b1"), true))
	dead_label = make_label("", 22, Color("f6fbff"), true)
	dead_box.add_child(dead_label)
	dead_box.add_child(make_label("Rキーでキャラクター作成から再挑戦", 18, Color("b7ddfb"), true))
	# Minecraft-inspired five-slot hotbar stays visible during gameplay.
	hotbar_container = HBoxContainer.new()
	var hotbar := hotbar_container
	hotbar.position = Vector2(261, 552)
	hotbar.add_theme_constant_override("separation", 6)
	layer.add_child(hotbar)
	for i in range(BAG_CAPACITY):
		var quick_button := make_button("%d  --" % (i + 1), Color("6c91b7"), Vector2(115, 72))
		quick_button.add_theme_font_size_override("font_size", 13)
		quick_button.expand_icon = true
		quick_button.focus_mode = Control.FOCUS_NONE
		quick_button.pressed.connect(quickbar_equip.bind(i))
		hotbar.add_child(quick_button)
		hotbar_buttons.append(quick_button)
	hotbar_currency = make_label("所持金 0G", 18, Color("ffe6a0"))
	hotbar_currency.position = Vector2(878, 572)
	layer.add_child(hotbar_currency)
	# The slot machine uses only coins earned from enemies; no real-money features.
	slot_panel = make_panel(Vector2(300, 123), Vector2(552, 400), Color("ffd36e"))
	layer.add_child(slot_panel)
	var slot_box := VBoxContainer.new()
	slot_box.add_theme_constant_override("separation", 12)
	slot_panel.get_child(0).add_child(slot_box)
	slot_box.add_child(make_label("★ キャンプのスロット ★", 28, Color("ffe3a0"), true))
	slot_box.add_child(make_label("敵が落とすゲーム内コインのみ使用・換金なし", 14, Color("b8d3e7"), true))
	slot_info = make_label("", 18, Color("fff1bb"), true)
	slot_box.add_child(slot_info)
	slot_result = make_label("◆  ◇  ◆\n超レア MYTHIC 1% / LEGENDARY 5%", 21, Color("ffc6e9"), true)
	slot_box.add_child(slot_result)
	# Slot results preview the ACTUAL awarded equipment art, including sword rarity.
	slot_prize_icon = TextureRect.new()
	slot_prize_icon.custom_minimum_size = Vector2(72, 72)
	slot_prize_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot_prize_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot_prize_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slot_prize_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_prize_icon.hide()
	slot_box.add_child(slot_prize_icon)
	slot_spin_button = make_button("[25G] 回す", Color("ffd36e"), Vector2(480, 51))
	slot_spin_button.pressed.connect(spin_slot)
	slot_box.add_child(slot_spin_button)
	var slot_exit := make_button("閉じる [E / Esc]", Color("b4a4ed"), Vector2(480, 37))
	slot_exit.pressed.connect(toggle_slot)
	slot_box.add_child(slot_exit)
	slot_panel.hide()

	merchant_panel = make_panel(Vector2(278, 92), Vector2(596, 466), Color("b4f1bd"))
	layer.add_child(merchant_panel)
	var merchant_box := VBoxContainer.new()
	merchant_box.add_theme_constant_override("separation", 6)
	merchant_panel.get_child(0).add_child(merchant_box)
	merchant_box.add_child(make_label("✦ 旅の武器商人・ルーンの店 ✦", 26, Color("e3ffd7"), true))
	merchant_info = make_label("", 15, Color("ffe1a3"), true)
	merchant_box.add_child(merchant_info)
	var merchant_stock := ["[1] 炎のレア剣  50G", "[2] 氷のレア弓  55G", "[3] 星のエピック魔杖  135G", "[4] 守護のレア鎧  55G", "[5] ニンジンの種×3  12G", "[6] メロンの種×2  42G", "[7] スイカの種×2  75G", "[8] キノコ×2  18G"]
	for i in range(merchant_stock.size()):
		var merchant_button := make_button(merchant_stock[i], Color("83cda0"), Vector2(530, 32))
		merchant_button.add_theme_font_size_override("font_size", 15)
		merchant_button.pressed.connect(buy_merchant_item.bind(i))
		merchant_box.add_child(merchant_button)
		merchant_buttons.append(merchant_button)
	var close_merchant := make_button("店を出る [E / Esc]", Color("c5efc6"), Vector2(530, 35))
	close_merchant.pressed.connect(toggle_merchant)
	merchant_box.add_child(close_merchant)
	merchant_panel.hide()

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
	inv_box.add_child(make_label("バッグ  /  5枠", 24, Color("87edff"), true))
	inv_box.add_child(make_label("装備はクリック / 防具を外す場合もクリック", 13, Color("adc6e1"), true))
	for i in range(BAG_CAPACITY):
		var item_row := HBoxContainer.new()
		item_row.add_theme_constant_override("separation", 5)
		var button := make_button("", Color("5b7a9f"), Vector2(331, 36))
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(use_backpack_slot.bind(i))
		inventory_buttons.append(button)
		item_row.add_child(button)
		var drop_button := make_button("捨てる", Color("f3958a"), Vector2(78, 36))
		drop_button.add_theme_font_size_override("font_size", 13)
		drop_button.pressed.connect(drop_backpack_slot.bind(i))
		discard_buttons.append(drop_button)
		item_row.add_child(drop_button)
		inv_box.add_child(item_row)
	inv_box.add_child(make_label("防具  /  4部位", 17, Color("eac88e"), true))
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
	var close_button := make_button("バッグを閉じる [I / Esc]", Color("5ab9ed"), Vector2(414, 34))
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
	coins = 0
	coin_drops.clear()
	mint_soul_on_ground = false
	mint_soul_carried = false
	mint_soul_pos = Vector2.ZERO
	slot_open = false
	slot_spin_clock = 0.0
	slot_roll = 0.0
	slot_reel_step = 0.0
	slot_panel.hide()
	jump_clock = 0.0
	jump_cooldown = 0.0
	jump_direction = Vector2.RIGHT
	seeds = 8
	carrots = 2
	mushrooms = 1
	stew_meals = 0
	broth_meals = 0
	wave = 0
	combat_elapsed = 0.0
	wave_target = 0
	wave_spawned = 0
	wave_clear_clock = -1.0
	countdown_last = -1
	crop_selection = 0
	melon_seeds = 0
	watermelon_seeds = 0
	melons = 0
	watermelons = 0
	melon_meals = 0
	watermelon_meals = 0
	crop_drops.clear()
	merchant_open = false
	merchant_panel.hide()
	countdown_label.text = ""
	damage_numbers.clear()
	hit_flash_clock = 0.0
	poison_clock = 0.0
	burn_clock = 0.0
	freeze_clock = 0.0
	freeze_lock_clock = 0.0
	status_tick = 0.0
	combo_count = 0
	combo_clock = 0.0
	wave_damage_taken = 0.0
	crit_sound_clock = 0.0
	phase = "prep"
	phase_clock = PREP_SECONDS
	first_reaper_spawned = false
	companion = player + Vector2(-59, 14)
	companion_level = 1
	companion_xp = 0
	companion_xp_needed = 18
	companion_damage = 3.6
	companion_max_hp = 90.0
	companion_hp = companion_max_hp
	companion_attack_clock = 0.5
	companion_meal_clock = 4.0
	companion_heal_clock = 7.0
	companion_walk_clock = 0.0
	companion_down_clock = 0.0
	companion_was_moving = false
	companion_mode = "巡回"
	companion_goal = CAMP_STATIONS[0]
	companion_decision_clock = 0.0
	companion_work_clock = 2.0
	companion_patrol_index = 0
	companion_skill_clock = 9.0
	companion_stats = [0, 0, 0, 0, 0, 0]
	hero_stats = [0, 0, 0, 0, 0, 0]
	pending_hero_points = 0
	pending_mint_points = 0
	upgrade_target = "hero"
	max_mp = 30.0
	mp = 30.0
	skill_buff_clock = 0.0
	skill_guard_clock = 0.0
	hostile_orbs.clear()
	hp_bar_color_state = -1
	generate_scenery()
	farm_plots.clear()
	for plot_pos in FARM_PLOTS:
		farm_plots.append({"pos": plot_pos, "progress": -1.0, "crop": 0})
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
	palette_button.text = "カラー: %s" % PALETTE_NAMES[palette_id]
	accessory_button.text = "帽子: %s" % ACCESSORY_NAMES[accessory_id]
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
	palette_button.text = "カラー: %s" % PALETTE_NAMES[palette_id]
	play_sound(AUDIO_PICKUP, -19.0)
	queue_redraw()

func cycle_accessory() -> void:
	if state != "choose":
		return
	accessory_id = (accessory_id + 1) % ACCESSORY_NAMES.size()
	accessory_button.text = "帽子: %s" % ACCESSORY_NAMES[accessory_id]
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
	show_status("%s / %s  キャンプで準備しよう！" % [character_name, CLASS_NAMES[index]], Color("90e7ed"))
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

func interact_nearby() -> void:
	# Mint's soul and shrine have priority so revival never fights with cooking.
	if mint_soul_carried and player.distance_to(REVIVE_SHRINE) < 90.0:
		revive_mint()
		return
	if mint_soul_on_ground and player.distance_to(mint_soul_pos) < 100.0:
		mint_soul_on_ground = false
		mint_soul_carried = true
		show_status("ミントの命を回収！ 遠くの月の祭壇へ運ぼう（マップ南東）", Color("ffa3d0"))
		play_sound(AUDIO_RARE, -13.0)
		return
	if player.distance_to(SLOT_POS) < 105.0:
		toggle_slot()
		return
	if player.distance_to(MERCHANT_POS) < 108.0:
		toggle_merchant()
		return
	for i in range(crop_drops.size() - 1, -1, -1):
		if player.distance_to(crop_drops[i]["pos"]) < 95.0:
			collect_crop_seed(i)
			return
	# Coins can be collected by E as well as by walking over them.
	for i in range(coin_drops.size() - 1, -1, -1):
		if player.distance_to(coin_drops[i]["pos"]) < 95.0:
			collect_coin(i)
			return
	# One key for pickups, plots and campfires. Closest interactable wins.
	var nearest_loot := 99999.0
	for drop in drops:
		nearest_loot = minf(nearest_loot, player.distance_to(drop["pos"]))
	var plot_i := nearest_plot_index()
	var farm_distance := 99999.0 if plot_i < 0 else player.distance_to(farm_plots[plot_i]["pos"])
	var camp_i := nearest_camp_index()
	var camp_distance := 99999.0 if camp_i < 0 else player.distance_to(CAMP_STATIONS[camp_i])
	if nearest_loot < 92.0 and nearest_loot <= farm_distance and nearest_loot <= camp_distance:
		pickup_nearby()
	elif farm_distance < 75.0 and farm_distance <= camp_distance:
		farm_interact()
	elif camp_distance < 115.0:
		toggle_cooking()
	elif nearest_loot < 92.0:
		pickup_nearby()
	else:
		show_status("近くに操作できるものがありません", Color("c2dce6"))

func crop_seed_count(crop_id: int) -> int:
	match crop_id:
		1: return melon_seeds
		2: return watermelon_seeds
	return seeds

func use_crop_seed(crop_id: int) -> void:
	match crop_id:
		1: melon_seeds -= 1
		2: watermelon_seeds -= 1
		_: seeds -= 1

func cycle_crop() -> void:
	crop_selection = (crop_selection + 1) % CROP_NAMES.size()
	show_status("植える作物：%s（種%d） / [F]で切替" % [CROP_NAMES[crop_selection], crop_seed_count(crop_selection)], CROP_COLORS[crop_selection])

func farm_interact() -> void:
	var plot_i := nearest_plot_index()
	if plot_i < 0:
		show_status("畑の近くでEキーを押してください", Color("bbdcc8"))
		return
	var plot: Dictionary = farm_plots[plot_i]
	var progress := float(plot["progress"])
	if progress < 0.0:
		if crop_seed_count(crop_selection) <= 0:
			show_status("%sの種がありません。商人や敵から入手 / [F]で切替" % CROP_NAMES[crop_selection], Color("ffc18a"))
			return
		use_crop_seed(crop_selection)
		plot["crop"] = crop_selection
		plot["progress"] = 0.0
		show_status("%sを植えた！ あと%d秒" % [CROP_NAMES[crop_selection], roundi(CROP_GROW[crop_selection])], CROP_COLORS[crop_selection])
		play_sound(AUDIO_PICKUP, -17.0)
	elif progress >= float(CROP_GROW[int(plot.get("crop", 0))]):
		var crop_id := int(plot.get("crop", 0))
		match crop_id:
			1: melons += 1
			2: watermelons += 1
			_: carrots += 2
		plot["progress"] = -1.0
		show_status("収穫！ %s +%d" % [CROP_NAMES[crop_id], 2 if crop_id == 0 else 1], CROP_COLORS[crop_id])
		burst(plot["pos"], CROP_COLORS[crop_id], 22)
		play_sound(AUDIO_PICKUP, -11.0)
	else:
		show_status("%s育成中… あと%d秒" % [CROP_NAMES[int(plot.get("crop", 0))], ceili(float(CROP_GROW[int(plot.get("crop", 0))]) - progress)], Color("b3f6b1"))

func spawn_crop_seed(pos: Vector2, crop_id: int) -> void:
	crop_drops.append({"pos": pos + Vector2(rng.randf_range(-15.0, 15.0), rng.randf_range(-15.0, 15.0)), "crop": crop_id, "life": 65.0, "phase": rng.randf() * TAU})
	burst(pos, CROP_COLORS[crop_id], 10)

func collect_crop_seed(index: int) -> void:
	if index < 0 or index >= crop_drops.size():
		return
	var crop_id: int = int(crop_drops[index]["crop"])
	match crop_id:
		1: melon_seeds += 1
		2: watermelon_seeds += 1
		_: seeds += 1
	crop_drops.remove_at(index)
	show_status("レアな種！ %sの種+1" % CROP_NAMES[crop_id], CROP_COLORS[crop_id])
	play_sound(AUDIO_RARE, -15.0)

func update_crop_drops(delta: float) -> void:
	for i in range(crop_drops.size() - 1, -1, -1):
		crop_drops[i]["life"] = float(crop_drops[i]["life"]) - delta
		crop_drops[i]["phase"] = float(crop_drops[i]["phase"]) + delta * 2.4
		if float(crop_drops[i]["life"]) <= 0.0:
			crop_drops.remove_at(i)

func toggle_cooking() -> void:
	if state != "playing":
		return
	if not cooking_open and nearest_camp_index() < 0:
		show_status("焚き火の近くでEキーを押してください", Color("ffd7a2"))
		return
	cooking_open = not cooking_open
	cooking_panel.visible = cooking_open
	if cooking_open:
		inventory_open = false
		inventory_panel.hide()
		refresh_cooking_ui()
		pickup_hint.text = ""

func refresh_cooking_ui() -> void:
	cooking_info.text = "ニンジン%d  キノコ%d  メロン%d  スイカ%d\n作り置き: シチュー%d [H] / スープ%d [J] / ジュース%d [K] / パフェ%d [L]" % [carrots, mushrooms, melons, watermelons, stew_meals, broth_meals, melon_meals, watermelon_meals]

func cook_recipe(which: int) -> void:
	if state != "playing" or not cooking_open:
		return
	if which == 0:
		if carrots < 2:
			show_status("シチューにはニンジンが2個必要です", Color("ffbbaa"))
			return
		carrots -= 2
		stew_meals += 1
		show_status("シチュー完成！ Hで食べる / ミントも食べます", Color("95ffae"))
	elif which == 1:
		if carrots < 1 or mushrooms < 1:
			show_status("ニンジン1個とキノコ1個が必要です", Color("ffbbaa"))
			return
		carrots -= 1
		mushrooms -= 1
		broth_meals += 1
		show_status("スープ完成！ Jで食べる / ミントも食べます", Color("95ffae"))
	elif which == 2:
		if melons < 1:
			show_status("メロンが1個必要です", Color("ffbbaa"))
			return
		melons -= 1
		melon_meals += 1
		show_status("メロンジュース完成！ KでHP・MP回復", Color("aaffc2"))
	else:
		if watermelons < 1:
			show_status("スイカが1個必要です", Color("ffbbaa"))
			return
		watermelons -= 1
		watermelon_meals += 1
		show_status("スイカパフェ完成！ LでHP回復", Color("aaffc2"))
	refresh_cooking_ui()
	play_sound(AUDIO_RARE, -16.0)
	burst(CAMP_STATIONS[maxi(0, nearest_camp_index())], Color("ffc782"), 24)

func quickbar_equip(index: int) -> void:
	if state != "playing" or cooking_open or slot_open:
		return
	equip_backpack_item(index)

func refresh_hotbar() -> void:
	if hotbar_buttons.is_empty() or backpack.size() < BAG_CAPACITY:
		return
	for i in range(BAG_CAPACITY):
		var item: Dictionary = backpack[i]
		var btn: Button = hotbar_buttons[i]
		if item.is_empty():
			btn.text = "%d  空き" % (i + 1)
			btn.icon = null
			btn.tooltip_text = "空きスロット"
			btn.add_theme_stylebox_override("normal", make_style(Color("1d2b3d"), Color("536a85"), 8))
		else:
			var rarity: int = int(item["rarity"])
			btn.icon = item_icon(item)
			var short_name: String = WEAPON_SHORT[int(item["kind"])] if str(item["type"]) == "weapon" else ARMOR_SHORT[int(item["slot"])]
			btn.text = "%d %s" % [i + 1, short_name]
			btn.tooltip_text = item_description(item) + "\nクリック / 数字キーで装備"
			btn.add_theme_stylebox_override("normal", make_style(Color("253349"), RARITY_COLORS[rarity], 8))
	hotbar_currency.text = "所持金 %dG\n種:人参%d/メロン%d/スイカ%d" % [coins, seeds, melon_seeds, watermelon_seeds]

func item_icon(item: Dictionary) -> Texture2D:
	if str(item.get("type", "")) == "armor":
		return ARMOR_ICONS[clampi(int(item.get("slot", 0)), 0, ARMOR_ICONS.size() - 1)]
	if int(item.get("kind", 0)) == 2:
		return SWORD_RARITY_ART[clampi(int(item.get("rarity", 0)), 0, 3)]
	return WEAPON_ICONS[clampi(int(item.get("kind", 0)), 0, WEAPON_ICONS.size() - 1)]

func toggle_merchant() -> void:
	if state != "playing":
		return
	if not merchant_open and player.distance_to(MERCHANT_POS) > 108.0:
		show_status("武器商人の近くでEキーを押してください", Color("caffd8"))
		return
	merchant_open = not merchant_open
	merchant_panel.visible = merchant_open
	if merchant_open:
		inventory_open = false
		inventory_panel.hide()
		cooking_open = false
		cooking_panel.hide()
		slot_open = false
		slot_panel.hide()
		refresh_merchant_ui()

func refresh_merchant_ui() -> void:
	merchant_info.text = "所持金 %dG  |  バッグ空き %d/5  |  [1〜8]で購入" % [coins, count_empty_bag_slots()]
	var costs := [50, 55, 135, 55, 12, 42, 75, 18]
	for i in range(merchant_buttons.size()):
		merchant_buttons[i].disabled = coins < costs[i] or (i < 4 and free_backpack_slot() < 0)

func buy_merchant_item(index: int) -> void:
	if not merchant_open or index < 0 or index > 7:
		return
	var costs := [50, 55, 135, 55, 12, 42, 75, 18]
	if coins < costs[index]:
		show_status("お金が足りません！", Color("ffb2a0"))
		return
	if index < 4 and free_backpack_slot() < 0:
		show_status("バッグがいっぱい！ [I]で整理", Color("ffb2a0"))
		return
	coins -= costs[index]
	match index:
		0: spawn_drop(MERCHANT_POS + Vector2(110, 25), 1, 2, 0)
		1: spawn_drop(MERCHANT_POS + Vector2(110, 25), 1, 1, 1)
		2: spawn_drop(MERCHANT_POS + Vector2(110, 25), 2, 5, 3)
		3: spawn_armor_drop(MERCHANT_POS + Vector2(110, 25), 1, 1)
		4: seeds += 3
		5: melon_seeds += 2
		6: watermelon_seeds += 2
		7: mushrooms += 2
	play_sound(AUDIO_PICKUP, -10.0)
	show_status("商人から購入！ [E]で拾える装備は店の右側に出ます", Color("b8ffd1"))
	refresh_merchant_ui()
	refresh_hotbar()


func toggle_slot() -> void:
	if state != "playing":
		return
	if not slot_open and player.distance_to(SLOT_POS) > 105.0:
		show_status("スロットマシンの近くでEキーを押してね", Color("ffe3a1"))
		return
	slot_open = not slot_open
	slot_panel.visible = slot_open
	if slot_open:
		inventory_open = false
		inventory_panel.hide()
		cooking_open = false
		cooking_panel.hide()
		refresh_slot_ui()

func refresh_slot_ui() -> void:
	slot_info.text = "所持金 %dG  /  1回 %dG" % [coins, SLOT_COST]
	slot_spin_button.disabled = coins < SLOT_COST or slot_spin_clock > 0.0

func spin_slot() -> void:
	if state != "playing" or not slot_open or slot_spin_clock > 0.0:
		return
	if coins < SLOT_COST:
		show_status("コインが足りません！ 敵を倒して集めよう", Color("ffbaad"))
		return
	coins -= SLOT_COST
	slot_roll = rng.randf()
	slot_spin_clock = 1.6
	slot_reel_step = 0.0
	slot_result.text = "◆  ◇  ★  回転中..."
	slot_prize_icon.texture = null
	slot_prize_icon.hide()
	refresh_slot_ui()
	refresh_hotbar()
	play_sound(AUDIO_PICKUP, -12.0, 1.5)

func resolve_slot_spin() -> void:
	var prize_pos: Vector2 = SLOT_POS + Vector2(-60, -15)
	var won_equipment := false
	if slot_roll < 0.01:
		slot_result.text = "★ ★ ★  神話級 MYTHIC 大当たり！"
		spawn_drop(prize_pos, 4)
		won_equipment = true
		play_sound(AUDIO_LEGEND, -4.0)
	elif slot_roll < 0.06:
		slot_result.text = "★ ★ ★  LEGENDARY 当たり！"
		spawn_drop(prize_pos, 3)
		won_equipment = true
	elif slot_roll < 0.20:
		slot_result.text = "◆ ◆ ◆  EPIC 装備！"
		spawn_drop(prize_pos, 2)
		won_equipment = true
	elif slot_roll < 0.48:
		slot_result.text = "◇ ◇ ◇  RARE 装備！"
		if rng.randf() < 0.5:
			spawn_armor_drop(prize_pos, 1)
			won_equipment = true
		else:
			spawn_drop(prize_pos, 1)
			won_equipment = true
	else:
		seeds += 2
		slot_result.text = "◇ ◆ ◇  はずれ… おまけで種+2"
		play_sound(AUDIO_IMPACT, -21.0)
	if won_equipment and not drops.is_empty():
		slot_prize_icon.texture = item_icon(drops.back())
		slot_prize_icon.show()
	else:
		slot_prize_icon.texture = null
		slot_prize_icon.hide()
	refresh_slot_ui()
	show_status("スロット結果：%s" % slot_result.text, Color("ffe0a1"))

func revive_mint() -> void:
	if not mint_soul_carried:
		return
	mint_soul_carried = false
	mint_soul_on_ground = false
	companion = REVIVE_SHRINE + Vector2(0, 43)
	companion_goal = companion
	companion_hp = companion_max_hp * 0.75
	companion_mode = "復活！"
	companion_decision_clock = 0.0
	companion_meal_clock = 4.0
	companion_heal_clock = 4.0
	burst(companion, Color("ffb7d8"), 40)
	play_sound(AUDIO_LEGEND, -12.0)
	show_status("ミントが復活！ LV%d と能力値はそのまま" % companion_level, Color("aaffd9"))

func collect_coin(index: int) -> void:
	if index < 0 or index >= coin_drops.size():
		return
	var amount: int = int(coin_drops[index]["amount"])
	coins += amount
	coin_drops.remove_at(index)
	play_sound(AUDIO_PICKUP, -22.0, 1.5)
	refresh_hotbar()

func spawn_coins(pos: Vector2, amount: int) -> void:
	coin_drops.append({"pos": pos + Vector2(rng.randf_range(-22.0, 22.0), rng.randf_range(-20.0, 20.0)), "amount": amount, "life": 65.0, "phase": rng.randf() * TAU})

func update_coins(delta: float) -> void:
	for i in range(coin_drops.size() - 1, -1, -1):
		var coin: Dictionary = coin_drops[i]
		coin["life"] = float(coin["life"]) - delta
		coin["phase"] = float(coin["phase"]) + delta * 4.0
		if player.distance_to(coin["pos"]) < 44.0:
			collect_coin(i)
		elif float(coin["life"]) <= 0.0:
			coin_drops.remove_at(i)

func is_player_airborne() -> bool:
	return jump_clock > 0.18

func start_jump() -> void:
	if jump_cooldown > 0.0 or freeze_lock_clock > 0.0 or state != "playing":
		return
	jump_clock = 0.62
	jump_cooldown = 1.55
	var heading := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): heading.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): heading.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): heading.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): heading.y += 1.0
	jump_direction = heading.normalized() if heading.length_squared() > 0.0 else Vector2.RIGHT.rotated(aim_angle)
	burst(player, Color("a8e6ff"), 8)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_M:
		muted = not muted
		if bgm_player != null:
			bgm_player.volume_db = -80.0 if muted else -17.0
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
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			select_upgrade(event.keycode - KEY_1)
		return
	if state == "dead":
		if event.keycode == KEY_R:
			reset_game()
		return
	if state == "playing":
		if merchant_open:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
				toggle_merchant()
			elif event.keycode >= KEY_1 and event.keycode <= KEY_8:
				buy_merchant_item(event.keycode - KEY_1)
			return
		if slot_open:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
				toggle_slot()
			return
		if cooking_open:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
				toggle_cooking()
			elif event.keycode == KEY_1:
				cook_recipe(0)
			elif event.keycode == KEY_2:
				cook_recipe(1)
			elif event.keycode == KEY_3:
				cook_recipe(2)
			elif event.keycode == KEY_4:
				cook_recipe(3)
			return
		if event.keycode == KEY_I or (inventory_open and event.keycode == KEY_ESCAPE):
			toggle_inventory()
			return
		if inventory_open:
			return
		if event.keycode == KEY_E:
			interact_nearby()
		elif event.keycode == KEY_SPACE:
			start_jump()
		elif event.keycode == KEY_F:
			cycle_crop()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			quickbar_equip(event.keycode - KEY_1)
		elif event.keycode == KEY_Q:
			activate_class_skill()
		elif event.keycode == KEY_H:
			eat_meal(false)
		elif event.keycode == KEY_J:
			eat_meal(true)
		elif event.keycode == KEY_K:
			eat_fruit(false)
		elif event.keycode == KEY_L:
			eat_fruit(true)
		elif event.keycode == KEY_F1:
			player = MERCHANT_POS + Vector2(-95, 15)
			camera.position = player
			show_status("テスト：武器商人へワープ！", Color("d0ffbb"))
		elif event.keycode == KEY_F4:
			player = REVIVE_SHRINE + Vector2(-72, 15)
			camera.position = player
			show_status("テスト：南東の月の祭壇へワープ！", Color("ffc2ed"))
		elif event.keycode == KEY_F2:
			spawn_drop(player + Vector2(85, 0), 4)
			show_status("テスト：神話級 MYTHIC 武器を出現", Color("ffa8e4"))
		elif event.keycode == KEY_F3:
			coins += 100
			refresh_hotbar()
			show_status("テスト：ゲーム内コイン+100G", Color("ffe49a"))
		elif event.keycode == KEY_F6:
			spawn_brute_test()
		elif event.keycode == KEY_F7:
			# Always cycle HEAD -> CHEST -> LEGGINGS -> ARMS for easy visual testing.
			spawn_armor_drop(player + Vector2(72, 0), 1, armor_test_slot)
			armor_test_slot = (armor_test_slot + 1) % ARMOR_SLOTS.size()
		elif event.keycode == KEY_F8:
			if event.shift_pressed:
				# Shift+F8: show all four creator-designed sword sprites on the ground.
				for tier in range(4):
					spawn_drop(player + Vector2(-96.0 + float(tier) * 66.0, 88.0), tier, 2)
				show_status("テスト：通常・レア・エピック・伝説の剣を4本出現", Color("b6edff"))
			else:
				# Debug: guarantee a legendary item without grinding.
				spawn_drop(player + Vector2(72, -20), 3)
		elif event.keycode == KEY_F9:
			spawn_reaper((player + Vector2(300, -140)).clamp(ARENA.position + Vector2(80, 80), ARENA.end - Vector2(80, 80)))
		elif event.keycode == KEY_F10:
			companion_take_damage(56.0)
			show_status("テスト：ミントに56ダメージ（2回でハートを落とす）", Color("bdfce5"))
		elif event.keycode == KEY_F11:
			# Developer shortcut: forcibly advance, clearing surviving enemies.
			if phase == "combat":
				enemies.clear()
			advance_phase()
		elif event.keycode == KEY_F12:
			# Developer: demonstrate Mint's independent leveling.
			award_mint_xp(30)

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

func update_music() -> void:
	if bgm_player == null:
		return
	var next_track := "battle" if phase == "combat" else "rest"
	if current_bgm != next_track:
		current_bgm = next_track
		bgm_player.stop()
		bgm_player.stream = AUDIO_BGM_BATTLE if next_track == "battle" else AUDIO_BGM_REST
		bgm_player.volume_db = -80.0 if muted else -17.0
		bgm_player.play()
	elif not bgm_player.playing:
		bgm_player.play()

func update_countdown() -> void:
	if phase == "combat":
		countdown_label.text = ""
		return
	var remain := ceili(phase_clock)
	if remain >= 1 and remain <= 5:
		countdown_label.text = str(remain)
		if countdown_last != remain:
			countdown_last = remain
			play_sound(AUDIO_COUNTDOWN, -10.0, 0.90 + float(5 - remain) * 0.13)
	else:
		countdown_label.text = ""


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
	jump_cooldown = maxf(0.0, jump_cooldown - delta)
	jump_clock = maxf(0.0, jump_clock - delta)
	if slot_spin_clock > 0.0:
		slot_spin_clock = maxf(0.0, slot_spin_clock - delta)
		slot_reel_step -= delta
		if slot_reel_step <= 0.0:
			slot_reel_step = 0.09
			var reels := ["★", "◆", "◇", "7"]
			slot_result.text = "%s  %s  %s  回転中..." % [reels[rng.randi_range(0, 3)], reels[rng.randi_range(0, 3)], reels[rng.randi_range(0, 3)]]
		if slot_spin_clock <= 0.0:
			resolve_slot_spin()
	enemy_sound_cooldown = maxf(0.0, enemy_sound_cooldown - delta)
	if state != "playing" or inventory_open or cooking_open or slot_open or merchant_open:
		update_hud()
		queue_redraw()
		return
	elapsed += delta
	update_music()
	update_countdown()
	hit_flash_clock = maxf(0.0, hit_flash_clock - delta)
	crit_sound_clock = maxf(0.0, crit_sound_clock - delta)
	combo_clock = maxf(0.0, combo_clock - delta)
	if combo_clock <= 0.0:
		combo_count = 0
	poison_clock = maxf(0.0, poison_clock - delta)
	burn_clock = maxf(0.0, burn_clock - delta)
	freeze_clock = maxf(0.0, freeze_clock - delta)
	freeze_lock_clock = maxf(0.0, freeze_lock_clock - delta)
	status_tick -= delta
	if status_tick <= 0.0:
		status_tick = 1.0
		if poison_clock > 0.0: apply_status_damage(3.0, Color("a3e96a"))
		if burn_clock > 0.0: apply_status_damage(4.0, Color("ff9b5a"))
	for i in range(damage_numbers.size() - 1, -1, -1):
		damage_numbers[i]["life"] = float(damage_numbers[i]["life"]) - delta
		damage_numbers[i]["pos"] = (damage_numbers[i]["pos"] as Vector2) + Vector2(0, -42.0 * delta)
		if float(damage_numbers[i]["life"]) <= 0.0:
			damage_numbers.remove_at(i)
	food_buff_clock = maxf(0.0, food_buff_clock - delta)
	skill_buff_clock = maxf(0.0, skill_buff_clock - delta)
	skill_guard_clock = maxf(0.0, skill_guard_clock - delta)
	mp = minf(max_mp, mp + (1.6 + float(hero_stats[3]) * 0.3) * delta)
	heal_spell_clock = maxf(0.0, heal_spell_clock - delta)
	for plot in farm_plots:
		if float(plot["progress"]) >= 0.0 and float(plot["progress"]) < float(CROP_GROW[int(plot.get("crop", 0))]):
			plot["progress"] = minf(float(CROP_GROW[int(plot.get("crop", 0))]), float(plot["progress"]) + delta)
	if phase != "combat":
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
		player += movement.normalized() * move_speed * (0.0 if freeze_lock_clock > 0.0 else (0.52 if freeze_clock > 0.0 else 1.0)) * (1.0 + float(hero_stats[1]) * 0.04) * (1.25 if food_buff_clock > 0.0 else 1.0) * (1.3 if skill_buff_clock > 0.0 else 1.0) * delta
	else:
		walk_clock = 0.0
	if jump_clock > 0.0:
		player += jump_direction * 270.0 * delta
	player = player.clamp(ARENA.position + Vector2(35, 45), ARENA.end - Vector2(35, 35))
	camera.position = player
	var aim: Vector2 = get_global_mouse_position() - player
	if aim.length() > 3.0:
		aim_angle = aim.angle()
	# The sanctuary is safe, but weapons are disabled inside it to prevent free farming.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and freeze_lock_clock <= 0.0 and fire_clock <= 0.0 and jump_clock <= 0.0 and phase == "combat" and not is_in_safe_camp(player):
		attack()
	if phase == "combat":
		combat_elapsed += delta
		spawn_clock -= delta
		if wave_spawned < wave_target and spawn_clock <= 0.0:
			var group_size := mini(4, 1 + int(floor(float(maxi(0, wave - 1)) / 4.0)))
			for spawn_i in range(group_size):
				if wave_spawned >= wave_target or enemies.size() >= wave_enemy_limit():
					break
				# The final third of wave 3+ contains one natural NIGHT REAPER.
				if wave >= 3 and not first_reaper_spawned and wave_spawned >= maxi(2, int(wave_target / 3)) and not has_active_reaper():
					first_reaper_spawned = true
					spawn_reaper(random_spawn_edge())
					show_status("強敵 NIGHT REAPER が出現！", Color("ff839e"))
				else:
					spawn_enemy()
				wave_spawned += 1
			spawn_clock = maxf(0.56, 1.65 - float(maxi(0, wave - 1)) * 0.075)
		if wave_spawned >= wave_target and enemies.is_empty():
			wave_clear_clock -= delta
			if wave_clear_clock < -1.2:
				advance_phase()
		else:
			wave_clear_clock = 0.0
	update_companion(delta)
	update_projectiles(delta)
	if phase == "combat":
		update_enemies(delta)
		update_hostile_orbs(delta)
		cleanup_defeated_enemies()
	update_particles(delta)
	update_drops(delta)
	update_coins(delta)
	update_crop_drops(delta)
	if state == "playing" and xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 4 + level * 3
		pending_hero_points += 1
		if level == 5:
			show_status("レベル5！ Qで『%s』が使える！" % SKILL_NAMES[class_id], Color("a4edff"))
		elif level == 10:
			show_status("レベル10！ 職業スキルが強化された！", Color("a4edff"))
	if state == "playing" and (pending_hero_points > 0 or pending_mint_points > 0):
		start_upgrade()
	update_hud()
	queue_redraw()

func advance_phase() -> void:
	if phase == "combat":
		# Only a fully cleared wave can reach this branch in normal play.
		phase = "rest"
		phase_clock = REST_SECONDS
		poison_clock = 0.0
		burn_clock = 0.0
		freeze_clock = 0.0
		freeze_lock_clock = 0.0
		countdown_last = -1
		projectiles.clear()
		hostile_orbs.clear()
		var clear_bonus := 5 + wave * 2
		if wave_damage_taken <= 0.0:
			clear_bonus += 12
			melon_seeds += 1
			show_status("ノーダメージWAVE！ ボーナス+12G・メロンの種！", Color("fff2a0"))
		coins += clear_bonus
		banner.text = "WAVE %d CLEAR！ %s +%dG" % [wave, "PERFECT！" if wave_damage_taken <= 0.0 else "全滅達成！", clear_bonus]
		banner.add_theme_color_override("font_color", Color("ffe99b"))
		banner_clock = 3.5
		banner.show()
		burst(player, Color("ffe88c"), 46)
		play_sound(AUDIO_WAVE_CLEAR, -9.0)
		seeds += 2
		mushrooms += 1
		if companion_hp > 0.0:
			companion_hp = minf(companion_max_hp, companion_hp + 25.0)
		var player_rest_heal := maxf(18.0, max_hp * REST_PLAYER_HEAL_FRACTION)
		var old_player_hp := hp
		hp = minf(max_hp, hp + player_rest_heal)
		burst(player, Color("8effb3"), 24)
		# Keep the wave-clear celebration on screen; the HUD shows the rest phase.
		play_sound(AUDIO_PICKUP, -12.0)
	else:
		phase = "combat"
		wave += 1
		phase_clock = 0.0
		wave_target = mini(56, 7 + wave * 4)
		wave_spawned = 0
		wave_clear_clock = 0.0
		wave_damage_taken = 0.0
		countdown_last = -1
		countdown_label.text = "GO!"
		spawn_clock = 0.5
		first_reaper_spawned = false
		show_status("WAVE %d！ 敵が強くなる / キャンプは安全" % wave, Color("ffb8a0"))
		play_sound(AUDIO_HEAVY, -20.0)

func is_in_safe_camp(point: Vector2) -> bool:
	for station in CAMP_STATIONS:
		if point.distance_to(station) < CAMP_RADIUS:
			return true
	return false

func keep_enemy_out_of_camp(point: Vector2) -> Vector2:
	var safe_pos: Vector2 = point
	for station in CAMP_STATIONS:
		# CAMP_STATIONS is an untyped constant Array: cast each entry explicitly.
		# Otherwise GDScript 4.7 cannot infer offset/outward with :=.
		var camp_center: Vector2 = station as Vector2
		var offset: Vector2 = safe_pos - camp_center
		var min_dist: float = CAMP_RADIUS + CAMP_ENEMY_MARGIN
		if offset.length() < min_dist:
			var outward: Vector2 = offset.normalized() if offset.length_squared() > 0.01 else Vector2.RIGHT
			safe_pos = camp_center + outward * min_dist
	return safe_pos

func wave_enemy_limit() -> int:
	return mini(MAX_ENEMIES - 1, 18 + wave * 7)

func has_active_reaper() -> bool:
	for enemy in enemies:
		if bool(enemy["boss"]) and float(enemy["hp"]) > 0.0:
			return true
	return false

func award_mint_xp(amount: int) -> void:
	if companion_hp <= 0.0:
		return
	companion_xp += amount
	while companion_xp >= companion_xp_needed:
		companion_xp -= companion_xp_needed
		companion_level += 1
		companion_xp_needed = 18 + companion_level * 9
		pending_mint_points += 1
		companion_hp = minf(companion_max_hp, companion_hp + 6.0)
		burst(companion, Color("a2ffdb"), 24)
		show_status("ミントがレベル%dに！ 能力を選んであげよう" % companion_level, Color("a4ffe2"))
		play_sound(AUDIO_RARE, -20.0)

func nearest_camp_index() -> int:
	for i in range(CAMP_STATIONS.size()):
		if player.distance_to(CAMP_STATIONS[i]) < 115.0:
			return i
	return -1

func eat_meal(is_broth: bool) -> void:
	if is_broth:
		if broth_meals < 1:
			show_status("スープがない！ 焚き火で[E]を押して料理", Color("ffbfa7"))
			return
		broth_meals -= 1
		hp = minf(max_hp, hp + 25.0)
		food_buff_clock = 30.0
		show_status("スープ！ HP+25 / 移動速度アップ", Color("a4ffbc"))
	else:
		if stew_meals < 1:
			show_status("シチューがない！ 焚き火で[E]を押して料理", Color("ffbfa7"))
			return
		stew_meals -= 1
		hp = minf(max_hp, hp + 40.0)
		show_status("シチュー！ HP+40", Color("a4ffbc"))
	burst(player, Color("adffca"), 20)
	play_sound(AUDIO_PICKUP, -12.0)

func eat_fruit(is_watermelon: bool) -> void:
	if is_watermelon:
		if watermelon_meals <= 0:
			show_status("スイカパフェがない！", Color("ffc5a3"))
			return
		watermelon_meals -= 1
		hp = minf(max_hp, hp + 60.0)
	else:
		if melon_meals <= 0:
			show_status("メロンジュースがない！", Color("ffc5a3"))
			return
		melon_meals -= 1
		hp = minf(max_hp, hp + 30.0)
		mp = minf(max_mp, mp + 25.0)
	burst(player, Color("b7ffaf"), 24)
	play_sound(AUDIO_PICKUP, -9.0)


func update_companion(delta: float) -> void:
	if companion_hp <= 0.0:
		companion_mode = "魂を祭壇へ"
		return
	companion_attack_clock -= delta
	companion_meal_clock -= delta
	companion_heal_clock -= delta
	companion_decision_clock -= delta
	companion_work_clock -= delta
	companion_skill_clock -= delta
	# Mint eats meals from the shared kitchen stock when seriously injured.
	if companion_hp < companion_max_hp * 0.64 and companion_meal_clock <= 0.0:
		if stew_meals > 0:
			stew_meals -= 1
			companion_hp = minf(companion_max_hp, companion_hp + 42.0 + float(companion_stats[2]) * 3.0)
			companion_meal_clock = 6.0
			show_status("ミントがシチューを食べて回復！", Color("c0ffe2"))
			burst(companion, Color("9fffc1"), 18)
			play_sound(AUDIO_PICKUP, -14.0)
		elif broth_meals > 0:
			broth_meals -= 1
			companion_hp = minf(companion_max_hp, companion_hp + 28.0 + float(companion_stats[2]) * 3.0)
			companion_meal_clock = 6.0
			show_status("ミントがスープを飲んで回復！", Color("c0ffe2"))
			burst(companion, Color("9fffc1"), 18)
			play_sound(AUDIO_PICKUP, -14.0)
	# Decide an independent destination every ~1.3s, not relative to player.
	if companion_decision_clock <= 0.0:
		companion_decision_clock = 1.3
		if companion_hp < companion_max_hp * 0.30 and phase == "combat":
			companion_mode = "退避"
			companion_goal = closest_camp_to(companion)
		elif phase == "combat":
			var closest_enemy: Dictionary = {}
			var best_distance := 580.0
			for enemy in enemies:
				if float(enemy["hp"]) <= 0.0:
					continue
				var distance: float = companion.distance_to(enemy["pos"])
				if distance < best_distance:
					closest_enemy = enemy
					best_distance = distance
			if not closest_enemy.is_empty():
				companion_mode = "戦闘"
				var target: Vector2 = closest_enemy["pos"]
				var away: Vector2 = (companion - target).normalized()
				companion_goal = target + away * 205.0
			else:
				companion_mode = "巡回"
				companion_goal = CAMP_STATIONS[companion_patrol_index % CAMP_STATIONS.size()] + Vector2(130, 70).rotated(float(companion_patrol_index) * 1.3)
				if companion.distance_to(companion_goal) < 125.0:
					companion_patrol_index += 1
		else:
			# Between waves Mint tends the crops, then prepares food at the campfire.
			var ready_plot := -1
			for i in range(farm_plots.size()):
				if float(farm_plots[i]["progress"]) >= float(CROP_GROW[int(farm_plots[i].get("crop", 0))]) or (float(farm_plots[i]["progress"]) < 0.0 and seeds > 0):
					if ready_plot < 0 or companion.distance_to(farm_plots[i]["pos"]) < companion.distance_to(farm_plots[ready_plot]["pos"]):
						ready_plot = i
			if ready_plot >= 0 and (carrots < 5 or stew_meals >= 2):
				companion_mode = "農作業"
				companion_goal = farm_plots[ready_plot]["pos"]
			else:
				companion_mode = "料理"
				companion_goal = closest_camp_to(companion)
	companion_goal = companion_goal.clamp(ARENA.position + Vector2(60, 60), ARENA.end - Vector2(60, 60))
	var dist := companion.distance_to(companion_goal)
	companion_was_moving = dist > 22.0
	if companion_was_moving:
		var step := minf(dist, (225.0 + float(companion_stats[1]) * 12.0) * delta)
		companion += (companion_goal - companion).normalized() * step
		companion_walk_clock += 9.0 * delta
	else:
		companion_walk_clock = 0.0
	# Independent farming/cooking only while safe and not in a menu.
	if phase != "combat" and companion_work_clock <= 0.0:
		companion_work_clock = 5.0
		if companion_mode == "農作業":
			for plot in farm_plots:
				if companion.distance_to(plot["pos"]) < 68.0:
					if float(plot["progress"]) >= float(CROP_GROW[int(plot.get("crop", 0))]):
						var mint_crop: int = int(plot.get("crop", 0))
						plot["progress"] = -1.0
						match mint_crop:
							1: melons += 1
							2: watermelons += 1
							_: carrots += 2
						show_status("ミントが%sを収穫！" % CROP_NAMES[mint_crop], Color("baffb9"))
					elif float(plot["progress"]) < 0.0 and seeds > 0:
						plot["progress"] = 0.0
						plot["crop"] = 0
						seeds -= 1
						show_status("ミントが畑に種をまいた！", Color("baffb9"))
					break
		elif companion_mode == "料理" and companion.distance_to(companion_goal) < 85.0 and carrots >= 2 and stew_meals < 3:
			carrots -= 2
			stew_meals += 1
			show_status("ミントがシチューを作った！ [H]で食べられる", Color("ffd9a2"))
	if phase != "combat":
		return
	# Level 5: Mint learns an automatic healing aura; level 10 upgrades it.
	if companion_level >= 5 and companion_skill_clock <= 0.0 and player.distance_to(companion) < 400.0 and hp < max_hp * 0.75:
		var heal_amount := 20.0 + float(companion_stats[5]) * 3.0 + (16.0 if companion_level >= 10 else 0.0)
		hp = minf(max_hp, hp + heal_amount)
		companion_hp = minf(companion_max_hp, companion_hp + heal_amount * 0.4)
		companion_skill_clock = 17.0
		burst(companion, Color("b5ffea"), 23)
		show_status("ミントのスキル『森の癒やし』！", Color("b5ffea"))
	if hp < max_hp * 0.48 and companion_heal_clock <= 0.0 and player.distance_to(companion) < 240.0:
		var heal_amount := 12.0 + float(companion_level - 1) * 1.0 + float(companion_stats[5]) * 2.0
		hp = minf(max_hp, hp + heal_amount)
		companion_heal_clock = maxf(7.0, 13.0 - float(companion_level - 1) * 0.35)
		burst(player, Color("9fffe0"), 12)
		show_status("ミントが主人公を回復！", Color("9fffe0"))
	if is_in_safe_camp(companion):
		return
	if companion_attack_clock <= 0.0:
		var best: Dictionary = {}
		var near := 400.0
		for enemy in enemies:
			if float(enemy["hp"]) <= 0.0:
				continue
			var d: float = companion.distance_to(enemy["pos"])
			if d < near:
				near = d
				best = enemy
		if not best.is_empty():
			var direction: Vector2 = ((best["pos"] as Vector2) - companion).normalized()
			var dmg := companion_damage * (1.0 + float(companion_stats[0]) * 0.08 + float(companion_stats[4]) * 0.07 + float(companion_stats[5]) * 0.04)
			projectiles.append({"pos": companion + direction * 27.0, "vel": direction * 720.0, "dmg": dmg, "accuracy": minf(0.99, 0.85 + float(companion_stats[4]) * 0.03), "radius": 5.0, "pierce": 1, "kind": "magic", "tint": Color("8bffe1"), "life": 1.1, "hit_ids": [], "crit_chance": crit_probability(companion_stats[4]), "trait": -1})
			companion_attack_clock = maxf(0.32, 0.85 - float(companion_level - 1) * 0.025 - float(companion_stats[1]) * 0.025)
			play_sound(AUDIO_BOW, -27.0, 1.4)

func closest_camp_to(pos: Vector2) -> Vector2:
	var nearest: Vector2 = CAMP_STATIONS[0]
	for station in CAMP_STATIONS:
		var point: Vector2 = station as Vector2
		if pos.distance_to(point) < pos.distance_to(nearest):
			nearest = point
	return nearest

func update_hostile_orbs(delta: float) -> void:
	for i in range(hostile_orbs.size() - 1, -1, -1):
		var orb: Dictionary = hostile_orbs[i]
		orb["pos"] = (orb["pos"] as Vector2) + (orb["vel"] as Vector2) * delta
		orb["life"] = float(orb["life"]) - delta
		# Hostile projectiles are absorbed at the sanctuary perimeter.
		var gone := float(orb["life"]) <= 0.0 or not ARENA.has_point(orb["pos"]) or is_in_safe_camp(orb["pos"])
		if not gone and not is_in_safe_camp(player) and not is_player_airborne() and player.distance_to(orb["pos"]) < 20.0:
			var orb_damage := maxf(2.0, float(orb.get("damage", 14.0)) * (1.0 - calculate_damage_reduction()))
			hp -= orb_damage
			wave_damage_taken += orb_damage
			if str(orb.get("status", "")) in ["venom", "frost", "ember"]:
				apply_player_status(str(orb["status"]))
			hurt_clock = 0.24
			burst(player, Color("ff6393"), 13)
			gone = true
			if hp <= 0.0:
				player_died()
		if not gone and companion_hp > 0.0 and not is_in_safe_camp(companion) and companion.distance_to(orb["pos"]) < 19.0:
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
		mint_soul_on_ground = true
		mint_soul_carried = false
		mint_soul_pos = companion
		show_status("ミントが倒れた！ ハートを拾い、南東の月の祭壇へ", Color("ffb0cb"))

func player_died() -> void:
	state = "dead"
	dead_panel.show()
	dead_label.text = "Wave %d  討伐 %d  レベル %d" % [wave, kills, level]

func generate_scenery() -> void:
	scenery.clear()
	var decor_rng := RandomNumberGenerator.new()
	decor_rng.seed = 802411
	for i in range(330):
		var pos := Vector2(decor_rng.randf_range(105.0, ARENA.end.x - 85.0), decor_rng.randf_range(175.0, ARENA.end.y - 68.0))
		var close_to_camp := false
		for station in CAMP_STATIONS:
			if pos.distance_to(station) < 255.0:
				close_to_camp = true
		if close_to_camp:
			continue
		scenery.append({"pos": pos, "kind": decor_rng.randi_range(0, 6), "size": decor_rng.randf_range(0.8, 1.4), "glow": decor_rng.randf_range(0.0, TAU)})

func crit_probability(dexterity: int) -> float:
	return minf(0.50, 0.05 + float(dexterity) * 0.025)

func add_damage_number(at: Vector2, amount: float, is_crit: bool, tint: Color = Color("fff3da")) -> void:
	damage_numbers.append({"pos": at + Vector2(rng.randf_range(-15.0, 15.0), -42.0), "amount": amount, "critical": is_crit, "tint": tint, "life": 0.9})
	if damage_numbers.size() > 70:
		damage_numbers.pop_front()

func deal_enemy_damage(enemy: Dictionary, base_damage: float, impact_pos: Vector2, crit_rate: float, element_id: int = -1) -> void:
	if float(enemy["hp"]) <= 0.0:
		return
	var is_critical: bool = rng.randf() < crit_rate
	var actual_damage: float = base_damage * (2.0 if is_critical else 1.0)
	enemy["hp"] = float(enemy["hp"]) - actual_damage
	enemy["hurt"] = 0.20 if is_critical else 0.12
	add_damage_number(impact_pos, actual_damage, is_critical, Color("ffe478") if is_critical else Color("fff3da"))
	if element_id == 0:
		enemy["burn"] = maxf(float(enemy.get("burn", 0.0)), 3.0)
	elif element_id == 1:
		enemy["freeze"] = maxf(float(enemy.get("freeze", 0.0)), 2.3)
	elif element_id == 2:
		enemy["poison"] = maxf(float(enemy.get("poison", 0.0)), 4.0)
	if is_critical:
		burst(impact_pos, Color("ffe18b"), 19)
		screen_shake = maxf(screen_shake, 0.18)
		hit_flash_clock = 0.13
		if crit_sound_clock <= 0.0:
			play_sound(AUDIO_CRITICAL, -12.0, rng.randf_range(0.96, 1.12))
			crit_sound_clock = 0.10
	else:
		burst(impact_pos, Color("b9e9ff"), 4)

func apply_player_status(kind: String) -> void:
	match kind:
		"poison":
			poison_clock = maxf(poison_clock, 5.0)
			show_status("毒を受けた！ キャンプに退避！", Color("b1f17d"))
		"frost":
			freeze_clock = maxf(freeze_clock, 3.5)
			freeze_lock_clock = maxf(freeze_lock_clock, 1.1)
			show_status("氷漬け！ 1.1秒行動不能 → 移動速度低下！", Color("a8e9ff"))
		"ember":
			burn_clock = maxf(burn_clock, 4.0)
			show_status("火傷！ 継続ダメージに注意！", Color("ffad82"))


func attack() -> void:
	var kind: int = int(equipped["kind"])
	var tier: int = int(equipped["rarity"])
	var power: float = RARITY_DAMAGE[tier] * float(equipped.get("bonus", 1.0)) * damage_mult * attack_stat_multiplier(kind) * (1.35 if skill_buff_clock > 0.0 else 1.0)
	var speed: float = RARITY_RATE[tier] * attack_speed_mult * (1.0 + float(hero_stats[1]) * 0.02)
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
		2: # Sword: longer reach and faster recovery, useful against bosses.
			fire_clock = 0.34 / speed
			melee_hit(110.0, 0.95, 5.2 * power, 21.0)
			burst(player + Vector2.RIGHT.rotated(aim_angle) * 75.0, Color("e5f7ff"), 11)
			play_sound(AUDIO_SLASH, -12.0, rng.randf_range(0.96, 1.08))
		3: # Greatsword: wide heavy cleave with meaningful knockback.
			fire_clock = 0.85 / speed
			attack_clock = 0.33
			attack_duration = 0.33
			melee_hit(155.0, 1.21, 9.8 * power, 48.0)
			play_sound(AUDIO_HEAVY, -10.0, rng.randf_range(0.91, 1.04))
			screen_shake = maxf(screen_shake, 0.09)
			burst(player + Vector2.RIGHT.rotated(aim_angle) * 105.0, Color("e6b7ff"), 12)
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
	projectiles.append({"pos": player + Vector2.RIGHT.rotated(angle) * 37.0, "vel": velocity, "dmg": dmg, "accuracy": hit_chance(int(equipped["kind"])), "radius": radius, "pierce": pierce, "kind": kind, "tint": tint, "life": 1.35, "hit_ids": [], "crit_chance": crit_probability(hero_stats[4]), "trait": int(equipped.get("trait", -1))})

func melee_hit(radius: float, half_angle: float, dmg: float, knockback: float) -> void:
	var direction := Vector2.RIGHT.rotated(aim_angle)
	for enemy in enemies:
		var diff: Vector2 = enemy["pos"] - player
		if diff.length() > radius + 16.0:
			continue
		if diff.length() > 1.0 and absf(wrapf(diff.angle() - aim_angle, -PI, PI)) > half_angle:
			continue
		if rng.randf() > hit_chance(int(equipped["kind"])):
			burst(enemy["pos"], Color("b1c0d1"), 2)
			continue
		deal_enemy_damage(enemy, dmg, enemy["pos"], crit_probability(hero_stats[4]), int(equipped.get("trait", -1)))
		enemy["pos"] = (enemy["pos"] as Vector2) + direction * knockback
		burst(enemy["pos"], Color("f2c6ff"), 6)

func random_spawn_edge() -> Vector2:
	# Enemies arrive beyond the current camera view, not from the distant world border.
	for tries in range(22):
		var angle := rng.randf_range(0.0, TAU)
		var d := rng.randf_range(570.0, 710.0)
		var result := (player + Vector2.RIGHT.rotated(angle) * d).clamp(ARENA.position + Vector2(55, 55), ARENA.end - Vector2(55, 55))
		if result.distance_to(player) > 475.0 and not is_in_safe_camp(result):
			return result
	var fallback := (player + Vector2(450, 300)).clamp(ARENA.position + Vector2(55, 55), ARENA.end - Vector2(55, 55))
	return keep_enemy_out_of_camp(fallback)

func spawn_enemy() -> void:
	if enemies.size() >= wave_enemy_limit():
		return
	# NIGHT REAPER is never in the random spawn pool; exactly one natural
	# spawn is handled by the combat timer after wave 3.
	var elite_chance := minf(0.23, 0.07 + float(maxi(0, wave - 1)) * 0.017)
	if rng.randf() < elite_chance:
		spawn_brute(random_spawn_edge())
		return
	# Elemental ranged enemies unlock gradually and telegraph with distinct colors.
	var roll: float = rng.randf()
	var kind := "grunt"
	if wave >= 6 and roll < 0.11:
		kind = "ember"
	elif wave >= 5 and roll < 0.23:
		kind = "frost"
	elif wave >= 3 and roll < 0.37:
		kind = "venom"
	elif wave >= 5 and roll < 0.49:
		kind = "zigzag"
	elif wave >= 3 and roll < 0.61:
		kind = "spitter"
	elif wave >= 2 and roll < 0.78:
		kind = "tank"
	elif roll < 0.90:
		kind = "runner"
	var base_hp := 8.5
	var base_speed := 106.0
	match kind:
		"runner":
			base_hp = 6.0
			base_speed = 181.0
		"tank":
			base_hp = 24.0
			base_speed = 68.0
		"spitter":
			base_hp = 11.0
			base_speed = 92.0
		"zigzag":
			base_hp = 9.0
			base_speed = 145.0
		"venom":
			base_hp = 11.0
			base_speed = 98.0
		"frost":
			base_hp = 13.0
			base_speed = 88.0
		"ember":
			base_hp = 12.0
			base_speed = 106.0
	var total_hp := base_hp * (1.0 + float(maxi(0, wave - 1)) * 0.13)
	var speed_growth := 1.0 + minf(0.24, float(maxi(0, wave - 1)) * 0.02)
	enemy_serial += 1
	enemies.append({"id": enemy_serial, "pos": random_spawn_edge(), "hp": total_hp, "max_hp": total_hp,
		"speed": base_speed * speed_growth, "kind": kind, "fast": kind == "runner" or kind == "zigzag", "elite": false, "boss": false,
		"touch": 0.0, "hurt": 0.0, "walk": rng.randf() * 4.0, "target_ally": rng.randf() < 0.28,
		"windup": 0.0, "charge": 0.0, "charge_cd": 0.0, "charge_dir": Vector2.ZERO, "orb_cd": rng.randf_range(0.7, 2.1), "poison": 0.0, "burn": 0.0, "freeze": 0.0, "status_tick": 1.0})

func spawn_brute(pos: Vector2) -> void:
	if enemies.size() >= MAX_ENEMIES:
		return
	var total_hp := 28.0 * (1.0 + float(maxi(0, wave - 1)) * 0.15)
	enemy_serial += 1
	enemies.append({"id": enemy_serial, "pos": pos, "hp": total_hp, "max_hp": total_hp,
		"speed": 79.0 * (1.0 + minf(0.22, float(maxi(0, wave - 1)) * 0.02)), "fast": false, "elite": true, "boss": false, "target_ally": rng.randf() < 0.32,
		"touch": 0.45, "hurt": 0.0, "walk": rng.randf() * 4.0,
		"windup": 0.0, "charge": 0.0, "charge_cd": 0.0, "charge_dir": Vector2.ZERO, "orb_cd": 0.0, "poison": 0.0, "burn": 0.0, "freeze": 0.0, "status_tick": 1.0})
	burst(pos, Color("aa91ff"), 19)

func spawn_reaper(pos: Vector2) -> void:
	# Reserve a boss slot even at high enemy density; F9 can always test one.
	var total_hp := 100.0 * (1.0 + float(maxi(0, wave - 3)) * 0.12)
	enemy_serial += 1
	enemies.append({"id": enemy_serial, "pos": pos, "hp": total_hp, "max_hp": total_hp,
		"speed": 112.0 * (1.0 + minf(0.18, float(maxi(0, wave - 3)) * 0.018)), "fast": false, "elite": true, "boss": true, "target_ally": rng.randf() < 0.22,
		"touch": 0.7, "hurt": 0.0, "walk": rng.randf() * 4.0,
		"windup": 0.0, "charge": 0.0, "charge_cd": 0.0, "charge_dir": Vector2.ZERO, "orb_cd": 2.4, "poison": 0.0, "burn": 0.0, "freeze": 0.0, "status_tick": 1.0})
	burst(pos, Color("fa5687"), 28)

func spawn_brute_test() -> void:
	# F6: spawn a single elite visibly near the player, away from the HUD.
	var target := (player + Vector2(215, -70)).clamp(ARENA.position + Vector2(40, 75), ARENA.end - Vector2(40, 35))
	spawn_brute(target)
	show_status("STORM BRUTE出現！ 突進に注意！", Color("cba3ff"))

func update_enemies(delta: float) -> void:
	for enemy in enemies:
		if float(enemy["hp"]) <= 0.0:
			continue
		for status in ["poison", "burn", "freeze"]:
			enemy[status] = maxf(0.0, float(enemy.get(status, 0.0)) - delta)
		enemy["status_tick"] = float(enemy.get("status_tick", 1.0)) - delta
		if float(enemy["status_tick"]) <= 0.0:
			enemy["status_tick"] = 1.0
			var dot_damage := (2.0 if float(enemy.get("poison", 0.0)) > 0.0 else 0.0) + (3.0 if float(enemy.get("burn", 0.0)) > 0.0 else 0.0)
			if dot_damage > 0.0:
				enemy["hp"] = float(enemy["hp"]) - dot_damage
				add_damage_number(enemy["pos"], dot_damage, false, Color("b7ff93"))
		if float(enemy["hp"]) <= 0.0:
			continue
		# If Mint shelters in camp, enemies must chase the exposed player instead.
		var target_ally: bool = bool(enemy["target_ally"]) and companion_hp > 0.0 and not is_in_safe_camp(companion)
		var target_pos: Vector2 = companion if target_ally else player
		var toward: Vector2 = target_pos - enemy["pos"]
		var elite: bool = bool(enemy["elite"])
		var boss: bool = bool(enemy["boss"])
		var movement_multiplier := 0.55 if float(enemy.get("freeze", 0.0)) > 0.0 else 1.0
		enemy["touch"] = maxf(0.0, float(enemy["touch"]) - delta)
		enemy["charge_cd"] = maxf(0.0, float(enemy["charge_cd"]) - delta)
		enemy["hurt"] = maxf(0.0, float(enemy["hurt"]) - delta)
		if boss:
			enemy["orb_cd"] = maxf(0.0, float(enemy["orb_cd"]) - delta)
			# Close to melee range instead of camping far away firing projectiles.
			if toward.length() > 26.0:
				enemy["pos"] = (enemy["pos"] as Vector2) + toward.normalized() * float(enemy["speed"]) * movement_multiplier * delta
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
				enemy["pos"] = (enemy["pos"] as Vector2) + toward.normalized() * float(enemy["speed"]) * movement_multiplier * delta
			enemy["walk"] = float(enemy["walk"]) + delta * 6.0
		else:
			var kind := str(enemy.get("kind", "grunt"))
			if kind in ["spitter", "venom", "frost", "ember"]:
				# Ranged enemy tries to keep distance, then spits purple projectiles.
				if toward.length() > 290.0:
					enemy["pos"] = (enemy["pos"] as Vector2) + toward.normalized() * float(enemy["speed"]) * movement_multiplier * delta
				elif toward.length() < 190.0 and toward.length_squared() > 0.1:
					enemy["pos"] = (enemy["pos"] as Vector2) - toward.normalized() * float(enemy["speed"]) * movement_multiplier * 0.65 * delta
				enemy["orb_cd"] = maxf(0.0, float(enemy["orb_cd"]) - delta)
				if float(enemy["orb_cd"]) <= 0.0 and toward.length() < 510.0 and not is_in_safe_camp(target_pos):
					enemy["orb_cd"] = 3.1 if kind == "frost" else 2.6
					var projectile_tint := Color("a6ff8c") if kind == "venom" else (Color("93e5ff") if kind == "frost" else (Color("ff9d66") if kind == "ember" else Color("bd86ff")))
					hostile_orbs.append({"pos": enemy["pos"], "vel": toward.normalized() * 330.0, "life": 1.9, "damage": 8.0 if kind != "ember" else 11.0, "tint": projectile_tint, "status": kind})
			elif kind == "zigzag" and toward.length_squared() > 0.1:
				var sideways: Vector2 = toward.normalized().orthogonal() * sin(float(enemy["walk"]) * 2.3) * 0.95
				enemy["pos"] = (enemy["pos"] as Vector2) + (toward.normalized() + sideways).normalized() * float(enemy["speed"]) * movement_multiplier * delta
			elif toward.length_squared() > 0.1:
				enemy["pos"] = (enemy["pos"] as Vector2) + toward.normalized() * float(enemy["speed"]) * movement_multiplier * delta
			enemy["walk"] = float(enemy["walk"]) + delta * (12.0 if enemy["fast"] else 8.0)
		# Enemies cannot enter the green camp ring, even during combat.
		enemy["pos"] = keep_enemy_out_of_camp((enemy["pos"] as Vector2).clamp(ARENA.position + Vector2(22, 40), ARENA.end - Vector2(22, 25)))
		var hit_radius := 46.0 if boss else (42.0 if elite else 33.0)
		var damage_scale := 1.0 + minf(0.80, float(maxi(0, wave - 1)) * 0.065)
		var normal_touch := 9.0
		match str(enemy.get("kind", "grunt")):
			"runner": normal_touch = 8.0
			"tank": normal_touch = 16.0
			"spitter": normal_touch = 7.0
			"zigzag": normal_touch = 10.0
			"venom": normal_touch = 8.0
			"frost": normal_touch = 8.0
			"ember": normal_touch = 11.0
		var raw_damage := (24.0 if boss else (18.0 if elite else normal_touch)) * damage_scale
		if not is_in_safe_camp(target_pos) and (target_ally or not is_player_airborne()) and target_pos.distance_to(enemy["pos"]) < hit_radius and float(enemy["touch"]) <= 0.0:
			if target_ally:
				companion_take_damage(raw_damage * 0.85)
			else:
				var guard_reduction := 0.55 if skill_guard_clock > 0.0 else 1.0
				var dealt := maxf(1.0, raw_damage * (1.0 - calculate_damage_reduction()) * guard_reduction)
				hp -= dealt
				wave_damage_taken += dealt
				if str(enemy.get("kind", "")) in ["venom", "frost", "ember"]:
					apply_player_status(str(enemy["kind"]))
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
					var accurate: bool = rng.randf() <= float(bullet.get("accuracy", 1.0))
					if accurate:
						deal_enemy_damage(enemy, float(bullet["dmg"]), bullet["pos"], float(bullet.get("crit_chance", 0.05)), int(bullet.get("trait", -1)))
					hit_ids.append(enemy["id"])
					bullet["pierce"] = int(bullet["pierce"]) - 1
					burst(bullet["pos"], bullet["tint"] if accurate else Color("a6a6a6"), 5)
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
		combo_count += 1
		combo_clock = 3.5
		if combo_count >= 3 and combo_count % 3 == 0:
			var combo_bonus := 2 + combo_count / 3
			coins += int(combo_bonus)
			show_status("%d連続撃破！ COMBO BONUS +%dG！" % [combo_count, combo_bonus], Color("ffe888"))
			burst(death_spot, Color("ffe58a"), 26)
			play_sound(AUDIO_CRITICAL, -13.0, 1.12)
		var boss: bool = bool(enemy["boss"])
		var xp_award := 9 if boss else (3 if elite else 1)
		xp += xp_award
		award_mint_xp(xp_award)
		if boss:
			spawn_coins(death_spot, rng.randi_range(24, 35))
			spawn_crop_seed(death_spot + Vector2(34, 0), 2 if rng.randf() < 0.5 else 1)
			screen_shake = 0.38
			burst(death_spot, Color("ffdc8a"), 65)
			play_sound(AUDIO_WAVE_CLEAR, -13.0)
		elif elite:
			spawn_coins(death_spot, rng.randi_range(6, 11))
		elif rng.randf() < 0.57:
			spawn_coins(death_spot, rng.randi_range(1, 3))
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
			if rng.randf() < 0.042:
				spawn_crop_seed(death_spot, 1)
			if rng.randf() < 0.012:
				spawn_crop_seed(death_spot + Vector2(28, 0), 2)
			var equipment_roll := rng.randf()
			if equipment_roll < 0.045:
				spawn_drop(death_spot, roll_loot_rarity())
			elif equipment_roll < 0.08:
				spawn_armor_drop(death_spot, roll_loot_rarity())

func build_drop_name(kind: int, rarity: int) -> String:
	match rarity:
		4: return MYTHIC_NAMES[kind]
		1: return RARE_NAMES[kind]
		2: return EPIC_NAMES[kind]
		3: return LEGEND_NAMES[kind]
	return WEAPONS[kind]

func roll_loot_rarity() -> int:
	var roll_value := rng.randf()
	if roll_value >= 0.95:
		return 3
	if roll_value >= 0.77:
		return 2
	return 1

func roll_brute_rarity() -> int:
	var roll_value := rng.randf()
	if roll_value < 0.08:
		return 3
	if roll_value < 0.40:
		return 2
	return 1

func spawn_drop(pos: Vector2, rarity: int, forced_kind: int = -1, forced_trait: int = -1) -> void:
	var kind := forced_kind if forced_kind >= 0 else rng.randi_range(0, WEAPONS.size() - 1)
	var element_id: int = forced_trait if forced_trait >= 0 else rng.randi_range(0, WEAPON_TRAITS.size() - 1)
	var bonus: float = 1.0 + float(element_id) * 0.04 + float(rarity) * 0.035
	var item_name: String = "%s・%s" % [WEAPON_TRAITS[element_id], build_drop_name(kind, rarity)]
	drops.append({"type": "weapon", "pos": pos, "rarity": rarity, "kind": kind, "trait": element_id, "bonus": bonus, "name": item_name, "life": 65.0 if rarity >= 3 else 32.0, "phase": rng.randf() * TAU})
	celebrate_loot(pos, rarity, item_name)

func spawn_armor_drop(pos: Vector2, rarity: int, forced_slot: int = -1) -> void:
	var slot := forced_slot if forced_slot >= 0 else rng.randi_range(0, ARMOR_SLOTS.size() - 1)
	var defense := maxi(1, roundi(float(ARMOR_BASE_DEF[slot]) * ARMOR_RARITY_MULT[rarity]))
	var style_id := rng.randi_range(0, 3)
	var style_names := ["守護", "銀月", "翡翠", "暁"]
	defense += style_id
	var item_name: String = "%s・%s %s" % [style_names[style_id], ARMOR_PREFIX[rarity], ARMOR_SLOTS[slot]]
	drops.append({"type": "armor", "pos": pos, "rarity": rarity, "slot": slot, "trait": style_id, "name": item_name, "defense": defense, "life": 55.0 if rarity >= 4 else (30.0 if rarity == 3 else 22.0), "phase": rng.randf() * TAU})
	celebrate_loot(pos, rarity, item_name)

func celebrate_loot(pos: Vector2, rarity: int, name: String) -> void:
	var c: Color = RARITY_COLORS[rarity]
	burst(pos, c, 40 if rarity == 4 else (24 if rarity == 3 else 9))
	if rarity >= 3:
		# Dedicated musical cue, banner and dramatic visual flash.
		play_sound(AUDIO_LEGEND, -6.0)
		banner.text = ("★★ 神話級 MYTHIC！ %s ★★" if rarity == 4 else "★ 伝説の装備！ %s ★") % name
		banner.add_theme_color_override("font_color", c)
		banner_clock = 4.2
		legendary_glow_clock = 3.3 if rarity == 4 else 2.4
		screen_shake = 0.26
	elif rarity == 2:
		play_sound(AUDIO_EPIC, -10.0)
		banner.text = "エピック装備！ %s" % name
		banner.add_theme_color_override("font_color", c)
		banner_clock = 2.4
	else:
		play_sound(AUDIO_RARE, -14.0)
		banner.text = "レア装備！ %s" % name
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
		item["trait"] = int(drop.get("trait", -1))
		item["bonus"] = float(drop.get("bonus", 1.0))
	else:
		item["slot"] = int(drop["slot"])
		item["defense"] = int(drop["defense"])
		item["trait"] = int(drop.get("trait", -1))
	return item

func item_description(item: Dictionary) -> String:
	if item.is_empty():
		return "-- 空き --"
	var rarity := str(RARITIES[int(item["rarity"])])
	if str(item["type"]) == "armor":
		return "%s  [防御+%d]  (%s)" % [item["name"], int(item["defense"]), rarity]
	return "%s  [武器/倍率x%.2f]  (%s)" % [item["name"], float(item.get("bonus", 1.0)), rarity]

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
		show_status("バッグがいっぱい！ [I]で整理してください", Color("ff9d9d"))
		play_sound(AUDIO_IMPACT, -23.0)
		return
	var item: Dictionary = to_inventory_item(drops[closest])
	backpack[empty_slot] = item
	var color: Color = RARITY_COLORS[int(item["rarity"])]
	burst(player, color, 16)
	play_sound(AUDIO_PICKUP, -10.0)
	drops.remove_at(closest)
	show_status("入手 [%d/5]: %s  |  装備は[I]" % [empty_slot + 1, item["name"]], color)
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
		merchant_open = false
		merchant_panel.hide()
		if slot_open:
			slot_open = false
			slot_panel.hide()
	inventory_message = ""
	inventory_panel.visible = inventory_open
	if inventory_open:
		refresh_inventory_ui()
		pickup_hint.text = ""

func use_backpack_slot(index: int) -> void:
	if not inventory_open:
		return
	equip_backpack_item(index)

func equip_backpack_item(index: int) -> void:
	if state != "playing" or index < 0 or index >= backpack.size():
		return
	var item: Dictionary = backpack[index]
	if item.is_empty():
		inventory_message = "この枠は空です"
		refresh_inventory_ui()
		return
	if str(item["type"]) == "weapon":
		var previous_weapon: Dictionary = equipped.duplicate(true)
		equipped = item.duplicate(true)
		backpack[index] = previous_weapon
		inventory_message = "武器を装備：%s" % item["name"]
	else:
		var slot := int(item["slot"])
		var previous_armor: Dictionary = armor_equipped[slot].duplicate(true)
		armor_equipped[slot] = item.duplicate(true)
		backpack[index] = previous_armor
		inventory_message = "防具を装備：%s（防御+%d）" % [item["name"], int(item["defense"])]
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
		inventory_buttons[i].icon = null if item.is_empty() else item_icon(item)
		inventory_buttons[i].expand_icon = true
		inventory_buttons[i].disabled = item.is_empty()
		discard_buttons[i].disabled = item.is_empty()
		var c: Color = Color("628aa7") if item.is_empty() else RARITY_COLORS[int(item["rarity"])]
		inventory_buttons[i].add_theme_color_override("font_color", c)
	for i in range(ARMOR_SLOTS.size()):
		var item: Dictionary = armor_equipped[i]
		armor_buttons[i].text = "%s: %s" % [ARMOR_SLOTS[i], "-- 空き --" if item.is_empty() else item_description(item)]
		armor_buttons[i].icon = null if item.is_empty() else item_icon(item)
		armor_buttons[i].expand_icon = true
		armor_buttons[i].disabled = item.is_empty()
		var c: Color = Color("628aa7") if item.is_empty() else RARITY_COLORS[int(item["rarity"])]
		armor_buttons[i].add_theme_color_override("font_color", c)
	defense_label.text = "防御力 %d  |  ダメージ軽減 %d%%" % [total_defense(), roundi(calculate_damage_reduction() * 100.0)]
	inventory_status.text = inventory_message
	refresh_hotbar()

func update_drops(delta: float) -> void:
	for i in range(drops.size() - 1, -1, -1):
		drops[i]["life"] = float(drops[i]["life"]) - delta
		drops[i]["phase"] = float(drops[i]["phase"]) + delta * 2.5
		if float(drops[i]["life"]) <= 0.0:
			drops.remove_at(i)
	pickup_hint.text = ""
	var nearest := 92.0
	if nearest_plot_index() >= 0:
		pickup_hint.text = "[E] 畑 / [F] 作物切替  %sの種%d" % [CROP_NAMES[crop_selection], crop_seed_count(crop_selection)]
	if nearest_camp_index() >= 0:
		pickup_hint.text = "[E] 料理  |  ニンジン%d キノコ%d  |  [H] シチュー%d [J] スープ%d" % [carrots, mushrooms, stew_meals, broth_meals]
	for d in drops:
		var dist: float = player.distance_to(d["pos"])
		if dist < nearest:
			nearest = dist
			# Free-space notification is shown when all five slots are occupied.
			if free_backpack_slot() < 0:
				pickup_hint.text = "バッグ満杯（5/5） | [I]で整理"
			else:
				pickup_hint.text = "[E] 拾う  %s  |  [I] バッグ" % d["name"]
			pickup_hint.add_theme_color_override("font_color", RARITY_COLORS[int(d["rarity"])])
	if player.distance_to(SLOT_POS) < 105.0:
		pickup_hint.text = "[E] スロット 25G  |  所持金 %dG" % coins
	if player.distance_to(MERCHANT_POS) < 108.0:
		pickup_hint.text = "[E] 武器商人ルーンの店  |  装備・レア作物の種を購入"
	for seed_drop in crop_drops:
		if player.distance_to(seed_drop["pos"]) < 95.0:
			pickup_hint.text = "[E] %sのレアな種を拾う" % CROP_NAMES[int(seed_drop["crop"])]
	for coin in coin_drops:
		if player.distance_to(coin["pos"]) < 90.0:
			pickup_hint.text = "[E] コイン +%dG" % int(coin["amount"])
	if mint_soul_on_ground and player.distance_to(mint_soul_pos) < 100.0:
		pickup_hint.text = "[E] ミントの命を拾う → 南東の月の祭壇へ"
	if mint_soul_carried and player.distance_to(REVIVE_SHRINE) < 90.0:
		pickup_hint.text = "[E] 月の祭壇でミントを蘇生"

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

func attack_stat_multiplier(kind: int) -> float:
	var physical := kind == 0 or kind == 1 or kind == 2 or kind == 3 or kind == 4
	var ranged := kind == 0 or kind == 1 or kind == 4
	var magic := kind == 5 or kind == 6
	var mult := 1.0 + float(hero_stats[4]) * 0.015
	if physical:
		mult += float(hero_stats[0]) * 0.08
	if ranged:
		mult += float(hero_stats[4]) * 0.07
	if magic:
		mult += float(hero_stats[5]) * 0.09
	return mult

func hit_chance(kind: int) -> float:
	var base := 0.92 if kind == 2 or kind == 3 else 0.86
	return minf(0.99, base + float(hero_stats[4]) * 0.03)

func activate_class_skill() -> void:
	if level < 5:
		show_status("職業スキルはレベル5で習得！", Color("ffc7a2"))
		return
	if phase != "combat" or is_in_safe_camp(player):
		show_status("スキルは戦闘中・キャンプの外で使えます", Color("ffc7a2"))
		return
	var cost := 18.0 if class_id == 3 or class_id == 5 else 14.0
	if mp < cost:
		show_status("MP不足！ 必要MP %d" % roundi(cost), Color("ffc7a2"))
		return
	mp -= cost
	var enhanced := level >= 10
	match class_id:
		0: # Warrior: defensive stance
			skill_guard_clock = 12.0 if enhanced else 8.0
			burst(player, Color("9edfff"), 24)
		1: # Archer: multi-arrow volley
			for i in range(7 if enhanced else 5):
				var spread := float(i - (3 if enhanced else 2)) * 0.14
				launch_projectile(aim_angle + spread, 900.0, (7.5 if enhanced else 5.5) * attack_stat_multiplier(1), 5.0, 2, Color("8fffc6"), "arrow")
		2: # Crossbowman: rapid fan burst
			for i in range(12 if enhanced else 8):
				var spread := float(i - (5.5 if enhanced else 3.5)) * 0.095
				launch_projectile(aim_angle + spread, 940.0, (4.3 if enhanced else 3.4) * attack_stat_multiplier(4), 4.0, 1, Color("ffd69b"), "arrow")
		3: # Mage: intelligence-scaled AOE
			for enemy in enemies:
				if (enemy["pos"] as Vector2).distance_to(player) < (280.0 if enhanced else 210.0):
					enemy["hp"] = float(enemy["hp"]) - (22.0 if enhanced else 14.0) * attack_stat_multiplier(5)
					enemy["hurt"] = 0.3
			burst(player, Color("d8a1ff"), 75)
		4: # Berserker: rage
			skill_buff_clock = 15.0 if enhanced else 10.0
			burst(player, Color("ff809b"), 35)
		5: # Healer: heal player and Mint
			var amount := (70.0 if enhanced else 42.0) * (1.0 + float(hero_stats[5]) * 0.06)
			hp = minf(max_hp, hp + amount)
			companion_hp = minf(companion_max_hp, companion_hp + amount)
			burst(player, Color("a4ffe0"), 38)
			burst(companion, Color("a4ffe0"), 25)
	show_status("スキル発動！ %s%s" % [SKILL_NAMES[class_id], "・強化版" if enhanced else ""], Color("b6edff"))
	play_sound(AUDIO_EPIC, -19.0)

func start_upgrade() -> void:
	if pending_hero_points <= 0 and pending_mint_points <= 0:
		return
	state = "upgrade"
	upgrade_target = "hero" if pending_hero_points > 0 else "mint"
	var owner_name := "主人公" if upgrade_target == "hero" else "ミント"
	var owner_level := level if upgrade_target == "hero" else companion_level
	var stats: Array[int] = hero_stats if upgrade_target == "hero" else companion_stats
	upgrade_heading.text = "%s LV%d！ 上げる能力を選択" % [owner_name, owner_level]
	stat_summary.text = "力%d  速%d  体%d  MP%d  器%d  知%d  |  [1〜6]で選択" % [stats[0], stats[1], stats[2], stats[3], stats[4], stats[5]]
	for i in range(6):
		upgrade_buttons[i].text = "[%d] %s +1  (現在 %d)\n%s" % [i + 1, STAT_NAMES[i], stats[i], STAT_DESCRIPTIONS[i]]
	upgrade_panel.show()
	play_sound(AUDIO_RARE, -15.0)

func select_upgrade(index: int) -> void:
	if state != "upgrade" or index < 0 or index >= 6:
		return
	if upgrade_target == "hero":
		hero_stats[index] += 1
		pending_hero_points -= 1
		match index:
			2:
				max_hp += 15.0
				hp = minf(max_hp, hp + 25.0)
			3:
				max_mp += 10.0
				mp = minf(max_mp, mp + 12.0)
	else:
		companion_stats[index] += 1
		pending_mint_points -= 1
		match index:
			2:
				companion_max_hp += 15.0
				companion_hp = minf(companion_max_hp, companion_hp + 25.0)
			3:
				companion_heal_clock = maxf(0.0, companion_heal_clock - 2.0)
	upgrade_panel.hide()
	state = "playing"
	show_status("%sの%sが1上がった！" % ["主人公" if upgrade_target == "hero" else "ミント", STAT_NAMES[index]], Color("baffd3"))
	play_sound(AUDIO_PICKUP, -13.0)
	if pending_hero_points > 0 or pending_mint_points > 0:
		start_upgrade()

func count_empty_bag_slots() -> int:
	var count := 0
	for item in backpack:
		if item.is_empty():
			count += 1
	return count

func compass(v: Vector2) -> String:
	var horizontal := "東" if v.x > 80.0 else ("西" if v.x < -80.0 else "")
	var vertical := "南" if v.y > 80.0 else ("北" if v.y < -80.0 else "")
	return vertical + horizontal if vertical + horizontal != "" else "近く"

func apply_status_damage(amount: float, color: Color) -> void:
	if state != "playing" or is_in_safe_camp(player):
		return
	hp -= amount
	if phase == "combat": wave_damage_taken += amount
	burst(player, color, 5)
	add_damage_number(player, amount, false, color)
	if hp <= 0.0:
		player_died()


func update_hud() -> void:
	var current_rarity: int = int(equipped["rarity"])
	hud.text = "%s / %s  LV%d  討伐%d  防御%d  バッグ%d/5  |  %s" % [character_name, CLASS_NAMES[class_id], level, kills, total_defense(), BAG_CAPACITY - count_empty_bag_slots(), str(equipped["name"])]
	hud.add_theme_color_override("font_color", RARITY_COLORS[current_rarity] if state == "playing" else Color("eaf6ff"))
	equipped_icon.texture = item_icon(equipped)
	equipped_icon.tooltip_text = "装備中: %s (%s)" % [str(equipped["name"]), RARITIES[current_rarity]]
	equipped_icon.visible = state == "playing" or state == "upgrade"
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = maxf(0.0, hp)
	player_hp_text.text = "主人公 HP %d / %d" % [maxi(0, roundi(hp)), roundi(max_hp)]
	mp_text.text = "MP %d / %d   XP %d / %d" % [roundi(mp), roundi(max_mp), xp, xp_needed]
	var new_state := 0 if hp < max_hp * 0.3 else (1 if hp < max_hp * 0.6 else 2)
	if hp_bar_color_state != new_state:
		hp_bar_color_state = new_state
		var hp_color := Color("f06477") if new_state == 0 else (Color("f5cc65") if new_state == 1 else Color("58e7a0"))
		player_hp_bar.add_theme_stylebox_override("fill", make_style(hp_color, hp_color, 5))
	companion_hp_bar.max_value = companion_max_hp
	companion_hp_bar.value = maxf(0.0, companion_hp)
	companion_hp_text.text = "ミント LV%d  %s" % [companion_level, ("復活祭壇へ" if mint_soul_carried else "ハートを回収" if companion_hp <= 0.0 else "%d / %d" % [roundi(companion_hp), roundi(companion_max_hp)])]
	companion_xp_text.text = "ミントXP %d/%d  |  %s" % [companion_xp, companion_xp_needed, companion_mode]
	phase_label.text = ("準備 あと%d秒" % ceili(phase_clock)) if phase == "prep" else ("休憩 あと%d秒  |  Wave %d" % [ceili(phase_clock), wave] if phase == "rest" else "Wave %d  討伐 %d/%d  残敵%d" % [wave, maxi(0, wave_spawned - enemies.size()), wave_target, enemies.size()])
	phase_label.add_theme_color_override("font_color", Color("a1ffc4") if phase != "combat" else Color("ffc39b"))
	var to_shrine := REVIVE_SHRINE - player
	var to_shop := MERCHANT_POS - player
	direction_label.text = "商人 %dm %s  |  月の祭壇 %dm %s" % [roundi(to_shop.length() / 10.0), compass(to_shop), roundi(to_shrine.length() / 10.0), compass(to_shrine)]
	var effects := ""
	if poison_clock > 0.0: effects += " [毒%d秒]" % ceili(poison_clock)
	if burn_clock > 0.0: effects += " [火傷%d秒]" % ceili(burn_clock)
	if freeze_clock > 0.0: effects += " [凍結%d秒]" % ceili(freeze_clock)
	mp_text.text += effects
	skill_text.text = "[Q] %s %s" % [SKILL_NAMES[class_id], ("強化" if level >= 10 else "習得済") if level >= 5 else "LV5で習得"]
	help.text = "WASD:移動  SPACE:回避%s  E:調べる/商人  F:作物選択  1-5:装備  I:バッグ  Q:スキル" % ("(%.1f秒)" % jump_cooldown if jump_cooldown > 0.0 else "")
	hotbar_container.visible = state == "playing" or state == "upgrade"
	hotbar_currency.visible = state == "playing" or state == "upgrade"

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
	var font: Font = ui_font
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
	draw_string(ui_font, pos + Vector2(-42, -70), "NIGHT REAPER", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe1e5"))

func draw_companion() -> void:
	if companion_hp <= 0.0:
		return
	var pos := companion
	var frame := int(companion_walk_clock) % 4
	draw_circle(pos + Vector2(0, 15), 17, Color(0, 0, 0, 0.28))
	draw_character(MINT_SPRITE, pos, frame, player.x > pos.x, 1.62, Color.WHITE)
	draw_rect(Rect2(pos + Vector2(-22, -44), Vector2(44, 5)), Color("172c39"))
	draw_rect(Rect2(pos + Vector2(-22, -44), Vector2(44.0 * companion_hp / companion_max_hp, 5)), Color("7df2d8"))
	draw_string(ui_font, pos + Vector2(-28, -51), "ミント LV%d" % companion_level, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("bdfff0"))
	# A tiny XP meter under Mint's HP bar makes leveling visible in-world.
	draw_rect(Rect2(pos + Vector2(-22, -36), Vector2(44, 3)), Color("173541"))
	draw_rect(Rect2(pos + Vector2(-22, -36), Vector2(44.0 * float(companion_xp) / float(companion_xp_needed), 3)), Color("72baff"))

func draw_loot(d: Dictionary) -> void:
	# Different icons for every weapon and armor part; rarity remains a colored rim.
	var pos: Vector2 = d["pos"]
	var rarity: int = int(d["rarity"])
	var c: Color = RARITY_COLORS[rarity]
	var phase_value: float = float(d["phase"])
	var center: Vector2 = pos + Vector2(0, -sin(phase_value) * 4.0)
	var icon: Texture2D = item_icon(d)
	draw_circle(pos + Vector2(0, 16), 20, Color(0, 0, 0, 0.32))
	draw_circle(center, 25.0 + sin(phase_value * 2.0) * 2.0, Color(c, 0.22))
	draw_rect(Rect2(center - Vector2(22, 22), Vector2(44, 44)), Color("142234"))
	draw_rect(Rect2(center - Vector2(22, 22), Vector2(44, 44)), c, false, 3.0)
	# Preserve the original pixel-art proportions, especially the tall legendary sword.
	var icon_size: Vector2 = icon.get_size()
	var icon_scale: float = minf(42.0 / icon_size.x, 46.0 / icon_size.y)
	var icon_rect_size: Vector2 = icon_size * icon_scale
	draw_texture_rect(icon, Rect2(center - icon_rect_size * 0.5, icon_rect_size), false)
	var trait_id: int = int(d.get("trait", -1))
	if trait_id >= 0:
		var rune_color: Color = TRAIT_COLORS[trait_id % TRAIT_COLORS.size()]
		draw_circle(center + Vector2(17, -17), 9.0, Color("101a2a"))
		draw_circle(center + Vector2(17, -17), 6.5, rune_color)
		draw_line(center + Vector2(-16, 13), center + Vector2(-4, 13), rune_color, 3.0)
	var short_name: String = WEAPON_SHORT[int(d["kind"])] if str(d["type"]) == "weapon" else ARMOR_SHORT[int(d["slot"])]
	draw_string(ui_font, center + Vector2(-17, 37), short_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c)
	if rarity >= 3:
		draw_line(center + Vector2(0, -132), center + Vector2(0, -30), Color(c, 0.32), 14.0)
		draw_line(center + Vector2(0, -132), center + Vector2(0, -30), Color(c, 0.84), 3.0)
		for i in range(8):
			var a: float = phase_value + float(i) * TAU / 8.0
			var radial: Vector2 = Vector2.RIGHT.rotated(a)
			draw_line(center + radial * 27.0, center + radial * 36.0, c, 2.5)

func draw_equipped_sword(sword_origin: Vector2, rarity: int, attacking: bool) -> void:
	# Sword art faces upward. Rotate it toward the mouse while keeping the grip at the hand.
	# No colored placeholder line: the creator's exact PNG is rendered on the wolf.
	var sword_art: Texture2D = SWORD_RARITY_ART[clampi(rarity, 0, 3)]
	var attack_progress: float = clampf(1.0 - attack_clock / maxf(attack_duration, 0.01), 0.0, 1.0)
	var swing: float = (attack_progress - 0.5) * 1.2 if attacking else 0.0
	var sword_rotation: float = aim_angle + PI * 0.5 + swing
	var hand_pos: Vector2 = sword_origin + Vector2.RIGHT.rotated(aim_angle) * 22.0
	var sword_size: Vector2 = sword_art.get_size()
	var sword_scale: float = 2.35 if rarity >= 3 else 2.65
	if rarity == 4:
		draw_circle(hand_pos + Vector2.RIGHT.rotated(aim_angle) * 28.0, 27.0, Color("ff91d9", 0.18))
	draw_set_transform(hand_pos, sword_rotation, Vector2(sword_scale, sword_scale))
	draw_texture_rect(sword_art, Rect2(Vector2(-sword_size.x * 0.5, -sword_size.y + 5.0), sword_size), false)
	draw_set_transform(Vector2.ZERO)

func draw_coin_drop(coin: Dictionary) -> void:
	var pos: Vector2 = coin["pos"]
	var bounce: float = sin(float(coin["phase"])) * 3.0
	var center: Vector2 = pos + Vector2(0, -bounce)
	draw_circle(pos + Vector2(2, 12), 15, Color(0, 0, 0, 0.28))
	draw_circle(center, 15, Color("725122"))
	draw_circle(center, 12, Color("ffd36d"))
	draw_arc(center, 9.0, 0.0, TAU, 24, Color("fff0aa"), 2.0)
	draw_string(ui_font, center + Vector2(-6, 6), "G", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("75501b"))

func draw_mint_heart(center: Vector2, scale_factor: float = 1.0) -> void:
	var c: Color = Color("ff80b6")
	var left: Vector2 = center + Vector2(-8, -4) * scale_factor
	var right: Vector2 = center + Vector2(8, -4) * scale_factor
	draw_circle(center, 25.0 * scale_factor, Color(Color("ff80b6"), 0.14))
	draw_circle(left, 9.0 * scale_factor, c)
	draw_circle(right, 9.0 * scale_factor, c)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-17, -2) * scale_factor, center + Vector2(17, -2) * scale_factor, center + Vector2(0, 21) * scale_factor]), c)
	draw_circle(center + Vector2(-8, -8) * scale_factor, 3.0 * scale_factor, Color("ffe8f1"))

func draw_revive_shrine() -> void:
	var c: Vector2 = REVIVE_SHRINE
	draw_circle(c + Vector2(0, 11), 37, Color("14283d"))
	draw_arc(c, 35, 0.0, TAU, 32, Color("ffb4d6"), 4.0)
	draw_rect(Rect2(c + Vector2(-19, -9), Vector2(38, 25)), Color("8495aa"))
	draw_rect(Rect2(c + Vector2(-15, -6), Vector2(30, 18)), Color("d7e5e9"))
	draw_mint_heart(c + Vector2(0, -24), 0.55)
	draw_string(ui_font, c + Vector2(-82, 57), "月の祭壇 / ミント蘇生 [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffc2dd"))
	for i in range(8):
		var angle := TAU * float(i) / 8.0 + elapsed * 0.1
		var glow_pos := c + Vector2.RIGHT.rotated(angle) * 61.0
		draw_circle(glow_pos, 5.0, Color("d8a6ff", 0.6))
		draw_arc(c, 67.0, 0.0, TAU, 48, Color("c4a0ff", 0.30), 3.0)

func draw_slot_machine() -> void:
	var c: Vector2 = SLOT_POS
	draw_circle(c + Vector2(0, 24), 42, Color(0, 0, 0, 0.35))
	draw_rect(Rect2(c + Vector2(-36, -45), Vector2(72, 77)), Color("17283c"))
	draw_rect(Rect2(c + Vector2(-36, -45), Vector2(72, 77)), Color("ffd276"), false, 4.0)
	draw_rect(Rect2(c + Vector2(-30, -36), Vector2(60, 17)), Color("ed82ae"))
	draw_string(ui_font, c + Vector2(-27, -23), "SLOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff6d9"))
	for i in range(3):
		draw_rect(Rect2(c + Vector2(-27 + i * 19, -13), Vector2(16, 25)), Color("fff1d3"))
		draw_string(ui_font, c + Vector2(-25 + i * 19, 5), "7", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d95a86"))
	draw_line(c + Vector2(39, -18), c + Vector2(48, -30), Color("b7d6e4"), 5.0)
	draw_circle(c + Vector2(48, -34), 7, Color("ff778b"))
	draw_string(ui_font, c + Vector2(-65, 61), "スロット [E] 25G", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffe2a0"))

func draw_crop_seed(seed_drop: Dictionary) -> void:
	var p: Vector2 = seed_drop["pos"]
	var crop_id: int = int(seed_drop["crop"])
	var y := sin(float(seed_drop["phase"])) * 4.0
	var c: Color = CROP_COLORS[crop_id]
	draw_circle(p, 24.0, Color(c, 0.18))
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -17 + y), p + Vector2(13, -2 + y), p + Vector2(0, 13 + y), p + Vector2(-13, -2 + y)]), c)
	draw_circle(p + Vector2(-4, -5 + y), 3.0, Color("ffffff"))
	draw_string(ui_font, p + Vector2(-28, 34), "%sの種" % CROP_NAMES[crop_id], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, c)

func draw_merchant() -> void:
	var p: Vector2 = MERCHANT_POS
	# Fantasy merchant stall and an original small hooded trader silhouette.
	draw_circle(p + Vector2(0, 24), 58.0, Color(0, 0, 0, 0.28))
	draw_rect(Rect2(p + Vector2(-58, -30), Vector2(116, 71)), Color("4c3a49"))
	draw_rect(Rect2(p + Vector2(-58, -30), Vector2(116, 71)), Color("c3d7a2"), false, 4.0)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-72, -29), p + Vector2(0, -92), p + Vector2(72, -29)]), Color("426f72"))
	draw_line(p + Vector2(-72, -29), p + Vector2(0, -92), Color("d5f4c8"), 4.0)
	draw_line(p + Vector2(0, -92), p + Vector2(72, -29), Color("d5f4c8"), 4.0)
	draw_circle(p + Vector2(0, -5), 21.0, Color("b7a8df"))
	draw_circle(p + Vector2(0, -17), 15.0, Color("f6d5ad"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-24, -16), p + Vector2(0, -50), p + Vector2(24, -16)]), Color("5d468b"))
	draw_circle(p + Vector2(-5, -18), 2.0, Color("273246"))
	draw_circle(p + Vector2(5, -18), 2.0, Color("273246"))
	for i in range(3):
		draw_circle(p + Vector2(-35 + 35 * i, 26), 9.0, RARITY_COLORS[mini(4, i + 1)])
	draw_string(ui_font, p + Vector2(-85, -110), "旅の商人 ルーン [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d8ffb9"))
	draw_arc(p, 105.0, 0.0, TAU, 45, Color("c6f7ba", 0.18), 2.0)


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
			var crop_id: int = int(plot.get("crop", 0))
			var grow_time: float = float(CROP_GROW[crop_id])
			var height := 7.0 + 16.0 * minf(1.0, progress / grow_time)
			draw_line(center + Vector2(0, 12), center + Vector2(0, 12 - height), Color("70de73"), 4.0)
			draw_circle(center + Vector2(-8, 5 - height * 0.52), 6.0, Color("5dcb75"))
			draw_circle(center + Vector2(8, 5 - height * 0.52), 6.0, Color("a0e681"))
			if progress >= grow_time:
				var fruit_radius := 7.0 if crop_id == 0 else (12.0 if crop_id == 1 else 15.0)
				draw_circle(center + Vector2(0, 3), fruit_radius, CROP_COLORS[crop_id])
				if crop_id == 2:
					for stripe in [-6, 0, 6]:
						draw_line(center + Vector2(stripe, -8), center + Vector2(stripe, 14), Color("2d8d59"), 2.0)
				draw_arc(center, 34, 0.0, TAU, 24, Color("ffdd8e"), 2.0)
	for station in CAMP_STATIONS:
		var f: Vector2 = station
		draw_circle(f + Vector2(0, 11), 28.0, Color("101821"))
		for k in range(9):
			var a := TAU * float(k) / 9.0
			draw_circle(f + Vector2.RIGHT.rotated(a) * 21.0, 7.0, Color("87949a"))
		draw_colored_polygon(PackedVector2Array([f + Vector2(-13, 8), f + Vector2(-5, -24), f + Vector2(4, -10), f + Vector2(10, -29), f + Vector2(17, 11)]), Color("ff963e"))
		draw_circle(f + Vector2(0, 3), 9.0, Color("ffeb9e"))
		draw_string(ui_font, f + Vector2(-43, 49), "料理 [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffdda4"))
	draw_string(ui_font, Vector2(1323, 700), "畑 [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b8f1ba"))
	draw_string(ui_font, Vector2(2129, 1044), "畑 [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b8f1ba"))
	draw_string(ui_font, Vector2(1710, 1110), "森の畑 [E/F]", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b8f1ba"))
	draw_revive_shrine()
	draw_slot_machine()
	draw_merchant()

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
	draw_rect(ARENA, Color("172c35"))
	# A distant violet-blue arcane grove and teal moonlit clearing.
	for i in range(7):
		draw_circle(Vector2(2780, 700), 430.0 - float(i) * 55.0, Color("7d6cb8", 0.020))
		draw_circle(Vector2(530, 1980), 370.0 - float(i) * 46.0, Color("62c4bb", 0.020))
	for x in range(int(ARENA.position.x) + 14, int(ARENA.end.x), 64):
		draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), Color("284448", 0.47), 1.0)
	for y in range(int(ARENA.position.y) + 12, int(ARENA.end.y), 64):
		draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), Color("284448", 0.47), 1.0)
	for prop in scenery:
		var p: Vector2 = prop["pos"]
		if p.distance_to(player) > 850.0:
			continue
		var rad: float = 18.0 * float(prop["size"])
		if int(prop["kind"]) == 0:
			draw_circle(p + Vector2(7, 15), rad + 4.0, Color(0, 0, 0, 0.23))
			draw_circle(p, rad + 5.0, Color("244c43"))
			draw_circle(p + Vector2(-6, -6), rad * 0.7, Color("3b7a5d"))
		elif int(prop["kind"]) == 1:
			draw_circle(p, rad * 0.7, Color("566471"))
			draw_circle(p + Vector2(-5, -5), rad * 0.37, Color("849ba0"))
		elif int(prop["kind"]) == 2:
			draw_circle(p, rad * 0.4, Color("519780"))
			draw_circle(p + Vector2(8, 3), rad * 0.26, Color("7ebb92"))
		elif int(prop["kind"]) == 3:
			# Moonlit fairy mushrooms with soft glowing halos.
			draw_circle(p, rad * 1.45, Color("74c9ff", 0.06 + 0.03 * sin(elapsed * 2.0 + float(prop["glow"]))))
			draw_line(p + Vector2(0, 12), p + Vector2(0, -2), Color("d3d6d9"), 5.0)
			draw_circle(p + Vector2(0, -5), rad * 0.63, Color("8bc4ff"))
			draw_circle(p + Vector2(-5, -9), 3.0, Color("e3f7ff"))
		elif int(prop["kind"]) == 4:
			# Rune stones with pulsing turquoise sigils.
			draw_colored_polygon(PackedVector2Array([p + Vector2(-18, 16), p + Vector2(-12, -20), p + Vector2(4, -30), p + Vector2(18, -15), p + Vector2(16, 16)]), Color("607d8b"))
			draw_arc(p + Vector2(0, -4), 12.0, 0.0, TAU, 20, Color("8cf2e7", 0.60 + 0.25 * sin(elapsed * 2.0)), 2.0)
			draw_line(p + Vector2(-9, -3), p + Vector2(9, -3), Color("b9ffea"), 2.0)
		elif int(prop["kind"]) == 5:
			# Shallow magical pools.
			draw_circle(p, rad * 1.7, Color("204c62", 0.70))
			draw_circle(p, rad * 1.4, Color("398b9d", 0.65))
			draw_arc(p, rad, elapsed * 0.4, elapsed * 0.4 + PI * 1.3, 20, Color("a6eaff", 0.55), 2.0)
		else:
			# Luminous fireflies around wildflowers.
			draw_line(p, p + Vector2(0, -12), Color("6ebf9e"), 2.0)
			for j in range(3):
				var a := elapsed * (0.6 + j * 0.13) + float(j) * TAU / 3.0 + float(prop["glow"])
				var light := p + Vector2(cos(a) * 15.0, -13 + sin(a) * 10.0)
				draw_circle(light, 8.0, Color("fff2a6", 0.11))
				draw_circle(light, 2.5, Color("f9efb0", 0.88))
	for station in CAMP_STATIONS:
		draw_circle(station, CAMP_RADIUS, Color("a3eac4", 0.11 if phase == "combat" else 0.19))
		draw_arc(station, CAMP_RADIUS, 0.0, TAU, 80, Color("86ffb5", 0.85), 4.0)
		draw_string(ui_font, station + Vector2(-77, -CAMP_RADIUS - 14), "安全キャンプ / 攻撃不可", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b6ffd1"))
	draw_rect(ARENA, Color("5d8798"), false, 5.0)
	draw_farm_and_kitchen()
	for d in drops:
		draw_loot(d)
	for coin in coin_drops:
		draw_coin_drop(coin)
	for seed_drop in crop_drops:
		draw_crop_seed(seed_drop)
	if mint_soul_on_ground:
		draw_mint_heart(mint_soul_pos + Vector2(0, -8 + sin(elapsed * 4.0) * 5.0))
		draw_string(ui_font, mint_soul_pos + Vector2(-46, -44), "ミントの命 [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffc0d8"))
	if mint_soul_carried:
		draw_mint_heart(player + Vector2(0, -85), 0.55)
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
		var kind := str(enemy.get("kind", "grunt"))
		var tint := Color.WHITE
		match kind:
			"runner": tint = Color("ff9898")
			"tank": tint = Color("a2b7d5")
			"spitter": tint = Color("c4a0ff")
			"zigzag": tint = Color("81e6ec")
			"venom": tint = Color("b6ff89")
			"frost": tint = Color("a4e4ff")
			"ember": tint = Color("ffa075")
		if float(enemy["hurt"]) > 0.0:
			tint = Color("ffe0ad")
		var frame := int(float(enemy["walk"])) % 4
		var size_factor := 2.15 if kind == "tank" else (1.48 if kind == "runner" else 1.62)
		draw_character(PIERO_WALK, pos, frame, facing_right, size_factor, tint)
		match kind:
			"runner":
				draw_line(pos + Vector2(-26, -7), pos + Vector2(-44, -7), Color("ff8282"), 3.0)
				draw_line(pos + Vector2(-26, 3), pos + Vector2(-38, 3), Color("ff8282"), 2.0)
			"tank":
				draw_rect(Rect2(pos + Vector2(-29, -9), Vector2(20, 32)), Color("496e94"))
				draw_rect(Rect2(pos + Vector2(-29, -9), Vector2(20, 32)), Color("e5f4ff"), false, 3.0)
			"spitter":
				draw_circle(pos + Vector2(0, -36), 12, Color("8f55d6"))
				draw_circle(pos + Vector2(0, -36), 5, Color("f2d5ff"))
			"zigzag":
				draw_arc(pos, 33, 0.0, TAU, 20, Color("65ffff", 0.65), 2.0)
			"venom":
				draw_circle(pos + Vector2(0, -34), 13.0, Color("70c447", 0.85))
				draw_string(ui_font, pos + Vector2(-12, -29), "毒", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("eeffdd"))
			"frost":
				draw_arc(pos, 35, 0.0, TAU, 22, Color("b4f4ff"), 4.0)
				draw_string(ui_font, pos + Vector2(-11, -32), "氷", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e7faff"))
			"ember":
				draw_circle(pos + Vector2(0, -38), 12.0 + sin(elapsed * 10.0) * 2.0, Color("ff9c55", 0.8))
				draw_string(ui_font, pos + Vector2(-11, -34), "炎", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("fff0c6"))
		var bar_width := 50.0 if kind == "tank" else 40.0
		draw_rect(Rect2(pos + Vector2(-bar_width * 0.5, -43), Vector2(bar_width, 5)), Color("3e344a"))
		draw_rect(Rect2(pos + Vector2(-bar_width * 0.5, -43), Vector2(bar_width * maxf(0.0, float(enemy["hp"]) / float(enemy["max_hp"])), 5)), Color("8af4a2"))
	for orb in hostile_orbs:
		var p: Vector2 = orb["pos"]
		var orb_color: Color = orb.get("tint", Color("ff6c95"))
		draw_circle(p, 13, Color(orb_color, 0.25))
		draw_circle(p, 7, orb_color)
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
			var trail: Vector2 = (bullet["vel"] as Vector2).normalized()
			draw_line(pos - trail * 29.0, pos, Color(c, 0.36), 5.0)
			draw_circle(pos, float(bullet["radius"]) + 5.0, Color(c, 0.20))
			draw_circle(pos, float(bullet["radius"]), c)
	for dmg_popup in damage_numbers:
		var popup_pos: Vector2 = dmg_popup["pos"]
		var is_critical: bool = bool(dmg_popup["critical"])
		var popup_color: Color = dmg_popup["tint"]
		var popup_size := 32 if is_critical else 18
		draw_string(ui_font, popup_pos + Vector2(-22, 0), ("CRIT! " if is_critical else "") + str(roundi(float(dmg_popup["amount"]))), HORIZONTAL_ALIGNMENT_LEFT, -1, popup_size, popup_color)
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
	var jump_height := 0.0
	if jump_clock > 0.0:
		jump_height = sin((1.0 - jump_clock / 0.62) * PI) * 40.0
	draw_circle(player + Vector2(3, 15), 21.0 + jump_height * 0.16, Color(0, 0, 0, 0.30 - jump_height * 0.003))
	if is_player_airborne():
		draw_arc(player, 35.0, 0.0, TAU, 24, Color("a8eaff", 0.6), 2.0)
	draw_player_with_armor(sprite, player_center + Vector2(0, walk_bob - jump_height), character_frame, cos(aim_angle) > 0.0, 1.82, Color("ff8585") if hurt_clock > 0.0 else WOLF_PALETTES[palette_id], lean)
	if freeze_lock_clock > 0.0:
		draw_colored_polygon(PackedVector2Array([player + Vector2(-32, 21), player + Vector2(-39, -40), player + Vector2(-6, -72), player + Vector2(37, -43), player + Vector2(33, 23)]), Color("8be8ff", 0.20))
		draw_arc(player + Vector2(0, -16), 42.0, 0.0, TAU, 28, Color("b7f2ff", 0.82), 3.0)
	draw_accessory(player_center + Vector2(0, walk_bob - jump_height))
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
			2:
				draw_equipped_sword(player_center + Vector2(0, walk_bob - jump_height), rarity, fighting)
			3:
				draw_line(player + Vector2(0, 0), player + Vector2.RIGHT.rotated(aim_angle) * 65.0, color, 9.0)
		if fighting and wtype >= 2:
			var radius := 110.0 if wtype == 2 else 155.0
			var sweep := 0.95 if wtype == 2 else 1.21
			var opacity := clampf(attack_clock / attack_duration, 0.0, 1.0)
			draw_arc(player, radius, aim_angle - sweep, aim_angle + sweep, 35, Color(color, opacity), 11.0 if wtype == 3 else 7.0)
			draw_arc(player, radius - 12.0, aim_angle - sweep, aim_angle + sweep, 35, Color("ffffff", opacity * 0.6), 2.0)
			draw_arc(player, radius * 0.86, aim_angle - sweep + 0.18, aim_angle + sweep + 0.18, 35, Color(color, opacity * 0.38), 14.0)
			var tip_a := aim_angle + sweep
			var tip := player + Vector2.RIGHT.rotated(tip_a) * radius
			draw_line(tip, tip + Vector2.RIGHT.rotated(tip_a + 0.9) * 24.0, Color("ffffff", opacity), 3.0)
	if brute_flash_clock > 0.0:
		draw_rect(ARENA, Color("ad6bff", minf(0.14, brute_flash_clock * 0.5)))
	if hit_flash_clock > 0.0:
		draw_rect(Rect2(player - Vector2(550, 320), Vector2(1100, 640)), Color("fff1bd", hit_flash_clock * 0.10))
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
