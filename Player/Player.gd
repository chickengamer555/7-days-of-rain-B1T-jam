extends CharacterBody2D

@export var speed = 300

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed

func _physics_process(delta):
	get_input()
	move_and_slide()

func _unhandled_input(event):
	if not event.is_action_pressed("Interact"):
		return
	var closest = null
	var closest_distance = INF
	for area in $Sensor.get_overlapping_areas():
		if not area.has_method("interact"):
			continue
		var distance = global_position.distance_squared_to(area.global_position)
		if distance < closest_distance:
			closest = area
			closest_distance = distance
	if closest != null:
		closest.interact()
		get_viewport().set_input_as_handled()
