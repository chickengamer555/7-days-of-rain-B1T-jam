extends CanvasLayer

@export var duration: float = 0.7 # secs each way

@onready var ink: ColorRect = $Ink

var busy = false

func _ready():
	ink.material.set_shader_parameter("progress", 0.0)

# ink rises covers screen
func cover():
	busy = true
	ink.mouse_filter = Control.MOUSE_FILTER_STOP # block clicks
	await _wave(0.0, 1.0)

# ink sinks and shows  screen
func uncover():
	await get_tree().process_frame # new scene load
	await get_tree().process_frame
	await _wave(1.0, 0.0)
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false

func change_scene(path: String):
	if busy:
		return
	await cover()
	get_tree().change_scene_to_file(path)
	await uncover()

func reload():
	if busy:
		return
	await cover()
	get_tree().reload_current_scene()
	await uncover()


func swap(do_this: Callable):
	if busy:
		return
	await cover()
	do_this.call()
	await uncover()

func _wave(from: float, to: float):
	var t = create_tween()
	t.tween_method(func(v): ink.material.set_shader_parameter("progress", v), from, to, duration)
	await t.finished
