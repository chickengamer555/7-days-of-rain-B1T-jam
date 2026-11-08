class_name DikeCrack
extends Node2D

func _ready():
	Clock.phase_changed.connect(update_dike) # check each phase
	if Flags != null and Flags.has_signal("flag_added"):
		Flags.flag_added.connect(_on_flag_added)
	update_dike() 

func _on_flag_added(tag: String) -> void:
	if tag == "dike_repaired":
		update_dike()

func update_dike():
	var stage = 0 # Intact
	if Flags != null and Flags.has("dike_repaired"):
		stage = 0 # Stays intact when reinforced with stone facing
	elif Clock.day >= 7:
		stage = 3 # Broken
	elif Clock.day >= 5:
		stage = 2 # VeryCracked
	elif Clock.day >= 3:
		stage = 1 # Cracked
	var layers = get_children() # in the order they are listed 
	for i in layers.size():
		layers[i].enabled = (i == stage) # on for the current stage (other off)
