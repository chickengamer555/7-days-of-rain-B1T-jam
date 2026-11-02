extends Node

var known = {} # Whats known in the ledger

signal entry_learned(id)

func learn(id):
	if known.has(id):
		return 
		#Do we know it already if we do then do nothing
	known[id] = {"day": Clock.day, "phase": Clock.phase} # If we dont know it store it with the current time
	entry_learned.emit(id) # State everything and send the id

func knows_all(list):
	return known.has_all(list)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
