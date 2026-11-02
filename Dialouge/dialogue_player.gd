class_name DialoguePlayer
extends Node


var current_id: String = ""
var finished: bool = false


var revisiting: bool = false


var repeat_questions: bool = false

var _tree: DialogueTree = null


var _asked: Array[DialogueChoice] = []

## Node ids already spoken this walk. Drives `revisiting`: the second time the walk parks on
## a node, its message was already delivered, so the UI can skip replaying it.
var _spoken: Dictionary = {}


## Start a walk at the tree's start node. `finished` stays false unless the start node has no
## askable choices (a single-beat conversation) or does not exist.
func begin(tree: DialogueTree) -> void:
	_tree = tree
	current_id = tree.start_id
	finished = false
	_asked.clear()
	_spoken.clear()
	_mark_arrival()
	_finish_if_stuck()


## The node the walk is currently parked on, or null if unresolved.
func current_node() -> DialogueNode:
	if _tree == null:
		return null
	return _tree.node_by_id(current_id)


func available_choices() -> Array[int]:
	return _available_indices(current_node())



func choose(k: int) -> void:
	if finished:
		return
	var node: DialogueNode = current_node()
	if node == null or not _available_indices(node).has(k):
		return
	var choice: DialogueChoice = node.choices[k]
	if not _asked.has(choice):
		_asked.append(choice)  # this question is now spent, filtered out everywhere it appears
	var target: String = choice.link_target()
	if target == "":
		finished = true
		return
	current_id = target
	_mark_arrival()
	_finish_if_stuck()



func _available_indices(node: DialogueNode) -> Array[int]:
	var out: Array[int] = []
	if node == null:
		return out
	for i: int in node.choices.size():
		var choice: DialogueChoice = node.choices[i]
		if choice != null and (repeat_questions or not _asked.has(choice)):
			out.append(i)
	return out



func _mark_arrival() -> void:
	revisiting = _spoken.has(current_id)
	_spoken[current_id] = true


## A walk parked on a missing node, or with nothing left to ask, can never move again.
func _finish_if_stuck() -> void:
	if _available_indices(current_node()).is_empty():
		finished = true
