extends Control

func _draw() -> void:
	var weather = get_parent()
	if weather != null and weather.has_method("draw_rain"):
		weather.draw_rain(self)
