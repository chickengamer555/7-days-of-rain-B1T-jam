extends CanvasLayer

@export var endings: Array[EndingData] = []

var pending_trigger = ""
var card_up = false

signal card_closed 

func _ready():
	Clock.flood_arrived.connect(on_flood) # Run the on flood when flood hapens
	Dialouge.conversation_ended.connect(on_conversation_ended) # run after each convo

func request(trigger):
	pending_trigger = trigger

func on_conversation_ended():
	if pending_trigger !="":
		var trigger = pending_trigger
		pending_trigger = ""
		resolve(trigger)

func on_flood():
	Ledger.learn("A1")
	resolve("flood")

func resolve(trigger):
	Clock.running = false
	var matched = null
	for ending in endings:
		if ending.trigger == trigger and (ending.condition == null or ending.condition.is_met()):
			matched = ending
			break
	if matched != null:
		$Card/CardLabel.text = matched.card_text
		$Card.show()
		card_up = true
		await card_closed 
		$Card.hide()
	Flags.clear()
	Clock.reset()
	get_tree().reload_current_scene()

func _unhandled_input(event):
	if card_up and event.is_action_pressed("Interact"):
		card_up = false
		card_closed.emit()
