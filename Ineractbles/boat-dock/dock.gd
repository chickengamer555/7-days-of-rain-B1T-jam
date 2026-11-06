class_name Dock
extends Area2D

signal docked

@export var step_off: Marker2D
@export var boat_spot: Marker2D

func dock(p) -> void:
	var b = p.boat # rember which boat
	p.leave_boat(step_off.global_position) # put player on the dock
	b.park(boat_spot.global_position) # the emepy boat appears at this place
	docked.emit()
