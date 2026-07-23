extends VSBase

@export_category("Team 1")
var team1_name: String = "Team Red"
var team1_audio : String
@export var ball1a_res: Resource
@export var ball1b_res: Resource

@export_category("Team 2")
var team2_name: String = "Team Blue"
var team2_audio : String
@export var ball2a_res: Resource
@export var ball2b_res: Resource

var p1a: Dictionary = {}
var p1b: Dictionary = {}
var p2a: Dictionary = {}
var p2b: Dictionary = {}
var team_duration = 0.7

const TEAM = preload("uid://cwx5gfoly55ad")
const AND = preload("uid://csfd6l238pnnv")

@onready var spawnpos_1a = $Spawnpos1a
@onready var spawnpos_1b = $Spawnpos1b
@onready var spawnpos_2a = $Spawnpos2a
@onready var spawnpos_2b = $Spawnpos2b

@onready var vs_spawn_1a = $VS/VsSpawn1a
@onready var vs_spawn_1b = $VS/VsSpawn1b
@onready var vs_spawn_2a = $VS/VsSpawn2a
@onready var vs_spawn_2b = $VS/VsSpawn2b

const WIN_BUBBLE_TEAM = preload("uid://bg42ux7vs0uyj")

# Returns true if a team has only one character
func team1_is_solo() -> bool:
	return ball1a_res != null and ball1b_res == null

func team2_is_solo() -> bool:
	return ball2a_res != null and ball2b_res == null


func _ready():
	VERSUS = load("res://Sounds/TeamAudio/versus.wav")
	TTS_WINS = load("res://Sounds/TeamAudio/wins.wav")
	await loop_pause()
	Global.game_mode = Global.GAME_MODES.DUO
	EventManager.round_time = 123

	Global.team_fight = true

	$VS.visible = true

	EventManager.won.connect(winner_display)

	setup_players()
	setup_stats()

	var arts = get_tree().get_nodes_in_group("SplashArt")
	setup_splash_arts(arts)
	setup_quotes()
	setup_names(arts)

	await intro_sequence()
	EventManager.start_round()


func setup_players():
	if ball1a_res:
		var b = ball1a_res.instantiate()
		b.global_position = spawnpos_1a.global_position
		add_child(b)
		b.set_team(1)
		p1a["BALL"] = b
		if !ball1b_res:
			b.global_position =(spawnpos_1a.global_position+spawnpos_1b.global_position)/2.0

	if ball1b_res:
		var b = ball1b_res.instantiate()
		b.global_position = spawnpos_1b.global_position
		add_child(b)
		b.set_team(1)
		p1b["BALL"] = b
		if !ball1a_res:
			b.global_position =(spawnpos_1a.global_position+spawnpos_1b.global_position)/2.0

	if ball2a_res:
		var b = ball2a_res.instantiate()
		b.global_position = spawnpos_2a.global_position
		add_child(b)
		b.set_team(2)
		p2a["BALL"] = b
		if !ball2b_res:
			b.global_position =(spawnpos_2a.global_position+spawnpos_2b.global_position)/2.0

	if ball2b_res:
		var b = ball2b_res.instantiate()
		b.global_position = spawnpos_2b.global_position
		add_child(b)
		b.set_team(2)
		p2b["BALL"] = b
		if !ball2a_res:
			b.global_position =(spawnpos_2a.global_position+spawnpos_2b.global_position)/2.0



func setup_stats():
	var counter := 0
	var list = get_tree().get_nodes_in_group("BStats")
	
	
	if team1_is_solo():
		list.insert(1,null)
		
	for i in list.size():
		if list[i]==null:
			counter+=1
			continue
		
		var dont_hide=false
		if i<2:
			if team1_is_solo():
				dont_hide=true
		else:
			if team2_is_solo():
				dont_hide=true
				
		if dont_hide==false:
			list[i].box.get_node("DescriptionBox").visible = false
		
		if i==0:
			%BStatMarker.set_target(list[i].box)
		elif i==1:
			%BStatMarker2.set_target(list[i].box)
		elif i==2:
			%BStatMarker3.set_target(list[i].box)
		elif i==3:
			%BStatMarker4.set_target(list[i].box)


func setup_splash_arts(arts):
	# Team 1 side
	if team1_is_solo():
		arts[0].reparent(flame_left)
		arts[0].rotation = -flame_left.rotation
		arts[0].global_position = vs_spawn_1a.global_position+Vector2(0,110)
		if arts[0].alignment_chart:
			arts[0].alignment_chart.global_position = $VS/Left/ACMarker.global_position
	else:
		arts[0].reparent(flame_left)
		arts[1].reparent(flame_left)
		arts[0].rotation = -flame_left.rotation
		arts[1].rotation = -flame_left.rotation
		arts[0].global_position = vs_spawn_1a.global_position
		arts[1].global_position = vs_spawn_1b.global_position
	for art in arts:
		if art.alignment_chart:
			art.alignment_chart.queue_free()

	# Team 2 side — index offset depends on team 1 size
	var t2_offset = 1 if team1_is_solo() else 2

	if team2_is_solo():
		arts[t2_offset].reparent(flame_right)
		arts[t2_offset].rotation = -flame_right.rotation
		arts[t2_offset].global_position = vs_spawn_2a.global_position
		if arts[t2_offset].alignment_chart:
			arts[t2_offset].alignment_chart.global_position = $VS/Right/ACMarker.global_position
	else:
		arts[t2_offset].reparent(flame_right)
		arts[t2_offset + 1].reparent(flame_right)
		arts[t2_offset].rotation = -flame_right.rotation
		arts[t2_offset + 1].rotation = -flame_right.rotation
		arts[t2_offset].global_position = vs_spawn_2a.global_position
		arts[t2_offset + 1].global_position = vs_spawn_2b.global_position
	for art in arts:
		if art.alignment_chart:
			art.alignment_chart.queue_free()


func setup_names(arts):
	# Solo side: use the character's own name_text just like VSBase does
	if team1_is_solo():
		$VS/Left/SplashName.text = arts[0].name_text.to_upper()
	else:
		$VS/Left/SplashName.text = team1_name.to_upper()

	var t2_offset = 1 if team1_is_solo() else 2
	if team2_is_solo():
		$VS/Right/SplashName.text = arts[t2_offset].name_text.to_upper()
	else:
		$VS/Right/SplashName.text = team2_name.to_upper()


func setup_quotes():
	var team1_data = null
	if team1_is_solo():
		team1_data = null
	else:
		team1_data=find_team_data(ball1a_res.resource_path, ball1b_res.resource_path)

	var team2_data = null 
	if team2_is_solo():
		team2_data = null 
	else:
		team2_data = find_team_data(ball2a_res.resource_path, ball2b_res.resource_path)

	## Team 1 quote
	if team1_is_solo():
		# VSBase behaviour: WinQuote nodes are already in the scene, nothing to instantiate
		var solo_quotes = get_tree().get_nodes_in_group("WinQuote")
		if solo_quotes.size() > 0:
			solo_quotes[0].global_position = $WinQuoteRight.global_position
			quotes.append(solo_quotes[0])
	elif team1_data != null:
		var team_quote = _build_team_quote(team1_data)
		team1_audio = team1_data.get("team_audio", "")
		team1_name  = team1_data.get("team_name", team1_name)
		$WinQuoteRight.add_child(team_quote)
		team_quote.position-=team_quote.size/2.0
		quotes.append(team_quote)
	else:
		quotes.append(null)
	## Team 2 quote
	if team2_is_solo():
		var solo_quotes = get_tree().get_nodes_in_group("WinQuote")
		# The second solo quote is index 1 if team1 is also solo, otherwise index 0
		var idx = 1 if team1_is_solo() else 0
		if solo_quotes.size() > idx:
			solo_quotes[idx].global_position = $WinQuoteLeft.global_position
			quotes.append(solo_quotes[idx])
	elif team2_data != null:
		var team_quote = _build_team_quote(team2_data)
		team2_audio = team2_data.get("team_audio", "")
		team2_name  = team2_data.get("team_name", team2_name)
		$WinQuoteLeft.add_child(team_quote)
		team_quote.position-=team_quote.size/2.0
		quotes.append(team_quote)
	else:
		quotes.append(null)

func _build_team_quote(data: Dictionary) -> MarginContainer:
	var team_quote: MarginContainer = WIN_BUBBLE_TEAM.instantiate()
	var lines: Array = data["lines"]

	var vbox: VBoxContainer = team_quote.get_node("MarginContainer/VBoxContainer")
	var template: Label = vbox.get_node("Description")

	# get rid of the second hardcoded label — duplication handles any line count now
	var description2 := vbox.get_node_or_null("Description2")
	if description2:
		description2.queue_free()

	for i in range(lines.size()):
		var line_node: Label = template if i == 0 else template.duplicate()
		if i > 0:
			vbox.add_child(line_node)
		line_node.text     = lines[i]["line"]
		line_node.modulate = TeamDictionary.colorInfo[lines[i]["color"]]

	return team_quote


func find_team_data(ball1_path, ball2_path):
	## Get name ids of each character
	var b1_name = TeamDictionary.ballInfo.get(ball1_path,null)
	if b1_name == null:
		return null
	#b1_name = b1_name[1]
	
	var b2_name = TeamDictionary.ballInfo.get(ball2_path,null)
	if b2_name == null:
		return null
	#b2_name = b2_name[1]
	
	## Get team data combinations based off ids
	return TeamDictionary.get_team_data(b1_name,b2_name)
	


func intro_sequence():
	await get_tree().create_timer(0.2).timeout

	Global.quake_trigger.emit(1.8)
	SoundQueue.play("res://Sounds/SSBINTRO.mp3", 0.76, 0.6)

	await get_tree().create_timer(1.16).timeout

	var arts = get_tree().get_nodes_in_group("SplashArt")
	p1a["SFX_NAME"] = arts[0].name_sound
	if not team1_is_solo():
		p1b["SFX_NAME"] = arts[1].name_sound

	var t2_offset = 1 if team1_is_solo() else 2
	p2a["SFX_NAME"] = arts[t2_offset].name_sound
	if not team2_is_solo():
		p2b["SFX_NAME"] = arts[t2_offset + 1].name_sound

	# Also mirror solo name sound into p1/p2 dicts so VSBase winner_audio path works
	if team1_is_solo():
		p1["SFX_NAME"] = p1a["SFX_NAME"]
	if team2_is_solo():
		p2["SFX_NAME"] = p2a["SFX_NAME"]

	await sound_names()

	slide_out_and_back($VS/Left,  $VS/Left.global_position  + Vector2(-offsetter, 0))
	slide_out_and_back($VS/Right, $VS/Right.global_position + Vector2(offsetter,  0))

	sliding = true
	SoundQueue.play("res://Sounds/short-riser_125bpm.wav", 0.8, 0.8)

	await get_tree().create_timer(0.55).timeout
	sliding = false
	EventManager.start_music()

	await get_tree().create_timer(1.65).timeout


func sound_names():
	await team1_name_sfx()

	audio_stream_player.stream = VERSUS
	audio_stream_player.play()
	await get_tree().create_timer(1).timeout

	await team2_name_sfx()


func team1_name_sfx():
	if team1_audio != "":
		audio_stream_player.stream = TEAM
		audio_stream_player.play()
		await get_tree().create_timer(team_duration).timeout
		audio_stream_player.stream = load(team1_audio)
		audio_stream_player.play()
		await get_tree().create_timer(1.2).timeout
	elif team1_is_solo():
		# VSBase solo behaviour: just play the one name sound
		audio_stream_player.stream = p1a["SFX_NAME"]
		audio_stream_player.play()
		await get_tree().create_timer(1).timeout
	else:
		audio_stream_player.stream = p1a["SFX_NAME"]
		audio_stream_player.play()
		await get_tree().create_timer(0.9).timeout
		audio_stream_player.stream = AND
		audio_stream_player.play()
		await get_tree().create_timer(0.5).timeout
		audio_stream_player.stream = p1b["SFX_NAME"]
		audio_stream_player.play()
		await get_tree().create_timer(1.1).timeout


func team2_name_sfx():
	if team2_audio != "":
		audio_stream_player.stream = TEAM
		audio_stream_player.play()
		await get_tree().create_timer(team_duration).timeout
		audio_stream_player.stream = load(team2_audio)
		audio_stream_player.play()
		await get_tree().create_timer(1.2).timeout
	elif team2_is_solo():
		audio_stream_player.stream = p2a["SFX_NAME"]
		audio_stream_player.play()
		await get_tree().create_timer(1).timeout
	else:
		audio_stream_player.stream = p2a["SFX_NAME"]
		audio_stream_player.play()
		await get_tree().create_timer(0.9).timeout
		audio_stream_player.stream = AND
		audio_stream_player.play()
		await get_tree().create_timer(0.5).timeout
		audio_stream_player.stream = p2b["SFX_NAME"]
		audio_stream_player.play()
		await get_tree().create_timer(1.1).timeout


func winner_audio(p):
	if p == 1:
		if team1_is_solo():
			# VSBase path: play name then "wins"
			audio_stream_player.stream = p1["SFX_NAME"]
			audio_stream_player.play()
			await get_tree().create_timer(1).timeout
		else:
			await team1_name_sfx()
	else:
		if team2_is_solo():
			audio_stream_player.stream = p2["SFX_NAME"]
			audio_stream_player.play()
			await get_tree().create_timer(1).timeout
		else:
			await team2_name_sfx()
	await get_tree().create_timer(0.2).timeout
	audio_stream_player.stream = TTS_WINS
	audio_stream_player.play()


func winner_display():
	$VS/Left/FlameLeft/VS.visible  = false
	$VS/Right/FlameRight/VS.visible = false

	SoundQueue.play("res://Sounds/victory-sound_130bpm_F_major.wav", 1, 0.7)

	await get_tree().create_timer(0.8).timeout
	EventManager.win_stinger()
	await get_tree().create_timer(2.65).timeout

	var nodes  = get_tree().get_nodes_in_group("Main")
	var winner = get_winner(nodes)
	var delay  = 0.85

	vs.winner_display(winner)

	if winner == null:
		audio_stream_player.stream = TIE
		audio_stream_player.play()
	
	elif is_p1_winner(winner):
		$VS/Left.visible = true

		if quotes.get(0)!=null:
			quotes[0].fade_in()

		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).tween_property($VS/Left, "global_position", $VS/Left.global_position + Vector2(offsetter, 0), delay)

		await get_tree().create_timer(1.1).timeout
		SoundQueue.play("res://Sounds/children-yay-sfx.wav", 1, 0.5)
		await get_tree().create_timer(1.5).timeout
		winner_audio(1)

	elif is_p2_winner(winner):
		$VS/Right.visible = true

		if quotes.get(1)!=null:
			quotes[1].fade_in()

		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).tween_property($VS/Right, "global_position", $VS/Right.global_position + Vector2(-offsetter, 0), delay)

		await get_tree().create_timer(1.1).timeout
		SoundQueue.play("res://Sounds/children-yay-sfx.wav", 1, 0.5)
		await get_tree().create_timer(1.5).timeout
		winner_audio(2)

	await get_tree().create_timer(2.7).timeout
	Global.art_showcase.emit()


func is_p1_winner(winner):
	return winner == p1a.get("BALL") or (not team1_is_solo() and winner == p1b.get("BALL"))

func is_p2_winner(winner):
	return winner == p2a.get("BALL") or (not team2_is_solo() and winner == p2b.get("BALL"))
