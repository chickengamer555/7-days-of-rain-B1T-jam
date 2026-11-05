extends CharacterBody2D

const TILE_SIZE: int = 16
const TILE_STEP: int=8
@export var tiles_per_second: float = 5.0
var is_moving: bool = false # am i mid step 
var target_position: Vector2 = Vector2.ZERO #where am i heading
@export_group("Textures")
@export var tex_down: Texture2D = preload("res://Player/player_down.png")
@export var tex_side: Texture2D = preload("res://Player/player_side.png")
@export var tex_up: Texture2D = preload("res://Player/player_up.png")

@export_group("Procedural Animation (Bobbing)")
@export var bob_speed: float = 14.0
@export var bob_amount: float = 2.0
@export var sway_speed: float = 9.0
@export var sway_angle: float = 0.06
@export var breathe_speed: float = 3.0
@export var breathe_amount: float = 0.02

enum Facing { DOWN, UP, LEFT, RIGHT }
var current_facing: Facing = Facing.DOWN

var anim_time: float = 0.0
var base_sprite_pos: Vector2 = Vector2.ZERO
var base_sprite_scale: Vector2 = Vector2.ONE

@onready var sprite: Sprite2D = $Sprite2D
@onready var sensor: Area2D = $Sensor

func _ready() -> void:
	global_position = global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE)) #round to nearest 16
	global_position = global_position.snapped(Vector2(TILE_STEP, TILE_STEP)) 
	target_position = global_position
	if sprite:
		base_sprite_pos = sprite.position
		base_sprite_scale = sprite.scale
		_update_facing(Facing.DOWN)

func get_input() -> Vector2:
	var x := Input.get_axis("left", "right") # -1, O or 1
	var y := Input.get_axis("up", "down")
	return Vector2(signf(x), signf(y))
	if x != 0:
		return Vector2(signf(x), 0)
	if y != 0:
		return Vector2(0, signf(y))
	return Vector2.ZERO

func _physics_process(delta: float) -> void:
	if is_moving:
		global_position = global_position.move_toward(target_position, tiles_per_second * TILE_SIZE * delta)
		if global_position != target_position:
			_animate_walking(delta)
			return
		is_moving = false
	if not Clock.running:
		_animate_idle(delta)
		return
	var dir := get_input()
	if dir == Vector2.ZERO:
		_animate_idle(delta)
		return 
	_determine_facing(dir)
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

	
