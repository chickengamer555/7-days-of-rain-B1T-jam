extends CanvasLayer

const BOOK = preload("res://data/ledger_book.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Clock.phase_changed.connect(update_clock)  # Move hands each face
	Ledger.entry_learned.connect(flash_new_entry) #Flash when smth learned
	$NewEntryTimer.timeout.connect($NewEntryIcon.hide) # zHide icon timer ends
	$ClockFace/HourHand.rotation = Clock.phase * TAU / 4 # Point at phase no spin
	$DayLabel.text = str(Clock.day) # Shows day

func update_clock(): # Tween animation for clock hands spinning 
	var target = Clock.phase * TAU / 4
	if target < $ClockFace/Hourhand.rotation:
		$ClockFace/Hourhand.rotation -= TAU
	var tween = create_tween().set_parallel()
	tween.tween_property($ClockFace/Hourhand, "rotation", target, 0.5)
	tween.tween_property($ClockFace/MinuteHand, "rotation", TAU, 0.5).from(0.0)
	$DayLabel.text = str(Clock.day)

func flash_new_entry(id):
	for entry in BOOK.entries:
		if entry.id == id:
			$NewEntryIcon.show()
			$NewEntryTimer.start()
			return


func _unhandled_input(event): # Make sure the proper keys are pressed and handling all input actions 
	if event.is_action_pressed("Ledger") and not Dialouge.active:
		if $LedgerScreen.visible:
			close_ledger()
		else:
			open_ledger()
	elif $LedgerScreen.visible and event.is_action_pressed("up"):
		$LedgerScreen/Scroll.scroll_vertical -= 20
	elif $LedgerScreen.visible and event.is_action_pressed("down"):
		$LedgerScreen/Scroll.scroll_vertical += 20

func open_ledger(): # Opens the ledgers checks which ones we know which ones we dont and adds the ones we do know to a list to displayit 
	Clock.running = false
	for child in $LedgerScreen/Scroll/Lines.get_children():
		child.queue_free()
	for entry in BOOK.entries:
		if Ledger.known.has(entry.id):
			var learned = Ledger.known[entry.id]
			var label = Label.new()
			label.text = " Day " + str(learned["day"]) + ", phase " + str(learned["phase"]) + ": " + entry.text
			label.autowrap_mode = TextServer.AUTOWRAP_WORD
			$LedgerScreen/Scroll/Lines.add_child(label)
	$LedgerScreen.show()

func close_ledger(): # Closes the ledger simply 
	$LedgerScreen.hide()
	Clock.running = true
