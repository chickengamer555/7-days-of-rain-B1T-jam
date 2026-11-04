extends CanvasLayer

signal thunder_triggered

const PALETTE_PAPER_DEFAULT: Color = Color(0.776471, 0.729412, 0.67451, 1.0) # #c6baac
const PALETTE_INK_DEFAULT: Color = Color(0.117647, 0.109804, 0.196078, 1.0)   # #1e1c32

const PALETTE_PAPER_WARM: Color = Color(0.917647, 0.87451, 0.784314, 1.0)    # #eadfc8 (Dawn)
const PALETTE_INK_WARM: Color = Color(0.164706, 0.113725, 0.090196, 1.0)     # #2a1d17 (Dawn)

const DROP_COUNT: int = 55
const STROKE_VECTOR: Vector2 = Vector2(-1.0, 4.0)

@export var rain_enabled: bool = true
@export var auto_thunder: bool = true

@onready var rain_canvas: Control = $RainCanvas
@onready var palette_rect: ColorRect = $PaletteLimiter
@onready var thunder_timer: Timer = $ThunderTimer

var drops: Array[Vector2] = []
var speeds: Array[float] = []

var is_warm_palette: bool = false
var palette_material: ShaderMaterial
var rain_material: ShaderMaterial

func _ready() -> void:
	layer = 80 # Above world, below full-screen menus / dialogue
	
	palette_material = palette_rect.material as ShaderMaterial
	rain_material = rain_canvas.material as ShaderMaterial
	
	_init_rain_drops()
	
	if Clock != null:
		Clock.phase_changed.connect(_on_clock_phase_changed)
		_update_day_dither()
		
	if auto_thunder and thunder_timer != null:
		thunder_timer.timeout.connect(_on_thunder_timer_timeout)
		_schedule_next_thunder()

func _process(delta: float) -> void:
	# Hide when on MainMenu so it doesn't duplicate the title rain
	var scene = get_tree().current_scene
	if scene != null and scene.name == "MainMenu":
		visible = false
		return
	else:
		visible = true

	if not rain_enabled:
		return
		
	for i in range(DROP_COUNT):
		var spd = speeds[i]
		drops[i].y += spd * delta
		drops[i].x -= (spd * 0.25) * delta
		if drops[i].y > 165.0:
			drops[i].y = randf_range(-15.0, -2.0)
			drops[i].x = randf_range(0.0, 255.0)
		elif drops[i].x < -10.0:
			drops[i].x = 250.0
			
	rain_canvas.queue_redraw()

func _init_rain_drops() -> void:
	drops.clear()
	speeds.clear()
	for i in range(DROP_COUNT):
		drops.append(Vector2(randf_range(0.0, 240.0), randf_range(0.0, 160.0)))
		speeds.append(randf_range(150.0, 210.0))

func draw_rain(control: Control) -> void:
	if not rain_enabled:
		return
	for i in range(DROP_COUNT):
		var p = drops[i]
		control.draw_line(p, p + STROKE_VECTOR, Color.WHITE, 1.0)

# ----------------- Palette Tricks & Shaders -----------------

func flash_thunder() -> void:
	if palette_material == null:
		return
	thunder_triggered.emit()
	palette_material.set_shader_parameter("invert_colors", true)
	
	# Invert for exactly 2 frames as specified in GDD
	await get_tree().process_frame
	await get_tree().process_frame
	palette_material.set_shader_parameter("invert_colors", false)

func set_warm_palette(warm: bool) -> void:
	is_warm_palette = warm
	var paper = PALETTE_PAPER_WARM if warm else PALETTE_PAPER_DEFAULT
	var ink = PALETTE_INK_WARM if warm else PALETTE_INK_DEFAULT
	
	if palette_material != null:
		palette_material.set_shader_parameter("paper_color", paper)
		palette_material.set_shader_parameter("ink_color", ink)
	if rain_material != null:
		rain_material.set_shader_parameter("paper_color", paper)
		rain_material.set_shader_parameter("ink_color", ink)

func _on_clock_phase_changed() -> void:
	_update_day_dither()

func _update_day_dither() -> void:
	if palette_material == null or Clock == null:
		return
	# Day 1: 0.0 -> Day 7: ~0.45 corner dither
	var day_factor = clampf((float(Clock.day) - 1.0) / 6.0, 0.0, 1.0)
	var intensity = day_factor * 0.45
	palette_material.set_shader_parameter("dither_intensity", intensity)

func _on_thunder_timer_timeout() -> void:
	flash_thunder()
	_schedule_next_thunder()

func _schedule_next_thunder() -> void:
	if thunder_timer != null:
		thunder_timer.wait_time = randf_range(16.0, 32.0)
		thunder_timer.start()
