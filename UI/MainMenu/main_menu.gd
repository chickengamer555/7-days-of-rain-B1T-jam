extends Control

const SETTINGS_FILE: String = "user://settings.json"
const PAPER_COLOR: Color = Color("#c6baac")
const INK_COLOR: Color = Color("#1e1c32")

const PIXEL_FONT = preload("res://Assets/UI/old-school-adventures-font/OldSchoolAdventures-42j9.ttf")

@onready var main_view: Control = $MainView
@onready var settings_view: Control = $SettingsView
@onready var controls_view: Control = $ControlsView
@onready var credits_btn: Button = $MainView/CreditsBtn
@onready var start_btn: Button = $MainView/StartBtn
@onready var settings_btn: Button = $MainView/SettingsBtn
@onready var controls_btn: Button = $MainView/ControlsBtn
@onready var quit_btn: Button = $MainView/QuitBtn

# Settings controls
@onready var vol_left_btn: Button = $SettingsView/VBox/VolRow/VolLeft
@onready var vol_label: Label = $SettingsView/VBox/VolRow/VolVal
@onready var vol_right_btn: Button = $SettingsView/VBox/VolRow/VolRight

@onready var win_left_btn: Button = $SettingsView/VBox/WinRow/WinLeft
@onready var win_label: Label = $SettingsView/VBox/WinRow/WinVal
@onready var win_right_btn: Button = $SettingsView/VBox/WinRow/WinRight

@onready var ff_left_btn: Button = $SettingsView/VBox/FFRow/FFLeft
@onready var ff_label: Label = $SettingsView/VBox/FFRow/FFVal
@onready var ff_right_btn: Button = $SettingsView/VBox/FFRow/FFRight

@onready var reset_data_btn: Button = $SettingsView/VBox/ResetDataBtn
@onready var settings_back_btn: Button = $SettingsView/VBox/SettingsBackBtn
@onready var controls_back_btn: Button = $ControlsView/ControlsBackBtn

var volume_level: int = 100
var is_fullscreen: bool = false
var ff_speed_index: int = 1
const FF_SPEEDS: Array[int] = [6, 12, 18, 24]

func _ready() -> void:
	_load_settings()
	settings_btn.pressed.connect(func(): Transition.swap(func(): _show_view(settings_view))) 
	controls_btn.pressed.connect(func(): Transition.swap(func(): _show_view(controls_view)))
	credits_btn.pressed.connect(func(): Transition.change_scene("res://UI/credits.tscn")) #  Credits
	quit_btn.pressed.connect(_on_quit_pressed)
	settings_back_btn.pressed.connect(func(): Transition.swap(func(): _show_view(main_view)))
	var normal = StyleBoxEmpty.new()
	var hover = StyleBoxFlat.new()
	hover.draw_center = false
	hover.border_color = INK_COLOR
	hover.set_border_width_all(2)
	hover.set_content_margin_all(0)
	_style_recursive(settings_view, normal, hover)
	_style_recursive(settings_view, normal, hover)
	vol_left_btn.pressed.connect(func(): _change_volume(-25))
	vol_right_btn.pressed.connect(func(): _change_volume(25))
	win_left_btn.pressed.connect(_toggle_fullscreen)
	win_right_btn.pressed.connect(_toggle_fullscreen)
	ff_left_btn.pressed.connect(func(): _change_ff_speed(-1))
	ff_right_btn.pressed.connect(func(): _change_ff_speed(1))
	reset_data_btn.pressed.connect(_on_reset_data_pressed)
	
	_connect_button_sounds(self)
	
	_show_view(main_view)
	if Sound:
		Sound.play_menu_music()
	if Clock.saved_world != null: # a game is paused
		start_btn.text = "Resume"

func _show_view(active_view: Control) -> void:
	main_view.visible = (active_view == main_view)
	settings_view.visible = (active_view == settings_view)
	controls_view.visible = (active_view == controls_view)



func _on_quit_pressed() -> void:
	get_tree().quit()

# ----------------- Settings Logic -----------------

func _change_volume(delta_pct: int) -> void:
	volume_level = clampi(volume_level + delta_pct, 0, 100)
	_apply_volume()
	_save_settings()

func _apply_volume() -> void:
	vol_label.text = "%d%%" % volume_level
	var master_bus_idx = AudioServer.get_bus_index("Master")
	if master_bus_idx >= 0:
		if volume_level <= 0:
			AudioServer.set_bus_mute(master_bus_idx, true)
		else:
			AudioServer.set_bus_mute(master_bus_idx, false)
			var linear = float(volume_level) / 100.0
			AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(linear))

func _toggle_fullscreen() -> void:
	is_fullscreen = not is_fullscreen
	_apply_window_mode()
	_save_settings()

func _apply_window_mode() -> void:
	win_label.text = "Full" if is_fullscreen else "Window"
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _change_ff_speed(direction: int) -> void:
	ff_speed_index = wrapi(ff_speed_index + direction, 0, FF_SPEEDS.size())
	_apply_ff_speed()
	_save_settings()

func _apply_ff_speed() -> void:
	var speed = FF_SPEEDS[ff_speed_index]
	ff_label.text = "%dx" % speed
	Clock.FAST_FOWARD_SPEED = speed

func _on_reset_data_pressed() -> void:
	Ledger.known.clear()
	reset_data_btn.text = "Cleared!"
	Ledger.save_game()
func _save_settings() -> void:
	var data = {
		"volume_level": volume_level,
		"is_fullscreen": is_fullscreen,
		"ff_speed_index": ff_speed_index
	}
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_FILE):
		var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				if parsed.has("volume_level"):
					volume_level = int(parsed["volume_level"])
				if parsed.has("is_fullscreen"):
					is_fullscreen = bool(parsed["is_fullscreen"])
				if parsed.has("ff_speed_index"):
					ff_speed_index = int(parsed["ff_speed_index"])
	_apply_volume()
	_apply_window_mode()
	_apply_ff_speed()

# ----------------- 1-Bit Aesthetic Styling -----------------






func _style_recursive(parent: Node, normal: StyleBox, hover: StyleBox) -> void:
	for child in parent.get_children():
		if child is Button:
			child.focus_mode = Control.FOCUS_NONE # Only mouse interaction, no arrow keys
			child.add_theme_font_override("font", PIXEL_FONT)
			child.add_theme_font_size_override("font_size", 7)
			child.add_theme_stylebox_override("normal", normal)
			child.add_theme_stylebox_override("hover", hover)
			child.add_theme_stylebox_override("pressed", hover)
			child.add_theme_stylebox_override("focus", normal)
			child.add_theme_color_override("font_color", INK_COLOR)
			child.add_theme_color_override("font_hover_color", INK_COLOR)
			child.add_theme_color_override("font_pressed_color", INK_COLOR)
			child.add_theme_color_override("font_focus_color", INK_COLOR)
		elif child is Label:
			child.add_theme_font_override("font", PIXEL_FONT)
			child.add_theme_font_size_override("font_size", 7)
			child.add_theme_color_override("font_color", INK_COLOR)
		_style_recursive(child, normal, hover)


func _on_start_btn_pressed() -> void:
	if Sound:
		Sound.play_game_music(0.4)
	if Clock.saved_world != null:
		var world = Clock.saved_world 
		Clock.saved_world = null # Clear it for next itmne 
		Clock.running = Clock.was_running # Put tome back to how it was 
		Transition.swap(func(): get_tree().change_scene_to_node(world))  # get the saved game in
	else:
		Clock.reset() 
		Transition.change_scene("res://Main/main.tscn")


func _on_controls_back_btn_pressed() -> void:
	Transition.swap(func(): _show_view(main_view))

func _connect_button_sounds(parent: Node) -> void:
	for child in parent.get_children():
		if child is Button:
			if not child.pressed.is_connected(_on_button_pressed):
				child.pressed.connect(_on_button_pressed)
		_connect_button_sounds(child)

func _on_button_pressed() -> void:
	if Sound:
		Sound.play_button()
