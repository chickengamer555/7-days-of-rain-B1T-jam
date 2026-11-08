extends Control

@export_multiline var credits_text: String = "" 
@export var speed: float = 15.0 # pixels per second
@export var fast_speed: float = 80.0 
@export_file("*.tscn") var next_scene: String = "res://UI/MainMenu/main_menu.tscn"

@onready var label: Label = $Text

func _ready():
	label.custom_minimum_size.x = size.x # wrap
	label.text = credits_text
	label.position = Vector2(0, size.y) # start below the screen

func _process(delta):
	var s = speed
	if Input.is_action_pressed("Fast_foward"):
		s = fast_speed
	label.position.y -= s * delta
	var text_height = label.get_combined_minimum_size().y # height of text
	if label.position.y + text_height < 0: # last line has left the top
		set_process(false)
		get_tree().change_scene_to_file(next_scene)
