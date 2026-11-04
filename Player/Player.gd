extends CharacterBody2D

@export var speed: float = 300.0



func _ready() -> void:
	pass

func get_input() -> void:
	if not Clock.running:
		velocity = Vector2.ZERO
		return	
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed



func _physics_process(delta: float) -> void:
	if not Clock.running:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	get_input()
	move_and_slide()

func _unhandled_input(event):
	if not event.is_action_pressed("Interact"):
		return
	if not Clock.running:
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
