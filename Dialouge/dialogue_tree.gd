class_name DialogueTree
extends Resource
## A conversation, stored flat and id-keyed: branching is by `next_id` String references

@export var start_id: String = ""
@export var nodes: Array[DialogueNode] = []


## Return the node whose `id` matches, or null if none does.
func node_by_id(id: String) -> DialogueNode:
	for node: DialogueNode in nodes:
		if node != null and node.id == id:
			return node
	return null


## Return a list of structural error strings; an EMPTY list means the tree is valid.

func validate() -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for node: DialogueNode in nodes:
		if node == null:
			errors.append("nodes contains a null entry")
			continue
		if seen.has(node.id):
			errors.append("duplicate node id '%s'" % node.id)
		seen[node.id] = true
	if not seen.has(start_id):
		errors.append("start_id '%s' resolves to no node" % start_id)
	for node: DialogueNode in nodes:
		if node == null:
			continue
		for i: int in node.choices.size():
			var choice: DialogueChoice = node.choices[i]
			if choice == null:
				errors.append("node '%s' has a null choice at index %d" % [node.id, i])
				continue
			var target: String = choice.link_target()
			if target != "" and not seen.has(target):
				errors.append("node '%s' choice link '%s' resolves to no node" % [
					node.id, target])
	return errors
