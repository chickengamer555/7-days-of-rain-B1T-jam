extends Node2D

func _ready():
		Clock.phase_changed.connect(update_dike) # check each phase
		update_dike() 

func update_dike():
		var stage = 0 # Intact
		if Clock.day >= 7:
				stage = 3 # Broken
		elif Clock.day >= 5:
				stage = 2 # VeryCracked
		elif Clock.day >= 3:
				stage = 1 # Cracked
		var layers = get_children() # in the order there listed 
		for i in layers.size():
				layers[i].enabled = (i == stage) # on for the current stage (other off)
