extends Node

@export var npc: NPCData
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print_rule()
	Clock.day = 4
	print_rule()
	Flags.add("has_cost_book")
	print_rule()

func print_rule():
	for rule in npc.rules:
		if rule.condition == null or rule.condition.is_met():
			print(rule.tree.resource_path)
			return

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
