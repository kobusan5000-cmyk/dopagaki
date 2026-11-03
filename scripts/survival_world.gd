extends Node2D
# Survival-first world: a continuous DayZ-style sandbox, not an extraction/WAVE match.
# This prototype deliberately leaves the original game at scenes/main.tscn intact.
const WOLF = preload("res://assets/ookami.png")
const WOLF_WALK = preload("res://assets/ookami_walk.png")
const MINT_WALK = preload("res://assets/mint_companion_walk.png")
const CHUBURA = preload("res://assets/visual_v017/bunny_portrait.png")
const PIERO_WALK = preload("res://assets/piero_walk.png")
const LOADOUT = preload("res://scripts/survival_loadout.gd")
const WEAPON_ICONS = [
	preload("res://assets/item_icons/weapon_0.png"),
	preload("res://assets/item_icons/weapon_1.png"),
	preload("res://assets/item_icons/weapon_2.png"),
	preload("res://assets/item_icons/weapon_3.png"),
	preload("res://assets/item_icons/weapon_4.png"),
	preload("res://assets/item_icons/weapon_5.png"),
	preload("res://assets/item_icons/weapon_6.png"),
	preload("res://assets/item_icons/weapon_7.png")
]
const SAVE_FILE := "user://dopagaki_world_v1.json"
const BOUNDS := Rect2(0, 0, 5400, 3300)
const ITEM_NAMES := ["食料", "飲料水", "包帯", "木材", "スクラップ", "弾薬"]
const ITEM_COLORS := [Color("ddc58e"), Color("85caff"), Color("f1d6dd"), Color("c29f70"), Color("b6c2c9"), Color("e9a982")]
const RESPAWN_POINTS := [Vector2(450, 550), Vector2(780, 2700), Vector2(1300, 1550)]
var random := RandomNumberGenerator.new()
var survivor := Vector2(450, 550)
var health := 100.0
var food := 82.0
var water := 78.0
var warmth := 80.0
var bleeding := false
var infection := false
var dead := false
var carried: Dictionary = {"食料": 1, "飲料水": 1, "包帯": 0, "木材": 0, "スクラップ": 0, "弾薬": 0}
var stored: Dictionary = {}
# Old weapon types and job identities now work inside the persistent world.
var class_id := 0
var equipped_weapon: Dictionary = LOADOUT.starter()
var weapon_inventory: Array[Dictionary] = []
var stored_weapons: Array[Dictionary] = []
var armor: Array[Dictionary] = [{}, {}, {}, {}]
var mint_pos := Vector2(400, 550)
var mint_health := 90.0
var mint_attack_clock := 0.0
var chubura_pos := Vector2(435, 590)
var look_dir := Vector2.RIGHT
var is_sneaking := false
var noise_timer := 0.0
var noise_origin := Vector2.ZERO
var noise_radius := 0.0
var shelters: Array[Vector2] = []
var caches: Array[Dictionary] = []
var zombies: Array[Dictionary] = []
var corpses: Array[Dictionary] = []
var world_clock := 0.0
var survived := 0.0
var spawn_clock := 0.0
var save_clock := 0.0
var attack_clock := 0.0
var raining := false
var weather_clock := 0.0
var bag_open := false
var camera: Camera2D
var hud: Label
var info: Label
var bag: Label
var notice: Label
var notice_clock := 0.0

func _ready() -> void:
	random.randomize()
	load_survivor()
	# A fixed seed keeps unlooted sites stable between restarts. Saved sites override it.
	if caches.is_empty():
		random.seed = 20261103
		for i in range(85):
			var at := random_position()
			var zone := 2 if at.x > 3650.0 else (1 if at.x > 1850.0 else 0)
			var box: Dictionary = {"position": at, "item": random.randi_range(0, ITEM_NAMES.size() - 1), "cooldown": 0.0}
			if i % 11 == 0:
				box["armor"] = {"slot": i % 4, "rarity": random.randi_range(0, zone + 1)}
			elif i % 7 == 0:
				box["weapon"] = LOADOUT.random_weapon(random, zone)
			caches.append(box)
	random.randomize()
	for i in range(26):
		spawn_zombie()
	mint_pos = survivor + Vector2(-65, 20)
	chubura_pos = survivor + Vector2(-25, 70)
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(BOUNDS.end.x)
	camera.limit_bottom = int(BOUNDS.end.y)
	add_child(camera)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = make_label(layer, Vector2(12, 12), 18)
	info = make_label(layer, Vector2(12, 581), 15)
	bag = make_label(layer, Vector2(870, 15), 17)
	notice = make_label(layer, Vector2(12, 98), 17)
	say("WASD移動 / Shift疾走 / E回収 / Space攻撃 / B持ち物")
	refresh_hud()

func make_label(layer: CanvasLayer, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f8f7ed"))
	label.add_theme_color_override("font_shadow_color", Color("14181e"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(label)
	return label

func random_position() -> Vector2:
	return Vector2(random.randf_range(110.0, BOUNDS.end.x - 110.0), random.randf_range(110.0, BOUNDS.end.y - 110.0))

func spawn_zombie() -> void:
	var at := random_position()
	if at.distance_to(survivor) < 500.0:
		at = (at + Vector2(610, 320)).clamp(BOUNDS.position, BOUNDS.end)
	zombies.append({"position": at, "health": 90.0, "attack": 0.0})

func _process(delta: float) -> void:
	if dead:
		refresh_hud()
		queue_redraw()
		return
	world_clock += delta
	survived += delta
	attack_clock = maxf(0.0, attack_clock - delta)
	notice_clock = maxf(0.0, notice_clock - delta)
	var movement := Vector2.ZERO
	if not bag_open:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): movement.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): movement.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): movement.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): movement.y += 1.0
	is_sneaking = Input.is_key_pressed(KEY_CTRL)
	var sprint := movement.length_squared() > 0.0 and Input.is_key_pressed(KEY_SHIFT) and not is_sneaking and food > 10.0 and water > 10.0
	if movement.length_squared() > 0.0:
		var speed := 135.0 if is_sneaking else (370.0 if sprint else 235.0)
		survivor = (survivor + movement.normalized() * speed * delta).clamp(BOUNDS.position + Vector2(32, 32), BOUNDS.end - Vector2(32, 32))
		look_dir = movement.normalized()
	camera.position = survivor
	noise_timer = maxf(0.0, noise_timer - delta)
	# Companions track the survivor instead of being restricted to the former safe hub.
	mint_pos = mint_pos.move_toward(survivor + Vector2(-63, 28), 285.0 * delta)
	chubura_pos = chubura_pos.move_toward(survivor + Vector2(46, 55), 260.0 * delta)
	food = maxf(0.0, food - (0.065 if sprint else 0.032) * delta)
	water = maxf(0.0, water - (0.10 if sprint else 0.051) * delta)
	var night := fmod(world_clock, 840.0) > 540.0
	warmth = clampf(warmth + (-0.17 if night or raining else 0.085) * delta, 0.0, 100.0)
	for shelter in shelters:
		if survivor.distance_to(shelter) < 120.0:
			warmth = minf(100.0, warmth + 0.40 * delta)
	if food <= 0.0 or water <= 0.0 or warmth < 10.0:
		hurt(3.0 * delta)
	if bleeding: hurt(0.55 * delta)
	if infection: hurt(0.32 * delta)
	weather_clock += delta
	if weather_clock > 150.0:
		weather_clock = 0.0
		raining = random.randf() < 0.45
	for cache in caches:
		if float(cache["cooldown"]) > 0.0:
			cache["cooldown"] = maxf(0.0, float(cache["cooldown"]) - delta)
			if float(cache["cooldown"]) <= 0.0:
				cache["item"] = random.randi_range(0, ITEM_NAMES.size() - 1)
	for zombie in zombies:
		var at: Vector2 = zombie["position"]
		var distance := survivor.distance_to(at)
		var detection := 95.0 if is_sneaking else (550.0 if sprint else 290.0)
		var noisy := noise_timer > 0.0 and at.distance_to(noise_origin) < noise_radius
		if distance < detection and distance > 38.0:
			zombie["position"] = at.move_toward(survivor, 109.0 * delta)
		elif noisy:
			zombie["position"] = at.move_toward(noise_origin, 100.0 * delta)
		zombie["attack"] = maxf(0.0, float(zombie["attack"]) - delta)
		if distance < 44.0 and float(zombie["attack"]) <= 0.0:
			zombie["attack"] = 1.8
			hurt(11.0, true)
			if random.randf() < 0.24: bleeding = true
			if random.randf() < 0.08: infection = true
			if dead: break
	mint_attack_clock = maxf(0.0, mint_attack_clock - delta)
	if mint_health > 0.0 and mint_attack_clock <= 0.0:
		for zombie in zombies:
			if (zombie["position"] as Vector2).distance_to(mint_pos) < 95.0:
				zombie["health"] = float(zombie["health"]) - 19.0
				mint_attack_clock = 3.0
				break
	for i in range(zombies.size() - 1, -1, -1):
		if float(zombies[i]["health"]) <= 0.0:
			zombies.remove_at(i)
	spawn_clock += delta
	if spawn_clock >= 13.0:
		spawn_clock = 0.0
		while zombies.size() < 26: spawn_zombie()
	save_clock += delta
	if save_clock > 30.0:
		save_clock = 0.0
		save_survivor()
	refresh_hud()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if dead:
		if event.keycode == KEY_R: new_survivor()
		return
	if event.keycode == KEY_B:
		bag_open = not bag_open
		return
	if event.keycode == KEY_ESCAPE:
		bag_open = false
		save_survivor()
		return
	if bag_open: return
	match event.keycode:
		KEY_E: interact()
		KEY_SPACE: attack(false)
		KEY_J: attack(true)
		KEY_Z: use_item("食料")
		KEY_X: use_item("飲料水")
		KEY_Y: use_item("包帯")
		KEY_F: build_shelter()
		KEY_C: craft_bandage()
		KEY_G: withdraw_from_shelter()
		KEY_V: cycle_weapon()
		KEY_H: stash_equipped_weapon()
		KEY_U: withdraw_weapon()
		KEY_I: repair_equipped_weapon()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7:
			select_class(event.keycode - KEY_1)

func interact() -> void:
	for i in range(corpses.size() - 1, -1, -1):
		var corpse: Dictionary = corpses[i]
		if survivor.distance_to(corpse["position"]) < 72.0:
			for key in ITEM_NAMES:
				carried[key] = int(carried.get(key, 0)) + int((corpse.get("items", {}) as Dictionary).get(key, 0))
			corpse["items"] = {}
			var found: Dictionary = LOADOUT.clean_weapon(corpse.get("equipped", {}))
			if not found.is_empty():
				if equipped_weapon.is_empty():
					equipped_weapon = found
					corpse["equipped"] = {}
				elif weapon_inventory.size() < 3:
					weapon_inventory.append(found)
					corpse["equipped"] = {}
			var unclaimed: Array[Dictionary] = []
			for candidate in corpse.get("weapons", []):
				var item: Dictionary = LOADOUT.clean_weapon(candidate)
				if weapon_inventory.size() < 3:
					weapon_inventory.append(item)
				else:
					unclaimed.append(item)
			corpse["weapons"] = unclaimed
			var recovered_armor: Array = corpse.get("armor", [])
			for slot in range(mini(4, recovered_armor.size())):
				if armor[slot].is_empty() and recovered_armor[slot] is Dictionary:
					armor[slot] = (recovered_armor[slot] as Dictionary).duplicate(true)
					recovered_armor[slot] = {}
			corpse["armor"] = recovered_armor
			if (corpse.get("equipped", {}) as Dictionary).is_empty() and unclaimed.is_empty() and all_armor_empty(recovered_armor):
				corpses.remove_at(i)
			say("遺体から物資と持ち込んだ装備を回収")
			save_survivor()
			return
	for shelter in shelters:
		if survivor.distance_to(shelter) < 110.0:
			var count := 0
			for key in ITEM_NAMES:
				var amount := int(carried.get(key, 0))
				stored[key] = int(stored.get(key, 0)) + amount
				carried[key] = 0
				count += amount
			say("拠点に%d個保管。装備は[H]で別途保管" % count)
			save_survivor()
			return
	for cache in caches:
		if float(cache["cooldown"]) <= 0.0 and survivor.distance_to(cache["position"]) < 72.0:
			if cache.has("weapon"):
				if weapon_inventory.size() >= 3:
					say("武器バッグ満杯。[V]で切り替え、[H]で保管")
					return
				var weapon: Dictionary = LOADOUT.clean_weapon(cache["weapon"])
				weapon_inventory.append(weapon)
				say("武器入手！ %s [V]で装備" % LOADOUT.name_for(weapon))
			elif cache.has("armor"):
				var armor_item: Dictionary = cache["armor"]
				var slot := clampi(int(armor_item.get("slot", 0)), 0, 3)
				var previous: Dictionary = armor[slot]
				armor[slot] = {"slot": slot, "rarity": clampi(int(armor_item.get("rarity", 0)), 0, 4)}
				if not previous.is_empty():
					cache["armor"] = previous
					say("防具を交換（部位%d）。前の防具はここに残った" % (slot + 1))
					return
				say("防具入手！（部位%d）" % (slot + 1))
			else:
				var name: String = ITEM_NAMES[int(cache["item"])]
				carried[name] = int(carried[name]) + 1
				say("%sを発見！" % name)
			cache["cooldown"] = 270.0
			save_survivor()
			return
	say("近くに調べるものがない")

func withdraw_from_shelter() -> void:
	for shelter in shelters:
		if survivor.distance_to(shelter) < 110.0:
			var count := 0
			for key in ITEM_NAMES:
				var amount := int(stored.get(key, 0))
				carried[key] = int(carried[key]) + amount
				stored[key] = 0
				count += amount
			say("拠点から%d個取り出した" % count)
			save_survivor()
			return
	say("拠点の近くで[G]を押してね")

func all_armor_empty(items: Array) -> bool:
	for item in items:
		if item is Dictionary and not (item as Dictionary).is_empty():
			return false
	return true

func select_class(index: int) -> void:
	if index < 0 or index >= LOADOUT.CLASS_NAMES.size():
		return
	var at_base := false
	for shelter in shelters:
		if survivor.distance_to(shelter) < 125.0:
			at_base = true
	if not at_base:
		say("職業変更は建築した拠点の近くで行う")
		return
	class_id = index
	say("職業: %s。得意武器の威力が上昇" % LOADOUT.CLASS_NAMES[index])
	save_survivor()

func cycle_weapon() -> void:
	if weapon_inventory.is_empty():
		say("予備武器がない。武器箱を探そう")
		return
	var next: Dictionary = weapon_inventory.pop_front()
	if not equipped_weapon.is_empty():
		weapon_inventory.append(equipped_weapon.duplicate(true))
	equipped_weapon = next
	say("装備: %s" % LOADOUT.name_for(equipped_weapon))
	save_survivor()

func stash_equipped_weapon() -> void:
	var near_base := false
	for shelter in shelters:
		if survivor.distance_to(shelter) < 110.0:
			near_base = true
	if not near_base or equipped_weapon.is_empty():
		say("拠点の近くで、装備中の武器を保管できる")
		return
	if stored_weapons.size() >= 24:
		say("武器保管庫がいっぱい")
		return
	stored_weapons.append(equipped_weapon.duplicate(true))
	equipped_weapon = {}
	say("武器を保管した。現在は素手")
	save_survivor()

func withdraw_weapon() -> void:
	var near_base := false
	for shelter in shelters:
		if survivor.distance_to(shelter) < 110.0:
			near_base = true
	if not near_base or stored_weapons.is_empty():
		say("武器保管庫を利用するには拠点が必要")
		return
	if not equipped_weapon.is_empty() and weapon_inventory.size() >= 3:
		say("持てる武器は装備中＋予備3本まで")
		return
	var retrieved: Dictionary = stored_weapons.pop_back()
	if equipped_weapon.is_empty():
		equipped_weapon = retrieved
	else:
		weapon_inventory.append(retrieved)
	say("武器を取り出した: %s" % LOADOUT.name_for(retrieved))
	save_survivor()

func repair_equipped_weapon() -> void:
	var fixed: Dictionary = LOADOUT.repair(equipped_weapon, int(carried.get("スクラップ", 0)))
	if fixed.is_empty():
		say("修理不可：装備中の武器とスクラップ2個が必要")
		return
	carried["スクラップ"] = int(carried["スクラップ"]) - 2
	equipped_weapon = fixed
	say("武器を修理！ 耐久%d%%" % roundi(float(equipped_weapon["condition"])))
	save_survivor()

func use_item(name: String) -> void:
	if int(carried.get(name, 0)) <= 0:
		say("%sがない。探索して見つけよう" % name)
		return
	carried[name] = int(carried[name]) - 1
	match name:
		"食料": food = minf(100.0, food + 45.0)
		"飲料水": water = minf(100.0, water + 50.0)
		"包帯":
			bleeding = false
			health = minf(100.0, health + 23.0)
	say("%sを使用" % name)

func craft_bandage() -> void:
	if int(carried["木材"]) < 1 or int(carried["スクラップ"]) < 2:
		say("包帯作成には 木材1 / スクラップ2 が必要")
		return
	carried["木材"] = int(carried["木材"]) - 1
	carried["スクラップ"] = int(carried["スクラップ"]) - 2
	carried["包帯"] = int(carried["包帯"]) + 1
	say("包帯を制作した")

func build_shelter() -> void:
	if int(carried["木材"]) < 6 or int(carried["スクラップ"]) < 3:
		say("拠点建設には 木材6 / スクラップ3 が必要")
		return
	for shelter in shelters:
		if survivor.distance_to(shelter) < 260.0:
			say("近くに拠点がある")
			return
	if shelters.size() >= 32: return
	carried["木材"] = int(carried["木材"]) - 6
	carried["スクラップ"] = int(carried["スクラップ"]) - 3
	shelters.append(survivor)
	say("拠点完成！ [E]で預ける / [G]で取り出す")
	save_survivor()

func attack(shoot: bool) -> void:
	if dead or bag_open or attack_clock > 0.0:
		return
	if shoot and not LOADOUT.is_ranged(equipped_weapon):
		say("射撃には遠距離武器が必要。武器箱で探そう")
		return
	if shoot and int(carried["弾薬"]) <= 0:
		say("弾薬がない")
		return
	if shoot:
		carried["弾薬"] = int(carried["弾薬"]) - 1
		noise_timer = 3.5
		noise_origin = survivor
		noise_radius = 830.0
	attack_clock = 0.65 if shoot else 0.88
	var reach: float = LOADOUT.range_for(equipped_weapon) if shoot else (105.0 if int(equipped_weapon.get("kind", 2)) == 3 else 80.0)
	var target := -1
	var best := reach
	for i in range(zombies.size()):
		var direction: Vector2 = (zombies[i]["position"] as Vector2) - survivor
		var distance := direction.length()
		if distance < best and distance > 0.01 and direction.normalized().dot(look_dir) >= (0.72 if shoot else 0.40):
			best = distance
			target = i
	if not equipped_weapon.is_empty():
		equipped_weapon = LOADOUT.worn(equipped_weapon)
	if target < 0:
		return
	var impact := LOADOUT.damage_for(equipped_weapon, class_id) if (shoot or not LOADOUT.is_ranged(equipped_weapon)) else 18.0
	zombies[target]["health"] = float(zombies[target]["health"]) - impact
	if float(zombies[target]["health"]) <= 0.0:
		var at: Vector2 = zombies[target]["position"]
		zombies.remove_at(target)
		if random.randf() < 0.28:
			caches.append({"position": at, "item": random.randi_range(0, ITEM_NAMES.size() - 1), "cooldown": 0.0})
		say("感染者を倒した")

func hurt(amount: float, combat: bool = false) -> void:
	if dead:
		return
	var protection := 0.0
	if combat:
		for piece in armor:
			if not piece.is_empty():
				protection += 0.035 + 0.025 * float(piece.get("rarity", 0))
	health = maxf(0.0, health - amount * (1.0 - minf(0.55, protection)))
	if health <= 0.0:
		dead = true
		corpses.append({"position": survivor, "items": carried.duplicate(true), "equipped": equipped_weapon.duplicate(true), "weapons": weapon_inventory.duplicate(true), "armor": armor.duplicate(true)})
		say("死亡！持ち物を落とした。[R]で新しい生存者")
		save_survivor()

func new_survivor() -> void:
	survivor = RESPAWN_POINTS[random.randi_range(0, RESPAWN_POINTS.size() - 1)]
	health = 100.0
	food = 82.0
	water = 78.0
	warmth = 80.0
	bleeding = false
	infection = false
	carried = {"食料": 1, "飲料水": 1, "包帯": 0, "木材": 0, "スクラップ": 0, "弾薬": 0}
	equipped_weapon = LOADOUT.starter()
	weapon_inventory.clear()
	armor = [{}, {}, {}, {}]
	mint_health = 90.0
	mint_pos = survivor + Vector2(-65, 20)
	chubura_pos = survivor + Vector2(46, 55)
	survived = 0.0
	bag_open = false
	dead = false
	say("新しい生存者として再出発。前の遺体は現地に残る")
	save_survivor()

func save_survivor() -> void:
	var coords: Array = []
	for shelter in shelters: coords.append([shelter.x, shelter.y])
	var saved_caches: Array = []
	for cache in caches:
		var at: Vector2 = cache["position"]
		var item: Dictionary = {"position": [at.x, at.y], "item": int(cache["item"]), "cooldown": float(cache["cooldown"])}
		if cache.has("weapon"):
			item["weapon"] = cache["weapon"]
		if cache.has("armor"):
			item["armor"] = cache["armor"]
		saved_caches.append(item)
	var saved_corpses: Array = []
	for corpse in corpses:
		var at: Vector2 = corpse["position"]
		saved_corpses.append({"position": [at.x, at.y], "items": corpse.get("items", {}), "equipped": corpse.get("equipped", {}), "weapons": corpse.get("weapons", []), "armor": corpse.get("armor", [])})
	var data := {
		"version": 2, "position": [survivor.x, survivor.y], "health": health,
		"food": food, "water": water, "warmth": warmth,
		"bleeding": bleeding, "infection": infection, "dead": dead,
		"carried": carried, "stored": stored, "shelters": coords,
		"world_clock": world_clock, "survived": survived,
		"class_id": class_id, "equipped_weapon": equipped_weapon,
		"weapon_inventory": weapon_inventory, "stored_weapons": stored_weapons,
		"armor": armor, "caches": saved_caches, "corpses": saved_corpses
	}
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(data))

func load_survivor() -> void:
	if not FileAccess.file_exists(SAVE_FILE): return
	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null: return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary: return
	var coords: Variant = data.get("position", [])
	if coords is Array and coords.size() == 2:
		survivor = Vector2(float(coords[0]), float(coords[1])).clamp(BOUNDS.position, BOUNDS.end)
	health = clampf(float(data.get("health", health)), 0.0, 100.0)
	food = clampf(float(data.get("food", food)), 0.0, 100.0)
	water = clampf(float(data.get("water", water)), 0.0, 100.0)
	warmth = clampf(float(data.get("warmth", warmth)), 0.0, 100.0)
	bleeding = bool(data.get("bleeding", false))
	infection = bool(data.get("infection", false))
	dead = bool(data.get("dead", false))
	world_clock = maxf(0.0, float(data.get("world_clock", 0.0)))
	survived = maxf(0.0, float(data.get("survived", 0.0)))
	var saved_carried: Variant = data.get("carried", {})
	var saved_stored: Variant = data.get("stored", {})
	for key in ITEM_NAMES:
		if saved_carried is Dictionary:
			carried[key] = clampi(int(saved_carried.get(key, carried[key])), 0, 999)
		if saved_stored is Dictionary:
			stored[key] = clampi(int(saved_stored.get(key, 0)), 0, 999)
	class_id = clampi(int(data.get("class_id", 0)), 0, 6)
	equipped_weapon = LOADOUT.clean_weapon(data.get("equipped_weapon", LOADOUT.starter()))
	weapon_inventory = LOADOUT.clean_weapons(data.get("weapon_inventory", []), 3)
	stored_weapons = LOADOUT.clean_weapons(data.get("stored_weapons", []), 24)
	var saved_armor: Variant = data.get("armor", [])
	if saved_armor is Array:
		for i in range(mini(4, saved_armor.size())):
			if saved_armor[i] is Dictionary and not (saved_armor[i] as Dictionary).is_empty():
				armor[i] = {"slot": i, "rarity": clampi(int(saved_armor[i].get("rarity", 0)), 0, 4)}
	var saved_shelters: Variant = data.get("shelters", [])
	if saved_shelters is Array:
		for at in saved_shelters:
			if at is Array and at.size() == 2 and shelters.size() < 32:
				shelters.append(Vector2(float(at[0]), float(at[1])).clamp(BOUNDS.position, BOUNDS.end))
	var saved_caches: Variant = data.get("caches", [])
	if saved_caches is Array:
		for box in saved_caches:
			if not box is Dictionary or caches.size() >= 130:
				continue
			var xy: Variant = box.get("position", [])
			if not xy is Array or xy.size() != 2:
				continue
			var at := Vector2(float(xy[0]), float(xy[1])).clamp(BOUNDS.position, BOUNDS.end)
			var cache: Dictionary = {"position": at, "item": clampi(int(box.get("item", 0)), 0, ITEM_NAMES.size() - 1), "cooldown": clampf(float(box.get("cooldown", 0.0)), 0.0, 270.0)}
			if box.has("weapon"):
				var item: Dictionary = LOADOUT.clean_weapon(box["weapon"])
				if not item.is_empty(): cache["weapon"] = item
			if box.has("armor") and box["armor"] is Dictionary:
				cache["armor"] = {"slot": clampi(int(box["armor"].get("slot", 0)), 0, 3), "rarity": clampi(int(box["armor"].get("rarity", 0)), 0, 4)}
			caches.append(cache)
	var saved_corpses: Variant = data.get("corpses", [])
	if saved_corpses is Array:
		for body in saved_corpses:
			if not body is Dictionary or corpses.size() >= 30:
				continue
			var xy: Variant = body.get("position", [])
			if not xy is Array or xy.size() != 2:
				continue
			var items: Dictionary = {}
			var raw_items: Variant = body.get("items", {})
			if raw_items is Dictionary:
				for key in ITEM_NAMES:
					items[key] = clampi(int(raw_items.get(key, 0)), 0, 999)
			var body_armor: Array = body.get("armor", []) if body.get("armor", []) is Array else []
			corpses.append({"position": Vector2(float(xy[0]), float(xy[1])).clamp(BOUNDS.position, BOUNDS.end), "items": items, "equipped": LOADOUT.clean_weapon(body.get("equipped", {})), "weapons": LOADOUT.clean_weapons(body.get("weapons", []), 3), "armor": body_armor})

func say(words: String) -> void:
	if notice != null: notice.text = words
	notice_clock = 5.0

func refresh_hud() -> void:
	if hud == null: return
	var time_of_day := "夜" if fmod(world_clock, 840.0) > 540.0 else "昼"
	var zone := "禁域" if survivor.x > 3650.0 else ("廃墟" if survivor.x > 1850.0 else "森")
	hud.text = "DOPAGAKI / %s %s | %s\nHP%d  空腹%d  水分%d  体温%d  生存%d分\n装備: %s  耐久%d%% | 予備%d/3 防具%d/4" % [zone, time_of_day, LOADOUT.CLASS_NAMES[class_id], roundi(health), roundi(food), roundi(water), roundi(warmth), int(survived / 60.0), LOADOUT.name_for(equipped_weapon), roundi(float(equipped_weapon.get("condition", 0.0))), weapon_inventory.size(), 4 - int(armor[0].is_empty()) - int(armor[1].is_empty()) - int(armor[2].is_empty()) - int(armor[3].is_empty())]
	if bleeding: hud.text += "  [出血]"
	if infection: hud.text += "  [感染]"
	if raining: hud.text += "  [雨]"
	info.text = "死亡: [R] 新しい生存者で再開" if dead else "WASD/Shift走る/Ctrl静音 | E拾う・預ける G引出 | Space近接 J射撃 V武器 | Bバッグ Z食 X水 Y包帯 C工作 F拠点 H/U保管 I修理 1-7職"
	bag.visible = bag_open
	if bag_open:
		var lines: Array[String] = ["持ち物  [B]閉じる"]
		for key in ITEM_NAMES: lines.append("%s : %d" % [key, int(carried[key])])
		lines.append("装備中: %s" % LOADOUT.name_for(equipped_weapon))
		for item in weapon_inventory:
			lines.append("予備: %s（%d%%）" % [LOADOUT.name_for(item), roundi(float(item["condition"]))])
		lines.append("防具: %d/4" % (4 - int(armor[0].is_empty()) - int(armor[1].is_empty()) - int(armor[2].is_empty()) - int(armor[3].is_empty())))
		lines.append("拠点物資:")
		for key in ITEM_NAMES: lines.append("%s : %d" % [key, int(stored.get(key, 0))])
		lines.append("保管武器: %d" % stored_weapons.size())
		bag.text = "\n".join(lines)
	notice.visible = notice_clock > 0.0

func _draw() -> void:
	draw_rect(BOUNDS, Color("284334"))
	draw_rect(Rect2(1850, 0, 1800, 3300), Color("49483e"))
	draw_rect(Rect2(3650, 0, 1750, 3300), Color("473c3a"))
	for i in range(200):
		var at := Vector2(float((i * 739 + 173) % 5200 + 95), float((i * 487 + 141) % 3100 + 95))
		if at.x < 1850.0:
			draw_circle(at, 27.0, Color("3c6145"))
			draw_circle(at + Vector2(-7, -6), 16.0, Color("4f7550"))
		else:
			draw_rect(Rect2(at - Vector2(30, 19), Vector2(60, 38)), Color("727064"))
	for shelter in shelters:
		draw_rect(Rect2(shelter - Vector2(44, 30), Vector2(88, 60)), Color("b39168"))
		draw_rect(Rect2(shelter - Vector2(44, 30), Vector2(88, 60)), Color("f1e0b1"), false, 3.0)
	for cache in caches:
		if float(cache["cooldown"]) <= 0.0:
			var at: Vector2 = cache["position"]
			var tint := Color("f6d47d") if cache.has("weapon") else (Color("a9b8fa") if cache.has("armor") else ITEM_COLORS[int(cache["item"])])
			draw_rect(Rect2(at - Vector2(13, 13), Vector2(26, 26)), tint)
			if cache.has("weapon"):
				var kind := int(cache["weapon"].get("kind", 2))
				draw_texture_rect(WEAPON_ICONS[clampi(kind, 0, 7)], Rect2(at - Vector2(15, 15), Vector2(30, 30)), false)
			elif cache.has("armor"):
				draw_rect(Rect2(at - Vector2(6, 8), Vector2(12, 16)), Color("424866"), false, 3.0)
	for corpse in corpses:
		draw_circle(corpse["position"], 19.0, Color("ad7f83"))
	for zombie in zombies:
		draw_sheet_first_frame(PIERO_WALK, zombie["position"], 49.0)
	# Use the original playable wolf and Mint's authored walk sheets.
	draw_sheet_first_frame(MINT_WALK, mint_pos, 48.0)
	draw_texture_rect(CHUBURA, Rect2(chubura_pos - Vector2(21, 21), Vector2(42, 42)), false)
	draw_sheet_first_frame(WOLF_WALK, survivor, 55.0)
	if not equipped_weapon.is_empty():
		draw_texture_rect(WEAPON_ICONS[clampi(int(equipped_weapon.get("kind", 2)), 0, 7)], Rect2(survivor + Vector2(16, 6), Vector2(23, 23)), false)
	# One subtle marker per nearby cache: Chubura helps locate supplies.
	for cache in caches:
		if float(cache["cooldown"]) <= 0.0 and chubura_pos.distance_to(cache["position"]) < 160.0:
			draw_arc(cache["position"], 30.0, 0.0, TAU, 20, Color("ffecac", 0.72), 2.0)

	if fmod(world_clock, 840.0) > 540.0:
		draw_rect(BOUNDS, Color(0.02, 0.04, 0.11, 0.27))
	if raining:
		draw_rect(BOUNDS, Color(0.12, 0.18, 0.28, 0.11))

# The walk animations are horizontal sprite strips. Keep the first frame visible
# even when asset sheets use different pixel dimensions.
func draw_sheet_first_frame(texture: Texture2D, at: Vector2, size: float) -> void:
	var frame_width := float(mini(texture.get_width(), texture.get_height()))
	draw_texture_rect_region(texture, Rect2(at - Vector2(size * 0.5, size * 0.5), Vector2(size, size)), Rect2(Vector2.ZERO, Vector2(frame_width, frame_width)))
