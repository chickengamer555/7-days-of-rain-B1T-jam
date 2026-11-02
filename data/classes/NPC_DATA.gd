class_name NPCData
extends Resource

@export var id: String = "" # Name used in tags
@export var display_name: String = "" # Name player see
@export var rules: Array[ConversationRule] = [] # What they say in order
