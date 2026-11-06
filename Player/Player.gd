extends CharacterBody2D

@onready var prompt: Label = $InteractPrompt
const GRASS_MATERIAL = preload("res://Shaders/grass_material.tres")
const TRAIL_SIZE: int = 32 # How many cells it rmebers
const TILE_SIZE: int = 16
const TILE_STEP: int=8

var trail := PackedVector3Array() # list sent to the shader
var trail_index: int = 0 # Which slot write to next
var last_cell := Vector2(INF, INF) # cell the feet were in last frame
var grass_clock: float = 0.0 # Timer for when grass comes back up
var is_moving: bool = false # am i mid step 
var target_position: Vector2 = Vector2.ZERO #where am i heading
var boat: Boat = null
var walk_mask: int = 0
var step_speed: float = 5.0 # how fast current moving
var is_drift_step: bool = false # is this step not mine
@export var upstream_speed: float = 2.5
@export var downstream_speed: float = 8.0
@export var drift_speed: float = 1.0
@export var tiles_per_second: float = 5.0
@export_group("Textures")
@export var tex_down: Texture2D = preload("res://Player/player_down.png")
@export var tex_side: Texture2D = preload("res://Player/player_side.png")
@export var tex_up: Texture2D = preload("res://Player/player_up.png")
@export var tex_boat: Texture2D
@export_group("Procedural Animation (Bobbing)")
@export var bob_speed: float = 14.0
@export var bob_amount: float = 2.0
@export var sway_speed: float = 9.0
@export var sway_angle: float = 0.06
@export var breathe_speed: float = 3.0
@export var breathe_amount: float = 0.02
@export_flags_2d_physics var boat_mask: int = 0
enum Facing { DOWN, UP, LEFT, RIGHT }
var current_facing: Facing = Facing.DOWN

var anim_time: float = 0.0
var base_sprite_pos: Vector2 = Vector2.ZERO
var base_sprite_scale: Vector2 = Vector2.ONE

@onready var sprite: Sprite2D = $Sprite2D
@onready var sensor: Area2D = $Sensor

func _ready() -> void:
	trail.resize(TRAIL_SIZE) # Make the 32 slots
	trail.fill(Vector3(0, 0, -1000.0)) # Mark themas stepped on 
	if DynamicDoor.pending_spawn_position != Vector2.INF:
		global_position = DynamicDoor.pending_spawn_position
		DynamicDoor.pending_spawn_position = Vector2.INF
	global_position = global_position.snapped(Vector2(TILE_STEP, TILE_STEP)) 
	target_position = global_position
	is_moving = false
	if sprite:
		base_sprite_pos = sprite.position
		base_sprite_scale = sprite.scale
		_update_facing(Facing.DOWN)
	var clk = get_node_or_null("/root/Clock")
	if clk:
		clk.running = true

func teleport_to(new_pos: Vector2) -> void:
	global_position = new_pos.snapped(Vector2(TILE_STEP, TILE_STEP))
	target_position = global_position
	is_moving = false
	velocity = Vector2.ZERO
	if sprite:
		sprite.position = base_sprite_pos
		sprite.rotation = 0.0
		sprite.scale = base_sprite_scale
	var clk = get_node_or_null("/root/Clock")
	if clk:
		clk.running = true
	_flatten_grass()

func get_input() -> Vector2:
	var x := Input.get_axis("left", "right")
	var y := Input.get_axis("up", "down")
	if x != 0:
		return Vector2(signf(x), 0)
	if y != 0:
		return Vector2(0, signf(y))
	return Vector2.ZERO

func _physics_process(delta: float) -> void:
	_update_prompt()
	grass_clock += delta # Count the grass timer
	_flatten_grass() # latten the grass
	if is_moving:
		if is_drift_step and get_input() != Vector2.ZERO: # drifting and i pressed key
			step_speed = downstream_speed
			is_drift_step = false
		global_position = global_position.move_toward(target_position, step_speed * TILE_SIZE * delta) 
		if global_position.distance_squared_to(target_position) > 0.1:
			_animate_walking(delta)
			return
		global_position = target_position
		is_moving = false
	if not Clock.running:
		_animate_idle(delta)
		return
	var dir := get_input()
	var drifting := false 
	if dir == Vector2.ZERO and boat and not _near_dock():
		dir = Vector2.RIGHT # current puhs you right
		drifting = true 
	if dir == Vector2.ZERO: # still no direction?
		_animate_idle(delta)
		return # stop here
	if not drifting:
		_determine_facing(dir)
	step_speed = _get_step_speed(dir, drifting) # Pick ths step speed 
	is_drift_step = drifting # rember who statt the step
	var target := global_position + dir * TILE_STEP
	if dir.x != 0:
		target.x = snappedf(target.x, TILE_STEP)
	if dir.y != 0:
		target.y = snappedf(target.y, TILE_STEP)
	var motion := target - global_position
	var hit := KinematicCollision2D.new() # only go as far as wall
	if test_move(global_transform, motion, hit):
		motion = hit.get_travel()
		if motion.length() < 0.5:   # already touching it
			_animate_idle(delta)
			return
	target_position = global_position + motion
	is_moving = true

func _determine_facing(dir: Vector2) -> void:
	var prev_facing = current_facing
	if dir.y == 0:
		if dir.x > 0:
			current_facing = Facing.RIGHT
		else:
			current_facing = Facing.LEFT
	else:
		if dir.y > 0:
			current_facing = Facing.DOWN
		else:
			current_facing = Facing.UP

	if prev_facing != current_facing:
		_update_facing(current_facing)

func _update_facing(facing: Facing) -> void:
	if not sprite:
		return
	match facing:
		Facing.DOWN:
			sprite.texture = tex_down
			sprite.flip_h = false
		Facing.UP:
			sprite.texture = tex_up
			sprite.flip_h = false
		Facing.RIGHT:
			sprite.texture = tex_side
			sprite.flip_h = false
		Facing.LEFT:
			sprite.texture = tex_side
			sprite.flip_h = true
	if boat:
		sprite.texture = tex_boat
func _animate_walking(delta: float) -> void:
	if not sprite:
		return
	anim_time += delta * bob_speed
	
	var bob_offset = abs(sin(anim_time)) * -bob_amount
	sprite.position.y = base_sprite_pos.y + bob_offset
	sprite.rotation = sin(anim_time * 0.5) * sway_angle
	
	var stretch = cos(anim_time * 2.0) * 0.035
	sprite.scale = Vector2(
		base_sprite_scale.x * (1.0 - stretch),
		base_sprite_scale.y * (1.0 + stretch)
	)

func _animate_idle(delta: float) -> void:
	if not sprite:
		return
	anim_time += delta * breathe_speed
	
	sprite.position.y = lerp(sprite.position.y, base_sprite_pos.y, 12.0 * delta)
	sprite.rotation = lerp(sprite.rotation, 0.0, 12.0 * delta)
	
	var breath = sin(anim_time) * breathe_amount
	sprite.scale = Vector2(
		base_sprite_scale.x * (1.0 - breath * 0.5),
		base_sprite_scale.y * (1.0 + breath)
	)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("Interact"):
		return
	if not Clock.running:
		return
	if boat:
		for area in sensor.get_overlapping_areas(): # go through range
			if area is Dock:
				area.dock(self) # get of here
				get_viewport().set_input_as_handled()
				return 
		return
	var closest = null
	var closest_distance = INF
	if sensor:
		for area in sensor.get_overlapping_areas():
			if not area.has_method("interact"):
				continue
			var distance = global_position.distance_squared_to(area.global_position)
			if distance < closest_distance:
				closest = area
				closest_distance = distance
	if closest != null:
		closest.interact()
		get_viewport().set_input_as_handled()

func _flatten_grass() -> void: # Flatten that damn gras
	var feet := global_position + Vector2(0, 9) # where feet are (the 9 is offset)
	var cell := (feet / TILE_SIZE).floor() # WHich cell it is
	if cell != last_cell: # Have you walked into new cell?
		trail_index = (trail_index + 1) % TRAIL_SIZE # Move to next spot and oldest step gets overwritten
		last_cell = cell # Rember the cell 
	trail[trail_index] = Vector3(cell.x, cell.y, grass_clock) # Stamp cell with time
	GRASS_MATERIAL.set_shader_parameter("trail", trail) # send list of to the shader
	GRASS_MATERIAL.set_shader_parameter("current_time", grass_clock) # Send time also to the shader 

func _update_prompt() -> void:
	var can_use = false #nth found
	if Clock.running:
		for area in sensor.get_overlapping_areas():
			if boat and area is Dock: 
				can_use = true
			elif not boat and area.has_method("interact"):
				can_use = true
	prompt.visible = can_use

func board(b: Boat) -> void: # boat calls this
	boat = b # remeber the boat
	walk_mask = collision_mask # save walking mask
	collision_mask = boat_mask # Swap collisons so player can go on water nd not shore
	z_index = -2
	teleport_to(b.global_position) # jump to boat
	_update_facing(current_facing) # swap to boat sprite 

func leave_boat(pos: Vector2) -> void:
	boat = null # on foot 
	collision_mask = walk_mask #back to normal walk 
	z_index = 0
	teleport_to(pos) # jump to pier
	_update_facing(current_facing) # current facging 

func _get_step_speed(dir: Vector2, drifting: bool) -> float:
	if not boat: #on foot?
		return tiles_per_second # normal walking speed
	if drifting:
		return drift_speed # slow drift 
	if dir.x < 0: # going left
		return upstream_speed
	if dir.x > 0: # Going right?
		return downstream_speed
	return tiles_per_second # up or down normal walking speed

func _near_dock() -> bool:
	for area in sensor.get_overlapping_areas():
		if area is Dock:
			return true 
	return false
