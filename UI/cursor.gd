extends CanvasLayer


const ARROW = preload("res://Assets/UI/Mouse 2.png")
const ARROW_TIP = Vector2(2, 1) # pixel that is the "point"

@onready var sprite: Sprite2D = $Sprite
var tip = ARROW_TIP

func _ready():
	layer = 128 # above everything else 
	process_mode = Node.PROCESS_MODE_ALWAYS # MOCE WHEN PAUSED
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN # hide the real one

func _process(delta):
	var m = get_viewport().get_mouse_position() # 240x160
	sprite.position = (m - tip).floor() # snap grid

func set_look(tex: Texture2D, hotspot: Vector2, outline: bool):
	sprite.texture = tex
	tip = hotspot
	sprite.material.set_shader_parameter("outline_enabled", outline)

func reset_look():
	set_look(ARROW, ARROW_TIP, true)
