extends Node2D

@export var npcs: Array[NPCData] = [] #Drag in npc files
const NPC_SCENE = preload("res://data/Npcs/NPC.tscn") # Load npc scene

func _ready():
		Clock.phase_changed.connect(refresh_npcs) #update npcs each phase
		$Player.position = $Spots.get_node("spot 1").position
		refresh_npcs()

func refresh_npcs(): # Removes every npc then puts each one at the spot the shcedule says they should be in
		for child in $NPCs.get_children():
				child.queue_free()
		for npc_data in npcs:
				var slot = npc_data.current_slot()
				if slot != null:
						var npc = NPC_SCENE.instantiate()
						$NPCs.add_child(npc)
						npc.setup(npc_data)
						npc.position = $Spots.get_node(slot.spot).position
