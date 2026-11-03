extends Area2D

var data: NPCData #What npc they are

func setup(npc_data):
	data = npc_data
	$Sprite2D.texture = data.sprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func interact(): #Lets us test npcs
	print(data.id)
