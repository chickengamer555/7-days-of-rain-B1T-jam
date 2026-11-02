extends CanvasLayer

@export var npc: NPCData

@onready var box = $Box
@onready var line = $Box/VBox/Line
@onready var choices = $Box/VBox/Choices

var walker = DialoguePlayer.new() # goes through tree and box shows it
var talking = false

func _ready():
		add_child(walker)
		box.hide()

func _unhandled_input(event):
		if not event.is_action_pressed("Interact"):
				return
		if not talking:
				start_talking()
		elif walker.available_choices().is_empty():
				stop_talking() # Nothing left so close

func start_talking():
		var tree = pick_tree()
		if tree == null:
				return
		talking = true
		Clock.running = false # Time doesnt run when talking (can change)
		box.show()
		walker.begin(tree)
		show_node()

func stop_talking():
		talking = false
		Clock.running = true
		box.hide()


func pick_tree():
		for rule in npc.rules:
				if rule != null and (rule.condition == null or rule.condition.is_met()):
						return rule.tree
		return null

func show_node():
		var node = walker.current_node()
		line.text = node.speaker + ": " + node.display_text()
		if node.effect != null:
				node.effect.apply() 

		for old in choices.get_children():
				choices.remove_child(old)
				old.queue_free() 

		for i in walker.available_choices():
				var button = Button.new()
				button.text = node.choices[i].display_label()
				button.pressed.connect(pick_choice.bind(i))
				choices.add_child(button)

func pick_choice(i):
		var choice = walker.current_node().choices[i]
		if choice.effect != null:
				choice.effect.apply()
		var ends_here = choice.link_target() == ""
		walker.choose(i)
		if ends_here:
				stop_talking()
		else:
				show_node()
