extends Node
## Everything the game is heard to do.
##
## It listens to EventBus and plays whatever data/sounds.json names against
## the moment that just happened. No screen calls this to make a noise, and no
## filename appears in any script — a sound is a row in a data file, like
## everything else in this project.
##
## IT SHIPS SILENT. There are no sound files yet. Every entry in sounds.json
## has an empty filename, which is a no-op, and a filename that points at
## something missing logs one quiet line the first time and is then never
## mentioned again. That is the same bargain ArtLoader strikes with art that
## has not been drawn: the wiring is finished and tested now, and becomes
## audible the moment there is something to play.
##
## THREE BUSES, on purpose. Music, Effects and Speech are mixed and muted
## separately, because spoken lines need to be turnable-off without losing
## the score, and the score needs to duck under them when they arrive.
##
## RULES CODE DOES NOT USE THIS. Same rule as EventBus: scripts/rules/ takes
## values in and hands results back, and is tested with none of this running.

const MUSIC := "Music"
const EFFECTS := "Effects"
const SPEECH := "Speech"

const AUDIO_PATH := "res://assets/audio/"

## How many effects can overlap. A card, a gaffe warning and a turn ending
## can all land within a second of each other, and cutting one off to start
## the next sounds like a bug.
const EFFECT_VOICES := 6

var _effect_players: Array[AudioStreamPlayer] = []
var _next_effect := 0
var _music: AudioStreamPlayer = null
var _speech: AudioStreamPlayer = null

## Filenames already reported missing, so a sound that is not there is
## mentioned once rather than on every card played.
var _already_warned: Dictionary = {}


func _ready() -> void:
	_build_players()
	_listen()


# ---------------------------------------------------------------------------
# Asking for a sound
# ---------------------------------------------------------------------------

## Plays a named sound from sounds.json. Unknown names, blank filenames and
## missing files are all quietly nothing.
func play(sound_name: String) -> void:
	var entry := _entry(sound_name)
	if entry.is_empty():
		return

	var stream := _stream(str(entry.get("file", "")))
	if stream == null:
		return

	match str(entry.get("bus", EFFECTS)).to_lower():
		"music": _play_music_stream(stream, bool(entry.get("loop", false)))
		"speech": _play_on(_speech, stream)
		_: _play_effect(stream)


## Starts a piece of music by its name in sounds.json.
##
## A name with no file behind it leaves whatever is playing alone rather than
## stopping it — call stop_music() for that. Silence and "carry on" are the
## same thing while there are no sound files, and will not be later.
func play_music(sound_name: String) -> void:
	play(sound_name)


func stop_music() -> void:
	if _music != null:
		_music.stop()


## Speaks one of a character's lines. Nothing is recorded yet, so this is
## currently always silent — it exists so that the call site can be written
## and reviewed now rather than retrofitted later.
func say(speaker_id: String, line_id: String) -> void:
	# Asked for rather than assumed: a speaker's entry is hand-written, and a
	# malformed one should be silent rather than bring the game down.
	var lines: Variant = DataDB.speech.get(speaker_id)
	if not (lines is Dictionary):
		return
	var stream := _stream(str((lines as Dictionary).get(line_id, "")))
	if stream != null:
		_play_on(_speech, stream)


# ---------------------------------------------------------------------------
# Mixing
# ---------------------------------------------------------------------------
# The three buses are controlled by name rather than by index, because a bus
# that is not in the layout resolves to Master and must not silence the game
# by being volume-adjusted into nothing.

## Sets a bus's volume, 0.0 silent to 1.0 full.
func set_volume(bus: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(clampf(linear, 0.0, 1.0)))


func set_muted(bus: String, muted: bool) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_mute(index, muted)


func is_muted(bus: String) -> bool:
	var index := AudioServer.get_bus_index(bus)
	return index >= 0 and AudioServer.is_bus_mute(index)


# ---------------------------------------------------------------------------
# Listening
# ---------------------------------------------------------------------------
# One place where a thing that happened becomes a thing that is heard. Adding
# a sound to a moment means a row in sounds.json; adding a moment means a
# signal here and an emitter beside it.

func _listen() -> void:
	EventBus.card_played.connect(_on_card_played)
	EventBus.turn_started.connect(func(_turn: int) -> void: play("turn_started"))
	EventBus.turn_ended.connect(func(_turn: int) -> void: play("turn_ended"))
	EventBus.intent_revealed.connect(
		func(_intent: Dictionary) -> void: play("intent_revealed"))
	EventBus.gaffe_changed.connect(_on_gaffe_changed)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.meta_changed.connect(_on_meta_changed)
	EventBus.xp_changed.connect(_on_xp_changed)


func _on_card_played(_card_id: String, result: Dictionary) -> void:
	# A card the room ignores should not sound like one that landed. The
	# battle screen puts this flag in, because whether a card is worth
	# anything HERE is a presentation question the engine's play_card()
	# result does not answer.
	play("card_useless" if bool(result.get("does_nothing", false)) else "card_played")


func _on_gaffe_changed(_value: int, delta: int, _limit: int, is_final_warning: bool) -> void:
	# Only when it ROSE. A card that clears a gaffe is good news and should
	# not sound alarmed — this used to test the meter's value instead of its
	# direction, so clearing a gaffe from three to one still set off the
	# alarm, which is the opposite of what the line above it promised.
	if delta <= 0:
		return
	play("gaffe_final" if is_final_warning else "gaffe")


func _on_battle_ended(outcome: String, _reason: String) -> void:
	stop_music()
	play("battle_won" if outcome == "win" else "battle_lost")


func _on_meta_changed(_name: String, _value: int, delta: int) -> void:
	play("meta_up" if delta > 0 else "meta_down")


func _on_xp_changed(_total: int, delta: int) -> void:
	play("xp_gained" if delta > 0 else "xp_spent")


# ---------------------------------------------------------------------------
# Plumbing
# ---------------------------------------------------------------------------

func _build_players() -> void:
	_music = _make_player(MUSIC)
	_speech = _make_player(SPEECH)
	for i in EFFECT_VOICES:
		_effect_players.append(_make_player(EFFECTS))


## A player on a named bus, or on Master if the layout has no such bus.
##
## Falling back rather than failing matters: a project opened without the bus
## layout should still be audible, not silently broken.
func _make_player(bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus if AudioServer.get_bus_index(bus) >= 0 else "Master"
	add_child(player)
	return player


func _entry(sound_name: String) -> Dictionary:
	var entry: Variant = DataDB.sounds.get(sound_name)
	return entry if entry is Dictionary else {}


## The stream behind a filename, or null for "there isn't one".
func _stream(file: String) -> AudioStream:
	if file.strip_edges().is_empty():
		return null

	var path := AUDIO_PATH + file
	if not ResourceLoader.exists(path):
		if not _already_warned.has(path):
			_already_warned[path] = true
			print("Audio: no sound file at %s yet — staying quiet." % path)
		return null

	return load(path) as AudioStream


## Round-robin, so overlapping effects do not cut each other off.
func _play_effect(stream: AudioStream) -> void:
	if _effect_players.is_empty():
		return
	var player := _effect_players[_next_effect % _effect_players.size()]
	_next_effect += 1
	_play_on(player, stream)


## Sets the loop flag on a COPY, never on the loaded resource.
##
## load() hands back one shared, cached instance, so setting .loop on it
## would change it for everybody: the same file used once as a looping bed
## and once as a one-shot sting would take whichever setting played last.
func _play_music_stream(stream: AudioStream, should_loop: bool) -> void:
	var mine := stream.duplicate() as AudioStream
	if mine is AudioStreamOggVorbis:
		(mine as AudioStreamOggVorbis).loop = should_loop
	elif mine is AudioStreamWAV:
		(mine as AudioStreamWAV).loop_mode = (
			AudioStreamWAV.LOOP_FORWARD if should_loop else AudioStreamWAV.LOOP_DISABLED)
	_play_on(_music, mine)


func _play_on(player: AudioStreamPlayer, stream: AudioStream) -> void:
	if player == null:
		return
	player.stream = stream
	player.play()
