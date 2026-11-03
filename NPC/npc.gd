class_name NPC
extends CharacterBody2D

@export var npc_data: NPCData
@export var character_name: String = ""

@onready var interactable: Interactable = get_node_or_null("Interactable")
@onready var prompt: CanvasItem = get_node_or_null("Interactable/Prompt")

func _ready() -> void:
	if npc_data != null:
		if character_name == "":
			character_name = npc_data.display_name
		if interactable != null:
			interactable.npc_data = npc_data
			interactable.prompt_message = "Talk to " + character_name
