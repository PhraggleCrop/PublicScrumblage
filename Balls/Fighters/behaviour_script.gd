extends Node
class_name BehaviourScript
## Reference to ball's stat controller
var sc :StatController
var creator_script:BehaviourScript

## Gets reference to ball
## Make sure behaviour script is child of main ball
@onready var ball:BallBodyBase = get_parent()

## Flag that enables/disables the behaviour
@export var behaviour_active = true

## Set base stuff
func _ready():
	sc=ball.stat_controller
	sc.stat_changed.connect(update_stats)
	sc.add_alias("BehaviourScript.behaviour_active", "BehaviourScript.behaviour_active")
	sc.set_base_stat("BehaviourScript.behaviour_active",true)
	EventManager._successfully_damaged_.connect(hit_process)
	ball.tree_exiting.connect(clear_list)
	ball.set_skin.connect(update_skin)

## GOES THROUGH TREE AND REPLACE ANY TEXTURES WITH A NEW TEXTURE
func replace_texture_recursive(node, old_tex, new_tex):
	# If node has a texture property
	if "texture" in node:
		if node.texture == old_tex:
			node.texture = new_tex
	# Scan children
	for child in node.get_children():
		replace_texture_recursive(
			child,
			old_tex,
			new_tex
		)
		
		
func update_skin():
	return
## This function is called when EventManager emits that something has been damaged.
## Grab the data and filter to make specific behaviours trigger from damage
func hit_process(data:Dictionary):
	return

## Use an await delay(x) to do a wait in code, that's compatible with hitstops
func delay(seconds:float):
	await STimer.delay_bs(seconds,self)
	return

## Update stats
func update_stats(stat_name,new_val):
	match stat_name:
		"Ball.enabled":
			behaviour_active=new_val and ball.enabled
			if new_val==true:
				process_mode=Node.PROCESS_MODE_INHERIT
			else:
				process_mode=Node.PROCESS_MODE_DISABLED
		"BehaviourScript.behaviour_active":
			behaviour_active=new_val and ball.enabled
			if new_val==true:
				process_mode=Node.PROCESS_MODE_INHERIT
			else:
				process_mode=Node.PROCESS_MODE_DISABLED

## Spawn list contains everythig spawned
var spawn_list = []
var delete_list = []

## Used to spawn other balls into the game
## Automatically parenting can be disabled for specific behaviours
## By default they are deleted when ball dies, but can disable too
## Additional data is stuff you can tag to data emitted when objet created
func spawn_thing(res,auto_parent:bool=true,delete_on_death:bool=true,additional_data:Dictionary={})->BallBodyBase:
	var new_thing = res.instantiate()
	new_thing.skin=ball.skin
	new_thing.creator_ball = ball
	new_thing.global_position=ball.global_position
	for i in new_thing.get_children():
		if i is BehaviourScript:
			i.creator_script=self
	if auto_parent:
		ball.get_parent().add_child(new_thing)
		#call_deferred("add_child",new_thing)
	new_thing.hitstop_effect(ball.freezed)
	new_thing.set_team(ball.team)
	new_thing.tree_exiting.connect(_remove_from_list.bind(new_thing))
	new_thing.skin=ball.skin
	spawn_list.append(new_thing)
	spawn_list_updated.emit()
	
	if delete_on_death:
		delete_list.append(new_thing)
		new_thing.tree_exiting.connect(_remove_from_dlist.bind(new_thing))
	
	if additional_data.get("AUTOTEAM",true):
		ball.team_setted.connect(new_thing.set_team)
		
	var spawn_data = {"SPAWNER":ball,"SPAWNED":new_thing}
	spawn_data.merge(additional_data)
	EventManager.thing_spawned.emit(spawn_data)
	return new_thing

func _remove_from_list(thing:BallBodyBase):
	spawn_list.erase(thing)
	spawn_list_updated.emit()
	
func _remove_from_dlist(thing:BallBodyBase):
	delete_list.erase(thing)

signal spawn_list_updated

## Called when ball is delete, delete things in delete list
func clear_list():
	for i in delete_list:
		i.destruction()



func utility_sfx(path:String):
	SoundQueue.play(path)

func utility_quake(strength:float):
	Global.quake_trigger.emit(strength)
