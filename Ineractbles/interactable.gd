@tool # run this script in the editor too, not just in the game
extends Area2D

@export var data: InteractbleData:
		set(value): # runs every time data changes
				data = value
				_show_sprite()

@onready var sprite_2d: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
		if sprite_2d == null:
				sprite_2d = get_node_or_null("Sprite2D")
		_show_sprite() # one more so it shows in game 

func _show_sprite() -> void:
		if sprite_2d == null:
				sprite_2d = get_node_or_null("Sprite2D")
		if sprite_2d == null or data == null:
				return
		if data.sprite:
				sprite_2d.texture = data.sprite # copy the .tres sprite onto the Sprite2D
		elif sprite_2d.texture != null and sprite_2d.texture.resource_path == "res://icon.svg":
				sprite_2d.texture = null # get rid of the placeholder Godot icon

func interact() -> void:
		if data and not data.rules.is_empty():
				Dialouge.run_first_match(data.rules, data.id)
