extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Flags: ", Flags.tags)
	print("Ledger: ", Ledger.known)
	Flags.add("test_flag")
	Ledger.learn("test_entry")

func _unhandled_input(event):
	if event.is_action_pressed("Interact"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("Ledger"):
		Flags.clear()
		print("Flags cleared")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
