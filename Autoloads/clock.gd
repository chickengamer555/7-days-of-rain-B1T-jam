extends Node

var day = 1
var phase = 0 # 0 morning 1 noon 2 dusk 3 night
var elapsed = 0.0 # Time into current phase
var running = true # Will be false during dialouges to prevent movment 
var SECONDS_PER_PHASE = 15
var FAST_FOWARD_SPEED = 12 # How much holding fast foward speeds time up

signal phase_changed #Npcs and hud will listen
signal flood_arrived #Looping autload listens to this


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not running:
		return #Do nothing if time is stopped
	var frame_time = delta
	if Input.is_action_pressed("Fast_foward"):
		frame_time *= FAST_FOWARD_SPEED
	elapsed += frame_time #Push stopwatch foward 
	if elapsed >= SECONDS_PER_PHASE:
			elapsed = 0.0
			advance_phase()

func advance_phase():
	if day == 7 and phase == 3:
		running = false
		flood_arrived.emit()
		return 
		# Checks if its the last day and emmits flood if it is
	phase += 1 # Increase phase by 1
	if phase > 3:
		phase = 0 # Reset after third phase
		day += 1
	elapsed = 0.0
	phase_changed.emit()

func stamp():
	return (day - 1) * 4 + phase # Turns our day and phase into 1 number
