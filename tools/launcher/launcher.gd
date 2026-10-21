extends Control
# DOPAGAKI tester launcher: fetches the newest build from GitHub Releases, shows the
# release notes, starts the game and helps the tester send a bug report.

const REPO := "kobusan5000-cmyk/dopagaki"
const REPORT_EMAIL := "keitakeitam2@gmail.com"
const GAME_ZIP := "DOPAGAKI_game.zip"
const GAME_EXE := "DOPAGAKI.exe"
const API_URL := "https://api.github.com/repos/%s/releases/latest" % REPO
const KEEP_VERSIONS := 3
const STATE_PATH := "user://state.json"
const VERSIONS_DIR := "user://versions"
const REPORTS_DIR := "user://reports"

var current_tag := ""
var latest_tag := ""
var latest_notes := ""
var latest_url := ""
var busy := false

var status_label: Label
var notes_label: RichTextLabel
var play_button: Button
var update_button: Button
var rollback_button: OptionButton
var report_panel: PanelContainer
var report_text: TextEdit
var http: HTTPRequest

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(VERSIONS_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORTS_DIR))
	load_state()
	build_ui()
	http = HTTPRequest.new()
	http.use_threads = true
	add_child(http)
	refresh_rollback_list()
	check_for_update()

func load_state() -> void:
	if FileAccess.file_exists(STATE_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STATE_PATH))
		if parsed is Dictionary:
			current_tag = str(parsed.get("current", ""))
	if not current_tag.is_empty() and not FileAccess.file_exists(game_exe_path(current_tag)):
		current_tag = ""

func save_state() -> void:
	var file := FileAccess.open(STATE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"current": current_tag}))

func version_dir(tag: String) -> String:
	return ProjectSettings.globalize_path("%s/%s" % [VERSIONS_DIR, tag])

func game_exe_path(tag: String) -> String:
	return "%s/%s" % [version_dir(tag), GAME_EXE]

func build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("111d31")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var title := Label.new()
	title.text = "DOPAGAKI  TEST LAUNCHER"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("7de9f0"))
	box.add_child(title)
	status_label = Label.new()
	status_label.text = "Checking for updates..."
	status_label.add_theme_font_size_override("font_size", 16)
	box.add_child(status_label)
	var notes_title := Label.new()
	notes_title.text = "WHAT IS NEW / 更新内容"
	notes_title.add_theme_color_override("font_color", Color("e6c98d"))
	box.add_child(notes_title)
	notes_label = RichTextLabel.new()
	notes_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notes_label.custom_minimum_size = Vector2(0, 220)
	notes_label.selection_enabled = true
	box.add_child(notes_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	play_button = Button.new()
	play_button.text = "PLAY / 起動"
	play_button.custom_minimum_size = Vector2(190, 52)
	play_button.disabled = true
	play_button.pressed.connect(play)
	row.add_child(play_button)
	update_button = Button.new()
	update_button.text = "UPDATE / 更新"
	update_button.custom_minimum_size = Vector2(150, 52)
	update_button.visible = false
	update_button.pressed.connect(download_latest)
	row.add_child(update_button)
	var report_button := Button.new()
	report_button.text = "REPORT BUG / 不具合を報告"
	report_button.custom_minimum_size = Vector2(210, 52)
	report_button.pressed.connect(func(): report_panel.visible = true)
	row.add_child(report_button)
	var rollback_row := HBoxContainer.new()
	box.add_child(rollback_row)
	var rb_label := Label.new()
	rb_label.text = "Older version / 前の版で遊ぶ:  "
	rollback_row.add_child(rb_label)
	rollback_button = OptionButton.new()
	rollback_button.item_selected.connect(on_rollback_selected)
	rollback_row.add_child(rollback_button)
	build_report_panel()

func build_report_panel() -> void:
	report_panel = PanelContainer.new()
	report_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	report_panel.visible = false
	add_child(report_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	report_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var header := Label.new()
	header.text = "BUG REPORT / 不具合の内容を書いてください\n(いつ・何をしたら・どうなったか)"
	box.add_child(header)
	report_text = TextEdit.new()
	report_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(report_text)
	var hint := Label.new()
	hint.text = "ボタンを押すと、版番号とゲームのログ入りの報告ファイルを保存し、\nメールの下書きを開きます。メールが開かない時は、開いたフォルダのファイルを %s に送ってください。" % REPORT_EMAIL
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var send := Button.new()
	send.text = "CREATE REPORT / 報告を作る"
	send.custom_minimum_size = Vector2(240, 46)
	send.pressed.connect(create_report)
	row.add_child(send)
	var cancel := Button.new()
	cancel.text = "CLOSE / 閉じる"
	cancel.custom_minimum_size = Vector2(150, 46)
	cancel.pressed.connect(func(): report_panel.visible = false)
	row.add_child(cancel)

func set_status(text: String) -> void:
	status_label.text = text

func installed_tags() -> Array[String]:
	var tags: Array[String] = []
	var dir := DirAccess.open(VERSIONS_DIR)
	if dir == null:
		return tags
	for entry in dir.get_directories():
		if FileAccess.file_exists(game_exe_path(entry)):
			tags.append(entry)
	tags.sort_custom(func(a: String, b: String): return tag_number(a) > tag_number(b))
	return tags

func tag_number(tag: String) -> int:
	return int(tag.trim_prefix("b"))

func refresh_rollback_list() -> void:
	rollback_button.clear()
	rollback_button.add_item("(current)")
	for tag in installed_tags():
		rollback_button.add_item(tag)
	rollback_button.select(0)

func on_rollback_selected(index: int) -> void:
	if index <= 0 or busy:
		return
	current_tag = rollback_button.get_item_text(index)
	save_state()
	set_status("Using older version %s." % current_tag)
	play_button.disabled = false
	refresh_rollback_list()

func check_for_update() -> void:
	busy = true
	http.request_completed.connect(on_release_info, CONNECT_ONE_SHOT)
	var err := http.request(API_URL, ["User-Agent: dopagaki-launcher", "Accept: application/vnd.github+json"])
	if err != OK:
		http.request_completed.disconnect(on_release_info)
		on_release_info(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())

func on_release_info(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	busy = false
	var parsed: Variant = null
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		parsed = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary):
		offline_mode(code)
		return
	latest_tag = str(parsed.get("tag_name", ""))
	latest_notes = str(parsed.get("body", ""))
	latest_url = ""
	for asset in parsed.get("assets", []):
		if str(asset.get("name", "")) == GAME_ZIP:
			latest_url = str(asset.get("browser_download_url", ""))
	if latest_url.is_empty():
		offline_mode(code)
		set_status("The newest release has no game file yet. " + status_label.text)
		return
	notes_label.text = "[%s]\n%s" % [latest_tag, latest_notes]
	if latest_tag == current_tag:
		set_status("You have the newest version (%s)." % latest_tag)
		play_button.disabled = false
	else:
		download_latest()

func offline_mode(code: int) -> void:
	if current_tag.is_empty():
		set_status("Could not reach the update server (code %d). Check your internet connection and restart." % code)
		play_button.disabled = true
	else:
		set_status("Offline - you can play the installed version (%s)." % current_tag)
		play_button.disabled = false

func download_latest() -> void:
	if busy or latest_url.is_empty():
		return
	busy = true
	update_button.visible = false
	play_button.disabled = true
	set_status("Downloading %s ..." % latest_tag)
	http.download_file = ProjectSettings.globalize_path("user://%s.zip" % latest_tag)
	http.request_completed.connect(on_download_done, CONNECT_ONE_SHOT)
	var err := http.request(latest_url, ["User-Agent: dopagaki-launcher"])
	if err != OK:
		http.request_completed.disconnect(on_download_done)
		on_download_done(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())

func on_download_done(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	busy = false
	http.download_file = ""
	var zip_path := ProjectSettings.globalize_path("user://%s.zip" % latest_tag)
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		offline_mode(code)
		set_status("Download failed (code %d). Press UPDATE to retry. %s" % [code, status_label.text])
		update_button.visible = true
		return
	set_status("Installing %s ..." % latest_tag)
	if not extract_zip(zip_path, version_dir(latest_tag)):
		set_status("Install failed - the downloaded file looks broken. Press UPDATE to retry.")
		update_button.visible = true
		return
	DirAccess.remove_absolute(zip_path)
	current_tag = latest_tag
	save_state()
	prune_old_versions()
	refresh_rollback_list()
	set_status("Updated to %s. Ready to play!" % current_tag)
	play_button.disabled = false

func extract_zip(zip_path: String, target: String) -> bool:
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return false
	DirAccess.make_dir_recursive_absolute(target)
	for entry in reader.get_files():
		if entry.ends_with("/"):
			continue
		var out_path := "%s/%s" % [target, entry]
		DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
		var file := FileAccess.open(out_path, FileAccess.WRITE)
		if file == null:
			reader.close()
			return false
		file.store_buffer(reader.read_file(entry))
		file.close()
	reader.close()
	return FileAccess.file_exists("%s/%s" % [target, GAME_EXE])

func prune_old_versions() -> void:
	var tags := installed_tags()
	for i in range(KEEP_VERSIONS, tags.size()):
		remove_dir_recursive(version_dir(tags[i]))

func remove_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for sub in dir.get_directories():
		remove_dir_recursive("%s/%s" % [path, sub])
	for f in dir.get_files():
		DirAccess.remove_absolute("%s/%s" % [path, f])
	DirAccess.remove_absolute(path)

func play() -> void:
	if current_tag.is_empty():
		return
	var pid := OS.create_process(game_exe_path(current_tag), [])
	if pid <= 0:
		set_status("Could not start the game. Try UPDATE or report a bug.")
	else:
		set_status("Game started (%s)." % current_tag)

func newest_game_log() -> String:
	var base := OS.get_data_dir().path_join("Godot/app_userdata")
	var best := ""
	var best_time := 0
	var root := DirAccess.open(base)
	if root == null:
		return ""
	for game_dir in root.get_directories():
		if game_dir.begins_with("DOPAGAKI Launcher"):
			continue
		var log_path := "%s/%s/logs/godot.log" % [base, game_dir]
		if FileAccess.file_exists(log_path):
			var t := FileAccess.get_modified_time(log_path)
			if t > best_time:
				best_time = t
				best = log_path
	return best

func create_report() -> void:
	var lines := PackedStringArray()
	lines.append("DOPAGAKI bug report")
	lines.append("Game version: %s   Newest release: %s" % [current_tag, latest_tag])
	lines.append("OS: %s   GPU: %s" % [OS.get_name(), RenderingServer.get_video_adapter_name()])
	lines.append("Time: %s" % Time.get_datetime_string_from_system())
	lines.append("")
	lines.append("--- Tester description ---")
	lines.append(report_text.text)
	lines.append("")
	lines.append("--- Game log (last 120 lines) ---")
	var log_path := newest_game_log()
	if log_path.is_empty():
		lines.append("(no game log found)")
	else:
		var log_lines := FileAccess.get_file_as_string(log_path).split("\n")
		lines.append_array(log_lines.slice(maxi(0, log_lines.size() - 120)))
	var full := "\n".join(lines)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := ProjectSettings.globalize_path("%s/report_%s.txt" % [REPORTS_DIR, stamp])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(full)
		file.close()
	DisplayServer.clipboard_set(full)
	var short_body := "Version %s\n\n%s\n\n(Full report with the game log is saved at: %s and is also copied to your clipboard - please paste it below.)" % [current_tag, report_text.text.left(1200), path]
	OS.shell_open("mailto:%s?subject=%s&body=%s" % [REPORT_EMAIL, ("DOPAGAKI bug report " + current_tag).uri_encode(), short_body.uri_encode()])
	OS.shell_open(path.get_base_dir())
	report_panel.visible = false
	set_status("Report saved and copied to clipboard. Send it to %s." % REPORT_EMAIL)
