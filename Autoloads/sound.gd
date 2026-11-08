extends Node

# Sound effects manager for 7 Days of Rain
# Handles all 6 SFX: Button Click, Collect, Dialogue, Typewriter, Water Flowing, Wind woosh

var SFX_BUTTON = preload("res://Assets/SFX/Button Click.ogg")
var SFX_COLLECT = preload("res://Assets/SFX/Collect.ogg")
var SFX_DIALOGUE = preload("res://Assets/SFX/Dialogue.ogg")
var SFX_TYPEWRITER = preload("res://Assets/SFX/Typewriter.ogg")
var SFX_WATER = preload("res://Assets/SFX/Water Flowing.ogg")
var SFX_WHOOSH = preload("res://Assets/SFX/Wind woosh.ogg")

var button_player: AudioStreamPlayer
var collect_player: AudioStreamPlayer
var dialogue_player: AudioStreamPlayer
var typewriter_player: AudioStreamPlayer
var water_player: AudioStreamPlayer
var whoosh_player: AudioStreamPlayer

var is_on_boat: bool = false
var water_base_db: float = -14.0
var water_boat_db: float = -7.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Persists and processes across pause & scenes

	# Ensure looping streams are configured
	if SFX_TYPEWRITER is AudioStreamOggVorbis:
		SFX_TYPEWRITER.loop = true
	if SFX_WATER is AudioStreamOggVorbis:
		SFX_WATER.loop = true

	# Dedicated audio players
	button_player = _create_player("ButtonPlayer", -2.0)
	collect_player = _create_player("CollectPlayer", 0.0)
	dialogue_player = _create_player("DialoguePlayer", -4.0)
	typewriter_player = _create_player("TypewriterPlayer", -6.0, SFX_TYPEWRITER)
	water_player = _create_player("WaterPlayer", water_base_db, SFX_WATER)
	whoosh_player = _create_player("WhooshPlayer", -2.0)

	_connect_autoloads()

func _create_player(player_name: String, volume_db: float = 0.0, default_stream: AudioStream = null) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.name = player_name
	p.bus = "Master"
	p.volume_db = volume_db
	if default_stream != null:
		p.stream = default_stream
	add_child(p)
	return p

func _connect_autoloads() -> void:
	# Clue / Ledger entry discovered -> play Collect chime
	var ledger = get_node_or_null("/root/Ledger")
	if ledger and ledger.has_signal("entry_learned"):
		if not ledger.entry_learned.is_connected(_on_entry_learned):
			ledger.entry_learned.connect(_on_entry_learned)

	# Lightning thunder in rain weather -> whoosh gust
	var weather = get_node_or_null("/root/Weather")
	if weather and weather.has_signal("thunder_triggered"):
		if not weather.thunder_triggered.is_connected(_on_thunder):
			weather.thunder_triggered.connect(_on_thunder)

	# Day 7 Flood arrival -> time warp whoosh
	var clock = get_node_or_null("/root/Clock")
	if clock and clock.has_signal("flood_arrived"):
		if not clock.flood_arrived.is_connected(_on_flood):
			clock.flood_arrived.connect(_on_flood)

func _process(_delta: float) -> void:
	# Fast-forward whoosh cue
	if Input.is_action_just_pressed("Fast_foward"):
		play_whoosh(-4.0, 1.25)

	# Ambient water stream management based on active scene
	var scene = get_tree().current_scene
	if scene != null:
		if scene.name == "Main":
			if not water_player.playing:
				start_water()
		elif scene.name == "MainMenu":
			if water_player.playing:
				stop_water()

func _on_entry_learned(_id: String) -> void:
	play_collect()

func _on_thunder() -> void:
	play_whoosh(-4.0, 0.85)

func _on_flood() -> void:
	play_whoosh(1.0, 0.7)

# ----------------- Public Playback API -----------------

func play_button(pitch_scale: float = 1.0) -> void:
	if button_player == null:
		return
	button_player.stream = SFX_BUTTON
	button_player.pitch_scale = pitch_scale * randf_range(0.96, 1.04)
	button_player.play()

func play_collect() -> void:
	if collect_player == null:
		return
	collect_player.stream = SFX_COLLECT
	collect_player.pitch_scale = randf_range(0.98, 1.02)
	collect_player.play()

func play_dialogue(pitch_scale: float = 1.0) -> void:
	if dialogue_player == null:
		return
	dialogue_player.stream = SFX_DIALOGUE
	dialogue_player.pitch_scale = pitch_scale * randf_range(0.95, 1.05)
	dialogue_player.play()

func stop_dialogue() -> void:
	if dialogue_player and dialogue_player.playing:
		dialogue_player.stop()

func play_typewriter() -> void:
	if typewriter_player and not typewriter_player.playing:
		typewriter_player.pitch_scale = randf_range(0.95, 1.05)
		typewriter_player.play()

func stop_typewriter() -> void:
	if typewriter_player and typewriter_player.playing:
		typewriter_player.stop()

func play_whoosh(volume_offset: float = 0.0, pitch_scale: float = 1.0) -> void:
	if whoosh_player == null:
		return
	whoosh_player.stream = SFX_WHOOSH
	whoosh_player.volume_db = -2.0 + volume_offset
	whoosh_player.pitch_scale = pitch_scale * randf_range(0.95, 1.05)
	whoosh_player.play()

func start_water(volume_db: float = NAN) -> void:
	if water_player == null:
		return
	if not is_nan(volume_db):
		water_base_db = volume_db
	water_player.volume_db = water_boat_db if is_on_boat else water_base_db
	if not water_player.playing:
		water_player.play()

func stop_water() -> void:
	if water_player and water_player.playing:
		water_player.stop()

func set_boat_state(on_boat: bool) -> void:
	is_on_boat = on_boat
	if water_player and water_player.playing:
		var target_db = water_boat_db if is_on_boat else water_base_db
		var tween = create_tween()
		if tween:
			tween.tween_property(water_player, "volume_db", target_db, 0.4)
