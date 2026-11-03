extends CanvasLayer

signal conversation_started(npc_data)
signal conversation_finished(npc_data)

var walker: DialoguePlayer = DialoguePlayer.new()
var current_npc: NPCData = null
var talking: bool = false

var box: PanelContainer
var line: Label
var choices: VBoxContainer

func _ready() -> void:
	layer = 100
	add_child(walker)
	_build_ui()
	box.hide()

func _build_ui() -> void:
	box = PanelContainer.new()
	box.name = "DialogueBox"
	add_child(box)
	
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 16
	box.offset_right = -16
	box.offset_bottom = -10
	box.offset_top = -60
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	box.add_child(vbox)
	
	line = Label.new()
	line.name = "Line"
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(line)
	
	choices = VBoxContainer.new()
	choices.name = "Choices"
	vbox.add_child(choices)

func _unhandled_input(event: InputEvent) -> void:
	if not talking:
		return
	if event.is_action_pressed("Interact"):
		if walker.available_choices().is_empty():
			stop_talking()
			get_viewport().set_input_as_handled()

func start_conversation(npc: NPCData) -> bool:
	if talking or npc == null:
		return false
	current_npc = npc
	var tree = _pick_tree(npc)
	if tree == null:
		return false
	return start_tree(tree, npc)

func start_tree(tree: DialogueTree, npc: NPCData = null) -> bool:
	if tree == null:
		return false
	current_npc = npc
	talking = true
	Clock.running = false
	box.show()
	walker.begin(tree)
	_show_node()
	conversation_started.emit(npc)
	return true

func stop_talking() -> void:
	talking = false
	Clock.running = true
	box.hide()
	var finished_npc = current_npc
	current_npc = null
	conversation_finished.emit(finished_npc)

func _pick_tree(npc: NPCData) -> DialogueTree:
	for rule in npc.rules:
		if rule != null and (rule.condition == null or rule.condition.is_met()):
			return rule.tree
	return null

func _show_node() -> void:
	var node = walker.current_node()
	if node == null:
		stop_talking()
		return
	
	var speaker_name = node.speaker
	if speaker_name == "" and current_npc != null:
		speaker_name = current_npc.display_name
	
	if speaker_name != "":
		line.text = speaker_name + ": " + node.display_text()
	else:
		line.text = node.display_text()
		
	if node.effect != null:
		node.effect.apply()
		
	for old in choices.get_children():
		choices.remove_child(old)
		old.queue_free()
		
	var avail = walker.available_choices()
	for i in avail:
		var choice = node.choices[i]
		var button = Button.new()
		button.text = choice.display_label()
		button.pressed.connect(_on_choice_pressed.bind(i))
		choices.add_child(button)

func _on_choice_pressed(i: int) -> void:
	var node = walker.current_node()
	if node == null or i >= node.choices.size():
		return
	var choice = node.choices[i]
	if choice.effect != null:
		choice.effect.apply()
	var ends_here = choice.link_target() == ""
	walker.choose(i)
	if ends_here:
		stop_talking()
	else:
		_show_node()
