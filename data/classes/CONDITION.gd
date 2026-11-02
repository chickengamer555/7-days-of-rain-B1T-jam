class_name Condition
extends Resource 

@export var needs_ledger: Array[String] = []
@export var needs_flags: Array[String] = []
@export var blocked_by_flags: Array[String] = []
@export var from_day: int = 1
@export var from_phase: int = 0
@export var to_day: int = 7
@export var to_phase: int = 3
@export var only_phases: Array[int] = []
#Grabbing all the stuff needed

func is_met() -> bool:
	if not Ledger.knows_all(needs_ledger):
		return false
	if not Flags.has_all_tags(needs_flags):
		return false
	if Flags.has_any_tag(needs_flags):
		return false
	var start = (from_day - 1) * 4 + from_phase
	var finish = (to_day - 1) * 4 + to_phase
	var now = Clock.stamp()
	if now < start or now > finish:
		return false
	if not only_phases.is_empty() and Clock.phase not in only_phases:
		return false
	return true
#This bassicly just does a whole checker to make sure everything passes correctly :D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
