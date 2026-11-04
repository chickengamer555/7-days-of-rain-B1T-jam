extends CanvasLayer

var active = false # Is convo running
var speaker_id = "" #whos talked to
var picked = {}
var picked_stamp = {} # phase it was picked in
var used = {} # Line eahc rule used 

signal choice_made(index)
signal conversation_ended

func run_first_match(rules, id):
	for rule in rules: # go through rulles 
		if rule.condition == null or rule.condition.is_met(): #is it allowed?
			speaker_id = id # Note who it is
			if not rule.random_lines.is_empty(): # Does it have random line if so pick one at random if not play convo
							start(make_line_tree(pick_line(rule), id))
			else:
				start(rule.tree) # Play the convo
			return # stop so only first match

func start(tree): # The func that begins a conversation 
	active = true
	Clock.running = false 
	$Walker.begin(tree)
	show_current()

func show_current(): # Bassicly creates the lines needed to showcase the text
	var node = $Walker.current_node()
	if node == null:
		end()
		return
	if node.effect != null:
		node.effect.apply()
	var lines: Array[Dictionary] = [{"character": node.speaker, "text": node.display_text()}]
	$Box.start_dialogue(lines)
	await $Box.dialogue_finished
	next_step()

func next_step(): # This whole block bassicly decides what comes next but checking unused choices checking if shit is allowed all that stuff 
	if $Walker.finished:
		end()
		return
	var node = $Walker.current_node()
	var allowed = []
	for index in $Walker.available_choices():
		var choice = node.choices[index]
		if choice.condition == null or choice.condition.is_met():
			allowed.append(index)
	if allowed.is_empty():
		end()
		return 
	var picked = allowed[0]
	if node.choices[picked].label != "":
		$Prompt.text = node.display_text()
		for index in allowed:
			var button = Button.new()
			button.text = node.choices[index].display_label()
			button.pressed.connect(choice_made.emit.bind(index))
			$ChoiceScroll/Choices.add_child(button)
		$Prompt.show()
		$ChoiceScroll.show()
		$ChoiceScroll/Choices.get_child(0).grab_focus()
		picked = await choice_made
		$Prompt.hide()
		$ChoiceScroll.hide()
		for old_button in $ChoiceScroll/Choices.get_children():
			old_button.queue_free()
	var before = $Walker.current_id
	$Walker.choose(picked)
	if $Walker.finished and $Walker.current_id == before:
		end()
	else:
		show_current()

func end():
	Flags.add("talked_" + speaker_id) # Recrod who talked 
	active = false  # Make it so no converdation is running
	Clock.running = true # Start up time again 
	conversation_ended.emit()

func _unhandled_input(event):
	if active and event.is_action_pressed("Interact"):
		$Box.advance()

func make_line_tree(text, id):
	var node = DialogueNode.new() # make the line
	node.id = "start" # gib id
	node.speaker = id.capitalize() # name in box 
	node.text = text # words
	var tree = DialogueTree.new() # make the ree
	tree.start_id = "start" # Start on line
	tree.nodes.append(node) #put line in tree
	return tree

func pick_line(rule): # The func that picks the random line
	if picked_stamp.get(rule, -1) == Clock.stamp(): # Alreaydy picled?
		return picked[rule] # Say it again
	var used_lines = used.get(rule, [] ) #lines rule used
	var fresh = [] # Unsued lines 
	for line in rule.random_lines: # go through all lines
		if line not in used_lines: # Not used yet?
			fresh.append(line) # add to list
		if fresh.is_empty(): 
			used_lines = [] # if there are no new lines then forgor them
			fresh = rule.random_line.dulicate() # List again time
			if fresh.size() > 1: # mor ethat one lines??
				fresh.erase(picked[rule]) # erase last one
	var line = fresh.pick_random() # pic  one 
	used_lines.append(line) # mark as said 
	used[rule] = used_lines
	picked[rule] = line
	picked_stamp[rule] = Clock.stamp()
	return line
