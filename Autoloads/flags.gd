extends Node


var tags = {} #Emtpy dicitonary well store tags in

func add(tag):
	tags[tag] = true #Stores tags we make

func has_all_tags(list):
	return tags.has_all(list)

func has_any_tag(list):
	for tag in list: # Go through the list of tags
		if tags.has(tag): # Is it stored?
			return true # Yes so leave
	return false #No it didnt

func clear():
	tags.clear()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
