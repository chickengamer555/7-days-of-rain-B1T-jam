extends Node

@export var npc: NPCData
@export var apply_test_state: bool = false

func _ready() -> void:
	print_rule()
#	Clock.day = 4
	print_rule()
	Flags.add("has_cost_book")
	print_rule()

func print_rule():
	if npc == null:
		return
	for rule in npc.rules:
		if rule.condition == null or rule.condition.is_met():
			print(rule.tree.resource_path)
			return
