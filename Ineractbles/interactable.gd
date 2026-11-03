extends Area2D

@export var data: InteractbleData

func interact():
	Dialouge.run_first_match(data.rules, data.id) # Start first convo alloweed 
