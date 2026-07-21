extends VSBase
#left over from a test, dont use this !
@export var boss_res: Resource
@export var ball1a_res: Resource
@export var ball1b_res: Resource
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

var boss_music = {
	'???': load("res://GameStuff/BossStuff/Sound/cannonBall.mp3"),
	#'Beta??': load()
}

var unique_banner : bool = false # switches to true if the boss character has a unique warning banner

func _ready():
	Global.game_mode=Global.GAME_MODES.DUO
	EventManager.round_time = 180
	Global.team_fight = true
	
	TTS_WINS=load("res://Sounds/TeamAudio/wins.wav")
	VERSUS=load("res://Sounds/TeamAudio/versus.wav")
	TIE=load("res://Sounds/TeamAudio/tie.wav")
	
	
	$VS.visible = true
	$Winner.visible = false
	$VS/Boss.scale.y = 0.0

	EventManager.won.connect(winner_display)

	setup_team()
	setup_boss()
	setup_stats()
	
	var arts = get_tree().get_nodes_in_group("SplashArt")
	setup_splash_arts(arts)
	setup_names(arts)
	setup_quotes()

	await intro_sequence()

	if ("hasIntro" in p2['BALL'].behaviour_script):
		print('hasIntro found')
		if (p2["BALL"].behaviour_script.hasIntro):
			begin_intro.emit()
			await p2['BALL'].behaviour_script.intro_finished
	else:
		print('not found')

	if boss_music.has(boss_name.text):
		MusicManager.play_music(boss_music.get(boss_name.text, 0), 0, true)
	else:
		MusicManager.play_music(load("res://Music/hit it.mp3"), 1.0, true)

	EventManager.start_round()

func setup_names(arts):
	#$VS/Left/FlameLeft/SplashName.text = raid_team.team_name.to_upper()
	boss_name.text = arts[3].name_text.to_upper()
	
func setup_team():
	if ball1a_res:
		var b = ball1a_res.instantiate()
		b.global_position = spawnpos_1a.global_position
		add_child(b)
		b.set_team(1)
		p1a["BALL"] = b

	if ball1b_res:
		var b = ball1b_res.instantiate()
		b.global_position = spawnpos_1b.global_position
		add_child(b)
		b.set_team(1)
		p1b["BALL"] = b

	if ball1c_res:
		var b = ball1c_res.instantiate()
		b.global_position = spawnpos_1c.global_position
		add_child(b)
		b.set_team(1)
		p1c["BALL"] = b

func setup_boss():
	if boss_res:
		var b2 = boss_res.instantiate()
		b2.global_position = spawnpos_2a.global_position
		add_child(b2)
		b2.set_team(2)
		p2["BALL"] = b2
		
		# checks if the boss has the start_intro signal
		begin_intro.connect(Callable(b2.behaviour_script, 'start_intro'))
		if b2.behaviour_script.has_method("camera_shake"): # checks if the boss has the camera shake method
			b2.behaviour_script.shake_camera.connect(camera_shake)
		if b2.behaviour_script.has_method("open_banner"):
			#print("unique warning banner found")
			unique_banner = true
			$VS/Boss.visible = false
			begin_banner.connect(Callable(b2.behaviour_script, 'open_banner'))
		else:
			#print("banner not found")
			pass

func camera_shake(shake_amount : float):
	$Camera2D.add_quake(shake_amount)

func setup_splash_arts(arts):
	if arts.size() < 2:
		return
	arts[0].reparent(flame_left)
	arts[1].reparent(flame_left)
	arts[2].reparent(flame_right)
	arts[3].reparent(flame_right)

	arts[0].rotation = -flame_left.rotation
	arts[1].rotation = -flame_right.rotation
	arts[2].rotation = -flame_left.rotation
	arts[3].rotation = -flame_right.rotation

	arts[0].global_position = vs_spawn_1a.global_position
	arts[1].global_position = vs_spawn_1b.global_position
	arts[2].global_position = vs_spawn_1c.global_position
	
	arts[3].reparent(boss_banner)
	arts[3].rotation = boss_banner.rotation
	arts[3].global_position = vs_spawn_2a.global_position
	
	for art in arts:
		if art.alignment_chart:
			art.alignment_chart.queue_free()

func sound_boss(): # i had the tween in here cuz im STUPID
	audio_stream_player.stream = RAID_MODE
	audio_stream_player.play()
	await get_tree().create_timer(2.5).timeout

	if unique_banner:
		begin_banner.emit()
		await p2['BALL'].behaviour_script.banner_finished
	else: # if a unique banner isn't found, play the normal one | put the flashes here cuz im a fraud
		var boss_banner_tween = get_tree().create_tween()
		boss_banner.size.y = 450
		boss_banner_tween.tween_property(boss_banner, 'size:y', 550, 0.3).set_trans(Tween.TRANS_QUAD)\
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

	$Camera2D.add_quake(1.8)
	SoundQueue.play("res://Sounds/SSBINTRO.mp3", 0.76, 0.6)

	await get_tree().create_timer(1.16).timeout

	var arts = get_tree().get_nodes_in_group("SplashArt")

	#p1["SFX_NAME"] = raid_team.team_audio
	p2["SFX_NAME"] = arts[3].name_sound # boss name
	
	await sound_boss()

	slide_out_and_back($VS/Left, $VS/Left.global_position + Vector2(-offsetter, 0))
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
	print(winner)
	print(p2.get("BALL"))
	if winner == p2.get("BALL"):
		SoundQueue.play("res://ModdedGameStuff/Bosses/snd_audience_aww.wav", 1, 0.7)
		await get_tree().create_timer(2.5).timeout
	else:
		SoundQueue.play("res://Sounds/victory-sound_130bpm_F_major.wav", 1, 0.7)
		
		await get_tree().create_timer(0.8).timeout
		SoundQueue.play("res://Music/hit it win.mp3",1,0.7)
		await get_tree().create_timer(2.65).timeout


	var delay = 0.85

	$Winner.visible = false
	$Winner.modulate.a = 0.0
	var wtween = get_tree().create_tween()
	wtween.tween_property($Winner, "modulate:a", 1.0, delay).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	$VS.slide_winner()
	if winner == null:
		$Winner/Label.text = "TIE"
		audio_stream_player.stream = TIE
		audio_stream_player.play()

	elif is_p1_winner(winner):
		$VS/Left.visible = true
		$VS/Right.visible = true

		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).tween_property($VS/Left, "global_position", $VS/Left.global_position + Vector2(offsetter, 0), delay)
		tween.parallel().tween_property($VS/Right, "global_position", $VS/Right.global_position + Vector2(-offsetter, 0), delay)

		await get_tree().create_timer(1.1).timeout
		SoundQueue.play("res://Sounds/children-yay-sfx.wav", 1, 0.5)
		await get_tree().create_timer(1.5).timeout
		winner_audio(p1)

	elif is_p2_winner(winner):
		$VS/BossWin.visible = true
		
		var boss_banner_tween = get_tree().create_tween()
		boss_banner_tween.tween_property(boss_banner, 'size:y', 550, 0.5).set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		boss_banner_tween.parallel().tween_property(boss_banner, 'position:y', boss_banner.position.y - 65, 0.5)
		await get_tree().create_timer(0.5)
		boss_quotes[4].fade_in()

		#var tween = get_tree().create_tween()
		#tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).tween_property($VS/Boss, "global_position", $VS/Boss.global_position + Vector2(0, -offsetter), delay)

		await get_tree().create_timer(1.1).timeout
		#SoundQueue.play("res://Sounds/children-yay-sfx.wav", 1, 0.5)
		await get_tree().create_timer(1.5).timeout
		winner_audio(p2)

func is_p1_winner(winner):
	return winner == p1a.get("BALL") or winner == p1b.get("BALL") or winner == p1c.get("BALL")

func is_p2_winner(winner):
	boss_won = true
	return winner == p2.get("BALL")
	
func winner_audio(p):
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
	var boss = get_tree().get_first_node_in_group("BossStat").get_node("DescriptionBox")
	for i in bstats:
		i.get_node("DescriptionBox").visible = false

	boss_stats=get_tree().get_first_node_in_group("BossStat")

	if boss_stats:
		if boss_stats.custom_music_override:
			boss_music=boss_stats.custom_music_override  
		if boss_stats.custom_music_override_ender != "":
			boss_music_end=boss_stats.custom_music_override_ender

	# Only these balls are actually in play this match
	var active_balls := []
	if ball1a_res:
		active_balls.append(ball1a_res)
	if ball1b_res:
		active_balls.append(ball1b_res)
	if ball1c_res:
		active_balls.append(ball1c_res)

	for i in get_tree().get_nodes_in_group("BStats"):

		if i.ball==boss_stats.ball:
			i.visible=false
			continue

		# hide the stat card for any ball resource that wasn't assigned
		if not active_balls.has(i.ball):
			i.visible = false
			continue

		i.scale=Vector2(1,1)*1.15
		i.position = b_stat_marker.position + Vector2(0,counter* offseter)
		counter+=1

	boss_stats.position = Vector2(-55, -115)
	
	boss.position = Vector2(724, 1100)

func setup_quotes():
	quotes = get_tree().get_nodes_in_group("TeamWinQuote")
	
	for i in quotes:
		i.reparent(self)
		
	#quotes[0].global_position = $WinQuoteLeft.global_position
	
	boss_quotes = get_tree().get_nodes_in_group("WinQuote")
	boss_quotes[0].global_position = $WinQuoteRight.global_position
