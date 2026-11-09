extends CanvasLayer

const BOOK = preload("res://data/ledger_book.tres")
const FONT = preload("res://Assets/UI/old-school-adventures-font/OldSchoolAdventures-42j9.ttf")
const LINE_HEIGHT = 10
const MARGIN = 12
const INK = Color("#1e1c32")

var mouse: Image = _make_cursor()
var margin_style = StyleBoxEmpty.new() 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	margin_style.content_margin_left = MARGIN + 3
	$LedgerScreen/Scroll/Lines.draw.connect(draw_ruling)
	Clock.phase_changed.connect(update_clock)  # Move hands each face
	Ledger.entry_learned.connect(flash_new_entry) #Flash when smth learned
	$NewEntryTimer.timeout.connect($NewEntryIcon.hide) # zHide icon timer ends
	$DayLabel.text = str(Clock.day) # Shows day
	$HourglassBox/HourglassButton.pressed.connect(_on_hourglass_pressed)
	$HourglassBox/HourglassButton.button_down.connect(func(): $HourglassBox.position.y = 8)
	$HourglassBox/HourglassButton.button_up.connect(func(): $HourglassBox.position.y = 7)
	update_hourglass_visibility()

func update_clock(): # Tween animation for clock hands spinning 
	$DayLabel.text = str(Clock.day)
	update_hourglass_visibility()

func update_hourglass_visibility() -> void:
	var has_looped: bool = false
	if Flags != null and Flags.has("loop_completed"):
		has_looped = true
	elif Ledger != null and (Ledger.loop_count >= 1 or Ledger.known.has("A1")):
		has_looped = true

	if has_looped and Clock.day < 7:
		$HourglassBox.show()
	else:
		$HourglassBox.hide()

func _on_hourglass_pressed() -> void:
	if Transition != null and Transition.busy:
		return
	if Dialouge != null and Dialouge.active:
		return
	if $LedgerScreen.visible:
		return
	if Clock.day >= 7:
		return

	if Sound:
		Sound.play_button()

	if Transition != null:
		Transition.swap(func():
			Clock.advance_day()
			if Sound != null:
				Sound.play_whoosh(1.5, 0.8)
		)
	else:
		Clock.advance_day()
		if Sound != null:
			Sound.play_whoosh(1.5, 0.8)

func _process(delta):
	var seconds = floor(Clock.elapsed)
	var day_progress = (Clock.phase + seconds / Clock.SECONDS_PER_PHASE) / 4.0 # How far through  day
	$ClockFace/MinuteHand.rotation = day_progress * TAU # Minute hand does a turn each day 
	$ClockFace/HourHand.rotation = (Clock.day - 1 + day_progress) * TAU / 12 # Hour hand does full loop like real clock

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
	if Sound:
		Sound.play_whoosh(-4.0, 1.35)
	Input.set_custom_mouse_cursor(mouse, Input.CURSOR_ARROW, Vector2(21, 0))
	Clock.running = false
	for child in $LedgerScreen/Scroll/Lines.get_children():
		child.queue_free()
	$LedgerScreen/Scroll/Lines.add_theme_constant_override("separation", 0) # entries stack 10px apart
	for entry in BOOK.entries:
		if Ledger.known.has(entry.id):
			var learned = Ledger.known[entry.id]
			var label = Label.new()
			label.text = " Day " + str(learned["day"]) + ", phase " + str(learned["phase"]) + ": " + entry.text
			label.autowrap_mode = TextServer.AUTOWRAP_WORD
			label.add_theme_font_override("font", FONT) # use proper font
			label.add_theme_font_size_override("font_size", 7) # font size
			label.add_theme_color_override("font_color", INK) # color
			label.add_theme_constant_override("line_spacing", 0) # No gaps
			label.add_theme_stylebox_override("normal", margin_style) # start after margin
			$LedgerScreen/Scroll/Lines.add_child(label)
	$LedgerScreen/Scroll/Lines.queue_redraw() # Redraw lines for new page hight
	$LedgerScreen.show()

func close_ledger(): # Closes the ledger simply 
	if Sound:
		Sound.play_button()
	Input.set_custom_mouse_cursor(null)
	$LedgerScreen.hide()
	Clock.running = true
	update_hourglass_visibility()

func draw_ruling():
	var page = $LedgerScreen/Scroll/Lines # page
	var y = LINE_HEIGHT  # First line at bottom of first row
	while y < page.size.y: #untill bottom of the page 
		page.draw_rect(Rect2(0, y, page.size.x, 1), INK) # 1 pixel line
		y += LINE_HEIGHT # down 1 row
	page.draw_rect(Rect2(MARGIN, 0, 1, page.size.y), INK)
		
func _make_cursor() -> Image: # Just couldnt be fucked to edit the mouse image so coded the crop
	var img: Image = load("res://Assets/UI/New Piskel-1.png.png").get_image()  
	img = img.get_region(Rect2i(6, 12, 16, 16))   
	img.resize(48, 48, Image.INTERPOLATE_NEAREST) 
	return img
