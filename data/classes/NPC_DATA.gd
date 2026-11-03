class_name NPCData
extends Resource

@export var id: String = "" # Name used in tags
@export var display_name: String = "" # Name player see
@export var rules: Array[ConversationRule] = [] # What they say in order
@export var sprite: Texture2D 
@export var schedule: Array[ScheduleSlot] = []

func current_slot(): 
	var awnser = null
	var best = -1 # Latest time found rn
	for slot in schedule: # go through all the rows
		var slot_stamp = (slot.day - 1) * 4 + slot.phase #Get rows time as numver
		if slot_stamp > Clock.stamp(): # Checls of the row is in the future 
			continue #Skip
		if slot.condition != null and not slot.condition.is_met(): #Does it have a condition that fails
			continue # skip
		if slot_stamp >= best: # Is it as late as the current best
			awnser = slot #Makes that row the new answer
			best = slot_stamp # Notes its time
	return awnser # Gives back nothing or the winning anwser 
