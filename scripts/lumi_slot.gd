extends PanelContainer
## In-game Godot port of the user-provided LUMI SLOT HTML.
## Purely virtual DOPAGAKI coins; there is no cash purchase or redemption.

signal wager_requested(cost: int)
signal spin_resolved(outcome: String, payout: int)
signal reel_stopped(index: int)
signal close_requested

const BET_GOLD := 25
const SYMBOLS := ["7", "BAR", "🍉", "🍒", "🍇", "↻"]
# BIG + REG is about one win in 4.5 spins, permanently fixed to setting 6.
# Fantasy game rates (not real-world slot machine probabilities).
# Setting 6 is permanently active; no player-adjustable odds.
const BIG_ODDS := 17.0
const REG_ODDS := 6.2
# Balanced against a 25G entry cost and much more frequent gear drops.
const ROLE_PAYOUT := {"BIG": 160, "REG": 60, "GRAPE": 8, "CHERRY": 2, "REPLAY": 0, "MISS": 0}
const RESULT_NAMES := {"BIG": "BIG BONUS!!", "REG": "REG BONUS!", "GRAPE": "🍇 ぶどう", "CHERRY": "🍒 チェリー", "REPLAY": "↻ リプレイ！", "MISS": "はずれ…"}

var wallet := 0
var replay_pending := false
var auto_play := false
var spinning := false
var spin_time := 0.0
var reel_tick := 0.0
var auto_wait := -1.0
var result_name := "MISS"
var stopped: Array[bool] = [true, true, true]
var center_symbols: Array[String] = ["7", "🍇", "BAR"]
var reel_tiles: Array = []
var _miss_result: Array[String] = ["7", "🍉", "BAR"]
var stop_buttons: Array[Button] = []
var balance_label: Label
var prize_label: Label
var info_label: Label
var result_label: Label
var big_lamp: Label
var reg_lamp: Label
var chance_lamp: Label
var stats_label: Label
var odds_label: Label
var graph_label: Label
var spin_button: Button
var auto_button: Button
var close_button: Button
var rng := RandomNumberGenerator.new()
var games := 0
var big_count := 0
var reg_count := 0
var grape_count := 0
var cherry_count := 0
var replay_count := 0
var medals_in := 0
var medals_out := 0
var history: Array[int] = [0]

func _ready() -> void:
	rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := _style(Color("24202c"), Color("aa8758"), 14)
	bg.set_border_width_all(3)
	add_theme_stylebox_override("panel", bg)
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 16)
	padding.add_theme_constant_override("margin_right", 16)
	padding.add_theme_constant_override("margin_top", 10)
	padding.add_theme_constant_override("margin_bottom", 12)
	add_child(padding)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(665, 550)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	padding.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	scroll.add_child(body)

	var heading := _label("✦ LUMI SLOT ✦", 28, Color("ffe4aa"), true)
	body.add_child(heading)
	body.add_child(_label("キャンプの遊技台｜ゲーム内Gだけを使用・換金なし", 12, Color("bcb4cf"), true))

	var money_row := HBoxContainer.new()
	money_row.add_theme_constant_override("separation", 12)
	balance_label = _label("", 18, Color("8be3c0"))
	balance_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money_row.add_child(balance_label)
	prize_label = _label("", 17, Color("ffe1a4"))
	money_row.add_child(prize_label)
	body.add_child(money_row)

	var lamp_row := HBoxContainer.new()
	lamp_row.add_theme_constant_override("separation", 10)
	big_lamp = _lamp("BIG", Color("ff6c73"))
	lamp_row.add_child(big_lamp)
	chance_lamp = _lamp("LUMI!", Color("ffe5a0"))
	lamp_row.add_child(chance_lamp)
	reg_lamp = _lamp("REG", Color("c0a0ff"))
	lamp_row.add_child(reg_lamp)
	body.add_child(lamp_row)

	var reels_row := HBoxContainer.new()
	reels_row.add_theme_constant_override("separation", 10)
	for i in range(3):
		var reel := PanelContainer.new()
		reel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reel.add_theme_stylebox_override("panel", _style(Color("f2efeb"), Color("776979"), 8))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		reel.add_child(col)
		var tiles: Array = []
		for j in range(3):
			var label := _label("7", 25 if j == 1 else 21, Color("862e55"), true)
			label.custom_minimum_size = Vector2(0, 43 if j == 1 else 33)
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if j == 1:
				label.add_theme_stylebox_override("normal", _style(Color("fff2c8"), Color("e1ac50"), 1))
			col.add_child(label)
			tiles.append(label)
		reel_tiles.append(tiles)
		reels_row.add_child(reel)
	body.add_child(reels_row)
	body.add_child(_label("◀ 中央1ライン有効 ▶　　リール停止順は自由", 12, Color("eac995"), true))

	var stop_row := HBoxContainer.new()
	stop_row.add_theme_constant_override("separation", 12)
	for i in range(3):
		var b := _button("STOP %d" % (i + 1), Color("b94b68"), 14)
		b.custom_minimum_size = Vector2(0, 38)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = true
		b.pressed.connect(stop_reel.bind(i))
		stop_row.add_child(b)
		stop_buttons.append(b)
	body.add_child(stop_row)

	result_label = _label("レバーONでスタート", 18, Color("ffe7b3"), true)
	result_label.custom_minimum_size = Vector2(0, 30)
	body.add_child(result_label)
	var spin_row := HBoxContainer.new()
	spin_row.add_theme_constant_override("separation", 8)
	spin_button = _button("レバーON", Color("e7b665"), 17)
	spin_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_button.custom_minimum_size = Vector2(0, 42)
	spin_button.pressed.connect(_request_wager)
	spin_row.add_child(spin_button)
	auto_button = _button("自動 OFF", Color("46bab4"), 13)
	auto_button.custom_minimum_size = Vector2(105, 42)
	auto_button.pressed.connect(_toggle_auto)
	spin_row.add_child(auto_button)
	body.add_child(spin_row)

	odds_label = _label("", 12, Color("a9e5e0"), true)
	body.add_child(odds_label)
	stats_label = _label("", 13, Color("f4e3cc"), true)
	body.add_child(stats_label)
	graph_label = _label("", 13, Color("b9d6ef"), true)
	body.add_child(graph_label)
	info_label = _label("Space: レバー　1・2・3: 停止　Esc/E: 閉じる", 12, Color("bfb9ce"), true)
	body.add_child(info_label)
	close_button = _button("ゲームへ戻る [E / Esc]", Color("aa9ad4"), 13)
	close_button.pressed.connect(func() -> void: close_requested.emit())
	body.add_child(close_button)
	for i in range(3):
		_paint_reel(i, center_symbols[i])
	_update_info()

func _style(fill: Color, edge: Color, rad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(2)
	s.set_corner_radius_all(rad)
	return s

func _label(text_value: String, font_size: int, tint: Color, center: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	if center:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _button(text_value: String, tint: Color, size: int) -> Button:
	var b := Button.new()
	b.text = text_value
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color("f5f0ec"))
	b.add_theme_stylebox_override("normal", _style(Color("383041"), tint, 8))
	b.add_theme_stylebox_override("hover", _style(Color("53415c"), tint.lightened(0.2), 8))
	b.add_theme_stylebox_override("pressed", _style(Color("5e3945"), Color("fff0b7"), 8))
	return b

func _lamp(value: String, tint: Color) -> Label:
	var l := _label(value, 19, Color("61596f"), true)
	l.custom_minimum_size = Vector2(100, 42)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_stylebox_override("normal", _style(Color("17131c"), tint.darkened(0.60), 12))
	return l

func _light_lamps(outcome: String) -> void:
	big_lamp.add_theme_color_override("font_color", Color("ff7474") if outcome == "BIG" else Color("61596f"))
	reg_lamp.add_theme_color_override("font_color", Color("c4a0ff") if outcome == "REG" else Color("61596f"))
	chance_lamp.add_theme_color_override("font_color", Color("fff2b1") if outcome in ["BIG", "REG"] else Color("61596f"))

func _paint_reel(index: int, center: String) -> void:
	var pos: int = SYMBOLS.find(center)
	if pos < 0:
		pos = 0
	var reel: Array = reel_tiles[index]
	reel[0].text = str(SYMBOLS[(pos + 1 + index) % SYMBOLS.size()])
	reel[1].text = center
	reel[2].text = str(SYMBOLS[(pos + 3 + index) % SYMBOLS.size()])
	var tone_color := Color("df4770") if center in ["7", "🍒"] else (Color("9268c0") if center == "BAR" else Color("387e6b"))
	reel[1].add_theme_color_override("font_color", tone_color)

func set_wallet(value: int) -> void:
	wallet = maxi(0, value)
	_update_info()

func _update_info() -> void:
	if balance_label == null:
		return
	balance_label.text = "所持金 %dG ｜ 1回 %dG" % [wallet, BET_GOLD]
	if replay_pending:
		balance_label.text += " ｜ 次回無料！"
	spin_button.disabled = spinning or auto_play or (wallet < BET_GOLD and not replay_pending)
	close_button.disabled = spinning
	auto_button.text = "自動 ON" if auto_play else "自動 OFF"
	auto_button.disabled = spinning and not auto_play
	var comb: float = 1.0 / (1.0 / BIG_ODDS + 1.0 / REG_ODDS)
	odds_label.text = "BIG 1/%.1f　 REG 1/%.1f　 合算 1/%.1f" % [BIG_ODDS, REG_ODDS, comb]
	var balance: int = medals_out - medals_in
	stats_label.text = "G数 %d　 BIG %d　 REG %d　 差枚 %s枚　ぶどう%d / チェリー%d / リプレイ%d" % [games, big_count, reg_count, ("+" if balance > 0 else "") + str(balance), grape_count, cherry_count, replay_count]
	var points := ""
	for i in range(maxi(0, history.size() - 32), history.size()):
		var value: int = history[i]
		var index: int = clampi(3 + int(float(value) / 35.0), 0, 7)
		points += "▁▂▃▄▅▆▇█".substr(index, 1)
	graph_label.text = "差枚の推移　" + points

func _request_wager() -> void:
	if spinning:
		return
	var cost: int = 0 if replay_pending else BET_GOLD
	if wallet < cost:
		result_label.text = "コイン不足！敵を倒して集めよう"
		auto_play = false
		_update_info()
		return
	wager_requested.emit(cost)

func begin_spin() -> void:
	# Call only after the world has actually charged the wager.
	if spinning:
		return
	var free_round: bool = replay_pending
	replay_pending = false
	spinning = true
	spin_time = 0.0
	reel_tick = 0.0
	auto_wait = -1.0
	stopped = [false, false, false]
	result_name = _draw_outcome()
	_miss_result = _result_symbols("MISS") if result_name == "MISS" else ["7", "🍉", "BAR"]
	medals_in += 0 if free_round else 3
	prize_label.text = "今回の払出　—"
	result_label.text = "回転中… STOPを押してね"
	_light_lamps("")
	for i in range(3):
		stop_buttons[i].disabled = true
	_update_info()

func _draw_outcome() -> String:
	var roll: float = rng.randf()
	var big_chance: float = 1.0 / BIG_ODDS
	var reg_chance: float = 1.0 / REG_ODDS
	if roll < big_chance:
		return "BIG"
	if roll < big_chance + reg_chance:
		return "REG"
	var cut: float = big_chance + reg_chance
	for result in ["GRAPE", "CHERRY", "REPLAY"]:
		var odds: float = 1.0 / (6.0 if result == "GRAPE" else (35.0 if result == "CHERRY" else 7.3))
		cut += odds
		if roll < cut:
			return result
	return "MISS"

func _result_symbols(role: String) -> Array[String]:
	match role:
		"BIG": return ["7", "7", "7"]
		"REG": return ["BAR", "BAR", "BAR"]
		"GRAPE": return ["🍇", "🍇", "🍇"]
		"REPLAY": return ["↻", "↻", "↻"]
		"CHERRY": return ["🍒", "🍇", "BAR"]
	var values: Array[String] = []
	for attempt in range(64):
		values = [str(SYMBOLS[rng.randi_range(0, SYMBOLS.size() - 1)]), str(SYMBOLS[rng.randi_range(0, SYMBOLS.size() - 1)]), str(SYMBOLS[rng.randi_range(0, SYMBOLS.size() - 1)])]
		if values[0] != "🍒" and not (values[0] == values[1] and values[1] == values[2]):
			return values
	return ["BAR", "7", "🍇"]

func stop_reel(index: int) -> void:
	if not spinning or spin_time < 0.24 or stopped[index]:
		return
	stopped[index] = true
	var symbols: Array[String] = _result_symbols(result_name) if result_name != "MISS" else _miss_result
	center_symbols[index] = symbols[index]
	_paint_reel(index, symbols[index])
	stop_buttons[index].disabled = true
	reel_stopped.emit(index)
	if stopped[0] and stopped[1] and stopped[2]:
		_finish_spin()

func _finish_spin() -> void:
	spinning = false
	games += 1
	var reward: int = int(ROLE_PAYOUT.get(result_name, 0))
	medals_out += reward
	history.append(medals_out - medals_in)
	if history.size() > 64:
		history.pop_front()
	match result_name:
		"BIG": big_count += 1
		"REG": reg_count += 1
		"GRAPE": grape_count += 1
		"CHERRY": cherry_count += 1
		"REPLAY": replay_count += 1
	replay_pending = result_name == "REPLAY"
	_light_lamps(result_name)
	prize_label.text = "今回の払出 %dG" % reward
	result_label.text = "%s　+%dG" % [str(RESULT_NAMES[result_name]), reward]
	spin_resolved.emit(result_name, reward)
	_update_info()
	if auto_play:
		auto_wait = 0.7

func _toggle_auto() -> void:
	auto_play = not auto_play
	if auto_play and not spinning:
		_request_wager()
	_update_info()

func handle_slot_key(key: int) -> void:
	match key:
		KEY_SPACE:
			if not spinning and not auto_play:
				_request_wager()
		KEY_1: stop_reel(0)
		KEY_2: stop_reel(1)
		KEY_3: stop_reel(2)

func _process(delta: float) -> void:
	if not visible:
		return
	if spinning:
		spin_time += delta
		reel_tick -= delta
		if reel_tick <= 0.0:
			reel_tick = 0.075
			for i in range(3):
				if not stopped[i]:
					_paint_reel(i, str(SYMBOLS[rng.randi_range(0, SYMBOLS.size() - 1)]))
		for i in range(3):
			stop_buttons[i].disabled = spin_time < 0.24 or stopped[i]
			if auto_play and spin_time > 0.48 + float(i) * 0.24 and not stopped[i]:
				stop_reel(i)
	elif auto_play and auto_wait > 0.0:
		auto_wait -= delta
		if auto_wait <= 0.0:
			_request_wager()

func prepare_new_game() -> void:
	# Reset the UI spin state while keeping session stats for the current game instance.
	spinning = false
	stopped = [true, true, true]
	auto_play = false
	auto_wait = -1.0
	replay_pending = false
	_update_info()
