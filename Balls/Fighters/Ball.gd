extends RigidBody2D
class_name BallBodyBase
## Emit on bounce
## Carries nothing
signal bounce

## Emit when bouncing on a wall
## Carries the wall object it bounced against
signal bounce_wall

## Emit when bouncing against a ball
## Carries the ball it bounced against
signal bounce_ball

## Emits when hitstopped
## Use HitstopManager for signals, dont touch
signal hitstop

## Emit when match starts
signal starter

## Emitted when the ball gets damaged by something
signal got_hit

## Emitted when the team value of the ball is set
## Used to propogate updates to other nodes/components in ball
signal team_setted

## Emitted from ball when a HealthManager node deems they are defeated
## Emits before defeated, which deletes the ball
signal pre_defeated

## Emits to delete ball
signal defeated

## Used as generic transfer of data, will contain a dictionary you
## can read from to trigger specific behaviours
signal data_transfer

## Emitted when the ball's ball_scale value is updated
## Propogates for scale updating behaviours
## Contains the new scale value
signal update_scale

## Emitted when dodge rate is updated
signal set_dodge_rate

## Stat controller
## Important component balls have
## Check it's documentation for more info
## To be brief though, it allows you to set and manipulate custom properties.
var stat_controller:StatController

@export_category("General Properties")
## Flag that dictates if the ball and it's behaviour script is actively running.
## A lot of prebuild nodes for the ball like Rotater ContactDamager HitboxDamager are also need this flag to be true
@export var enabled:bool=true

## Controls size of ball.
## Components like Rotater and Visual will scale automatically
## Rigidbody's main collisions are also updated
## This is used since godot won't let us scale rigitboxides directly.
@export var ball_scale:float=1.0

## Freeze physics is used cause I'm a lazy ass
## It freezes the physics of the ball so that it won't bounce or be affected by stuff
## I use it to prevent it from doing physics things when needed
@export var freeze_physics:bool=false

## This export is honestly unnecessary but I started the project using it so I'm just sticking with it.
## List strings in here, when Ball is created, it adds itself to these groups.
## This allows us to essentially "tag" balls for any specific interactions you may want.
## For example, if we tag a ball "AntiStatus" it becomes immune to status effects.
## We could also tag a Ball as Robot if we'd want, as an example, Katie to heal them on a wrench swing.
## By default balls have "Main" as their tag.
## Main is reserved for the MAIN fighters, the game ends when the only remaining main balls are all from one team.
## So minions and summonables shouldn't have main by default.
@export var groups:Array[String]=["Main"]

## Velocity is the speed a ball tries to move at
@export var velocity:float =650.0

## Freezed is true while the game is hitstopped
var freezed=true

## Ball's linear velocity saved between hitstops
var prefreeze_l_velocity:Vector2

## Ball's angular velocity saved between hitstops
var prefreeze_a_velocity:float

## Ball's gravity
var prefreeze_gravity:float

## Team id.
## Same teamed things are coded to not hurt one another.
var team :int

## Bounce speed boost is a speed added to the base velocity upon bouncing.
## If you want a ball to not be boosted on bounces, set to low value.
## When set to 0, the ball will have a new custom behaviour where it's bounces.
## are based off it's pre existant physics velocity.
@export var bounce_speed_boost :float = 350.0

## Normalizer rate is the rate at which the ball tries to return to it's target velocity variable (above).
@export var normalizer_speed_up:float = 20.0
@export var normalizer_speed_down:float = 20.0

## The string pathway to the bounce sound played when bouncing
@export var bounce_sfx:String="res://Sounds/chopwoodz-bounce.wav"

@export_category("Special Properties")

@export var value_scale:float=1.0
## Autocleave makes weapons against it automatically cleave through it.
## I use it for really tiny props that can be hit by weapons but shouldn't affect trajectories.
@export var auto_cleave:bool=false

## If false prevent other balls from tirggering their bounce signals on it
@export var bouncable:bool=true

## Percent chance rate at which it can avoid a hitbox (0-1)
@export var dodge_rate:float = 0.0

## Flag that deletes ball object on defeat.
@export var delete_on_defeat:bool=true

## Disable default dodge visual for custom implementations!
@export var default_dodge_effect:bool=true

@export_category("Physics")

## The object will collide with other balls
@export var ball_collide:bool=true

## The object will collide with walls of arenas.
## Usually disabled for projectiles to fly out.
@export var wall_collide:bool=true

## Flag will make ball jump past ceiling when it has a gravity value
@export var grav_ignore_ceiling:bool = true


@export_category("Misc")
## Id a ball can have to enable/disable alternate looks or behaviours
## Reference this flag in behaviour script!
@export var skin:String = ""

## Currently my implementation is limited to a singular collision shape
## The ball's collision should have default name
## May change in the future
@onready var collision = get_node("CollisionShape2D")
@export var is_ball:bool=true
var creator_ball:BallBodyBase

func get_root_creator()->BallBodyBase:
	if creator_ball!=null:
		return creator_ball.get_root_creator()
	return self

## Load stat controller on creation
var sc_r=preload("res://Balls/Components/stat_controller.tscn")

## Update/set if we collide with walls
func set_wall_collide(truefalse):
	stat_controller.set_base_stat("Ball.wall_collide",truefalse)

## On initilization, create our stat controller
## Set our prefreeze velo
func _init():
	prefreeze_l_velocity=velocity*Vector2(randf()-0.5,randf()-0.5).normalized()
	var sc=sc_r.instantiate()
	add_child(sc)
	stat_controller=sc
	custom_integrator=true

## Function is called by hitboxes to check if we dodge
## If we dodge, play a dodge effect
func dodges(source_ball):
	if is_instance_valid(source_ball):
		if dodge_rate>randf() and source_ball.team!=team:
			EventManager.dodge_event.emit(source_ball,self)
			dodge_effect()
			return true
	return false
	
## Emitted when we dodge
signal dodged

signal set_skin

var dodge_scale:float=1.0

## Effect that's played when dodging
func dodge_effect():
	await get_tree().process_frame
	PopUpManager.pop_text("DODGED",global_position)
	HitstopManager.set_histop(0.35*dodge_scale)
	dodge_scale=0.0
	SoundQueue.play("res://Sounds/teleport.wav")
	dodged.emit()
	if !default_dodge_effect:
		return
	visible=false
	await HitstopManager.resume
	visible=true

func _physics_process(delta: float) -> void:
	dodge_scale=clampf(dodge_scale+delta*0.5,0,1)

const REVIVE_SYSTEM = preload("uid://bxcky5aigg02k")
var reviving=false
signal knocked_down

func revive_sequence():
	knocked_down.emit()
	stat_controller.set_base_stat("Global.Enabled",false)
	reviving=true
	var add=REVIVE_SYSTEM.instantiate()
	add.ball=self
	EventManager.log_downed(self)
	add_child(add)
	

## Set up main elements
func _enter_tree():
	##Trigger something died in EventManager when we leave tree
	tree_exiting.connect(EventManager.something_died)
	
	##Call startmatch function when round starts
	EventManager.round_start.connect(start_match)
	
	##Add our ball to groups
	for group in groups:
		add_to_group(group)
	##All balls are in ball group
	if is_ball:
		add_to_group("Ball")
	
	##Connect when hitstops occurto our hitstop_effect function
	HitstopManager.set_stop.connect(hitstop_effect)
	
	##Trigger speed boost on bounce
	bounce.connect(speed_bounce_boost)
	
	##Defeat connects to deleting ball
	defeated.connect(destruction)
	
	## Connect stat changes to update_stats
	stat_controller.stat_changed.connect(update_stats)
	
	##Set base values in stat_controller
	stat_controller.set_base_stat("Ball.ball_scale",ball_scale)
	stat_controller.set_base_stat("Ball.value_scale",value_scale)
	stat_controller.set_base_stat("Ball.velocity",velocity)
	stat_controller.set_base_stat("Ball.bounce_speed_boost",bounce_speed_boost)
	stat_controller.set_base_stat("Ball.normalizer_speed_up", normalizer_speed_up)
	stat_controller.set_base_stat("Ball.normalizer_speed_down", normalizer_speed_down)
	stat_controller.set_base_stat("Ball.gravity_scale",gravity_scale)
	stat_controller.set_base_stat("Ball.dodge_rate",dodge_rate)
	stat_controller.set_base_stat("Ball.wall_collide",wall_collide)
	stat_controller.set_base_stat("Ball.ball_collide",ball_collide)
	stat_controller.set_base_stat("Global.Enabled",enabled)

##Delete our object if delete_on_defeat is enabled
func destruction():
	if reviving:
		return
		
	if delete_on_defeat:
		EventManager.process_death(self)

##Behaviour script reference for the mian script that controls ball
var behaviour_script:BehaviourScript

## Use to get scaling value of ball for abilities and meter scaling
func get_value_scale():
	var val = value_scale
	if !is_in_group("Main"):
		val*=Global.ALT_SCALE
	if is_in_group("AntiInteract"):
		val *= 0.0
	return val

var time_spawned=0
func _ready():
	time_spawned=Time.get_ticks_msec()
	max_contacts_reported=10
	stat_controller.set_base_stat("Ball.collision_disabled",collision.disabled)
	stat_controller.set_base_stat("Ball.mass",mass)
	stat_controller.set_base_stat("Ball.freeze",freeze or freeze_physics)
	#print(HitstopManager.hitstopped)
	hitstop_effect(HitstopManager.hitstopped)
	##Set our behaviour script reference
	for i in get_children():
		if i is BehaviourScript:
			behaviour_script=i
			break
		
	readied.emit()
	
	if groups.has("Main") and skin=="":
		skin = Global.skin_mode
	set_skin.emit()
	
		
## Emitted when we are readied, means our variables and stuff are ready to be referenced
signal readied
## Update our variables based off stat_controller
func update_stats(stat_name,new_val):
	match stat_name:
		"Global.Enabled":
			stat_controller.set_base_stat("Ball.freeze",!new_val)
			if new_val:
				set_deferred("process_mode",Node.PROCESS_MODE_INHERIT)
			else:
				set_deferred("process_mode",Node.PROCESS_MODE_DISABLED)
		"Ball.ball_scale":
			ball_scale=new_val
			update_scale.emit()
			for child in get_children():
				if child is CollisionShape2D:
					child.scale=ball_scale*Vector2(1,1)
		"Ball.wall_collide":
			wall_collide=new_val
			update_collisions()
		"Ball.ball_collide":
			ball_collide=new_val
			update_collisions()
		"Ball.value_scale":
			value_scale=new_val
		"Ball.velocity":
			velocity=new_val
		"Ball.dodge_rate":
			dodge_rate=new_val
			set_dodge_rate.emit(new_val)
		"Ball.freeze":
			await get_tree().physics_frame
			
			if freeze_physics==false:
				freeze=new_val
			else:
				freeze=true
		"Ball.bounce_speed_boost":
			bounce_speed_boost=new_val
		"Ball.normalizer_speed_up":
			normalizer_speed_up = new_val
		"Ball.normalizer_speed_down":
			normalizer_speed_down = new_val
		"Ball.collision_disabled":
			collision.set_deferred("disabled",new_val)
		
		"Ball.gravity_scale":
			gravity_scale=new_val
			update_collisions()
		"Ball.linear_velocity":
			
			if freezed:
				#last_movement_vector=new_val
				prefreeze_l_velocity=new_val
			else:
				linear_velocity=new_val
				prefreeze_l_velocity=linear_velocity
		"Ball.mass":
			mass=new_val

## Update our colllisions based off gravity and grav_ignore_ceiling.
func update_collisions():
	
	set_collision_layer_value(5,ball_collide)
	set_collision_mask_value(5,ball_collide)
	set_collision_mask_value(1,wall_collide)
	if gravity_scale==0.0:
		set_collision_mask_value(17,wall_collide)
	else:
		set_collision_mask_value(17,!grav_ignore_ceiling)

## Use this function to set the team.
## Round/behaviour script automatically sets it
func set_team(t_id):
	team=t_id
	team_setted.emit(t_id)

## Speed applied on bounce
func speed_bounce_boost():
	if gravity_scale==0.0:
		##IF boost is zero, bounce based off velocity
		if bounce_speed_boost==0.0:
			set_velocity(get_velocity().normalized() * (get_velocity().length()))
		else:
			set_velocity(get_velocity().normalized() * (velocity+bounce_speed_boost))

## Function to get velocity of ball.
## If ball is frozen from hitstop, use the prefreeze value.
func get_velocity():
	if freezed:
		return prefreeze_l_velocity
	else:
		return linear_velocity

## Function to set velocity of ball
func set_velocity(val):
	stat_controller.set_base_stat("Ball.linear_velocity",val)

## Function to add velocity value
func add_velocity(val):
	stat_controller.set_base_stat("Ball.linear_velocity",get_velocity()+val)

signal revive
func revive_function():
	stat_controller.set_base_stat("HealthManager.health",stat_controller.get_stat("HealthManager.max_health"))
	reviving=false
	stat_controller.set_base_stat("Global.Enabled",true)
	EventManager.log_revived(self)
	revive.emit()
	SoundQueue.play("res://Sounds/power-up_F_major.wav")

## Function called every physics frame
## Uses normalizer rate to make the physics velocity match velocity variable
func _integrate_forces(state: PhysicsDirectBodyState2D):
	if freeze_physics:
		return
	if linear_velocity==Vector2.ZERO:
		return
		
	var vel = state.linear_velocity
	if vel==Vector2.ZERO:
		return
		

	if state.total_gravity != Vector2.ZERO:
		vel += state.total_gravity * state.step
	if gravity_scale==0.0:
		var current_speed = vel.length()

		if current_speed > 0.0:
			var rate
			if current_speed < velocity :
				rate = normalizer_speed_up 
			else:
				rate = normalizer_speed_down
			var new_speed = move_toward(current_speed,velocity,rate * 20 * state.step)

			vel = vel.normalized() * max(new_speed,0.001)

	state.linear_velocity = vel
	prefreeze_l_velocity=state.linear_velocity 

## Hitstop effect called when ball is stopped
func hitstop_effect(truefalse):
	if truefalse and freezed==false:
		hitstop.emit(true)
		freezed=true
		set_velocity(prefreeze_l_velocity)
		linear_velocity = Vector2.ZERO
		prefreeze_a_velocity=angular_velocity
		angular_velocity=0.0
	elif !truefalse and freezed==true:
		hitstop.emit(false)
		freezed=false
		set_velocity(prefreeze_l_velocity)
		angular_velocity=prefreeze_a_velocity

## Function when match start
## Makes movement random
func start_match():
	hitstop_effect(false)
	starter.emit()
	set_velocity((Vector2(randf()-0.5,randf()-0.5).normalized()*velocity))

## Detects when body is entered
func _on_body_entered(body):
	if freezed or HitstopManager.hitstopped:
		return
	## On the instant we spawn, ignore collision checks
	#if Time.get_ticks_msec()-time_spawned<5:
	#	return
	if body is StaticBody2D:
		bounce.emit()
		bounce_wall.emit(body)
		bounce_sound()
		
	if body is BallBodyBase:
		bounce_ball.emit(body)
		if !body.bouncable || !bouncable:
			return
		bounce.emit()
		bounce_sound()

## Play bounce noise
func bounce_sound():
	if bounce_sfx!="":
		SoundQueue.play(bounce_sfx,1.0,0.35)
		
func _on_area_2d_area_entered(area):
	pass
