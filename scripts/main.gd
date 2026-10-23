extends Node2D

# DOPAGAKI v0.17 — Moonlit Forest Visual Overhaul (Drive published base b36).
# Solo prototype; network/4-player functionality is NOT implemented.
# Compatible with Godot 4.3–4.7; one runnable Node2D scene.

const SIZE := Vector2(1152, 648)
const ARENA := Rect2(40, 105, 3600, 2380)
const CAMP_STATIONS := [Vector2(1170, 842), Vector2(2020, 1175)]
const CAMP_RADIUS := 365.0
const CAMP_ENEMY_MARGIN := 27.0
const STASH_POS := Vector2(1390, 1085)
const STASH_MAX := 16
const STASH_SAVE := "user://dopagaki_stash_v1.json"
const WANDERER_START := Vector2(1650, 850)
const MAX_ENEMIES := 78
const REST_PLAYER_HEAL_FRACTION := 0.24
const REST_SECONDS := 26.0
const PREP_SECONDS := 25.0
# Defend from the direction the mouse is pointing; the first 0.24s is a perfect parry.
const PARRY_WINDOW := 0.24
const GUARD_DAMAGE_MULT := 0.30
const GUARD_HALF_ANGLE := 1.24 # around a 142-degree front arc
const GUARD_RESTART_DELAY := 0.28
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
const WEAPONS := ["PISTOL", "BOW", "SWORD", "GREATSWORD", "REPEATING CROSSBOW", "ARCANE STAFF", "HEALING STAFF", "KUNAI"]
const CLASS_NAMES := ["戦士", "弓兵", "連弩士", "メイジ", "バーサーカー", "ヒーラー", "忍者"]
const CLASS_DESC := ["剣と防御のバランス型", "弓で遠距離攻撃", "連射する弩で攻撃", "知力で魔法を強化", "大剣の高火力と高HP", "回復と遠距離支援", "剣とクナイ・分身の術"]
const CLASS_WEAPONS := [2, 1, 4, 5, 3, 6, 7]
const WOLF_PALETTES := [Color("ffffff"), Color("ffe4c0"), Color("bce4ff"), Color("edc4ff"), Color("d3ffbe"), Color("ffc6da")]
const PALETTE_NAMES := ["オリジナル", "ゴールド", "アイス", "ライラック", "ミント", "ローズ"]
const ACCESSORY_NAMES := ["なし", "星", "王冠", "光"]
const FARM_PLOTS := [Vector2(1390, 723), Vector2(1460, 723), Vector2(1530, 723), Vector2(1390, 800), Vector2(1460, 800), Vector2(1530, 800), Vector2(2230, 1085), Vector2(2300, 1085), Vector2(2230, 1162), Vector2(2300, 1162), Vector2(1710, 1160), Vector2(1780, 1160), Vector2(1850, 1160)]
const GROW_SECONDS := 10.0
const RARITIES := ["COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC"]
const ARMOR_SLOTS := ["HEAD", "CHEST", "LEGGINGS", "ARMS"]
const ARMOR_BASE_DEF := [2, 5, 3, 2]
const ARMOR_PREFIX := ["WORN", "GUARDED", "ENCHANTED", "MYTHIC", "DIVINE"]
const ARMOR_RARITY_MULT := [1.0, 1.6, 2.3, 3.5, 5.0]
const BAG_CAPACITY := 5
const SLOT_COST := 25
const SLOT_POS := Vector2(865, 895)
const REVIVE_SHRINE := Vector2(3060, 1860)
const MERCHANT_POS := Vector2(1780, 985)
const WEAPON_TRAITS := ["烈火", "氷霜", "猛毒", "星光", "疾風"]
const TRAIT_COLORS := [Color("ff985a"), Color("9be6ff"), Color("9eff9b"), Color("ffe68b"), Color("c5a2ff")]
const CROP_NAMES := ["ニンジン", "メロン", "スイカ"]
const MEAL_NAMES := ["ニンジンシチュー", "ハンタースープ", "メロンジュース", "スイカパフェ"]
const RABBIT_NAME := "ちゅぶら"
const RABBIT_GEAR_NAMES := ["なし", "赤いリボン", "探検ハーネス", "月の首飾り"]
const RABBIT_GEAR_COSTS := [0, 12, 40, 80]
const CROP_GROW := [10.0, 22.0, 35.0]
const CROP_COLORS := [Color("ffa665"), Color("aaff8d"), Color("79d7b0")]
const WEAPON_SHORT := ["銃", "弓", "剣", "大剣", "連弩", "魔杖", "癒杖", "クナイ"]
const ARMOR_SHORT := ["頭", "胴", "脚", "腕"]
const WEAPON_ICONS := [
	preload("res://assets/item_icons/weapon_0.png"),
	preload("res://assets/item_icons/weapon_1.png"),
	preload("res://assets/item_icons/weapon_2.png"),
	preload("res://assets/item_icons/weapon_3.png"),
	preload("res://assets/item_icons/weapon_4.png"),
	preload("res://assets/item_icons/weapon_5.png"),
	preload("res://assets/item_icons/weapon_6.png"),
	preload("res://assets/item_icons/weapon_7.png")
]
# Original pixel art provided by the game creator. Sword kind=2 uses tier-specific art.
# MYTHIC currently shares the legendary sprite with a unique magenta aura.
const SWORD_RARITY_ART := [
	preload("res://assets/visual_v016/sword_common_polished.png"),
	preload("res://assets/visual_v016/sword_rare_polished.png"),
	preload("res://assets/visual_v016/sword_epic_polished.png"),
	preload("res://assets/visual_v016/sword_legendary_polished.png")
]

# Greatsword (kind=3) tier art. MYTHIC shares the legendary sprite, like the sword.
const GREATSWORD_RARITY_ART := [
	preload("res://assets/visual_v016/greatsword_common.png"),
	preload("res://assets/visual_v016/greatsword_rare.png"),
	preload("res://assets/visual_v016/greatsword_epic.png"),
	preload("res://assets/visual_v016/greatsword_legendary.png")
]

func greatsword_art_for_rarity(rarity: int) -> Texture2D:
	return GREATSWORD_RARITY_ART[clampi(rarity, 0, 3)]

func sword_art_for_rarity(rarity: int) -> Texture2D:
	# Explicit mapping so EPIC always resolves to the custom purple sword art.
	match clampi(rarity, 0, 4):
		0:
			return SWORD_RARITY_ART[0]
		1:
			return SWORD_RARITY_ART[1]
		2:
			return SWORD_RARITY_ART[2]
		3:
			return SWORD_RARITY_ART[3]
		4:
			# MYTHIC still reuses the legendary art with an aura.
			return SWORD_RARITY_ART[3]
		_:
			return SWORD_RARITY_ART[0]
const ARMOR_ICONS := [
	preload("res://assets/item_icons/armor_0.png"),
	preload("res://assets/item_icons/armor_1.png"),
	preload("res://assets/item_icons/armor_2.png"),
	preload("res://assets/item_icons/armor_3.png")
]
const UI_ICON_BAG: Texture2D = preload("res://assets/ui_icons/bag.png")
const UI_ICON_COOKPOT: Texture2D = preload("res://assets/ui_icons/cookpot.png")
const RESOURCE_ICONS := [
	preload("res://assets/ui_icons/carrot.png"),
	preload("res://assets/ui_icons/melon.png"),
	preload("res://assets/ui_icons/watermelon.png")
]
const CRAFT_RESOURCE_ICONS := [
	preload("res://assets/ui_icons/carrot.png"),
	preload("res://assets/ui_icons/mushroom.png"),
	preload("res://assets/ui_icons/melon.png"),
	preload("res://assets/ui_icons/watermelon.png")
]
const MEAL_ICONS := [
	preload("res://assets/ui_icons/stew.png"),
	preload("res://assets/ui_icons/soup.png"),
	preload("res://assets/ui_icons/juice.png"),
	preload("res://assets/ui_icons/parfait.png")
]
const FOREST_FLOOR: Texture2D = preload("res://assets/visual_v016/forest_floor.png")
const FOREST_VARIANTS := [
	preload("res://assets/visual_v017/forest_0.png"),
	preload("res://assets/visual_v017/forest_1.png"),
	preload("res://assets/visual_v017/forest_2.png"),
	preload("res://assets/visual_v017/forest_3.png")
]
const CAMP_GROUND_V017: Texture2D = preload("res://assets/visual_v017/camp_organic.png")
const FOREST_TREE_V017: Texture2D = preload("res://assets/visual_v017/forest_tree.png")
const TENT_V017: Texture2D = preload("res://assets/visual_v017/canvas_tent.png")
const BARRELS_V017: Texture2D = preload("res://assets/visual_v017/barrel_stack.png")
const RUNE_V017: Texture2D = preload("res://assets/visual_v017/rune_stone.png")
const BANNER_V017: Texture2D = preload("res://assets/visual_v017/banner_celtic.png")
const FENCE_V017: Texture2D = preload("res://assets/visual_v017/forest_fence.png")
const FERN_V017: Texture2D = preload("res://assets/visual_v017/fern.png")
const ROCK_V017: Texture2D = preload("res://assets/visual_v017/boulder.png")
const GLOW_AMBER_V017: Texture2D = preload("res://assets/visual_v017/glow_amber.png")
const GLOW_MOON_V017: Texture2D = preload("res://assets/visual_v017/glow_moon.png")
const GLOW_GREEN_V017: Texture2D = preload("res://assets/visual_v017/glow_emerald.png")
const MINI_BACKGROUND_V017: Texture2D = preload("res://assets/visual_v017/minimap_bg.png")
const HERO_BADGE_V017: Texture2D = preload("res://assets/visual_v017/hero_portrait.png")
const BUNNY_BADGE_V017: Texture2D = preload("res://assets/visual_v017/bunny_portrait.png")
const CAMP_FLOOR: Texture2D = preload("res://assets/visual_v016/camp_cobblestone.png")
const CAMP_LANTERN: Texture2D = preload("res://assets/visual_v016/camp_lantern.png")
const LOOT_FRAME: Texture2D = preload("res://assets/visual_v016/loot_frame.png")
const STASH_ART: Texture2D = preload("res://assets/visual_v016/stash_chest.png")
const SLOT_ART: Texture2D = preload("res://assets/visual_v016/slot_machine.png")
const COOK_ART: Texture2D = preload("res://assets/visual_v016/campfire_pot.png")
const MERCHANT_ART: Texture2D = preload("res://assets/visual_v016/merchant_stall.png")
const VISUALS_REVISION := "v0.17 翡翠の森・夜光キャンプ"
const RARITY_COLORS := [Color("d0e2f1"), Color("59cdff"), Color("d493ff"), Color("ffd568"), Color("ff91d9")]
const RARITY_DAMAGE := [1.0, 1.38, 1.88, 2.85, 4.4]
const RARITY_RATE := [1.0, 1.06, 1.13, 1.22, 1.33]
const RARE_NAMES := ["GILDED PISTOL", "HUNTER'S BOW", "MOON SWORD", "IRON CLEAVER", "SWIFT REPEATER", "RUNE WAND", "BLESSED STAFF", "SHADOW KUNAI"]
const EPIC_NAMES := ["STORM PISTOL", "PHANTOM BOW", "SOLAR SABER", "TITAN BLADE", "THUNDER REPEATER", "ASTRAL STAFF", "LIFEBLOOM", "MOON KUNAI"]
const LEGEND_NAMES := ["STARFALL", "CELESTIAL BOW", "FATEBREAKER", "WORLDENDER", "INFINITE SALVO", "VOIDCALLER", "SUNHEALER", "PHANTOM KUNAI"]
const MYTHIC_NAMES := ["神銃・天雷", "神弓・暁", "神剣・星砕", "神斧・終焉", "神連弩・無限", "神杖・深淵", "神杖・聖樹", "神クナイ・影月"]
const STAT_NAMES := ["力", "スピード", "体力", "MP", "器用", "知力"]
const STAT_DESCRIPTIONS := ["物理攻撃力 +8%", "移動 +4% / 攻撃速度 +2%", "最大HP +15 / HP回復", "最大MP +10 / MP自然回復", "命中率 +3% / 射撃 +7% / 会心率 +2.5%", "魔法攻撃力 +9%"]
const SKILL_NAMES := ["鉄壁の構え", "五連矢", "連弩乱射", "魔力爆発", "狂戦士の怒り", "癒やしの波動", "影分身の術"]
const SKILL_DESCRIPTIONS := ["被ダメージを8秒間軽減", "狙った方向に5本の矢", "狙った方向に8本の矢", "周囲の敵に魔法ダメージ", "10秒間、攻撃力と速度を上昇", "自分とミントを回復", "分身2体が自動攻撃（Lv10で3体）"]
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
const AUDIO_PARRY: AudioStream = preload("res://audio/parry.wav")
const AUDIO_BGM_REST: AudioStream = preload("res://audio/kk_celtic15_loop.ogg")
const AUDIO_BGM_BATTLE: AudioStream = preload("res://audio/kk_celtic5_loop.ogg")

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
var guard_active := false
var guard_parry_clock := 0.0
var guard_restart_clock := 0.0
var guard_press_used := false
var parry_flash_clock := 0.0
var successful_parries := 0
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
var upgrade_open := false
var stash_open := false
var stash_items: Array[Dictionary] = []
var stash_loaded := false
var wanderer := Vector2(1650, 850)
var wanderer_goal := Vector2(1650, 850)
var wanderer_hp := 185.0
var wanderer_hostile := false
var wanderer_attack_clock := 0.0
var wanderer_patrol_clock := 0.0
var wanderer_walk_clock := 0.0
var wanderer_hurt_clock := 0.0

# Black rabbit pet: light support only, cute and weak.
var rabbit_pet := Vector2(1168, 902)
var rabbit_pet_goal := Vector2(1168, 902)
var rabbit_pet_mode := "ついてくる"
var rabbit_pet_attack_clock := 0.0
var rabbit_pet_walk_clock := 0.0
var rabbit_patrol_clock := 0.0
var rabbit_pet_meal_clock := 0.0
var rabbit_pet_bob_clock := 0.0
var rabbit_pet_was_moving := false
var rabbit_pet_enabled := true
var rabbit_gear_level := 0
var rabbit_affection := 35.0
var rabbit_hunger := 48.0 # 0=空腹 / 100=満腹
var rabbit_carried := false
var rabbit_pet_glow := 0.0
var rabbit_menu_open := false
var rabbit_menu: PanelContainer
var rabbit_menu_info: Label
var rabbit_menu_buttons: Array[Button] = []
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
var corpses: Array[Dictionary] = []
var meal_displays: Array[Dictionary] = []
var shadow_clone_clock := 0.0
var shadow_clone_fire := 0.0
var particles: Array[Dictionary] = []
var upgrades: Array[int] = []
var banner_clock := 0.0
var legendary_glow_clock := 0.0
var screen_shake := 0.0
var screen_shake_strength := 0.0
var critical_flash_clock := 0.0
var impact_sparks: Array[Dictionary] = []
var impact_rings: Array[Dictionary] = []
const MAX_IMPACT_SPARKS := 260
var muted := false
var audio_players: Array[AudioStreamPlayer] = []
var audio_index := 0

var hud: Label
var help: Label
var controls_panel: PanelContainer
var controls_open := false
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
var upgrade_close_button: Button
var upgrade_hero_button: Button
var upgrade_mint_button: Button
var stash_panel: PanelContainer
var stash_title: Label
var stash_bag_buttons: Array[Button] = []
var stash_storage_buttons: Array[Button] = []
var stash_equip_button: Button
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
var cooking_buttons: Array[Button] = []
var meal_display_buttons: Array[Button] = []
var defense_label: Label
var inventory_status: Label
var minimap_panel: Control
var minimap_marker: Panel

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
		var ogg_stream: AudioStreamOggVorbis = music_stream as AudioStreamOggVorbis
		if ogg_stream != null:
			ogg_stream.loop = true
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
	load_stash()
	reset_game()

func make_style(fill: Color, border: Color, radius: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.corner_detail = 7
	style.shadow_size = 3
	style.shadow_color = Color("050a12", 0.55)
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
	var panel_style: StyleBoxFlat = make_style(Color("111b27"), border.darkened(0.23), 10)
	panel_style.set_border_width_all(3)
	panel_style.shadow_size = 16
	panel_style.shadow_offset = Vector2(0, 6)
	panel_style.shadow_color = Color(0.01, 0.02, 0.04, 0.84)
	panel_style.content_margin_top = 1.0
	panel.add_theme_stylebox_override("panel", panel_style)
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
	b.add_theme_stylebox_override("normal", make_style(Color("1c2b39"), color.darkened(0.19), 8))
	b.add_theme_stylebox_override("hover", make_style(Color("314352"), color.lightened(0.14), 8))
	b.add_theme_stylebox_override("pressed", make_style(Color("3d4f60"), color, 8))
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
	var status_back := Panel.new()
	status_back.position = Vector2.ZERO
	status_back.size = Vector2(SIZE.x, 113.0)
	status_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var status_style := make_style(Color(0.055, 0.075, 0.107, 0.94), Color(0.69, 0.51, 0.27, 0.72), 0)
	status_style.border_width_top = 0
	status_style.border_width_left = 0
	status_style.border_width_right = 0
	layer.add_child(status_back)
	status_back.add_theme_stylebox_override("panel", status_style)
	var hero_medallion := TextureRect.new()
	hero_medallion.texture = HERO_BADGE_V017
	hero_medallion.position = Vector2(3, 9)
	hero_medallion.size = Vector2(42, 42)
	hero_medallion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_medallion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_medallion.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hero_medallion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hero_medallion)
	var bunny_medallion := TextureRect.new()
	bunny_medallion.texture = BUNNY_BADGE_V017
	bunny_medallion.position = Vector2(338, 40)
	bunny_medallion.size = Vector2(23, 23)
	bunny_medallion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bunny_medallion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bunny_medallion.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bunny_medallion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bunny_medallion)
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
	# The character's overhead bar is the only hero HP bar.
	player_hp_bar = make_health_bar(Vector2(48, 39), Vector2(297, 26), Color("58e7a0"))
	player_hp_bar.hide()
	layer.add_child(player_hp_bar)
	player_hp_text = make_label("", 17, Color.WHITE, true)
	player_hp_text.hide()
	layer.add_child(player_hp_text)
	companion_hp_bar = make_health_bar(Vector2(362, 39), Vector2(235, 26), Color("69ddea"))
	layer.add_child(companion_hp_bar)
	companion_hp_text = make_label("", 15, Color.BLACK, true)
	companion_hp_text.add_theme_color_override("font_outline_color", Color.WHITE)
	companion_hp_text.add_theme_constant_override("outline_size", 4)
	companion_hp_text.position = Vector2(362, 43)
	companion_hp_text.custom_minimum_size = Vector2(235, 23)
	layer.add_child(companion_hp_text)
	companion_xp_text = make_label("", 13, Color("93e5d5"))
	companion_xp_text.position = Vector2(364, 67)
	companion_xp_text.custom_minimum_size = Vector2(240, 17)
	layer.add_child(companion_xp_text)
	mp_text = make_label("", 15, Color("b6a4ff"))
	mp_text.position = Vector2(48, 42)
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

	# Compact live-position map. Markers use the real ARENA / player coordinates,
	# not a fake static screenshot.
	minimap_panel = Control.new()
	minimap_panel.position = Vector2(969, 128)
	minimap_panel.custom_minimum_size = Vector2(168, 140)
	minimap_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(minimap_panel)
	var mini_art := TextureRect.new()
	mini_art.texture = MINI_BACKGROUND_V017
	mini_art.size = Vector2(168, 140)
	mini_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mini_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_panel.add_child(mini_art)
	for camp_location in CAMP_STATIONS:
		var camp_dot := Label.new()
		camp_dot.text = "◆"
		camp_dot.position = Vector2(4, 0) + Vector2((camp_location.x - ARENA.position.x) / ARENA.size.x * 150.0, (camp_location.y - ARENA.position.y) / ARENA.size.y * 121.0)
		camp_dot.add_theme_font_size_override("font_size", 13)
		camp_dot.add_theme_color_override("font_color", Color("f3c67a"))
		camp_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		minimap_panel.add_child(camp_dot)
	minimap_marker = Panel.new()
	minimap_marker.size = Vector2(9, 9)
	minimap_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var marker_style := make_style(Color("d5edfc"), Color("62cfff"), 5)
	marker_style.set_border_width_all(2)
	minimap_marker.add_theme_stylebox_override("panel", marker_style)
	minimap_panel.add_child(minimap_marker)
	var map_caption := make_label("翡翠の森 · 現在地", 12, Color("d1e9d6"), true)
	map_caption.position = Vector2(-1, -21)
	map_caption.custom_minimum_size = Vector2(168, 19)
	minimap_panel.add_child(map_caption)
	minimap_panel.hide()
	# Character creation is intentionally a single menu, with six class archetypes.
	choose_panel = make_panel(Vector2(112, 32), Vector2(928, 552), Color("42cfd5"))
	layer.add_child(choose_panel)
	var choose_box := VBoxContainer.new()
	choose_box.add_theme_constant_override("separation", 7)
	choose_panel.get_child(0).add_child(choose_box)
	choose_box.add_child(make_label("DOPAGAKI  /  キャラクター作成", 29, Color("7de9f0"), true))
	choose_box.add_child(make_label("森の遺跡・ビジュアル強化  |  ガード・パリィ・黒うさぎ『ちゅぶら』", 14, Color("d0dcf3"), true))
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
		var btn := make_button("%d  %s\n%s" % [i + 1, CLASS_NAMES[i], CLASS_DESC[i]], Color("45cad3"), Vector2(269, 64))
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(select_class.bind(i))
		grid.add_child(btn)
		class_buttons.append(btn)
	choose_box.add_child(make_label("[1〜7] 職業を選択  /  先に名前・色・帽子を設定", 15, Color("adc6e1"), true))
	choose_box.add_child(make_label("敵を全滅でWAVEクリア！ [T]で黒うさぎ『ちゅぶら』をお世話できるよ", 16, Color("86eac5"), true))
	# A compact cooking menu with recipe buttons and resource counter.
	cooking_panel = make_panel(Vector2(311, 36), Vector2(530, 566), Color("f6b970"))
	layer.add_child(cooking_panel)
	var cook_box := VBoxContainer.new()
	cook_box.add_theme_constant_override("separation", 5)
	cooking_panel.get_child(0).add_child(cook_box)
	var cook_header := HBoxContainer.new()
	cook_header.add_theme_constant_override("separation", 10)
	var cook_symbol := TextureRect.new()
	cook_symbol.texture = preload("res://assets/ui_icons/cookpot.png")
	cook_symbol.custom_minimum_size = Vector2(32, 32)
	cook_symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cook_symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cook_symbol.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cook_header.add_child(cook_symbol)
	cook_header.add_child(make_label("キャンプの料理", 28, Color("ffd5a0"), true))
	cook_box.add_child(cook_header)
	cooking_info = make_label("", 18, Color("b6e8ce"), true)
	cook_box.add_child(cooking_info)
	var soup := make_button("[1] ニンジンシチュー（ニンジン2）  HP+40 [H]", Color("ffd39f"), Vector2(461, 50))
	soup.icon = preload("res://assets/ui_icons/stew.png")
	soup.expand_icon = true
	soup.pressed.connect(cook_recipe.bind(0))
	cook_box.add_child(soup)
	var broth := make_button("[2] ハンタースープ（ニンジン1・キノコ1）\nHP+25 / 30秒間移動速度アップ [J]", Color("ffd39f"), Vector2(461, 70))
	broth.add_theme_font_size_override("font_size", 15)
	broth.icon = preload("res://assets/ui_icons/soup.png")
	broth.expand_icon = true
	broth.pressed.connect(cook_recipe.bind(1))
	cook_box.add_child(broth)
	var melon_button := make_button("[3] メロンジュース（メロン1）  HP+30 / MP+25 [K]", Color("c1e88d"), Vector2(461, 43))
	melon_button.add_theme_font_size_override("font_size", 15)
	melon_button.icon = preload("res://assets/ui_icons/juice.png")
	melon_button.expand_icon = true
	melon_button.pressed.connect(cook_recipe.bind(2))
	cook_box.add_child(melon_button)
	var watermelon_button := make_button("[4] スイカパフェ（スイカ1）  HP+60 [L]", Color("a3e7c4"), Vector2(461, 43))
	watermelon_button.add_theme_font_size_override("font_size", 15)
	watermelon_button.icon = preload("res://assets/ui_icons/parfait.png")
	watermelon_button.expand_icon = true
	watermelon_button.pressed.connect(cook_recipe.bind(3))
	cook_box.add_child(watermelon_button)
	cook_box.add_child(make_label("完成した料理をキャンプの展示台に飾れるよ！", 15, Color("a8ffe1"), true))
	var decorate_box := GridContainer.new()
	decorate_box.columns = 2
	decorate_box.add_theme_constant_override("h_separation", 7)
	decorate_box.add_theme_constant_override("v_separation", 5)
	cook_box.add_child(decorate_box)
	for meal_id in range(4):
		var meal_titles := ["[5] シチューを飾る", "[6] スープを飾る", "[7] ジュースを飾る", "[8] パフェを飾る"]
		var decoration_btn := make_button(meal_titles[meal_id], Color("d6b781"), Vector2(220, 33))
		decoration_btn.icon = MEAL_ICONS[meal_id]
		decoration_btn.expand_icon = true
		decoration_btn.add_theme_font_size_override("font_size", 14)
		decoration_btn.pressed.connect(place_meal_display.bind(meal_id))
		decorate_box.add_child(decoration_btn)
		meal_display_buttons.append(decoration_btn)
	var exit_cook := make_button("閉じる [E / Esc]", Color("f6b970"), Vector2(461, 32))
	exit_cook.pressed.connect(toggle_cooking)
	cook_box.add_child(exit_cook)
	cooking_panel.hide()

	# ちゅぶら is a small independent pet; interact near it with [T].
	rabbit_menu = make_panel(Vector2(285, 117), Vector2(584, 398), Color("d6a9ed"))
	layer.add_child(rabbit_menu)
	var rabbit_box := VBoxContainer.new()
	rabbit_box.add_theme_constant_override("separation", 9)
	rabbit_menu.get_child(0).add_child(rabbit_box)
	rabbit_box.add_child(make_label("🐇 ちゅぶらのお世話", 29, Color("eac7ff"), true))
	rabbit_menu_info = make_label("", 16, Color("e8eaf6"), true)
	rabbit_box.add_child(rabbit_menu_info)
	var rabbit_titles := ["[1] なでる  ♥", "[2] 抱っこ / おろす", "[3] にんじんをあげる", "[4] ペット装備を購入・装着"]
	for rabbit_action in range(4):
		var rabbit_button := make_button(rabbit_titles[rabbit_action], Color("b6a1ed"), Vector2(502, 46))
		rabbit_button.pressed.connect(rabbit_action_selected.bind(rabbit_action))
		rabbit_menu_buttons.append(rabbit_button)
		rabbit_box.add_child(rabbit_button)
	var rabbit_close := make_button("閉じる [T / Esc]", Color("d6a9ed"), Vector2(502, 34))
	rabbit_close.pressed.connect(toggle_rabbit_menu)
	rabbit_box.add_child(rabbit_close)
	rabbit_menu.hide()

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
	upgrade_box.add_child(make_label("[1〜6] 能力に振り分け  |  ポイントは使うまで消えません", 15, Color("a6ffdf"), true))
	var upgrade_switches := HBoxContainer.new()
	upgrade_hero_button = make_button("主人公の能力", Color("80b9fc"), Vector2(190, 38))
	upgrade_hero_button.pressed.connect(set_upgrade_target.bind("hero"))
	upgrade_switches.add_child(upgrade_hero_button)
	upgrade_mint_button = make_button("ミントの能力", Color("84e0c1"), Vector2(190, 38))
	upgrade_mint_button.pressed.connect(set_upgrade_target.bind("mint"))
	upgrade_switches.add_child(upgrade_mint_button)
	upgrade_close_button = make_button("閉じる [P / Esc]", Color("a7b4ef"), Vector2(250, 38))
	upgrade_close_button.pressed.connect(toggle_upgrade_menu)
	upgrade_switches.add_child(upgrade_close_button)
	upgrade_box.add_child(upgrade_switches)
	upgrade_panel.hide()

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
	var bag_head := HBoxContainer.new()
	bag_head.add_theme_constant_override("separation", 8)
	var bag_icon := TextureRect.new()
	bag_icon.texture = UI_ICON_BAG
	bag_icon.custom_minimum_size = Vector2(30, 30)
	bag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bag_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bag_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bag_head.add_child(bag_icon)
	bag_head.add_child(make_label("バッグ  /  5枠", 24, Color("87edff"), true))
	inv_box.add_child(bag_head)
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

	# Controls reference: its own screen, opened with [C], instead of a long line on the HUD.
	controls_panel = make_panel(Vector2(256, 70), Vector2(640, 500), Color("8fd3a6"))
	layer.add_child(controls_panel)
	var ctl_padding: MarginContainer = controls_panel.get_child(0)
	ctl_padding.add_theme_constant_override("margin_top", 14)
	ctl_padding.add_theme_constant_override("margin_bottom", 14)
	var ctl_box := VBoxContainer.new()
	ctl_box.add_theme_constant_override("separation", 5)
	ctl_padding.add_child(ctl_box)
	ctl_box.add_child(make_label("操作方法", 26, Color("b8ffd0"), true))
	var ctl_grid := GridContainer.new()
	ctl_grid.columns = 2
	ctl_grid.add_theme_constant_override("h_separation", 22)
	ctl_grid.add_theme_constant_override("v_separation", 4)
	ctl_box.add_child(ctl_grid)
	for row in CONTROLS_HELP:
		var key_label := make_label(row[0], 16, Color("ffe69c"))
		key_label.custom_minimum_size = Vector2(150, 0)
		ctl_grid.add_child(key_label)
		ctl_grid.add_child(make_label(row[1], 16, Color("dbe9f7")))
	var ctl_close := make_button("閉じる [C / Esc]", Color("8fd3a6"), Vector2(0, 34))
	ctl_close.add_theme_font_size_override("font_size", 14)
	ctl_close.pressed.connect(toggle_controls)
	ctl_box.add_child(ctl_close)
	controls_panel.hide()
	# Persistent gear chest. Stored equipment survives deaths and F5 relaunches.
	stash_panel = make_panel(Vector2(218, 35), Vector2(710, 565), Color("cba977"))
	layer.add_child(stash_panel)
	var chest_pad: MarginContainer = stash_panel.get_child(0)
	var chest_box := VBoxContainer.new()
	chest_box.add_theme_constant_override("separation", 5)
	chest_pad.add_child(chest_box)
	stash_title = make_label("倉庫", 22, Color("ffe2af"), true)
	chest_box.add_child(stash_title)
	chest_box.add_child(make_label("クリックで預ける / 取り出す。死亡後も、再起動後も保存されます。", 14, Color("aaf1d7")))
	var bag_label := make_label("持ち物から預ける（5枠）", 17, Color("dbecff"))
	chest_box.add_child(bag_label)
	var pocket_grid := GridContainer.new()
	pocket_grid.columns = 5
	chest_box.add_child(pocket_grid)
	for i in range(BAG_CAPACITY):
		var bag_btn := make_button("", Color("86b9d4"), Vector2(123, 55))
		bag_btn.add_theme_font_size_override("font_size", 11)
		bag_btn.pressed.connect(stash_deposit_backpack.bind(i))
		pocket_grid.add_child(bag_btn)
		stash_bag_buttons.append(bag_btn)
	stash_equip_button = make_button("装備中の武器も倉庫に預ける（代わりに初期銃を装備）", Color("dcb577"), Vector2(622, 32))
	stash_equip_button.add_theme_font_size_override("font_size", 14)
	stash_equip_button.pressed.connect(stash_deposit_equipped)
	chest_box.add_child(stash_equip_button)
	chest_box.add_child(make_label("倉庫内（クリックでバッグへ）", 17, Color("ffddab")))
	var chest_scroll := ScrollContainer.new()
	chest_scroll.custom_minimum_size = Vector2(640, 245)
	chest_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chest_box.add_child(chest_scroll)
	var stored_grid := GridContainer.new()
	stored_grid.columns = 2
	stored_grid.add_theme_constant_override("h_separation", 7)
	stored_grid.add_theme_constant_override("v_separation", 4)
	chest_scroll.add_child(stored_grid)
	for i in range(STASH_MAX):
		var stored_btn := make_button("", Color("d0a66f"), Vector2(307, 40))
		stored_btn.add_theme_font_size_override("font_size", 12)
		stored_btn.pressed.connect(stash_withdraw.bind(i))
		stored_grid.add_child(stored_btn)
		stash_storage_buttons.append(stored_btn)
	var chest_controls := HBoxContainer.new()
	var exit_chest := make_button("閉じる [E / Esc]", Color("cdb184"), Vector2(250, 38))
	exit_chest.pressed.connect(toggle_stash)
	chest_controls.add_child(exit_chest)
	var leave_btn := make_button("生還して帰還 [V]（持ち物も倉庫へ）", Color("99dfb8"), Vector2(370, 38))
	leave_btn.add_theme_font_size_override("font_size", 14)
	leave_btn.pressed.connect(extract_alive)
	chest_controls.add_child(leave_btn)
	chest_box.add_child(chest_controls)
	stash_panel.hide()
	choose_panel.hide()
	cooking_panel.hide()
	rabbit_menu.hide()
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
	guard_active = false
	guard_parry_clock = 0.0
	guard_restart_clock = 0.0
	guard_press_used = false
	parry_flash_clock = 0.0
	successful_parries = 0
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
	rabbit_pet = player + Vector2(52, 48)
	rabbit_pet_goal = rabbit_pet
	rabbit_pet_mode = "ついてくる"
	rabbit_pet_attack_clock = 0.25
	rabbit_pet_walk_clock = 0.0
	rabbit_patrol_clock = 0.0
	rabbit_pet_meal_clock = 2.0
	rabbit_pet_bob_clock = 0.0
	rabbit_pet_was_moving = false
	rabbit_pet_enabled = true
	rabbit_gear_level = 0
	rabbit_affection = 35.0
	rabbit_hunger = 48.0
	rabbit_carried = false
	rabbit_pet_glow = 0.0
	rabbit_menu_open = false
	rabbit_menu.hide()
	hero_stats = [0, 0, 0, 0, 0, 0]
	pending_hero_points = 0
	pending_mint_points = 0
	upgrade_open = false
	stash_open = false
	stash_panel.hide()
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
	controls_open = false
	controls_panel.hide()
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
	wanderer = WANDERER_START
	wanderer_goal = WANDERER_START
	wanderer_hp = 185.0
	wanderer_hostile = false
	wanderer_attack_clock = 0.2
	wanderer_patrol_clock = 0.0
	wanderer_walk_clock = 0.0
	wanderer_hurt_clock = 0.0
	projectiles.clear()
	drops.clear()
	corpses.clear()
	meal_displays.clear()
	shadow_clone_clock = 0.0
	shadow_clone_fire = 0.0
	particles.clear()
	upgrades.clear()
	banner_clock = 0.0
	legendary_glow_clock = 0.0
	screen_shake = 0.0
	screen_shake_strength = 0.0
	critical_flash_clock = 0.0
	impact_sparks.clear()
	impact_rings.clear()
	camera.offset = Vector2.ZERO
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
		6: # Ninja: quick kunai throws and short range sword combos.
			move_speed = 309.0
			max_hp = 95.0
			hp = 95.0
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
	# Ground gear has first priority; slot rewards cannot get stuck under an interaction.
	for drop in drops:
		if player.distance_to(drop["pos"]) < 92.0:
			pickup_nearby()
			return
	for display_index in range(meal_displays.size()):
		if player.distance_to(meal_displays[display_index]["pos"]) < 62.0:
			collect_meal_display(display_index)
			return
	if player.distance_to(STASH_POS) < 105.0:
		toggle_stash()
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


func meal_amount(kind: int) -> int:
	match kind:
		0: return stew_meals
		1: return broth_meals
		2: return melon_meals
		3: return watermelon_meals
	return 0

func add_meal_amount(kind: int, increment: int) -> void:
	match kind:
		0: stew_meals += increment
		1: broth_meals += increment
		2: melon_meals += increment
		3: watermelon_meals += increment

func place_meal_display(kind: int) -> void:
	if not cooking_open or meal_amount(kind) <= 0:
		show_status("その料理の作り置きがありません", Color("ffc0a3"))
		return
	var camp_i := nearest_camp_index()
	if camp_i < 0:
		return
	var taken: Array[int] = []
	for meal in meal_displays:
		if int(meal["camp"]) == camp_i:
			taken.append(int(meal["spot"]))
	var open_spot := -1
	for test_spot in range(8):
		if not taken.has(test_spot):
			open_spot = test_spot
			break
	if open_spot < 0:
		show_status("展示台がいっぱい！（キャンプごとに8皿まで）", Color("ffc0a3"))
		return
	add_meal_amount(kind, -1)
	var camp: Vector2 = CAMP_STATIONS[camp_i]
	var position := camp + Vector2(-105.0 + float(open_spot % 4) * 70.0, 145.0 + float(open_spot / 4) * 72.0)
	meal_displays.append({"camp": camp_i, "spot": open_spot, "kind": kind, "pos": position})
	show_status("料理を展示！ 展示台の近くで[E]を押すと回収", Color("ffeaa8"))
	play_sound(AUDIO_PICKUP, -16.0)
	refresh_cooking_ui()

func collect_meal_display(index: int) -> void:
	if index < 0 or index >= meal_displays.size():
		return
	var dish_type: int = int(meal_displays[index]["kind"])
	add_meal_amount(dish_type, 1)
	meal_displays.remove_at(index)
	show_status("飾っていた料理を回収して作り置きに戻した！", Color("b8ffdc"))
	play_sound(AUDIO_PICKUP, -18.0)

func draw_meal_displays() -> void:
	var dish_colors := [Color("ce996a"), Color("dfc68f"), Color("9eea91"), Color("ed8eae")]
	for meal in meal_displays:
		var pos: Vector2 = meal["pos"]
		var kind: int = int(meal["kind"])
		var food_color: Color = dish_colors[kind]
		draw_circle(pos + Vector2(2, 13), 28.0, Color("091119", 0.28))
		draw_rect(Rect2(pos + Vector2(-27, -17), Vector2(54, 44)), Color("815d42"))
		draw_rect(Rect2(pos + Vector2(-27, -17), Vector2(54, 44)), Color("d9b986"), false, 3.0)
		draw_circle(pos, 18.0, Color("e6e1d7"))
		draw_circle(pos, 13.0, food_color)
		match kind:
			0:
				for n in range(3):
					draw_circle(pos + Vector2(-7 + n * 7, 1), 3, Color("f7ba68"))
			1:
				draw_arc(pos, 9.0, 0, TAU, 20, Color("f0ddbd"), 2.5)
			2:
				draw_rect(Rect2(pos + Vector2(-7, -10), Vector2(14, 22)), Color("c4f7a7"))
				draw_line(pos + Vector2(0, -10), pos + Vector2(5, -19), Color("f7f4d3"), 2)
			3:
				draw_circle(pos + Vector2(0, -3), 7.0, Color("fbf5ee"))
				draw_circle(pos + Vector2(3, -7), 4.0, Color("ed6389"))
		draw_string(ui_font, pos + Vector2(-34, 43), "料理展示 [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("ffe5bd"))

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
			btn.add_theme_stylebox_override("normal", make_style(Color("15232c"), Color("6b665a"), 7))
		else:
			var rarity: int = int(item["rarity"])
			btn.icon = item_icon(item)
			var short_name: String = WEAPON_SHORT[int(item["kind"])] if str(item["type"]) == "weapon" else ARMOR_SHORT[int(item["slot"])]
			btn.text = "%d %s" % [i + 1, short_name]
			btn.tooltip_text = item_description(item) + "\nクリック / 数字キーで装備"
			btn.add_theme_stylebox_override("normal", make_style(Color("152430"), RARITY_COLORS[rarity], 7))
	hotbar_currency.text = "所持金 %dG\n種:人参%d/メロン%d/スイカ%d" % [coins, seeds, melon_seeds, watermelon_seeds]

func item_icon(item: Dictionary) -> Texture2D:
	if str(item.get("type", "")) == "armor":
		return ARMOR_ICONS[clampi(int(item.get("slot", 0)), 0, ARMOR_ICONS.size() - 1)]
	if int(item.get("kind", 0)) == 2:
		return sword_art_for_rarity(int(item.get("rarity", 0)))
	if int(item.get("kind", 0)) == 3:
		return greatsword_art_for_rarity(int(item.get("rarity", 0)))
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
	var prize_pos: Vector2 = SLOT_POS + Vector2(130, 145)
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
	show_status("スロット結果：%s  （装備はマシン右下の景品台）" % slot_result.text, Color("ffe0a1"))

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

func can_raise_guard() -> bool:
	return state == "playing" and phase == "combat" and not inventory_open and not cooking_open and not slot_open and not merchant_open and not rabbit_menu_open and jump_clock <= 0.0 and freeze_lock_clock <= 0.0 and not is_in_safe_camp(player)

func update_guard_state(delta: float) -> void:
	guard_restart_clock = maxf(0.0, guard_restart_clock - delta)
	parry_flash_clock = maxf(0.0, parry_flash_clock - delta)
	var pressed: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if not pressed:
		if guard_active:
			guard_restart_clock = maxf(guard_restart_clock, GUARD_RESTART_DELAY)
		guard_active = false
		guard_parry_clock = 0.0
		guard_press_used = false
		return
	if not can_raise_guard():
		guard_active = false
		guard_parry_clock = 0.0
		return
	if not guard_press_used:
		guard_press_used = true
		if guard_restart_clock <= 0.0:
			guard_active = true
			guard_parry_clock = PARRY_WINDOW
			play_sound(AUDIO_SLASH, -23.0, 1.75)
	if guard_active:
		guard_parry_clock = maxf(0.0, guard_parry_clock - delta)

func incoming_from_front(origin_pos: Vector2) -> bool:
	var to_attack: Vector2 = origin_pos - player
	if to_attack.length_squared() <= 0.1:
		return true
	var facing: Vector2 = Vector2.RIGHT.rotated(aim_angle)
	return facing.dot(to_attack.normalized()) >= cos(GUARD_HALF_ANGLE)

# Returns true on perfect parry; callers use it to cancel missiles/contact as appropriate.
func receive_enemy_hit(raw_damage: float, origin_pos: Vector2, status_name: String = "", attacker: Dictionary = {}) -> bool:
	var guarded: bool = guard_active and incoming_from_front(origin_pos)
	if guarded and guard_parry_clock > 0.0:
		guard_parry_clock = 0.0 # one parry per right-click press
		parry_flash_clock = 0.46
		successful_parries += 1
		trigger_camera_shake(0.25, 12.0)
		var parry_pos: Vector2 = player + Vector2.RIGHT.rotated(aim_angle) * 47.0
		burst(parry_pos, Color("fff2aa"), 30)
		emit_impact_sparks(parry_pos, Color("ffe6a1"), 39, 320.0)
		emit_impact_ring(parry_pos, Color("fff0a6"), 68.0, 0.34, 6.0)
		play_sound(AUDIO_PARRY, -8.0, 1.0)
		show_status("JUST PARRY! 完全防御  ×%d" % successful_parries, Color("fff2a6"))
		if not attacker.is_empty() and float(attacker.get("hp", 0.0)) > 0.0:
			var impact_direction: Vector2 = (attacker["pos"] as Vector2) - player
			if impact_direction.length_squared() < 0.01:
				impact_direction = Vector2.RIGHT.rotated(aim_angle)
			attacker["pos"] = keep_enemy_out_of_camp((attacker["pos"] as Vector2) + impact_direction.normalized() * 78.0)
			attacker["stun"] = maxf(float(attacker.get("stun", 0.0)), 0.52 if bool(attacker.get("boss", false)) else 0.92)
			attacker["touch"] = maxf(float(attacker.get("touch", 0.0)), 1.0)
			deal_enemy_damage(attacker, 4.0 + float(level) * 0.45, attacker["pos"], 0.0, -1)
		return true
	var damage_factor: float = GUARD_DAMAGE_MULT if guarded else 1.0
	var skill_factor: float = 0.55 if skill_guard_clock > 0.0 else 1.0
	var dealt: float = maxf(1.0, raw_damage * (1.0 - calculate_damage_reduction()) * damage_factor * skill_factor)
	hp -= dealt
	wave_damage_taken += dealt
	if guarded:
		burst(player + Vector2.RIGHT.rotated(aim_angle) * 35.0, Color("94dcff"), 9)
		play_sound(AUDIO_IMPACT, -23.0, 1.55)
	else:
		if status_name in ["venom", "frost", "ember"]:
			apply_player_status(status_name)
		burst(player, Color("ff6393"), 13)
		play_sound(AUDIO_IMPACT, -13.0)
		hurt_clock = 0.24
	if hp <= 0.0:
		player_died()
	return false

func is_player_airborne() -> bool:
	return jump_clock > 0.18

func start_jump() -> void:
	if jump_cooldown > 0.0 or freeze_lock_clock > 0.0 or state != "playing" or guard_active:
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
		if event.keycode >= KEY_1 and event.keycode <= KEY_7:
			select_class(event.keycode - KEY_1)
		return
	if state == "dead":
		if event.keycode == KEY_R:
			reset_game()
		return
	if state == "playing":
		if controls_open:
			if event.keycode == KEY_C or event.keycode == KEY_ESCAPE:
				toggle_controls()
			return
		if event.keycode == KEY_C and not (rabbit_menu_open or merchant_open or slot_open or cooking_open or inventory_open):
			toggle_controls()
		if upgrade_open:
			if event.keycode == KEY_P or event.keycode == KEY_ESCAPE:
				toggle_upgrade_menu()
			elif event.keycode == KEY_TAB:
				set_upgrade_target("mint" if upgrade_target == "hero" else "hero")
			elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
				select_upgrade(event.keycode - KEY_1)
			return
		if stash_open:
			if event.keycode == KEY_E or event.keycode == KEY_ESCAPE:
				toggle_stash()
			elif event.keycode == KEY_V:
				extract_alive()
			return
		if event.keycode == KEY_P and not inventory_open and not cooking_open and not merchant_open and not slot_open and not rabbit_menu_open:
			toggle_upgrade_menu()
			return
		if rabbit_menu_open:
			if event.keycode == KEY_T or event.keycode == KEY_ESCAPE:
				toggle_rabbit_menu()
			elif event.keycode >= KEY_1 and event.keycode <= KEY_4:
				rabbit_action_selected(event.keycode - KEY_1)
			return
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
			elif event.keycode >= KEY_5 and event.keycode <= KEY_8:
				place_meal_display(event.keycode - KEY_5)
			return
		if event.keycode == KEY_I or (inventory_open and event.keycode == KEY_ESCAPE):
			toggle_inventory()
			return
		if inventory_open:
			return
		if event.keycode == KEY_T:
			toggle_rabbit_menu()
		elif event.keycode == KEY_E:
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
			if event.shift_pressed:
				var fx_pos: Vector2 = player + Vector2.RIGHT.rotated(aim_angle) * 105.0
				emit_impact_sparks(fx_pos, Color("ffd56a"), 44, 360.0)
				emit_impact_ring(fx_pos, Color("fff2ad"), 93.0, 0.38, 7.0)
				trigger_camera_shake(0.27, 16.0)
				critical_flash_clock = 0.11
				play_sound(AUDIO_CRITICAL, -10.0)
				show_status("テスト：クリティカル火花エフェクト！", Color("fff1b0"))
			else:
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
		var shake_fade: float = minf(1.0, screen_shake / 0.20)
		var jitter: float = screen_shake_strength * shake_fade
		camera.offset = Vector2(rng.randf_range(-jitter, jitter), rng.randf_range(-jitter, jitter))
	else:
		screen_shake_strength = 0.0
		camera.offset = camera.offset.lerp(Vector2.ZERO, minf(1.0, delta * 24.0))
	critical_flash_clock = maxf(0.0, critical_flash_clock - delta)
	update_impact_fx(delta)
	if brute_flash_clock > 0.0:
		brute_flash_clock = maxf(0.0, brute_flash_clock - delta)
	attack_clock = maxf(0.0, attack_clock - delta)
	jump_cooldown = maxf(0.0, jump_cooldown - delta)
	jump_clock = maxf(0.0, jump_clock - delta)
	update_guard_state(delta)
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
	if state != "playing" or inventory_open or cooking_open or slot_open or merchant_open or rabbit_menu_open or upgrade_open or stash_open:
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
	shadow_clone_clock = maxf(0.0, shadow_clone_clock - delta)
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
		player += movement.normalized() * move_speed * (0.64 if guard_active else 1.0) * (0.0 if freeze_lock_clock > 0.0 else (0.52 if freeze_clock > 0.0 else 1.0)) * (1.0 + float(hero_stats[1]) * 0.04) * (1.25 if food_buff_clock > 0.0 else 1.0) * (1.3 if skill_buff_clock > 0.0 else 1.0) * delta
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
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not guard_active and freeze_lock_clock <= 0.0 and fire_clock <= 0.0 and jump_clock <= 0.0 and phase == "combat" and not is_in_safe_camp(player):
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
	update_rabbit_pet(delta)
	update_wanderer(delta)
	update_shadow_clones(delta)
	update_projectiles(delta)
	if phase == "combat":
		update_enemies(delta)
		update_hostile_orbs(delta)
		cleanup_defeated_enemies()
	update_particles(delta)
	update_corpses(delta)
	update_drops(delta)
	update_coins(delta)
	update_crop_drops(delta)
	while state == "playing" and xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 4 + level * 3
		pending_hero_points += 1
		show_status("レベル%d！ 能力ポイント+1（Pであとから振り分け）" % level, Color("b4eeff"))
		if level == 5:
			show_status("レベル5！ Qで『%s』が使える！" % SKILL_NAMES[class_id], Color("a4edff"))
		elif level == 10:
			show_status("レベル10！ 職業スキルが強化された！", Color("a4edff"))
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
			# A projectile can be guarded or perfectly parried from the front.
			receive_enemy_hit(float(orb.get("damage", 14.0)), orb["pos"], str(orb.get("status", "")))
			gone = true
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
	controls_open = false
	controls_panel.hide()
	dead_label.text = "Wave %d  討伐 %d  レベル%d → 次回LV1\n持ち物・装備は失うが倉庫の%d個は保存済み" % [wave, kills, level, stash_items.size()]

func generate_scenery() -> void:
	scenery.clear()
	var decor_rng := RandomNumberGenerator.new()
	decor_rng.seed = 802411
	for i in range(125):
		var pos := Vector2(decor_rng.randf_range(105.0, ARENA.end.x - 85.0), decor_rng.randf_range(175.0, ARENA.end.y - 68.0))
		var close_to_camp := false
		for station in CAMP_STATIONS:
			if pos.distance_to(station) < CAMP_RADIUS + 80.0:
				close_to_camp = true
		if close_to_camp:
			continue
		scenery.append({"pos": pos, "kind": decor_rng.randi_range(0, 2), "size": decor_rng.randf_range(0.8, 1.4), "glow": decor_rng.randf_range(0.0, TAU)})

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
		emit_impact_sparks(impact_pos, Color("ffd56a"), 38, 355.0)
		emit_impact_ring(impact_pos, Color("fff2ad"), 82.0, 0.36, 6.5)
		trigger_camera_shake(0.27, 16.0)
		critical_flash_clock = maxf(critical_flash_clock, 0.11)
		hit_flash_clock = 0.13
		if crit_sound_clock <= 0.0:
			play_sound(AUDIO_CRITICAL, -12.0, rng.randf_range(0.96, 1.12))
			crit_sound_clock = 0.10
	else:
		burst(impact_pos, Color("b9e9ff"), 4)
		emit_impact_sparks(impact_pos, Color("bed9ff"), 5, 132.0)

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
			trigger_camera_shake(0.12, 5.0)
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
		7: # Ninja: sword within reach; otherwise throw kunai.
			var close_target := false
			for foe in enemies:
				if float(foe["hp"]) > 0.0 and player.distance_to(foe["pos"]) < 108.0:
					close_target = true
					break
			if close_target:
				fire_clock = 0.31 / speed
				attack_duration = 0.21
				melee_hit(112.0, 1.10, 5.4 * power, 26.0)
				burst(player + Vector2.RIGHT.rotated(aim_angle) * 65.0, Color("caa3ff"), 10)
				play_sound(AUDIO_SLASH, -15.0, 1.25)
			else:
				fire_clock = 0.42 / speed
				launch_projectile(aim_angle, 940.0, 4.6 * power, 5.0, 1, Color("c6afff"), "kunai")
				play_sound(AUDIO_BOW, -19.0, 1.40)

func launch_projectile(angle: float, speed: float, dmg: float, radius: float, pierce: int, tint: Color, kind: String) -> void:
	var velocity := Vector2.RIGHT.rotated(angle) * speed * projectile_speed_mult
	projectiles.append({"pos": player + Vector2.RIGHT.rotated(angle) * 37.0, "vel": velocity, "dmg": dmg, "accuracy": hit_chance(int(equipped["kind"])), "radius": radius, "pierce": pierce, "kind": kind, "tint": tint, "life": 1.35, "hit_ids": [], "crit_chance": crit_probability(hero_stats[4]), "trait": int(equipped.get("trait", -1)), "owner": "hero"})

func melee_hit(radius: float, half_angle: float, dmg: float, knockback: float) -> void:
	var direction := Vector2.RIGHT.rotated(aim_angle)
	if wanderer_hp > 0.0 and phase == "combat" and not is_in_safe_camp(wanderer):
		var neutral_diff: Vector2 = wanderer - player
		if neutral_diff.length() <= radius + 15.0 and (neutral_diff.length() < 2.0 or absf(wrapf(neutral_diff.angle() - aim_angle, -PI, PI)) < half_angle):
			damage_wanderer(dmg)
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
		var parry_stun: float = float(enemy.get("stun", 0.0))
		if parry_stun > 0.0:
			enemy["stun"] = maxf(0.0, parry_stun - delta)
			enemy["touch"] = maxf(float(enemy.get("touch", 0.0)), 0.18)
			enemy["hurt"] = 0.14
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
				# Contact attacks also feed through directional guard/parry.
				receive_enemy_hit(raw_damage, enemy["pos"], str(enemy.get("kind", "")), enemy)
				if hp <= 0.0:
					return
			enemy["touch"] = maxf(float(enemy["touch"]), 1.2 if elite else 0.76)

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
		if not exhausted and str(bullet.get("owner", "")) == "hero" and wanderer_hp > 0.0 and not is_in_safe_camp(wanderer) and wanderer.distance_to(bullet["pos"]) <= 25.0 + float(bullet["radius"]):
			damage_wanderer(float(bullet["dmg"]))
			exhausted = true
		if exhausted:
			projectiles.remove_at(i)



func ninja_clone_position(clone_index: int, clone_total: int) -> Vector2:
	var angle := elapsed * 1.45 + (TAU * float(clone_index) / float(clone_total))
	return player + Vector2.RIGHT.rotated(angle) * 86.0

func update_shadow_clones(delta: float) -> void:
	if shadow_clone_clock <= 0.0 or phase != "combat" or is_in_safe_camp(player):
		return
	shadow_clone_fire -= delta
	if shadow_clone_fire > 0.0:
		return
	shadow_clone_fire = 0.59 if level >= 10 else 0.74
	var total := 3 if level >= 10 else 2
	for i in range(total):
		var clone_pos := ninja_clone_position(i, total)
		var best_dist := 385.0
		var target: Dictionary = {}
		for foe in enemies:
			if float(foe["hp"]) <= 0.0:
				continue
			var dist: float = clone_pos.distance_to(foe["pos"])
			if dist < best_dist:
				best_dist = dist
				target = foe
		if target.is_empty():
			continue
		var direction: Vector2 = ((target["pos"] as Vector2) - clone_pos).normalized()
		projectiles.append({"pos": clone_pos + direction * 22.0, "vel": direction * 910.0, "dmg": (4.7 if level >= 10 else 3.3) * attack_stat_multiplier(7), "accuracy": 0.96, "radius": 5.0, "pierce": 1, "kind": "kunai", "tint": Color("c6a5ff"), "life": 1.1, "hit_ids": [], "crit_chance": crit_probability(hero_stats[4]), "trait": -1})
		burst(clone_pos, Color("a88dff"), 4)

func draw_shadow_clones() -> void:
	if shadow_clone_clock <= 0.0 or class_id != 6:
		return
	var total := 3 if level >= 10 else 2
	for i in range(total):
		var at: Vector2 = ninja_clone_position(i, total)
		draw_circle(at + Vector2(0, 17), 18.0, Color("5a3ca0", 0.22))
		draw_character(WOLF_WALK, at, int(walk_clock) % 4, cos(aim_angle) > 0.0, 1.72, Color(0.67, 0.50, 1.0, 0.61))
		draw_rect(Rect2(at + Vector2(-12, -36), Vector2(24, 11)), Color("59387a", 0.79))
		draw_string(ui_font, at + Vector2(-25, -51), "分身", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("d9c9ff"))

func update_corpses(delta: float) -> void:
	for i in range(corpses.size() - 1, -1, -1):
		corpses[i]["life"] = float(corpses[i]["life"]) - delta
		if float(corpses[i]["life"]) <= 0.0:
			corpses.remove_at(i)

func draw_corpses() -> void:
	for corpse in corpses:
		var pos: Vector2 = corpse["pos"]
		if pos.distance_to(player) > 900.0:
			continue
		var alpha: float = clampf(float(corpse["life"]) / 1.25, 0.0, 1.0)
		draw_circle(pos + Vector2(3, 17), 26.0, Color("091119", 0.26 * alpha))
		var tex: Texture2D = NIGHT_REAPER if bool(corpse["boss"]) else (STORM_BRUTE if bool(corpse["elite"]) else PIERO_WALK)
		var tex_size := Vector2(40, 48) if bool(corpse["elite"]) else Vector2(32, 40)
		var scale_value := 1.55 if bool(corpse["elite"]) else 1.40
		var tint := Color(0.45, 0.51, 0.55, alpha)
		draw_set_transform(pos + Vector2(0, 14), 1.35 if bool(corpse["facing"]) else -1.35, Vector2(scale_value, scale_value * 0.70))
		draw_texture_rect_region(tex, Rect2(-tex_size.x / 2.0, -tex_size.y / 2.0, tex_size.x, tex_size.y), Rect2(0, 0, tex_size.x, tex_size.y), tint)
		draw_set_transform(Vector2.ZERO)

func cleanup_defeated_enemies() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		if float(enemy["hp"]) > 0.0:
			continue
		var death_spot: Vector2 = enemy["pos"]
		var elite: bool = bool(enemy["elite"])
		# Visually keep fallen enemies for exactly five seconds, then fade away.
		corpses.append({"pos": death_spot, "kind": str(enemy.get("kind", "grunt")), "boss": bool(enemy["boss"]), "elite": elite, "life": 5.0, "facing": player.x > death_spot.x})
		if corpses.size() > 55:
			corpses.remove_at(0)
		burst(death_spot, Color("a1cbff") if elite else Color("ff7c9b"), 24 if elite else 12)
		if bool(enemy["boss"]):
			emit_impact_sparks(death_spot, Color("ffd38d"), 58, 440.0)
			emit_impact_ring(death_spot, Color("ffe3a1"), 176.0, 0.60, 11.0)
		elif elite:
			emit_impact_sparks(death_spot, Color("bb9bff"), 28, 265.0)
			emit_impact_ring(death_spot, Color("c5a9ff"), 100.0, 0.40, 6.0)
		else:
			emit_impact_sparks(death_spot, Color("ffb1a7"), 9, 185.0)
			emit_impact_ring(death_spot, Color("ffd1b4"), 50.0, 0.25, 3.5)
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
			trigger_camera_shake(0.45, 22.0)
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
	var bonus: float = snappedf(rng.randf_range(0.85, 1.20) + float(element_id) * 0.04 + float(rarity) * 0.035, 0.01)
	var item_name: String = "%s・%s  [威力x%.2f]" % [WEAPON_TRAITS[element_id], build_drop_name(kind, rarity), bonus]
	drops.append({"type": "weapon", "pos": pos, "rarity": rarity, "kind": kind, "trait": element_id, "bonus": bonus, "name": item_name, "life": 65.0 if rarity >= 3 else 32.0, "phase": rng.randf() * TAU})
	celebrate_loot(pos, rarity, item_name)

func spawn_armor_drop(pos: Vector2, rarity: int, forced_slot: int = -1) -> void:
	var slot := forced_slot if forced_slot >= 0 else rng.randi_range(0, ARMOR_SLOTS.size() - 1)
	var defense := maxi(1, roundi(float(ARMOR_BASE_DEF[slot]) * ARMOR_RARITY_MULT[rarity] * rng.randf_range(0.80, 1.30)))
	var style_id := rng.randi_range(0, 3)
	var style_names := ["守護", "銀月", "翡翠", "暁"]
	defense += style_id
	var item_name: String = "%s・%s %s [防御+%d]" % [style_names[style_id], ARMOR_PREFIX[rarity], ARMOR_SLOTS[slot], defense]
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
		trigger_camera_shake(0.30, 14.0)
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

# Long item names must not be cut off: shrink the font until the text fits next to the icon
# (never below 9 px; the full text is always available as the tooltip).
func fit_item_button(button: Button, text_value: String, button_width: float, base_size: int = 14) -> void:
	var available := button_width - 60.0
	var size := base_size
	while size > 9 and ui_font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > available:
		size -= 1
	button.text = text_value
	button.tooltip_text = text_value
	button.clip_text = true
	button.add_theme_font_size_override("font_size", size)

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

const CONTROLS_HELP := [
	["WASD / 矢印キー", "移動"],
	["マウス左ボタン", "攻撃（戦闘中、カーソルの方向へ）"],
	["SPACE", "回避"],
	["E", "調べる（拾う・畑・料理・商人・スロット）"],
	["Q", "クラススキル（LV5で習得）"],
	["1 - 5", "バッグの装備をすばやく切り替え"],
	["I", "バッグを開く / 閉じる"],
	["F", "作物の切り替え"],
	["T", "ちゅぶらのお世話メニュー"],
	["H / J", "シチュー / スープを食べる"],
	["K / L", "果物を食べる"],
	["M", "音のオン / オフ"],
	["C", "この操作方法を開く / 閉じる"],
	["Esc", "開いている画面を閉じる"],
]

func toggle_controls() -> void:
	if state != "playing":
		return
	controls_open = not controls_open
	controls_panel.visible = controls_open

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
		fit_item_button(inventory_buttons[i], "[%d]  %s" % [i + 1, item_description(item)], 331.0)
		inventory_buttons[i].icon = null if item.is_empty() else item_icon(item)
		inventory_buttons[i].expand_icon = true
		inventory_buttons[i].disabled = item.is_empty()
		discard_buttons[i].disabled = item.is_empty()
		var c: Color = Color("628aa7") if item.is_empty() else RARITY_COLORS[int(item["rarity"])]
		inventory_buttons[i].add_theme_color_override("font_color", c)
	for i in range(ARMOR_SLOTS.size()):
		var item: Dictionary = armor_equipped[i]
		fit_item_button(armor_buttons[i], "%s: %s" % [ARMOR_SLOTS[i], "-- 空き --" if item.is_empty() else item_description(item)], 414.0)
		armor_buttons[i].icon = ARMOR_ICONS[i] if item.is_empty() else item_icon(item)
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
		pickup_hint.text = "[E] 料理  |  🥕%d 🍄%d 🍈%d 🍉%d  |  🍲%d 🥣%d 🧃%d 🍨%d" % [carrots, mushrooms, melons, watermelons, stew_meals, broth_meals, melon_meals, watermelon_meals]
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
	if player.distance_to(SLOT_POS) < 105.0 and nearest >= 92.0:
		pickup_hint.text = "[E] スロット 25G  |  景品は右下の受け取り台へ"
	if player.distance_to(MERCHANT_POS) < 108.0:
		pickup_hint.text = "[E] 武器商人ルーンの店  |  装備・レア作物の種を購入"
	for meal in meal_displays:
		if player.distance_to(meal["pos"]) < 62.0:
			pickup_hint.text = "[E] 飾った料理を回収"
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
	if player.distance_to(STASH_POS) < 106.0:
		pickup_hint.text = "[E] 倉庫を開く  |  預けた装備は死亡しても残る"

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

func trigger_camera_shake(duration: float, strength: float) -> void:
	screen_shake = maxf(screen_shake, duration)
	screen_shake_strength = maxf(screen_shake_strength, strength)

func emit_impact_sparks(at: Vector2, tint: Color, count: int, speed: float) -> void:
	# Drawn as bright streaks that fly outward from the impact point.
	for spark_index in range(count):
		if impact_sparks.size() >= MAX_IMPACT_SPARKS:
			impact_sparks.remove_at(0)
		var direction: Vector2 = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
		var velocity: Vector2 = direction * rng.randf_range(speed * 0.52, speed * 1.22)
		var lifetime: float = rng.randf_range(0.17, 0.41)
		var warm_color: Color = tint.lerp(Color.WHITE, rng.randf_range(0.05, 0.55))
		impact_sparks.append({"pos": at, "vel": velocity, "life": lifetime, "total": lifetime, "color": warm_color, "width": rng.randf_range(1.8, 3.5)})

func emit_impact_ring(at: Vector2, tint: Color, max_radius: float, lifetime: float, thickness: float) -> void:
	if impact_rings.size() >= 28:
		impact_rings.remove_at(0)
	impact_rings.append({"pos": at, "color": tint, "radius": max_radius, "life": lifetime, "total": lifetime, "width": thickness})

func update_impact_fx(delta: float) -> void:
	for i in range(impact_sparks.size() - 1, -1, -1):
		var spark: Dictionary = impact_sparks[i]
		spark["life"] = float(spark["life"]) - delta
		if float(spark["life"]) <= 0.0:
			impact_sparks.remove_at(i)
			continue
		var velocity: Vector2 = spark["vel"]
		spark["pos"] = (spark["pos"] as Vector2) + velocity * delta
		spark["vel"] = velocity.move_toward(Vector2.ZERO, 195.0 * delta) + Vector2(0.0, 70.0 * delta)
	for i in range(impact_rings.size() - 1, -1, -1):
		impact_rings[i]["life"] = float(impact_rings[i]["life"]) - delta
		if float(impact_rings[i]["life"]) <= 0.0:
			impact_rings.remove_at(i)

func draw_impact_fx() -> void:
	for ring in impact_rings:
		var age: float = clampf(1.0 - float(ring["life"]) / float(ring["total"]), 0.0, 1.0)
		var opacity: float = 1.0 - age
		var center: Vector2 = ring["pos"]
		var col: Color = ring["color"]
		var radius: float = 9.0 + float(ring["radius"]) * age
		draw_arc(center, radius, 0.0, TAU, 48, Color(col, opacity * 0.9), maxf(1.0, float(ring["width"]) * opacity))
		if age < 0.30:
			# Brief star-shaped flash at the exact hit point.
			var flash_alpha: float = 1.0 - age / 0.30
			draw_line(center + Vector2(-19, 0), center + Vector2(19, 0), Color("fff8e7", flash_alpha), 3.0)
			draw_line(center + Vector2(0, -19), center + Vector2(0, 19), Color("fff8e7", flash_alpha), 3.0)
	for spark in impact_sparks:
		var alpha: float = clampf(float(spark["life"]) / float(spark["total"]), 0.0, 1.0)
		var center: Vector2 = spark["pos"]
		var velocity: Vector2 = spark["vel"]
		var direction: Vector2 = velocity.normalized() if velocity.length_squared() > 0.001 else Vector2.RIGHT
		var tail: Vector2 = center - direction * (10.0 + velocity.length() * 0.038)
		var col: Color = spark["color"]
		draw_line(tail, center, Color(col, alpha), maxf(1.0, float(spark["width"]) * alpha), true)
		if alpha > 0.36:
			draw_circle(center, 1.7 * alpha, Color("fffdf1", alpha))

func attack_stat_multiplier(kind: int) -> float:
	var physical := kind == 0 or kind == 1 or kind == 2 or kind == 3 or kind == 4 or kind == 7
	var ranged := kind == 0 or kind == 1 or kind == 4 or kind == 7
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
		6: # Ninja: shadow clones independently throw kunai at nearby enemies.
			shadow_clone_clock = 12.0 if enhanced else 8.0
			shadow_clone_fire = 0.1
			burst(player, Color("c4a2ff"), 50)
	show_status("スキル発動！ %s%s" % [SKILL_NAMES[class_id], "・強化版" if enhanced else ""], Color("b6edff"))
	play_sound(AUDIO_EPIC, -19.0)

func toggle_upgrade_menu() -> void:
	if state != "playing":
		return
	upgrade_open = not upgrade_open
	upgrade_panel.visible = upgrade_open
	if upgrade_open:
		inventory_open = false
		inventory_panel.hide()
		refresh_upgrade_panel()

func set_upgrade_target(target: String) -> void:
	if not upgrade_open or target not in ["hero", "mint"]:
		return
	upgrade_target = target
	refresh_upgrade_panel()

func refresh_upgrade_panel() -> void:
	if not upgrade_open:
		return
	var owner_name := "主人公" if upgrade_target == "hero" else "ミント"
	var owner_level: int = level if upgrade_target == "hero" else companion_level
	var points: int = pending_hero_points if upgrade_target == "hero" else pending_mint_points
	var stats: Array[int] = hero_stats if upgrade_target == "hero" else companion_stats
	upgrade_heading.text = "%s LV%d  |  未使用ポイント %d" % [owner_name, owner_level, points]
	stat_summary.text = "力%d  速%d  体%d  MP%d  器%d  知%d  |  主人公P%d / ミントP%d" % [stats[0], stats[1], stats[2], stats[3], stats[4], stats[5], pending_hero_points, pending_mint_points]
	for i in range(6):
		upgrade_buttons[i].text = "[%d] %s +1  (現在 %d)\n%s" % [i + 1, STAT_NAMES[i], stats[i], STAT_DESCRIPTIONS[i]]
		upgrade_buttons[i].disabled = points <= 0

func select_upgrade(index: int) -> void:
	if not upgrade_open or index < 0 or index >= 6:
		return
	if upgrade_target == "hero":
		if pending_hero_points <= 0:
			return
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
		if pending_mint_points <= 0:
			return
		companion_stats[index] += 1
		pending_mint_points -= 1
		match index:
			2:
				companion_max_hp += 15.0
				companion_hp = minf(companion_max_hp, companion_hp + 25.0)
			3:
				companion_heal_clock = maxf(0.0, companion_heal_clock - 2.0)
	show_status("%sの%sが1上がった！" % ["主人公" if upgrade_target == "hero" else "ミント", STAT_NAMES[index]], Color("baffd3"))
	play_sound(AUDIO_PICKUP, -13.0)
	refresh_upgrade_panel()

func load_stash() -> void:
	if stash_loaded:
		return
	stash_loaded = true
	stash_items.clear()
	if not FileAccess.file_exists(STASH_SAVE):
		return
	var raw: String = FileAccess.get_file_as_string(STASH_SAVE)
	var decoded: Variant = JSON.parse_string(raw)
	if typeof(decoded) == TYPE_ARRAY:
		for entry in decoded:
			if typeof(entry) == TYPE_DICTIONARY and str(entry.get("type", "")) in ["weapon", "armor"] and stash_items.size() < STASH_MAX:
				stash_items.append(entry.duplicate(true))

func save_stash() -> void:
	var save_file := FileAccess.open(STASH_SAVE, FileAccess.WRITE)
	if save_file == null:
		show_status("倉庫の保存に失敗！ 空き容量・権限を確認", Color("ff9e9e"))
		return
	save_file.store_string(JSON.stringify(stash_items))
	save_file.close()

func toggle_stash() -> void:
	if state != "playing":
		return
	if not stash_open and player.distance_to(STASH_POS) > 106.0:
		show_status("キャンプの倉庫の近くでEキーを押してね", Color("ffe6b5"))
		return
	stash_open = not stash_open
	stash_panel.visible = stash_open
	if stash_open:
		inventory_open = false
		inventory_panel.hide()
		refresh_stash_ui()

func refresh_stash_ui() -> void:
	if not stash_open:
		return
	stash_title.text = "倉庫 %d/%d  |  死亡後も保持  |  今回のLV%dは死亡で初期化" % [stash_items.size(), STASH_MAX, level]
	for i in range(BAG_CAPACITY):
		var item: Dictionary = backpack[i]
		var bag_button: Button = stash_bag_buttons[i]
		bag_button.text = "[%d] 空き" % (i + 1) if item.is_empty() else "[%d] %s" % [i + 1, WEAPON_SHORT[int(item.get("kind", 0))] if str(item.get("type", "")) == "weapon" else ARMOR_SHORT[int(item.get("slot", 0))]]
		bag_button.icon = null if item.is_empty() else item_icon(item)
		bag_button.expand_icon = true
		bag_button.tooltip_text = "" if item.is_empty() else item_description(item)
		bag_button.disabled = item.is_empty() or stash_items.size() >= STASH_MAX
	stash_equip_button.disabled = stash_items.size() >= STASH_MAX
	for i in range(STASH_MAX):
		var button: Button = stash_storage_buttons[i]
		if i < stash_items.size():
			var item: Dictionary = stash_items[i]
			button.text = "[%d] %s" % [i + 1, str(item["name"]).substr(0, 14)]
			button.tooltip_text = item_description(item)
			button.icon = item_icon(item)
			button.disabled = free_backpack_slot() < 0
		else:
			button.text = "[%d] 空き" % (i + 1)
			button.tooltip_text = ""
			button.icon = null
			button.disabled = true
		button.expand_icon = true

func stash_deposit_backpack(index: int) -> void:
	if not stash_open or index < 0 or index >= BAG_CAPACITY or stash_items.size() >= STASH_MAX or backpack[index].is_empty():
		return
	stash_items.append(backpack[index].duplicate(true))
	backpack[index] = {}
	save_stash()
	refresh_stash_ui()
	refresh_inventory_ui()
	show_status("倉庫に預けた！ 次の挑戦でも取り出せます", Color("ffe7a5"))

func stash_deposit_equipped() -> void:
	if not stash_open or stash_items.size() >= STASH_MAX:
		return
	stash_items.append(equipped.duplicate(true))
	equipped = {"type": "weapon", "kind": 0, "rarity": 0, "name": "PISTOL"}
	save_stash()
	refresh_stash_ui()
	refresh_inventory_ui()
	show_status("武器を倉庫へ。初期銃に切り替えた", Color("ffe7a5"))

func stash_withdraw(index: int) -> void:
	if not stash_open or index < 0 or index >= stash_items.size():
		return
	var slot: int = free_backpack_slot()
	if slot < 0:
		show_status("バッグが満杯！", Color("ff9d9d"))
		return
	backpack[slot] = stash_items[index].duplicate(true)
	stash_items.remove_at(index)
	save_stash()
	refresh_stash_ui()
	refresh_inventory_ui()
	show_status("倉庫から装備を取り出した", Color("b9f4e4"))

func extract_alive() -> void:
	if not stash_open or state != "playing" or player.distance_to(STASH_POS) > 106.0:
		return
	# Extracting alive banks the loadout as long as there is enough chest space.
	var bank: Array[Dictionary] = []
	for item in backpack:
		if not item.is_empty():
			bank.append(item.duplicate(true))
	for item in armor_equipped:
		if not item.is_empty():
			bank.append(item.duplicate(true))
	# Ignore only the basic unmodified starter weapon.
	var starter_kind: int = CLASS_WEAPONS[class_id]
	if not (int(equipped.get("kind", -1)) == starter_kind and int(equipped.get("rarity", -1)) == 0 and str(equipped.get("name", "")) == WEAPONS[starter_kind]):
		bank.append(equipped.duplicate(true))
	if stash_items.size() + bank.size() > STASH_MAX:
		show_status("倉庫の空きが足りない！ 整理してから帰還しよう", Color("ffb9a5"))
		return
	for item in bank:
		stash_items.append(item)
	save_stash()
	reset_game()
	show_status("無事生還！ 装備%d個を倉庫へ保存。次はLV1から" % bank.size(), Color("a8ffdb"))

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
	mp_text.text = "MP %d/%d   XP %d/%d   [P]能力P:主人公%d / ミント%d" % [roundi(mp), roundi(max_mp), xp, xp_needed, pending_hero_points, pending_mint_points]
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
	var guard_status: String = "パリィ受付!" if guard_active and guard_parry_clock > 0.0 else ("ガード中" if guard_active else ("ガード待ち %.1f秒" % guard_restart_clock if guard_restart_clock > 0.0 else "ガード可"))
	help.text = "WASD移動 左クリック攻撃 右クリックガード[%s]  SPACE回避 E操作 Iバッグ P能力 Tちゅぶら C操作方法" % guard_status
	hotbar_container.visible = state == "playing" or state == "upgrade"
	hotbar_currency.visible = state == "playing" or state == "upgrade"
	minimap_panel.visible = state == "playing" or state == "upgrade"
	minimap_marker.position = Vector2(5.0 + clampf((player.x - ARENA.position.x) / ARENA.size.x, 0.0, 1.0) * 150.0, 6.0 + clampf((player.y - ARENA.position.y) / ARENA.size.y, 0.0, 1.0) * 121.0)

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
	draw_circle(center, 33.0 + sin(phase_value * 2.0) * 2.0, Color(c, 0.10 if rarity < 3 else 0.22))
	draw_circle(center + Vector2(0, 18), 25.0, Color(c, 0.12))
	draw_texture_rect(LOOT_FRAME, Rect2(center - Vector2(32, 32), Vector2(64, 64)), false)
	draw_rect(Rect2(center - Vector2(26, 26), Vector2(52, 52)), Color(c, 0.16 if rarity < 3 else 0.34), false, 2.0)
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
	var sword_art: Texture2D = sword_art_for_rarity(rarity)
	var attack_progress: float = clampf(1.0 - attack_clock / maxf(attack_duration, 0.01), 0.0, 1.0)
	var swing: float = (attack_progress - 0.5) * 1.2 if attacking else 0.0
	var sword_rotation: float = aim_angle + PI * 0.5 + swing
	var hand_pos: Vector2 = sword_origin + Vector2.RIGHT.rotated(aim_angle) * 22.0
	var sword_size: Vector2 = sword_art.get_size()
	var sword_scale: float = 1.62 if rarity >= 3 else 1.73
	var rarity_tint: Color = RARITY_COLORS[rarity]
	var blade_world: Vector2 = hand_pos + Vector2.RIGHT.rotated(aim_angle) * 43.0
	if rarity >= 1:
		draw_circle(blade_world, 23.0 + 2.0 * sin(elapsed * 5.0), Color(rarity_tint, 0.10 if rarity < 3 else 0.24))
	if attacking:
		draw_line(hand_pos, blade_world, Color(rarity_tint, 0.16), 15.0)
	if rarity == 4:
		draw_circle(blade_world, 28.0, Color("ff91d9", 0.18))
	draw_set_transform(hand_pos, sword_rotation, Vector2(sword_scale, sword_scale))
	draw_texture_rect(sword_art, Rect2(Vector2(-sword_size.x * 0.5, -sword_size.y + 5.0), sword_size), false)
	draw_set_transform(Vector2.ZERO)

func draw_equipped_greatsword(sword_origin: Vector2, rarity: int, attacking: bool) -> void:
	# Same pose as draw_equipped_sword with the greatsword art, a little larger.
	var sword_art: Texture2D = greatsword_art_for_rarity(rarity)
	var attack_progress: float = clampf(1.0 - attack_clock / maxf(attack_duration, 0.01), 0.0, 1.0)
	var swing: float = (attack_progress - 0.5) * 1.2 if attacking else 0.0
	var sword_rotation: float = aim_angle + PI * 0.5 + swing
	var hand_pos: Vector2 = sword_origin + Vector2.RIGHT.rotated(aim_angle) * 22.0
	var sword_size: Vector2 = sword_art.get_size()
	var sword_scale: float = 1.9
	var rarity_tint: Color = RARITY_COLORS[rarity]
	var blade_world: Vector2 = hand_pos + Vector2.RIGHT.rotated(aim_angle) * 52.0
	if rarity >= 1:
		draw_circle(blade_world, 27.0 + 2.0 * sin(elapsed * 5.0), Color(rarity_tint, 0.10 if rarity < 3 else 0.24))
	if attacking:
		draw_line(hand_pos, blade_world, Color(rarity_tint, 0.16), 19.0)
	if rarity == 4:
		draw_circle(blade_world, 32.0, Color("ff91d9", 0.18))
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
	draw_circle(c + Vector2(0, -20), 76.0, Color("eac578", 0.065))
	draw_texture_rect(SLOT_ART, Rect2(c - Vector2(55.0, 99.0), Vector2(110.0, 146.0)), false)
	draw_string(ui_font, c + Vector2(-62, 67), "スロット [E] 25G", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffe2a0"))

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
	draw_circle(p + Vector2(0, 20), 108.0, Color("9ddbb1", 0.045))
	draw_texture_rect(MERCHANT_ART, Rect2(p - Vector2(83.0, 99.0), Vector2(166.0, 159.0)), false)
	draw_string(ui_font, p + Vector2(-85, -114), "旅の商人 ルーン [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d8ffb9"))

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
		var flame_glow: float = 1.0 + 0.08 * sin(elapsed * 7.4)
		draw_v017_glow(f + Vector2(0, -10), GLOW_AMBER_V017, 370.0 * flame_glow, 0.85)
		draw_circle(f + Vector2(0, 9), 85.0 * flame_glow, Color("ffc478", 0.055))
		draw_circle(f + Vector2(0, 5), 45.0 * flame_glow, Color("ffb26d", 0.12))
		draw_texture_rect(COOK_ART, Rect2(f - Vector2(62.0, 80.0), Vector2(124.0, 116.0)), false)
		draw_string(ui_font, f + Vector2(-43, 55), "料理 [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffdda4"))
	draw_string(ui_font, Vector2(1390, 675), "農場 [E/F]", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b8f1ba"))
	draw_string(ui_font, Vector2(2230, 1032), "農場 [E/F]", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("b8f1ba"))
	draw_string(ui_font, Vector2(1710, 1110), "森の畑 [E/F]", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b8f1ba"))
	draw_revive_shrine()
	var payout: Vector2 = SLOT_POS + Vector2(130, 145)
	draw_rect(Rect2(payout - Vector2(52, 36), Vector2(104, 72)), Color("293b43", 0.55))
	draw_rect(Rect2(payout - Vector2(52, 36), Vector2(104, 72)), Color("edcf82", 0.8), false, 3.0)
	draw_string(ui_font, payout + Vector2(-64, 62), "スロット景品 / [E]拾う", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("fff0b6"))
	draw_slot_machine()
	draw_merchant()

func toggle_rabbit_menu() -> void:
	if state != "playing":
		return
	if not rabbit_menu_open and not rabbit_carried and player.distance_to(rabbit_pet) > 115.0:
		show_status("ちゅぶらの近くで [T] を押してね", Color("ead7ff"))
		return
	rabbit_menu_open = not rabbit_menu_open
	rabbit_menu.visible = rabbit_menu_open
	if rabbit_menu_open:
		inventory_open = false
		inventory_panel.hide()
		refresh_rabbit_menu()

func refresh_rabbit_menu() -> void:
	if rabbit_menu_info == null:
		return
	var gear_next := mini(3, rabbit_gear_level + 1)
	var gear_line := "装備は最上級まで購入済" if rabbit_gear_level >= 3 else "次の装備: %s (%dG)" % [RABBIT_GEAR_NAMES[gear_next], RABBIT_GEAR_COSTS[gear_next]]
	rabbit_menu_info.text = "名前: %s　好物: にんじん\nなかよし度: %d/100  満腹度: %d/100　にんじん: %d個\n装備: %s　%s\n状態: %s" % [RABBIT_NAME, roundi(rabbit_affection), roundi(rabbit_hunger), carrots, RABBIT_GEAR_NAMES[rabbit_gear_level], gear_line, "抱っこ中" if rabbit_carried else rabbit_pet_mode]
	rabbit_menu_buttons[2].disabled = carrots <= 0 or rabbit_hunger >= 98.0
	rabbit_menu_buttons[3].disabled = rabbit_gear_level >= 3 or coins < RABBIT_GEAR_COSTS[gear_next]
	rabbit_menu_buttons[3].text = "[4] 次の装備を購入 (%dG)" % RABBIT_GEAR_COSTS[gear_next] if rabbit_gear_level < 3 else "[4] すべての装備を購入済"

func rabbit_action_selected(action: int) -> void:
	if state != "playing" or not rabbit_pet_enabled:
		return
	match action:
		0: # Pet
			rabbit_affection = minf(100.0, rabbit_affection + 9.0)
			rabbit_pet_glow = 1.15
			burst(rabbit_pet, Color("ff9bc8"), 17)
			play_sound(AUDIO_PICKUP, -20.0, 1.55)
			show_status("%sをなでた！ なかよし度 +9 ♥" % RABBIT_NAME, Color("ffd1ed"))
		1: # Carry / put down
			rabbit_carried = not rabbit_carried
			if rabbit_carried:
				rabbit_pet = player + Vector2(0, -44)
				show_status("%sを抱っこした！" % RABBIT_NAME, Color("ead6ff"))
			else:
				rabbit_pet = (player + Vector2(57, 20)).clamp(ARENA.position + Vector2(40, 40), ARENA.end - Vector2(40, 40))
				show_status("%sをそっとおろした" % RABBIT_NAME, Color("ead6ff"))
		2: # Raw carrot treat
			if carrots <= 0:
				show_status("にんじんがない！ 畑で収穫しよう", Color("ffcdb8"))
				return
			if rabbit_hunger >= 98.0:
				show_status("%sはおなかいっぱい！" % RABBIT_NAME, Color("ffe9cd"))
				return
			carrots -= 1
			rabbit_hunger = minf(100.0, rabbit_hunger + 38.0)
			rabbit_affection = minf(100.0, rabbit_affection + 15.0)
			rabbit_pet_glow = 1.5
			burst(rabbit_pet, Color("ffac6d"), 20)
			play_sound(AUDIO_PICKUP, -13.0, 1.3)
			show_status("%sはにんじんが大好き！ ♥+15" % RABBIT_NAME, Color("ffdeb0"))
		3: # Sequential small pet gear upgrades from in-game coins
			if rabbit_gear_level >= 3:
				show_status("%sの装備はすべて揃っているよ" % RABBIT_NAME, Color("d9cfff"))
				return
			var next_level: int = rabbit_gear_level + 1
			var cost: int = RABBIT_GEAR_COSTS[next_level]
			if coins < cost:
				show_status("ちゅぶらの装備には %dG 必要！" % cost, Color("ffe0b2"))
				return
			coins -= cost
			rabbit_gear_level = next_level
			rabbit_pet_glow = 1.7
			burst(rabbit_pet, Color("bfa8ff"), 26)
			play_sound(AUDIO_RARE, -18.0)
			refresh_hotbar()
			show_status("ちゅぶらに『%s』を装備！" % RABBIT_GEAR_NAMES[next_level], Color("e9c9ff"))
	refresh_rabbit_menu()

func update_rabbit_pet(delta: float) -> void:
	if not rabbit_pet_enabled or state != "playing":
		return
	rabbit_pet_attack_clock = maxf(0.0, rabbit_pet_attack_clock - delta)
	rabbit_pet_meal_clock = maxf(0.0, rabbit_pet_meal_clock - delta)
	rabbit_patrol_clock = maxf(0.0, rabbit_patrol_clock - delta)
	rabbit_pet_glow = maxf(0.0, rabbit_pet_glow - delta)
	rabbit_pet_bob_clock += delta * 8.0
	rabbit_hunger = maxf(0.0, rabbit_hunger - delta * 0.45)
	if rabbit_carried:
		rabbit_pet = player + Vector2(0, -44)
		rabbit_pet_mode = "抱っこ中"
		return

	var target_meal_index := -1
	if rabbit_pet_meal_clock <= 0.0 and rabbit_hunger < 75.0:
		var best_meal_score := 999999.0
		for i in range(meal_displays.size()):
			var meal_pos: Vector2 = meal_displays[i]["pos"]
			var meal_type: int = int(meal_displays[i]["kind"])
			# Carrot stew is Chubura's favorite: go after it first.
			var score: float = rabbit_pet.distance_to(meal_pos) + (0.0 if meal_type == 0 else 180.0)
			if score < best_meal_score and rabbit_pet.distance_to(meal_pos) < 470.0:
				best_meal_score = score
				target_meal_index = i
	var enemy_target: Dictionary = {}
	var enemy_found := false
	var best_enemy_dist := 999999.0
	if phase == "combat":
		for enemy in enemies:
			if float(enemy["hp"]) <= 0.0:
				continue
			var de: float = rabbit_pet.distance_to(enemy["pos"])
			if de < best_enemy_dist and de < 220.0:
				best_enemy_dist = de
				enemy_target = enemy
				enemy_found = true
	if target_meal_index >= 0:
		rabbit_pet_mode = "ごはんを探す"
		rabbit_pet_goal = meal_displays[target_meal_index]["pos"]
	elif enemy_found and not is_in_safe_camp(rabbit_pet):
		rabbit_pet_mode = "戦う"
		var enemy_pos: Vector2 = enemy_target["pos"]
		var away: Vector2 = (rabbit_pet - enemy_pos).normalized()
		if away.length_squared() < 0.01:
			away = Vector2.RIGHT
		rabbit_pet_goal = enemy_pos + away * 48.0
	else:
		rabbit_pet_mode = "自由におさんぽ"
		if rabbit_patrol_clock <= 0.0 or rabbit_pet.distance_to(rabbit_pet_goal) < 18.0:
			# Independent patrol: not locked to the player's feet.
			rabbit_patrol_clock = rng.randf_range(1.5, 3.7)
			rabbit_pet_goal = (rabbit_pet + Vector2(rng.randf_range(-200.0, 200.0), rng.randf_range(-190.0, 190.0))).clamp(ARENA.position + Vector2(40, 40), ARENA.end - Vector2(40, 40))
		if rabbit_pet.distance_to(player) > 810.0:
			rabbit_pet_goal = player + Vector2(rng.randf_range(-190.0, 190.0), rng.randf_range(-170.0, 170.0))
	rabbit_pet_goal = rabbit_pet_goal.clamp(ARENA.position + Vector2(40, 40), ARENA.end - Vector2(40, 40))
	var dist: float = rabbit_pet.distance_to(rabbit_pet_goal)
	rabbit_pet_was_moving = dist > 8.0
	if rabbit_pet_was_moving:
		var step: float = minf(dist, (227.0 + float(rabbit_gear_level) * 8.0) * delta)
		rabbit_pet += (rabbit_pet_goal - rabbit_pet).normalized() * step
		rabbit_pet_walk_clock += 10.0 * delta
	else:
		rabbit_pet_walk_clock = 0.0
	if target_meal_index >= 0 and rabbit_pet.distance_to(meal_displays[target_meal_index]["pos"]) < 28.0:
		var meal_kind: int = int(meal_displays[target_meal_index]["kind"])
		meal_displays.remove_at(target_meal_index)
		rabbit_pet_meal_clock = 13.0
		rabbit_hunger = minf(100.0, rabbit_hunger + (45.0 if meal_kind == 0 else 26.0))
		rabbit_affection = minf(100.0, rabbit_affection + (8.0 if meal_kind == 0 else 3.0))
		rabbit_pet_glow = 1.1
		burst(rabbit_pet, Color("ffc2ea"), 12)
		play_sound(AUDIO_PICKUP, -20.0, 1.3)
		show_status("%sが展示された%sを食べた！" % [RABBIT_NAME, MEAL_NAMES[meal_kind]], Color("ffe7f6"))
	if enemy_found and rabbit_pet_attack_clock <= 0.0 and rabbit_pet.distance_to(enemy_target["pos"]) < 70.0 and not is_in_safe_camp(rabbit_pet):
		var pet_damage: float = 2.3 + float(rabbit_gear_level) * 0.45
		deal_enemy_damage(enemy_target, pet_damage, enemy_target["pos"], 0.04, -1)
		rabbit_pet_attack_clock = 1.15
		burst(enemy_target["pos"], Color("d7d1ff"), 6)

func draw_rabbit_pet() -> void:
	if not rabbit_pet_enabled:
		return
	var p: Vector2 = rabbit_pet
	var bob: float = sin(rabbit_pet_bob_clock) * 1.5 if not rabbit_carried else 0.0
	if rabbit_carried:
		p = player + Vector2(0, -55)
	if rabbit_pet_glow > 0.0:
		draw_circle(p + Vector2(0, -8), 25.0, Color("ff9ccc", minf(0.24, rabbit_pet_glow * 0.15)))
	draw_circle(p + Vector2(0, 10), 12.0, Color(0, 0, 0, 0.22))
	# Pointy ears with inner-ear highlights.
	draw_colored_polygon(PackedVector2Array([p + Vector2(-10, -12 + bob), p + Vector2(-8, -31 + bob), p + Vector2(-1, -13 + bob)]), Color("161820"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(10, -12 + bob), p + Vector2(8, -31 + bob), p + Vector2(1, -13 + bob)]), Color("161820"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -14 + bob), p + Vector2(-7, -25 + bob), p + Vector2(-3, -14 + bob)]), Color("72526e"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(8, -14 + bob), p + Vector2(7, -25 + bob), p + Vector2(3, -14 + bob)]), Color("72526e"))
	draw_circle(p + Vector2(0, bob), 12.0, Color("171920"))
	draw_circle(p + Vector2(0, -10 + bob), 10.0, Color("23242c"))
	draw_circle(p + Vector2(-4, -12 + bob), 1.5, Color("ff777c"))
	draw_circle(p + Vector2(4, -12 + bob), 1.5, Color("ff777c"))
	draw_circle(p + Vector2(0, -8 + bob), 1.7, Color("ffd7e9"))
	draw_circle(p + Vector2(10, -2 + bob), 3.0, Color("eef4ff"))
	# Visuals change with each pet gear upgrade.
	if rabbit_gear_level >= 1:
		draw_line(p + Vector2(-10, -2 + bob), p + Vector2(10, -2 + bob), Color("ff7d91"), 3.5)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 0 + bob), p + Vector2(0, 6 + bob), p + Vector2(3, 0 + bob)]), Color("ff9aa9"))
	if rabbit_gear_level >= 2:
		draw_rect(Rect2(p + Vector2(-13, 1 + bob), Vector2(26, 8)), Color("867258", 0.82))
		draw_rect(Rect2(p + Vector2(6, 2 + bob), Vector2(6, 6)), Color("dfc797"))
	if rabbit_gear_level >= 3:
		draw_circle(p + Vector2(0, 7 + bob), 5.0, Color("c4adff"))
		draw_arc(p + Vector2(0, 7 + bob), 8.0, 0.0, TAU, 20, Color("ebc8ff", 0.8), 2.0)
	if rabbit_pet_glow > 0.0:
		for i in range(3):
			var heart_pos: Vector2 = p + Vector2(-13 + float(i) * 13.0, -40 - rabbit_pet_glow * 5.0)
			draw_circle(heart_pos, 3.0, Color("ffb2d8", minf(1.0, rabbit_pet_glow)))
	draw_string(ui_font, p + Vector2(-29, -40), RABBIT_NAME, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f2dcff"))

func damage_wanderer(amount: float) -> void:
	if wanderer_hp <= 0.0:
		return
	wanderer_hp = maxf(0.0, wanderer_hp - amount)
	wanderer_hurt_clock = 0.25
	burst(wanderer, Color("ffe5a4"), 12)
	if not wanderer_hostile:
		wanderer_hostile = true
		show_status("放浪剣士『アッシュ』が敵対！ 攻撃されたので反撃してくる！", Color("ff9a8a"))
	if wanderer_hp <= 0.0:
		show_status("アッシュは倒れた（次の挑戦で再登場）", Color("ffb898"))
		emit_impact_sparks(wanderer, Color("ffd6a0"), 26, 220.0)

func update_wanderer(delta: float) -> void:
	if state != "playing" or wanderer_hp <= 0.0:
		return
	wanderer_attack_clock = maxf(0.0, wanderer_attack_clock - delta)
	wanderer_patrol_clock -= delta
	wanderer_hurt_clock = maxf(0.0, wanderer_hurt_clock - delta)
	var npc_target := Vector2.ZERO
	var can_attack := false
	if wanderer_hostile:
		npc_target = player
		can_attack = phase == "combat" and not is_in_safe_camp(player)
	else:
		var nearest: float = 480.0
		for enemy in enemies:
			if float(enemy["hp"]) <= 0.0:
				continue
			var d: float = wanderer.distance_to(enemy["pos"])
			if d < nearest:
				nearest = d
				npc_target = enemy["pos"]
				can_attack = phase == "combat"
	if can_attack:
		var diff: Vector2 = npc_target - wanderer
		var dist: float = diff.length()
		if dist > 150.0:
			wanderer += diff.normalized() * 174.0 * delta
			wanderer_walk_clock += 8.0 * delta
		if dist < 405.0 and wanderer_attack_clock <= 0.0 and dist > 5.0:
			wanderer_attack_clock = 1.12 if wanderer_hostile else 0.82
			if wanderer_hostile:
				# Uses the existing projectile collision and right-click guard/parry.
				hostile_orbs.append({"pos": wanderer + diff.normalized() * 34.0, "vel": diff.normalized() * 410.0, "life": 1.45, "damage": 12.0, "tint": Color("ffb16f"), "status": ""})
			else:
				var foe: Dictionary = {}
				var best: float = 70.0
				for enemy in enemies:
					var d2: float = wanderer.distance_to(enemy["pos"])
					if float(enemy["hp"]) > 0.0 and d2 < best:
						best = d2
						foe = enemy
				if not foe.is_empty():
					deal_enemy_damage(foe, 11.0, foe["pos"], 0.09)
				else:
					projectiles.append({"pos": wanderer + diff.normalized() * 22.0, "vel": diff.normalized() * 880.0, "dmg": 10.0, "accuracy": 0.98, "radius": 6.0, "pierce": 1, "kind": "arrow", "tint": Color("fff0b9"), "life": 0.9, "hit_ids": [], "crit_chance": 0.09, "trait": -1, "owner": "wanderer"})
	else:
		if wanderer_patrol_clock <= 0.0 or wanderer.distance_to(wanderer_goal) < 26.0:
			wanderer_patrol_clock = rng.randf_range(2.5, 5.5)
			wanderer_goal = (WANDERER_START + Vector2(rng.randf_range(-290.0, 290.0), rng.randf_range(-280.0, 280.0))).clamp(ARENA.position + Vector2(40, 40), ARENA.end - Vector2(40, 40))
		var movement: Vector2 = wanderer_goal - wanderer
		if movement.length() > 10.0:
			wanderer += movement.normalized() * minf(movement.length(), 115.0 * delta)
			wanderer_walk_clock += delta * 7.0
	wanderer = keep_enemy_out_of_camp(wanderer.clamp(ARENA.position + Vector2(40, 45), ARENA.end - Vector2(40, 45)))

func draw_wanderer() -> void:
	if wanderer_hp <= 0.0:
		return
	var p: Vector2 = wanderer
	draw_circle(p + Vector2(0, 16), 23.0, Color(0, 0, 0, 0.30))
	draw_character(WOLF_WALK, p, int(wanderer_walk_clock) % 4, player.x > p.x, 1.82, Color("ffb6a1") if wanderer_hurt_clock > 0.0 else Color("b4d9ef"))
	draw_rect(Rect2(p + Vector2(-19, -28), Vector2(38, 12)), Color("476b7d"))
	draw_line(p + Vector2(20, -5), p + Vector2(41, -35), Color("f5ddab"), 5.0)
	draw_rect(Rect2(p + Vector2(-29, -54), Vector2(58, 7)), Color("2c3342"))
	draw_rect(Rect2(p + Vector2(-29, -54), Vector2(58.0 * wanderer_hp / 185.0, 7)), Color("ff6969") if wanderer_hostile else Color("a3e4d0"))
	draw_string(ui_font, p + Vector2(-62, -61), "敵対 アッシュ" if wanderer_hostile else "中立 アッシュ", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ff9b83") if wanderer_hostile else Color("b8f4e3"))

func draw_stash_chest() -> void:
	var p: Vector2 = STASH_POS
	draw_circle(p + Vector2(0, 16), 53.0, Color(0.0, 0.0, 0.0, 0.12))
	draw_texture_rect(STASH_ART, Rect2(p - Vector2(56.0, 51.0), Vector2(112.0, 86.0)), false)
	draw_string(ui_font, p + Vector2(-86, 58), "永続倉庫 [E]  /  生還可", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffe5ae"))

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

func draw_v017_glow(at: Vector2, texture: Texture2D, diameter: float, alpha: float = 1.0) -> void:
	draw_texture_rect(texture, Rect2(at - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter), false, Color(1.0, 1.0, 1.0, alpha))

func draw_fantasy_ground() -> void:
	# A painterly pixel forest: four varied tiles keep the huge arena from looking stamped.
	draw_rect(ARENA.grow(120.0), Color("0a151c"))
	var tile_size: float = 256.0
	var left_tile: int = int(floor((player.x - 870.0) / tile_size))
	var right_tile: int = int(ceil((player.x + 870.0) / tile_size))
	var top_tile: int = int(floor((player.y - 560.0) / tile_size))
	var bottom_tile: int = int(ceil((player.y + 560.0) / tile_size))
	for tx in range(left_tile, right_tile + 1):
		for ty in range(top_tile, bottom_tile + 1):
			var dest := Rect2(float(tx) * tile_size, float(ty) * tile_size, tile_size, tile_size)
			if dest.intersects(ARENA):
				var variant: int = posmod(tx * 19 + ty * 13 + tx * ty, FOREST_VARIANTS.size())
				draw_texture_rect(FOREST_VARIANTS[variant], dest, false)
	# Decorative foliage is intentionally subdued: loot and usable objects remain bright.
	for prop in scenery:
		var p: Vector2 = prop["pos"]
		if p.distance_to(player) > 825.0:
			continue
		var scale_size: float = float(prop["size"])
		match int(prop["kind"]):
			0:
				var fsize: Vector2 = Vector2(61, 55) * scale_size
				draw_texture_rect(FERN_V017, Rect2(p - fsize * 0.5, fsize), false, Color(0.72, 0.81, 0.80, 0.82))
			1:
				var rock_size: Vector2 = Vector2(60, 45) * scale_size
				draw_texture_rect(ROCK_V017, Rect2(p - rock_size * 0.5, rock_size), false, Color(0.77, 0.84, 0.90, 0.78))
			2:
				var fsize2: Vector2 = Vector2(38, 39) * scale_size
				draw_texture_rect(FERN_V017, Rect2(p - fsize2 * 0.5, fsize2), false, Color(0.60, 0.83, 0.77, 0.86))
	# Organic stone circles replace the previous repetitive square / rigid paving.
	for station in CAMP_STATIONS:
		if station.distance_to(player) > 1260.0:
			continue
		draw_v017_glow(station + Vector2(0, -100), GLOW_AMBER_V017, 760.0, 0.75)
		draw_texture_rect(CAMP_GROUND_V017, Rect2(station - Vector2(384, 384), Vector2(768, 768)), false)
		draw_circle(station, CAMP_RADIUS, Color("a3eac4", 0.020 if phase == "combat" else 0.035))
		draw_arc(station, CAMP_RADIUS - 12.0, 0.0, TAU, 80, Color("b4cea8", 0.32), 2.0)
		# Cozy embroidered tent, woodland banner, supplies, and wood fences.
		var tent_center: Vector2 = station + Vector2(-170, -168)
		draw_texture_rect(TENT_V017, Rect2(tent_center - Vector2(114, 91), Vector2(226, 172)), false)
		draw_texture_rect(BARRELS_V017, Rect2(station + Vector2(-252, 115), Vector2(88, 70)), false)
		draw_texture_rect(BANNER_V017, Rect2(station + Vector2(122, -298), Vector2(64, 168)), false)
		draw_texture_rect(FENCE_V017, Rect2(station + Vector2(-35, 270), Vector2(190, 53)), false)
		for i in range(6):
			var angle: float = TAU * float(i) / 6.0 + PI / 6.0
			var lp: Vector2 = station + Vector2.RIGHT.rotated(angle) * 318.0
			var flicker: float = 0.96 + 0.04 * sin(elapsed * 7.0 + float(i))
			draw_v017_glow(lp + Vector2(0, -57), GLOW_AMBER_V017, 230.0 * flicker, 0.70)
			draw_texture_rect(CAMP_LANTERN, Rect2(lp - Vector2(16.0, 71.0), Vector2(32.0, 65.0)), false)
			draw_circle(lp + Vector2(0, -57), 3.0 * flicker, Color("fff3b1", 0.93))
		# fireflies slowly orbit away from interaction labels
		for j in range(15):
			var theta: float = float(j) * 2.39996 + elapsed * (0.10 if j % 2 == 0 else -0.06)
			var distance: float = 95.0 + float(j % 6) * 35.0
			var firefly: Vector2 = station + Vector2(cos(theta) * distance, sin(theta) * distance * 0.70 - 29.0)
			var fade: float = 0.22 + 0.28 * (0.5 + 0.5 * sin(elapsed * 2.7 + float(j) * 3.0))
			draw_circle(firefly, 2.0, Color("b6fbd4", fade))
		draw_string(ui_font, station + Vector2(-86, -CAMP_RADIUS - 17), "✦ 月光キャンプ / 安全区域", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("f6deb0"))
	# Trees and ruined rune-stones flank the camp without covering the action or pickups.
	var grove := [Vector2(700, 485), Vector2(745, 1220), Vector2(1570, 385), Vector2(1570, 1415), Vector2(2060, 620), Vector2(2400, 1455), Vector2(2820, 650), Vector2(3050, 2320)]
	for tree_pos in grove:
		if tree_pos.distance_to(player) < 850.0:
			draw_texture_rect(FOREST_TREE_V017, Rect2(tree_pos - Vector2(95, 170), Vector2(190, 191)), false)
	for rune_pos in [Vector2(1640, 760), Vector2(1940, 1720), Vector2(2650, 1050), Vector2(2950, 1670)]:
		if rune_pos.distance_to(player) < 800.0:
			draw_v017_glow(rune_pos - Vector2(0, 30), GLOW_MOON_V017, 195.0, 0.32)
			draw_texture_rect(RUNE_V017, Rect2(rune_pos - Vector2(36, 111), Vector2(72, 104)), false)
	draw_rect(ARENA, Color("5d8584", 0.72), false, 3.0)

func _draw() -> void:
	draw_fantasy_ground()
	draw_farm_and_kitchen()
	draw_stash_chest()
	draw_meal_displays()
	draw_corpses()
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
		if bullet["kind"] == "kunai":
			var direction: Vector2 = (bullet["vel"] as Vector2).normalized()
			draw_line(pos - direction * 13.0, pos + direction * 9.0, Color("a49ad2"), 4.0)
			draw_colored_polygon(PackedVector2Array([pos + direction * 15.0, pos + direction.rotated(2.4) * 8.0, pos + direction.rotated(-2.4) * 8.0]), Color("e9e0ff"))
		elif bullet["kind"] == "arrow":
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
	draw_impact_fx()
	draw_companion()
	draw_wanderer()
	draw_rabbit_pet()
	draw_shadow_clones()
	var player_center := player
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
	if class_id == 6:
		# Ninja mask and headband, layered over the hero's existing sprite.
		draw_rect(Rect2(player_center + Vector2(-19, -35 - jump_height), Vector2(38, 16)), Color("28233f"))
		draw_line(player_center + Vector2(-19, -39 - jump_height), player_center + Vector2(21, -39 - jump_height), Color("a96eff"), 4.0)
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
				draw_equipped_greatsword(player_center + Vector2(0, walk_bob - jump_height), rarity, fighting)
			7:
				var tip: Vector2 = player + Vector2.RIGHT.rotated(aim_angle) * (61.0 if fighting else 45.0)
				draw_line(player + Vector2(0, -7), tip, Color("abb2cc"), 4.0)
				draw_colored_polygon(PackedVector2Array([tip + Vector2.RIGHT.rotated(aim_angle) * 15.0, tip + Vector2.RIGHT.rotated(aim_angle + 2.2) * 8.0, tip + Vector2.RIGHT.rotated(aim_angle - 2.2) * 8.0]), Color("d6c9f4"))
		if fighting and wtype >= 2 and wtype <= 3:
			var radius := 110.0 if wtype == 2 else 155.0
			var sweep := 0.95 if wtype == 2 else 1.21
			var opacity := clampf(attack_clock / attack_duration, 0.0, 1.0)
			draw_arc(player, radius + 5.0, aim_angle - sweep, aim_angle + sweep, 35, Color(color, opacity * 0.20), 25.0 if wtype == 3 else 17.0)
			draw_arc(player, radius, aim_angle - sweep, aim_angle + sweep, 35, Color(color, opacity * 0.91), 10.0 if wtype == 3 else 7.0)
			draw_arc(player, radius - 12.0, aim_angle - sweep, aim_angle + sweep, 35, Color("fff6e3", opacity * 0.75), 2.5)
			draw_arc(player, radius * 0.86, aim_angle - sweep + 0.18, aim_angle + sweep + 0.18, 35, Color(color, opacity * 0.38), 14.0)
			var tip_a := aim_angle + sweep
			var tip := player + Vector2.RIGHT.rotated(tip_a) * radius
			draw_line(tip, tip + Vector2.RIGHT.rotated(tip_a + 0.9) * 24.0, Color("ffffff", opacity), 3.0)
	# Shield and parry visual, facing the mouse.
	if guard_active:
		var shield_color: Color = Color("ffe59a") if guard_parry_clock > 0.0 else Color("7bd7ff")
		draw_arc(player, 48.0, aim_angle - GUARD_HALF_ANGLE, aim_angle + GUARD_HALF_ANGLE, 38, shield_color, 8.0)
		draw_arc(player, 39.0, aim_angle - GUARD_HALF_ANGLE + 0.12, aim_angle + GUARD_HALF_ANGLE - 0.12, 32, Color(shield_color, 0.45), 3.0)
		if guard_parry_clock > 0.0:
			draw_arc(player, 57.0, aim_angle - GUARD_HALF_ANGLE, aim_angle + GUARD_HALF_ANGLE, 34, Color("fff4b5", 0.42), 3.0)
	if parry_flash_clock > 0.0:
		draw_arc(player, 66.0 + 28.0 * (1.0 - parry_flash_clock / 0.46), 0.0, TAU, 50, Color("ffe9a3", clampf(parry_flash_clock * 1.85, 0.0, 1.0)), 7.0)
	if brute_flash_clock > 0.0:
		draw_rect(Rect2(player - SIZE * 0.5, SIZE), Color("bb93ff", minf(0.08, brute_flash_clock * 0.4)))
	if critical_flash_clock > 0.0:
		draw_rect(Rect2(player - SIZE * 0.5, SIZE), Color("ffedab", 0.13 * critical_flash_clock / 0.11))
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
	draw_string(ui_font, player + Vector2(-26, -69), "%d/%d" % [maxi(0, roundi(hp)), roundi(max_hp)], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f8fff9"))
	if state != "playing":
		draw_rect(ARENA, Color(0.02, 0.04, 0.09, 0.67))
