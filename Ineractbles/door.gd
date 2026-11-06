class_name DynamicDoor
extends Area2D

signal door_opened
signal door_closed
signal door_locked_tried

enum DoorType { INTERACT, WALK_THROUGH, SCENE, TELEPORT, RETURN }

static var last_scene: String = ""
static var last_position: Vector2 = Vector2.INF
static var pending_spawn_position: Vector2 = Vector2.INF

@export var door_type: DoorType = DoorType.INTERACT
@export var is_return_door: bool = false
@export var return_spawn_offset: Vector2 = Vector2(0, 16)
@export var is_open: bool = false:
	set(v):
		is_open = v
		if is_inside_tree():
			_update_visual(false)
@export var is_locked: bool = false
@export var use_schedule: bool = false
@export var open_phases: Array[int] = [0, 1, 2]
@export var open_days: Array[int] = [1, 2, 3, 4, 5, 6, 7]
@export var required_flags: Array[String] = []
@export var blocked_flags: Array[String] = []
@export var grant_flag: String = ""
@export_file("*.tscn") var target_scene: String = ""
@export var target_position: Vector2 = Vector2.ZERO
@export var door_sprite: Sprite2D
@export var texture_closed: Texture2D
@export var texture_open: Texture2D
@export var slide_offset: Vector2 = Vector2(14, 0)
@export var physical_collider: CollisionShape2D

var _base_pos: Vector2 = Vector2.ZERO
var _animating: bool = false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	if door_sprite:
		_base_pos = door_sprite.position
	var clk = get_node_or_null("/root/Clock")
	if clk:
		if clk.has_signal("phase_changed"):
			clk.phase_changed.connect(_on_clock_changed)
		if clk.has_signal("day_changed"):
			clk.day_changed.connect(_on_clock_changed)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_check_schedule()
	_update_visual(true)

func interact() -> void:
	if _animating:
		return
	if not can_open():
		_play_locked()
		door_locked_tried.emit()
		return
	if is_return_door or door_type == DoorType.RETURN:
		_execute_return()
		return
	match door_type:
		DoorType.INTERACT, DoorType.WALK_THROUGH:
			toggle_door()
		DoorType.SCENE:
			_record_return_data()
			if target_position != Vector2.ZERO:
				DynamicDoor.pending_spawn_position = target_position
			if target_scene != "":
				var t = get_tree()
				if t:
					t.change_scene_to_file(target_scene)
		DoorType.TELEPORT:
			_record_return_data()
			_teleport_player(target_position)

func _record_return_data() -> void:
	if is_return_door or door_type == DoorType.RETURN:
		return
	var t = get_tree()
	if t and t.current_scene and t.current_scene.scene_file_path != "":
		DynamicDoor.last_scene = t.current_scene.scene_file_path
	elif owner and owner.scene_file_path != "":
		DynamicDoor.last_scene = owner.scene_file_path
	var p = t.get_first_node_in_group("Player") if t else null
	if p:
		DynamicDoor.last_position = p.global_position
	else:
		DynamicDoor.last_position = global_position + return_spawn_offset

func _execute_return() -> void:
	var t = get_tree()
	if not t:
		return
	if DynamicDoor.last_scene != "" and (t.current_scene == null or t.current_scene.scene_file_path != DynamicDoor.last_scene):
		if DynamicDoor.last_position != Vector2.INF:
			DynamicDoor.pending_spawn_position = DynamicDoor.last_position
		t.change_scene_to_file(DynamicDoor.last_scene)
	elif DynamicDoor.last_position != Vector2.INF:
		_teleport_player(DynamicDoor.last_position)

func _teleport_player(pos: Vector2) -> void:
	if pos == Vector2.ZERO or pos == Vector2.INF:
		return
	var t = get_tree()
	var p = t.get_first_node_in_group("Player") if t else null
	if p:
		if p.has_method("teleport_to"):
			p.teleport_to(pos)
		else:
			p.global_position = pos
	var clk = get_node_or_null("/root/Clock")
	if clk:
		clk.running = true

func can_open() -> bool:
	if is_locked:
		return false
	var clk = get_node_or_null("/root/Clock")
	if use_schedule and clk:
		if not open_phases.is_empty() and not (clk.phase in open_phases):
			return false
		if not open_days.is_empty() and not (clk.day in open_days):
			return false
	var flg = get_node_or_null("/root/Flags")
	if flg:
		for f in required_flags:
			if not flg.has_tag(f):
				return false
		for f in blocked_flags:
			if flg.has_tag(f):
				return false
	return true

func _check_schedule() -> void:
	if use_schedule and not can_open() and is_open:
		close_door(true)

func toggle_door() -> void:
	if is_open:
		close_door()
	else:
		open_door()

func open_door(immediate: bool = false) -> void:
	if is_open:
		return
	is_open = true
	var flg = get_node_or_null("/root/Flags")
	if grant_flag != "" and flg:
		flg.add_tag(grant_flag)
	_update_visual(immediate)
	door_opened.emit()

func close_door(immediate: bool = false) -> void:
	if not is_open:
		return
	is_open = false
	_update_visual(immediate)
	door_closed.emit()

func _update_visual(immediate: bool = false) -> void:
	if physical_collider:
		physical_collider.set_deferred("disabled", is_open)
	if not door_sprite:
		return
	if is_open and texture_open:
		door_sprite.texture = texture_open
	elif not is_open and texture_closed:
		door_sprite.texture = texture_closed
	var target = _base_pos + (slide_offset if is_open else Vector2.ZERO)
	if immediate:
		door_sprite.position = target
	else:
		_animating = true
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(door_sprite, "position", target, 0.2)
		tw.finished.connect(func(): _animating = false)

func _play_locked() -> void:
	if not door_sprite or _animating:
		return
	_animating = true
	var tw = create_tween().set_trans(Tween.TRANS_SINE)
	var x = door_sprite.position.x
	tw.tween_property(door_sprite, "position:x", x - 2.0, 0.04)
	tw.tween_property(door_sprite, "position:x", x + 2.0, 0.04)
	tw.tween_property(door_sprite, "position:x", x, 0.04)
	tw.finished.connect(func(): _animating = false)

func _on_clock_changed(_v: int = 0) -> void:
	_check_schedule()

func _on_body_entered(b: Node2D) -> void:
	if b.is_in_group("Player") and door_type == DoorType.WALK_THROUGH and can_open():
		open_door()

func _on_body_exited(b: Node2D) -> void:
	if b.is_in_group("Player") and door_type == DoorType.WALK_THROUGH and is_open:
		close_door()
