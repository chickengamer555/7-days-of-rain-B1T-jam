extends Control

const DROP_COUNT: int = 35
const RAIN_COLOR: Color = Color(0.118, 0.11, 0.196, 0.3) # #1e1c32 with gentle transparency

var drops: Array[Vector2] = []
var speeds: Array[float] = []

func _ready() -> void:
	for i in range(DROP_COUNT):
		drops.append(Vector2(randf_range(0, 240), randf_range(0, 160)))
		speeds.append(randf_range(110.0, 160.0))

func _process(delta: float) -> void:
	for i in range(DROP_COUNT):
		var spd = speeds[i]
		drops[i].y += spd * delta
		drops[i].x -= (spd * 0.25) * delta
		if drops[i].y > 165:
			drops[i].y = randf_range(-15, -2)
			drops[i].x = randf_range(0, 260)
		elif drops[i].x < -10:
			drops[i].x = 250
	queue_redraw()

func _draw() -> void:
	for i in range(DROP_COUNT):
		var p = drops[i]
		draw_line(p, p + Vector2(-1, 4), RAIN_COLOR, 1.0)
