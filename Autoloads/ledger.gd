extends Node

var known = {} # Whats known in the ledger
var loop_count: int = 0
var save_file

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
	save_file = VersionedSaveFile.new("user://ledger.sav", 1) # point at save 
	var data = save_file.read() # read the file 
	if save_file.last_status == VersionedSaveFile.Status.LOADED: # did it load 
		known = data.get("known", {}) # Use the saved entry 
		loop_count = data.get("loop_count", 0)
	if known.has("A1") and loop_count == 0:
		loop_count = 1
	if loop_count >= 1 and Flags != null:
		Flags.add("loop_completed")

func save_game():
	save_file.write({"known": known, "loop_count": loop_count})

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
