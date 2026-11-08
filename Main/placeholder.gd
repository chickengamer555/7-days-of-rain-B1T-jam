extends Node2D

@export var npcs: Array[NPCData] = [] #Drag in npc files
const NPC_SCENE = preload("res://data/Npcs/NPC.tscn") # Load npc scene

func _ready():
		Clock.phase_changed.connect(refresh_npcs) #update npcs each phase
		Dialouge.conversation_ended.connect(refresh_npcs) # update npcs after each convo
		refresh_npcs()

func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel") and not Transition.busy:
				get_viewport().set_input_as_handled() # stop anything else reactimg to esc
				Clock.was_running = Clock.running # rember if time is going 
				Clock.running = false  #stop clock
				Clock.saved_world = self # keep hold of whole scrren
				_go_to_menu.call_deferred() # wait till end of frame 

func _go_to_menu():
	var tree = get_tree()
	await Transition.cover() # ink with town showing 
	tree.root.remove_child(self)
	tree.current_scene = null
	tree.change_scene_to_file("res://UI/MainMenu/main_menu.tscn")
	await Transition.uncover()

func refresh_npcs(): # Removes every npc then puts each one at the spot the shcedule says they should be in
		for child in $NPCs.get_children():
				child.queue_free()
		for npc_data in npcs:
				var slot = npc_data.current_slot()
				if slot != null:
						var npc = NPC_SCENE.instantiate()
						$NPCs.add_child(npc)
						npc.setup(npc_data)
						npc.global_position = $Spots.get_node(npc_data.id + "/" + slot.spot).global_position
