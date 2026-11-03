extends Node2D
# Survival-first world: a continuous DayZ-style sandbox, not an extraction/WAVE match.
# This prototype deliberately leaves the original game at scenes/main.tscn intact.
const WOLF = preload("res://assets/ookami.png")
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
	for i in range(85):
		caches.append({"position": random_position(), "item": random.randi_range(0, ITEM_NAMES.size() - 1), "cooldown": 0.0})
	for i in range(26):
		spawn_zombie()
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
	var sprint := movement.length_squared() > 0.0 and Input.is_key_pressed(KEY_SHIFT) and food > 10.0 and water > 10.0
	if movement.length_squared() > 0.0:
		survivor = (survivor + movement.normalized() * (370.0 if sprint else 235.0) * delta).clamp(BOUNDS.position + Vector2(32, 32), BOUNDS.end - Vector2(32, 32))
	camera.position = survivor
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
		if distance < 410.0 and distance > 38.0:
			zombie["position"] = at.move_toward(survivor, 109.0 * delta)
		zombie["attack"] = maxf(0.0, float(zombie["attack"]) - delta)
		if distance < 44.0 and float(zombie["attack"]) <= 0.0:
			zombie["attack"] = 1.8
			hurt(11.0)
			if random.randf() < 0.24: bleeding = true
			if random.randf() < 0.08: infection = true
			if dead: break
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

func interact() -> void:
	for i in range(corpses.size() - 1, -1, -1):
		var corpse: Dictionary = corpses[i]
		if survivor.distance_to(corpse["position"]) < 72.0:
			for key in corpse["items"].keys():
				carried[key] = int(carried.get(key, 0)) + int(corpse["items"][key])
			corpses.remove_at(i)
			say("遺体から持ち物を回収")
			return
	for shelter in shelters:
		if survivor.distance_to(shelter) < 110.0:
			var count := 0
			for key in ITEM_NAMES:
				var amount := int(carried.get(key, 0))
				stored[key] = int(stored.get(key, 0)) + amount
				carried[key] = 0
				count += amount
			say("拠点に%d個保管。死亡しても保管物は残る" % count)
			save_survivor()
			return
	for cache in caches:
		if float(cache["cooldown"]) <= 0.0 and survivor.distance_to(cache["position"]) < 72.0:
			var name: String = ITEM_NAMES[int(cache["item"])]
			carried[name] = int(carried[name]) + 1
			cache["cooldown"] = 270.0
			say("%sを発見！" % name)
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
	if attack_clock > 0.0: return
	if shoot and int(carried["弾薬"]) <= 0:
		say("弾薬がない")
		return
	if shoot: carried["弾薬"] = int(carried["弾薬"]) - 1
	attack_clock = 0.65 if shoot else 0.88
	var closest := 480.0 if shoot else 75.0
	var target := -1
	for i in range(zombies.size()):
		var distance: float = (zombies[i]["position"] as Vector2).distance_to(survivor)
		if distance < closest:
			closest = distance
			target = i
	if target < 0: return
	zombies[target]["health"] = float(zombies[target]["health"]) - (95.0 if shoot else 48.0)
	if float(zombies[target]["health"]) <= 0.0:
		var at: Vector2 = zombies[target]["position"]
		zombies.remove_at(target)
		if random.randf() < 0.35:
			caches.append({"position": at, "item": random.randi_range(0, ITEM_NAMES.size() - 1), "cooldown": 0.0})
		say("感染者を倒した")

func hurt(amount: float) -> void:
	if dead: return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		dead = true
		corpses.append({"position": survivor, "items": carried.duplicate(true)})
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
	survived = 0.0
	bag_open = false
	dead = false
	say("新しい生存者として再出発。前の遺体は現地に残る")
	save_survivor()

func save_survivor() -> void:
	var coords: Array = []
	for shelter in shelters: coords.append([shelter.x, shelter.y])
	var data := {
		"version": 1, "position": [survivor.x, survivor.y], "health": health,
		"food": food, "water": water, "warmth": warmth,
		"bleeding": bleeding, "infection": infection, "dead": dead,
		"carried": carried, "stored": stored, "shelters": coords,
		"world_clock": world_clock, "survived": survived
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
	var saved_shelters: Variant = data.get("shelters", [])
	if saved_shelters is Array:
		for at in saved_shelters:
			if at is Array and at.size() == 2 and shelters.size() < 32:
				shelters.append(Vector2(float(at[0]), float(at[1])).clamp(BOUNDS.position, BOUNDS.end))

func say(words: String) -> void:
	if notice != null: notice.text = words
	notice_clock = 5.0

func refresh_hud() -> void:
	if hud == null: return
	var time_of_day := "夜" if fmod(world_clock, 840.0) > 540.0 else "昼"
	var zone := "禁域" if survivor.x > 3650.0 else ("廃墟" if survivor.x > 1850.0 else "森")
	hud.text = "DOPAGAKI / 生存サンドボックス  %s %s\nHP%d  空腹%d  水分%d  体温%d  生存%d分" % [zone, time_of_day, roundi(health), roundi(food), roundi(water), roundi(warmth), int(survived / 60.0)]
	if bleeding: hud.text += "  [出血]"
	if infection: hud.text += "  [感染]"
	if raining: hud.text += "  [雨]"
	info.text = "死亡: [R] 新しい生存者で再開" if dead else "WASD移動 Shift走る | E拾う・預ける G取り出す | Space近接 J射撃 | Bバッグ Z食料 X水 Y包帯 C工作 F拠点"
	bag.visible = bag_open
	if bag_open:
		var lines: Array[String] = ["持ち物  [B]閉じる"]
		for key in ITEM_NAMES: lines.append("%s : %d" % [key, int(carried[key])])
		lines.append("拠点保管庫:")
		for key in ITEM_NAMES: lines.append("%s : %d" % [key, int(stored.get(key, 0))])
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
			draw_rect(Rect2(at - Vector2(10, 10), Vector2(20, 20)), ITEM_COLORS[int(cache["item"])])
	for corpse in corpses:
		draw_circle(corpse["position"], 19.0, Color("ad7f83"))
	for zombie in zombies:
		draw_circle(zombie["position"], 22.0, Color("b95750"))
		draw_circle(zombie["position"] + Vector2(7, -6), 5.0, Color("f1b09b"))
	draw_texture_rect(WOLF, Rect2(survivor - Vector2(27, 27), Vector2(54, 54)), false)
	if fmod(world_clock, 840.0) > 540.0:
		draw_rect(BOUNDS, Color(0.02, 0.04, 0.11, 0.27))
	if raining:
		draw_rect(BOUNDS, Color(0.12, 0.18, 0.28, 0.11))
