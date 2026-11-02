class_name DialogueNode
extends Resource


@export var id: String = ""
@export var speaker: String = ""
@export var text: String = ""
@export var choices: Array[DialogueChoice] = []


## The spoken line to show: `text` with every inline `{...}` tag removed.
func display_text() -> String:
	return DialogueTags.strip(text)
