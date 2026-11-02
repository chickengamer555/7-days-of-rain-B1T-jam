extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	Clock.flood_arrived.connect(on_flood)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = "Day " + str(Clock.day) + " Phase " + str(Clock.phase) + " Time " + str(snappedf(Clock.elapsed, 0.1))
	
func on_flood():
	print("FLOOD TIME!")
