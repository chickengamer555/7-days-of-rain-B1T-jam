extends ColorRect


func _ready():
	Clock.phase_changed.connect(update_rain) # runs every 15 seconds, when the phase changes
	update_rain() 
	
func update_rain():
	var progress = Clock.stamp() / 27.0 
	var cycle = 1.0 - Clock.stamp() * 0.07 # 0.05 faster each phase
	material.set_shader_parameter("cycle", maxf(cycle, 0.6)) # do go below 0.6 or the splashes get cut off
	material.set_shader_parameter("density", lerpf(0.3, 1.5, progress)) # light rain to downpour
