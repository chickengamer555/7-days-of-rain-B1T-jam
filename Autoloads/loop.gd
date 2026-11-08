extends CanvasLayer

@export var endings: Array[EndingData] = []

var pending_trigger = ""
var card_up = false
var is_victory = false

signal card_closed 

@onready var card: ColorRect = $Card
@onready var title_label: Label = $Card/Margin/VBox/TitleLabel
@onready var card_label: Label = $Card/Margin/VBox/CardLabel
@onready var prompt_label: Label = $Card/Margin/VBox/PromptLabel

func _ready() -> void:
	visible = true
	if card:
		card.visible = false
	Clock.flood_arrived.connect(on_flood)
	Dialouge.conversation_ended.connect(on_conversation_ended)

func request(trigger: String) -> void:
	pending_trigger = trigger

func on_conversation_ended() -> void:
	if pending_trigger != "":
		var trigger = pending_trigger
		pending_trigger = ""
		resolve(trigger)

func on_flood() -> void:
	Ledger.learn("A1")
	resolve("flood")

func resolve(trigger: String) -> void:
	Clock.running = false
	var matched: EndingData = null
	
	# Find matching ending data resource
	for ending in endings:
		if ending != null and ending.trigger == trigger:
			if ending.condition == null or ending.condition.is_met():
				matched = ending
				break
				
	# Fallback match for reset/flood
	if matched == null and (trigger == "flood" or trigger == "early_reset" or trigger == "loop"):
		for ending in endings:
			if ending != null and (ending.trigger == "flood" or ending.trigger == "early_reset"):
				matched = ending
				break

	if matched != null:
		is_victory = (matched.id == "true_ending" or matched.trigger == "true_ending")
		
		if is_victory:
			# Dawn: stop rain, swap to warm palette
			var weather = get_node_or_null("/root/Weather")
			if weather:
				weather.rain_enabled = false
				weather.set_warm_palette(true)
			if Sound:
				Sound.stop_water()
				Sound.play_collect()
			if card:
				card.color = Color(0.917647, 0.87451, 0.784314, 1.0)
			if title_label:
				title_label.text = "DAWN — YOU WON"
				title_label.add_theme_color_override("font_color", Color(0.164706, 0.113725, 0.090196, 1.0))
			if card_label:
				card_label.add_theme_color_override("font_color", Color(0.164706, 0.113725, 0.090196, 1.0))
			if prompt_label:
				prompt_label.text = "[ Press E to return to Main Menu ]"
				prompt_label.add_theme_color_override("font_color", Color(0.164706, 0.113725, 0.090196, 1.0))
		else:
			if Sound:
				Sound.play_whoosh(-2.0, 0.9)
			if card:
				card.color = Color(0.7764706, 0.7294118, 0.6745098, 1)
			if title_label:
				title_label.text = "NIGHT 7 — THE FLOOD" if trigger == "flood" else "THE SHRINE BELL"
				title_label.add_theme_color_override("font_color", Color(0.11764706, 0.10980392, 0.19607843, 1))
			if card_label:
				card_label.add_theme_color_override("font_color", Color(0.11764706, 0.10980392, 0.19607843, 1))
			if prompt_label:
				prompt_label.text = "[ Press E to wake up on Day 1 ]"
				prompt_label.add_theme_color_override("font_color", Color(0.11764706, 0.10980392, 0.19607843, 1))

		if card_label:
			card_label.text = matched.card_text
		card.show()
		card_up = true
		await card_closed 
		card.hide()
		
		if is_victory:
			Flags.clear()
			Clock.reset()
			# Restore weather state for title screen
			var weather = get_node_or_null("/root/Weather")
			if weather:
				weather.rain_enabled = true
				weather.set_warm_palette(false)
			get_tree().change_scene_to_file("res://UI/MainMenu/main_menu.tscn")
			return

	# Loopable reset:
	Flags.clear()
	Clock.reset()
	if Sound:
		Sound.play_whoosh(2.0, 0.7)
	get_tree().reload_current_scene()
	Transition.reload()

func _unhandled_input(event: InputEvent) -> void:
	if card_up and event.is_action_pressed("Interact"):
		card_up = false
		card_closed.emit()
