class_name DialogueChoice
extends Resource

@export var label: String = ""
@export var next_id: String = ""


## The text shown on the player's button: `label` with every inline `{...}` tag removed.
func display_label() -> String:
	return DialogueTags.strip(label)


## The node this choice routes to: an inline link tag in `label` wins; otherwise `next_id`.
## An empty result means terminal (the conversation ends here).
func link_target() -> String:
	var inline: String = DialogueTags.link_target(label)
	return inline if inline != "" else next_id
