extends VSBase

@export_category("BOSS")
@export var boss_res: Resource

@export_category("CHARACTERS")
@export var b1_extra_lives:int=1
@export var ball1a_res: Resource
@export var b2_extra_lives:int=1
@export var ball1b_res: Resource
@export var b3_extra_lives:int=1
@export var ball1c_res: Resource

var raid_team : TeamRaid_1v3

signal begin_banner
signal begin_intro

@onready var spawnpos_1a: Marker2D = $Spawnpos1
@onready var spawnpos_1b: Marker2D = $Spawnpos1b
@onready var spawnpos_1c: Marker2D = $Spawnpos1c

@onready var spawnpos_2a: Marker2D = $Spawnpos2

@onready var vs_spawn_1a: Marker2D = $VS/VsSpawn1
@onready var vs_spawn_1b: Marker2D = $VS/VsSpawn1b
@onready var vs_spawn_1c: Marker2D = $VS/VsSpawn1c

@onready var vs_spawn_2a: Marker2D = $VS/VsSpawn2

@onready var flame_top: TextureRect = $VS/Top/FlameTop

@onready var boss_banner: ColorRect = $VS/Boss/BossBanner
@onready var alert: ColorRect = $VS/alert
@onready var boss_name: Label = $VS/Boss/BossBanner/bossName

var p1a: Dictionary = {}
var p1b: Dictionary = {}
var p1c: Dictionary = {}
var p2a: Dictionary = {}

var team_duration=0.7

var TEAM = load("res://Sounds/TeamAudio/team.wav")
var RAID_MODE = load("res://GameStuff/BossStuff/Sound/raid_mode.wav")
var ALERT = load("res://GameStuff/BossStuff/Sound/alert.wav")
var FAILURE = load("res://GameStuff/BossStuff/Sound/failure.wav")

var boss_won : bool = false
var boss_quotes = []

var boss_music:Resource = load("res://GameStuff/BossStuff/Sound/cannonBall.mp3")
var boss_music_end:String = "res://Music/hit it win.mp3"

var unique_banner : bool = false

# to be adaptable for the boss to do 1v1 & 1v2
var boss_num : int = 3 # its number in the array for things like splash art, etc

# using these to keep track of which player variable isnt used
# if p1 is not there, numbers for p2 & p3 will change | writing this here for me
# if p2 is not there, numbers for only p3 will change
# if p3 is not there, nothing ever happens | [-]_[-] |
var player1 : bool = true
var player1_num : int = 0

var player2 : bool = true
var player2_num : int = 1

var player3 : bool = true
var player3_num : int = 2

func _ready():
	Global.game_mode=Global.GAME_MODES.DUO
	EventManager.round_time = 999
	Global.team_fight = true
	
	TTS_WINS=load("res://Sounds/TeamAudio/wins.wav")
	VERSUS=load("res://Sounds/TeamAudio/versus.wav")
	TIE=load("res://Sounds/TeamAudio/tie.wav")
	
	$VS.visible = true

	EventManager.won.connect(winner_display)

	setup_team()
	setup_boss()
	setup_stats()
	
	
	var arts = get_tree().get_nodes_in_group("SplashArt")
	setup_splash_arts(arts)
	setup_names(arts)
	setup_quotes()

	if boss_num < 3:
		$VS/Top.visible = false

	await intro_sequence()

	if ("hasIntro" in p2['BALL'].behaviour_script):
		print('hasIntro found')
		if (p2["BALL"].behaviour_script.hasIntro):
			begin_intro.emit()
			await p2['BALL'].behaviour_script.intro_finished
	else:
		print('not found')
		pass


	MusicManager.play_music((boss_music), 0, true)

	EventManager.start_round()

func setup_names(arts):
	boss_name.text = arts[boss_num].name_text.to_upper()
	
func setup_team():
	if ball1a_res:
		var b = ball1a_res.instantiate()
		b.global_position = spawnpos_1a.global_position
		add_child(b)
		b.set_team(1)
		p1a["BALL"] = b
		EventManager.set_extra_lives(b,b1_extra_lives)
	else:
		player1 = false
		boss_num -= 1
		player2_num -= 1
		player3_num -= 1

	if ball1b_res:
		var b = ball1b_res.instantiate()
		if player1:
			b.global_position = spawnpos_1b.global_position
		else:
			b.global_position = spawnpos_1a.global_position
		add_child(b)
		b.set_team(1)
		p1b["BALL"] = b
		EventManager.set_extra_lives(b,b2_extra_lives)
	else:
		player2 = false
		boss_num -= 1
		player3_num -= 1

	if ball1c_res:
		var b = ball1c_res.instantiate()
		b.global_position = spawnpos_1c.global_position
		add_child(b)
		b.set_team(1)
		p1c["BALL"] = b
		EventManager.set_extra_lives(b,b3_extra_lives)
	else:
		player3 = false
		boss_num -= 1
		if ball1b_res:
			p1b["BALL"].global_position = spawnpos_1c.global_position

func setup_boss():
	if boss_res:
		var b2 = boss_res.instantiate()
		b2.global_position = spawnpos_2a.global_position
		add_child(b2)
		b2.set_team(2)
		p2["BALL"] = b2
		begin_intro.connect(Callable(b2.behaviour_script, 'start_intro'))
		if b2.behaviour_script.has_method("camera_shake"):
			b2.behaviour_script.shake_camera.connect(camera_shake)
		if b2.behaviour_script.has_method("open_banner"):
			unique_banner = true
			$VS/Boss.visible = false
			begin_banner.connect(Callable(b2.behaviour_script, 'open_banner'))
		else:
			unique_banner = false
			$VS/Boss.visible = true

func camera_shake(shake_amount : float):
	$Camera2D.add_quake(shake_amount)

func setup_splash_arts(arts):
	if arts.size() < 2:
		return
	if boss_num < 3:
		vs_spawn_1a.position = Vector2(-367.2, -270.0)
		vs_spawn_1c.position = Vector2(348.0, -270.0)
		
	if player1:
		arts[player1_num].reparent(flame_left)
		arts[player1_num].rotation = -flame_left.rotation
		arts[player1_num].global_position = vs_spawn_1a.global_position
	if player2:
		if !player1:
			arts[player2_num].reparent(flame_left)
			arts[player2_num].rotation = -flame_left.rotation
			arts[player2_num].global_position = vs_spawn_1a.global_position
		if player1 && player3:
			arts[player2_num].reparent(flame_top)
			arts[player2_num].rotation = -flame_top.rotation
			arts[player2_num].global_position = vs_spawn_1b.global_position
		elif !player3:
			arts[player2_num].reparent(flame_right)
			arts[player2_num].rotation = -flame_right.rotation
			arts[player2_num].global_position = vs_spawn_1c.global_position
	if player3:
		arts[player3_num].reparent(flame_right)
		arts[player3_num].rotation = -flame_left.rotation
		arts[player3_num].global_position = vs_spawn_1c.global_position

	arts[boss_num].reparent(flame_right)
	arts[boss_num].rotation = -flame_right.rotation
	arts[boss_num].reparent(boss_banner)
	arts[boss_num].rotation = boss_banner.rotation
	arts[boss_num].global_position = vs_spawn_2a.global_position
	
	for art in arts:
		if art.alignment_chart:
			art.alignment_chart.queue_free()

func sound_boss():
	#audio_stream_player.stream = RAID_MODE
	#audio_stream_player.play()
	
	await get_tree().create_timer(2.5).timeout

	if unique_banner:
		begin_banner.emit()
		await p2['BALL'].behaviour_script.banner_finished
	else:
		var boss_banner_tween = get_tree().create_tween()
		#boss_banner.size.y = 450
		boss_banner_tween.tween_property(boss_banner, 'size:y', 550, 0.5).set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		boss_banner_tween.parallel().tween_property(boss_banner, 'position:y', boss_banner.position.y - 65, 0.3)
		boss_banner_tween.parallel().tween_property(alert, 'modulate:a', 0.5, 0.3)
		boss_banner_tween.tween_property(alert, 'modulate:a', 0.0, 0.3)
		
		audio_stream_player.stream = ALERT
		audio_stream_player.play()
		
		await get_tree().create_timer(0.8).timeout
		
		var alert2_tween = get_tree().create_tween()
		alert2_tween.tween_property(alert, 'modulate:a', 0.5, 0.3)
		alert2_tween.tween_property(alert, 'modulate:a', 0.0, 0.3)
		
		audio_stream_player.play()
		
		await get_tree().create_timer(0.8).timeout
		
		var alert3_tween = get_tree().create_tween()
		alert3_tween.tween_property(alert, 'modulate:a', 0.5, 0.3)
		alert3_tween.tween_property(alert, 'modulate:a', 0.0, 0.3)
		
		audio_stream_player.play()

		await get_tree().create_timer(0.8).timeout

func intro_sequence():
	await get_tree().create_timer(0.2).timeout

	Global.quake_trigger.emit(1.8)
	SoundQueue.play("res://Sounds/SSBINTRO.mp3", 0.76, 0.6)

	await get_tree().create_timer(1.16).timeout

	var arts = get_tree().get_nodes_in_group("SplashArt")
	
	p2["SFX_NAME"] = arts[boss_num].name_sound
	
	await sound_boss()
	
	slide_out_and_back($VS/Left, $VS/Left.global_position + Vector2(-offsetter, 0))
	if boss_num == 3:
		slide_out_and_back($VS/Top, $VS/Top.global_position + Vector2(0, -offsetter))
	slide_out_and_back($VS/Right, $VS/Right.global_position + Vector2(offsetter, 0))
	sliding = true
	SoundQueue.play("res://Sounds/short-riser_125bpm.wav", 0.8, 0.8)
	
	var close_banner_tween = get_tree().create_tween()
	close_banner_tween.tween_property(boss_banner, 'size:y', 0, 0.3).set_trans(Tween.TRANS_QUAD)\
	.set_ease(Tween.EASE_OUT)
	close_banner_tween.parallel().tween_property(boss_banner, 'position:y', boss_banner.position.y + 300, 0.3)
	
	await get_tree().create_timer(0.55).timeout
	sliding = false

	await get_tree().create_timer(1.65).timeout

func winner_display():
	var nodes = get_tree().get_nodes_in_group("Main")
	var winner = get_winner(nodes)
	
	if winner == p2.get("BALL"):
		SoundQueue.play("uid://cqg22wm6v51sm", 1, 0.7)
		await get_tree().create_timer(2.5).timeout
	else:
		SoundQueue.play("res://Sounds/victory-sound_130bpm_F_major.wav", 1, 0.7)
		
		await get_tree().create_timer(0.8).timeout
		
		
		
		SoundQueue.play(boss_music_end,1,0.7)
		
		
		
		await get_tree().create_timer(2.65).timeout

	var delay = 0.85

	vs.winner_display(winner)
	$VS.slide_winner()
	if winner == null:
		audio_stream_player.stream = TIE
		audio_stream_player.play()

	elif winner == p1a.get("BALL") || winner == p1b.get("BALL") || winner == p1c.get("BALL"):
		$VS/Left.visible = true
		$VS/Right.visible = true
		if boss_num == 3:
			$VS/Top.visible = true

		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).tween_property($VS/Left, "global_position", $VS/Left.global_position + Vector2(offsetter, 0), delay)
		tween.parallel().tween_property($VS/Top, "global_position", $VS/Top.global_position + Vector2(0, offsetter), delay)
		tween.parallel().tween_property($VS/Right, "global_position", $VS/Right.global_position + Vector2(-offsetter, 0), delay)

		await get_tree().create_timer(1.1).timeout
		SoundQueue.play("res://Sounds/children-yay-sfx.wav", 1, 0.5)
		await get_tree().create_timer(1.5).timeout
		winner_audio(p1)

	elif is_p2_winner(winner):
		$VS/Boss.visible = true
		var boss_banner_tween = get_tree().create_tween()
		boss_banner_tween.tween_property(boss_banner, 'size:y', 550, 0.5).set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		boss_banner_tween.parallel().tween_property(boss_banner, 'position:y', boss_banner.position.y - 65, 0.5)
		#await get_tree().create_timer(0.5).timeout
		boss_quotes[boss_num].fade_in()

		await get_tree().create_timer(2.5).timeout
		winner_audio(p2)
		
		
	await get_tree().create_timer(2.4).timeout
	Global.art_showcase.emit()

func is_p1_winner(winner):
	
	return winner == p1a.get("BALL") or winner == p1b.get("BALL") or winner == p1c.get("BALL")

func is_p2_winner(winner):
	boss_won = true
	return winner == p2.get("BALL")
	
func winner_audio(_p):
	if !boss_won:
		audio_stream_player.stream = TEAM
		audio_stream_player.play()

		await get_tree().create_timer(1.2).timeout

		audio_stream_player.stream = TTS_WINS
		audio_stream_player.play()
	else:
		audio_stream_player.stream = FAILURE
		audio_stream_player.play()

func setup_stats():
	var counter := 0
	var boss_stats
	var bstats= get_tree().get_nodes_in_group("BStats")
	
	if !p2.get("BALL").get_node("StatsUI/BossDisplay"):
		print("not found")
		var temp = load("res://GameStuff/BossStuff/boss_stat_display.tscn").instantiate()
		p2.get("BALL").get_node("StatsUI").add_child(temp)
	else:
		print("BossDisplay found")
	
	var boss = p2.get("BALL").get_node("StatsUI/BossDisplay/Box/DescriptionBox")
		
	for i in bstats:
		i.box.get_node("DescriptionBox").visible = false
		
	boss_stats=p2.get("BALL").get_node("StatsUI/BossDisplay")
	
	if boss_stats:
		if boss_stats.custom_music_override:
			boss_music=boss_stats.custom_music_override  
		if boss_stats.custom_music_override_ender != "":
			boss_music_end=boss_stats.custom_music_override_ender
	
	
	var bstatlist = get_tree().get_nodes_in_group("BStats")
	
	%BStatMarker.set_target(bstatlist[0].box)
	%BStatMarker2.set_target(bstatlist[1].box)
	%BStatMarker3.set_target(bstatlist[2].box)

	bstatlist[3].box.visible=false
	boss_stats.position = Vector2(-55, -115)
	
	boss.position = Vector2(724, 1100)

func setup_quotes():
	quotes = get_tree().get_nodes_in_group("TeamWinQuote")
	
	#for i in quotes:
		#i.reparent(self)
		
	boss_quotes = get_tree().get_nodes_in_group("WinQuote")
	boss_quotes[0].global_position = $WinQuoteRight.global_position
