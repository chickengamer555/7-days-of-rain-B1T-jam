class_name Interactable
extends Area2D

signal interacted(by_actor)
signal focused
signal unfocused

@export var prompt_message: String = "Talk"
@export var npc_data: NPCData = null
@export var dialogue_tree: DialogueTree = null
@export var effect: Effect = null
@export var condition: Condition = null
@export var disabled: bool = false

@export var prompt_indicator: CanvasItem = null

var is_focused: bool = false

func _ready() -> void:
	add_to_group("interactables")
	if prompt_indicator != null:
		prompt_indicator.visible = false
	else:
		var default_prompt = get_node_or_null("Prompt")
		if default_prompt != null and default_prompt is CanvasItem:
			prompt_indicator = default_prompt
			prompt_indicator.visible = false

func can_interact() -> bool:
	if disabled:
		return false
	if condition != null and not condition.is_met():
		return false
	return true

func focus() -> void:
	if not can_interact():
		return
	is_focused = true
	if prompt_indicator != null:
		prompt_indicator.visible = true
	focused.emit()

func unfocus() -> void:
	is_focused = false
	if prompt_indicator != null:
		prompt_indicator.visible = false
	unfocused.emit()

func interact(by_actor: Node = null) -> void:
	if not can_interact():
		return
	interacted.emit(by_actor)
	if effect != null:
		effect.apply()
	var dm = get_node_or_null("/root/DialogueManager")
	if dm != null:
		if npc_data != null:
			dm.start_conversation(npc_data)
		elif dialogue_tree != null:
			dm.start_tree(dialogue_tree)
