extends Area2D

@export var data: InteractbleData

@onready var sprite_2d: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	if data:
		if data.sprite and sprite_2d:
			sprite_2d.texture = data.sprite
		elif sprite_2d and sprite_2d.texture != null and sprite_2d.texture.resource_path == "res://icon.svg":
			sprite_2d.texture = null

func interact() -> void:
	if data and not data.rules.is_empty():
		Dialouge.run_first_match(data.rules, data.id) 
