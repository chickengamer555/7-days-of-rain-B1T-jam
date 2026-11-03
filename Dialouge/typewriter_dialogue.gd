class_name TypewriterDialogue
extends Control

# Dialogue box with a typewriter effect: types each line out, then waits for a click.

signal dialogue_finished

# Timers can't run at zero.
const MIN_SECONDS_PER_CHARACTER := 0.001

# Seconds between characters. Larger is slower. Takes effect at once, even mid-line. 
@export var seconds_per_character: float = 0.05:
	set(value):
		seconds_per_character = maxf(value, MIN_SECONDS_PER_CHARACTER)
		_apply_speed()

var dialogue_lines: Array[Dictionary] = []
var current_line_index: int = 0
var is_typing: bool = false
var waiting_for_click: bool = false
var target_text: String = ""
var char_index: int = 0

var _typewriter_timer: Timer = null

@onready var character_name_label: Label = %CharacterNameLabel
@onready var dialogue_text_label: Label = %DialogueTextLabel
@onready var background_panel: Panel = %BackgroundPanel


func _ready() -> void:
	_typewriter_timer = Timer.new()
	_typewriter_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_typewriter_timer.wait_time = seconds_per_character
	_typewriter_timer.timeout.connect(_on_typewriter_timer_timeout)
	add_child(_typewriter_timer)

	visible = false

	background_panel.gui_input.connect(_on_background_panel_gui_input)
	background_panel.mouse_filter = Control.MOUSE_FILTER_STOP


## Clicks anywhere on the (full-screen) root count too, not only on the box.
func _gui_input(event: InputEvent) -> void:
	_click_from(event)


## Starts a conversation, replacing any that is running. An empty list finishes straight away.
func start_dialogue(lines: Array[Dictionary]) -> void:
	_stop_typing()
	dialogue_lines = lines
	current_line_index = 0
	visible = true
	_show_current_line()


## What a click does: finishes the line being typed, or goes to the next line. Does nothing when no
## dialogue is running. Call it from your own input, such as a key or a gamepad button.
func advance() -> void:
	if is_typing:
		char_index = target_text.length()
		dialogue_text_label.visible_characters = char_index
		_finish_line()
	elif waiting_for_click:
		waiting_for_click = false
		current_line_index += 1
		_show_current_line()





func _show_current_line() -> void:
	if current_line_index >= dialogue_lines.size():
		_finish_dialogue()
		return
	var line_data: Dictionary = dialogue_lines[current_line_index]
	character_name_label.text = str(line_data.get("character", ""))
	target_text = str(line_data.get("text", ""))
	char_index = 0
	dialogue_text_label.text = target_text
	dialogue_text_label.visible_characters = 0
	is_typing = true
	_typewriter_timer.start()


func _finish_line() -> void:
	is_typing = false
	_typewriter_timer.stop()
	waiting_for_click = true


func _finish_dialogue() -> void:
	_stop_typing()
	visible = false
	dialogue_finished.emit()


## Clears the state of whatever was on screen, so a restart can't inherit it.
func _stop_typing() -> void:
	is_typing = false
	waiting_for_click = false
	if _typewriter_timer:
		_typewriter_timer.stop()


func _apply_speed() -> void:
	if _typewriter_timer == null:
		return
	_typewriter_timer.wait_time = seconds_per_character
	# Changing wait_time alone leaves the countdown already in progress running at the old speed.
	if is_typing:
		_typewriter_timer.start()


func _click_from(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click: InputEventMouseButton = event
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			advance()


func _on_typewriter_timer_timeout() -> void:
	if char_index < target_text.length():
		char_index += 1
		dialogue_text_label.visible_characters = char_index
	if char_index >= target_text.length():
		_finish_line()


func _on_background_panel_gui_input(event: InputEvent) -> void:
	_click_from(event)
