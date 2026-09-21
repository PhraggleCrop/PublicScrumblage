## Global manager of event signals
## Hook up to it to trigger when things happen

extends Node
## Emitted when a hit occurs
signal hit

## Emitted after calculation when damage is applied
## This is what BS's HitProcessor connects to
signal _successfully_damaged_

signal attribute_damage
## Emits when a crit occurs
signal critted

## Emits when a match ends
signal match_end

## Emits when someone critted
signal critter

## Emits when someone has a status applied or removed
signal status_effected

## Emits to cause screen shake
signal shake

## Signal emitted when a dodge occurs
signal dodge_event(attacker,dodger)

## Emits at round start, end, winning
signal round_start
signal round_end
signal won
signal winners
signal lock_health

## Emits when a special move triggers
signal s_move

## Signal thats emitted when behaviourscripts spawn stuff
## Arguement is a data dictionary
## EventManager.thing_spawned.emit(ball,new_thing)
signal thing_spawned

var round_time:float=99.0
var round_ongoing=false

signal round_set

var extra_lives :Dictionary = {}
var downed:Array = []

signal update_extra_lives

func set_extra_lives(ball:BallBodyBase,count:int):
	extra_lives[ball]=count
	update_extra_lives.emit(ball,count)

func _ready() -> void:
	await get_tree().process_frame
	round_set.emit()

func log_revived(ball:BallBodyBase):
	downed.erase(ball)

func log_downed(ball:BallBodyBase):
	downed.append(ball)
	
	var team_checker:Dictionary = {}
	for i in team_check_dict.keys():
		if !team_checker.keys().has(i):
			team_checker[i]=[]
		team_checker[i]=team_check_dict[i]
	
	## Check how many balls are downed on our downed balls team
	## If it equals the number of balls on their team, we delete 
	var down_count=0
	for i in downed:
		if i.team==ball.team:
			down_count+=1
			
	if team_check_dict[ball.team].size()==down_count:
		var id = ball.team
		for i in downed:
			if i.team==id:
				i.queue_free()

func check_downeds():
	var team_checker:Dictionary = {}
	for i in get_tree().get_nodes_in_group("Main"):
		if !team_checker.keys().has(i.team):
			team_checker[i.team]=[]
		team_checker[i.team].append(i)
	for i in team_checker.keys():
		var check=false
		for x in team_checker[i]:
			if !x.reviving:
				check=true
		if check==false:
			for x in team_checker[i]:
				x.queue_free()
				
func process_death(ball:BallBodyBase):
	var x_lives = extra_lives.get(ball,0)
	if x_lives>0:
		set_extra_lives(ball,x_lives-1)
		ball.revive_sequence()
	else:
		#print("DELETE")
		deleting_node.emit(ball)
		ball.queue_free()
		await get_tree().process_frame
		check_downeds()
signal deleting_node

func start_music():
	if get_tree().get_nodes_in_group("Super").size()>0:
		MusicManager.play_music(load("res://Music/superballsbattle.mp3"), 1.0, true)
		return
		
	match Global.skin_mode:
		"Summer":
			MusicManager.play_music(load("res://Music/Beach Where OCs Go to Ball Lab.mp3"), 1.0, true)
		_:
			MusicManager.play_music(load("res://Music/hit it.mp3"), 1.0, true)
		
func win_stinger():
	if get_tree().get_nodes_in_group("Super").size()>0:
		SoundQueue.play("res://Music/superballsbattleWIN.mp3", 1.0, 0.4)
		return
	match Global.skin_mode:
		"Summer":
			SoundQueue.play("res://Music/Beach Where OCs Go to WIN.mp3", 1.0, 0.25)
		_:
			SoundQueue.play("res://Music/hit it win.mp3",1,0.7)
		

## Calls a special move effect to happen
## Zooms onto ball and displays a graphic
func special_move(ball:BallBodyBase,graphic:Texture=load("res://Assets/testgraphic.png"),sound:String="res://Balls/Fighters/Hiro/Special_Hiro.wav"):
	s_move.emit(ball.global_position,graphic)
	await get_tree().create_timer(0.65)
	if sound!="":
		SoundQueue.play(sound)

var team_check_dict : Dictionary = {}

func start_round():
	EventManager.round_start.emit()
	round_ongoing=true
	team_check_dict.clear()
	for i in get_tree().get_nodes_in_group("Main"):
		if team_check_dict.has(i.team):
			team_check_dict[i.team].append(i)
		else:
			team_check_dict[i.team]=[i]
		i.tree_exiting.connect(_rem.bind(i))
	
	count_emit()

func _rem(ball):
	for i in team_check_dict.keys():
		team_check_dict[i].erase(ball)
		if team_check_dict[i].size()==0:
			team_check_dict.erase(i)
			
## Emits number of fighters
signal fighter_count_update
signal team_count_update

signal resize_camera_arena

func count_emit():
	var count = 0
	for i in team_check_dict.keys():
		count+=team_check_dict[i].size()
	fighter_count_update.emit(count)


signal died
func something_died():
	if !round_ongoing:
		return
	await get_tree().physics_frame
	died.emit()
	team_count_update.emit(team_check_dict.size())
	count_emit()
	
	if team_check_dict.size()<=1:
		won.emit()
		lock_health.emit()
		winners.emit(get_tree().get_nodes_in_group("Main"))
		MusicManager.stop_music()
		round_ongoing=false
	
func _process(delta):
	if HitstopManager.hitstopped:
		return
	if !round_ongoing or round_time<=0:
		return
	round_time-=delta
	if round_time<=0.0 and !HitstopManager.hitstopped:
		
		round_time=0.0
		round_end.emit()
		lock_health.emit()
		HitstopManager.set_histop(99999)
		SoundQueue.play("res://Sounds/foul-short-wet-whistle-fx_C_minor.wav",1.2,1)
	
