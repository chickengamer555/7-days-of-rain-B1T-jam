class_name Effect
extends Resource

@export var add_ledger: Array[String] = [] #Ledgers to give
@export var add_flags: Array[String] = [] #Flags to give
@export var ending_trigger: String = ""
@export var advance_day: bool = false



func apply():
	for id in add_ledger:
		Ledger.learn(id) # Go through ledger and add each one
	for tag in add_flags:
		Flags.add(tag) # Go through all flags and store each one

	if advance_day and Clock != null:
		Clock.request_advance_day()

	if ending_trigger != "":
		Loop.request(ending_trigger)
