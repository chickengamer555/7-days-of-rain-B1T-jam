extends CharacterBody2D

@export var speed: float = 300.0

@onready var interaction_detector: Area2D = get_node_or_null("InteractionDetector")

var nearby_interactables: Array[Interactable] = []
var closest_interactable: Interactable = null

func _ready() -> void:
	if interaction_detector:
		interaction_detector.area_entered.connect(_on_interaction_area_entered)
		interaction_detector.area_exited.connect(_on_interaction_area_exited)

func get_input() -> void:
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed

func is_dialogue_active() -> bool:
	var dm = get_node_or_null("/root/DialogueManager")
	return dm != null and dm.talking

func _physics_process(delta: float) -> void:
	if not Clock.running or is_dialogue_active():
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	get_input()
	move_and_slide()

	
	if not nearby_interactables.is_empty():
		_update_closest_interactable()

func _unhandled_input(event: InputEvent) -> void:
	if is_dialogue_active():
		return
		
	if event.is_action_pressed("Interact"):
		if closest_interactable != null and closest_interactable.can_interact():
			closest_interactable.interact(self)
			get_viewport().set_input_as_handled()

func _on_interaction_area_entered(area: Area2D) -> void:
	if area is Interactable:
		if not nearby_interactables.has(area):
			nearby_interactables.append(area)
			_update_closest_interactable()

func _on_interaction_area_exited(area: Area2D) -> void:
	if area is Interactable:
		nearby_interactables.erase(area)
		if area == closest_interactable:
			area.unfocus()
			closest_interactable = null
		_update_closest_interactable()

func _update_closest_interactable() -> void:
	var best_interactable: Interactable = null
	var min_distance_sq: float = INF
	
	var i = nearby_interactables.size() - 1
	while i >= 0:
		var interactable = nearby_interactables[i]
		if not is_instance_valid(interactable) or not interactable.is_inside_tree():
			nearby_interactables.remove_at(i)
		elif not interactable.can_interact():
			if interactable == closest_interactable:
				interactable.unfocus()
				closest_interactable = null
		else:
			var d_sq = global_position.distance_squared_to(interactable.global_position)
			if d_sq < min_distance_sq:
				min_distance_sq = d_sq
				best_interactable = interactable
		i -= 1
		
	if best_interactable != closest_interactable:
		if closest_interactable != null and is_instance_valid(closest_interactable):
			closest_interactable.unfocus()
		closest_interactable = best_interactable
		if closest_interactable != null:
			closest_interactable.focus()


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
