class_name Boat
extends Area2D

signal boarded #fire when player gets in
signal parked # go when boat is left at dock

func interact() -> void: #func plater calls
	var p = get_tree().get_first_node_in_group("Player") # find player 
	if p == null:
		return # stop if no play
	hide() # emepty boat disspaeras
	p.board(self) # player becomes boat
	boarded.emit() 

func park(pos: Vector2) -> void:
	global_position = pos # move ot the dock boat spot
	show() # appear again
	parked.emit()
