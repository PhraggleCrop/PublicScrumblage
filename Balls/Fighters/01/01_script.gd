extends BehaviourScript
@onready var rotater = $"../Rotater"
@onready var lazer_collision = $"../Rotater/LazerArea/CollisionShape2D"
@onready var lazer_area = $"../Rotater/LazerArea"
@onready var looper: Node = $Looper

var shot_count=3
var bullet_res = load("res://Balls/Fighters/01/01Bullet.tscn")
var rot_lock=null
var active=false
var lazering=false

func _ready():
	super()
	if ball.skin=="Summer":
		$"../Visuals/Default/Default".texture=load("res://Balls/Fighters/01/01ballsummer1.png")
		$"../Visuals/Default/Lazering".texture = load("res://Balls/Fighters/01/01ballsummer3.png")
		$"../Visuals/Hurt/Hurt".texture=load("res://Balls/Fighters/01/01ballsummer2.png")
		$"../Rotater/WeaponHolder/WeaponFlipper/WeaponHitbox/WeaponVisual/Weapon".texture=load("res://Balls/Fighters/01/01gunsummer.png")
		$"../StatsUI/BallStatDisplay/VsSplash/SPLASHART/TextureRect".visible=false
		$"../StatsUI/BallStatDisplay/VsSplash/SPLASHART/SummerRect".visible=true
		$"../StatsUI/BallStatDisplay/Box/BattleBar/Icon".texture=load("res://Balls/Fighters/01/01ballsummer1.png")
		
		
	lazer_area.visible=false
	## When status affect is applied, connect to this function
	EventManager.status_effected.connect(status_lazer)
	## Shoot on timed trigger
	looper.trigger.connect(shoot)

## While we shoot lazer, if we are afflicted by status effects that disable our behaviour script
## Hide the lazer
func status_lazer(data):
	var victim = data["VICTIM"]
	var strength = data["STRENGTH"]
	if victim==ball:
		if strength != -1:
			if sc.get_stat("BehaviourScript.behaviour_active")==false:
				lazer_area.visible=false
				sc.set_base_stat("LazerHitbox.collision_disabled",true)
				lazer_loop.volume_db=-80
		else:
			
			if sc.get_stat("BehaviourScript.behaviour_active")==true:
				lazer_area.visible=lazering
				sc.set_base_stat("LazerHitbox.collision_disabled",!lazering)
				lazer_loop.volume_db=3

@onready var autogain: Node = $Autogain

var lazer_hit=false
var burntick =0

## Called when out lazer starts
## Disable out shoot trigger loop
## Set out active flag to true to indicate we are shooting
func lazer():
	if active:
		return
	looper.active=false
	active=true
	autogain.enabled=false
	
	## rot_lock is our target angle to aim before firing lazer
	$"../Rotater/WeaponHolder/WeaponFlipper/WeaponVisual/Node2D/Count".visible=false
	var dir = Global.dir_closest_ball(ball)
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT.rotated(rotater.rotation)
	rot_lock = dir.angle()
	sc.set_base_stat("Rotater.rotation_rate",0)
	sc.set_base_stat("Rotater.bounce_spin_boost",0.0)
	sc.set_base_stat("Ball.velocity",25)
	sc.set_base_stat("Mood.disabled",true)
	
	lazer_scale = 0.0
	
	$"../Visuals/Default".set_visual("Lazering")
	
	
	$"../CPUParticles2D".emitting=true
	Global.rotate_to(rotater,rot_lock,0.8)
	SoundQueue.play("res://Sounds/laser-power-up_B_minor.wav",0.9,0.8)
	
	## Power up and wait delay before releasing lazer
	await delay(2.2)
	
	## Check if we can fire before enabling things
	if !Global.can_act(ball):
		lazer_end()
		return
	
	## Enable our collisions 
	sc.set_base_stat("LazerHitbox.collision_disabled",false)
	$"../CPUParticles2D".emitting=false
	rotater.aiming=true
	rotater.aim_speed=0.011
	lazer_sound()
	
	lazering=true
	
	lazer_area.visible=true
	var tween := create_tween()
	tween.tween_property(self, "lazer_scale", 0.1, 0.15)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	tween.tween_property(self, "lazer_scale", 1.2, 0.08)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "lazer_scale", 1.0, 0.05)
	await tween.finished
	ball.set_velocity((ball.get_velocity()-Vector2.RIGHT.rotated(rotater.rotation)*500))
		
@onready var lazer_start = $"../LazerStart"
@onready var lazer_loop = $"../LazerLoop"
@onready var lazer_ender = $"../LazerEnd"

## Lazer sfx setip
func lazer_sound():
	lazer_start.play()
	await lazer_start.finished
	lazer_loop.play()
	await lazer_loop.finished
	lazer_ender.play()

## Function when lazer ends
## Disables evernthing
func lazer_end():
	
	autogain.enabled=true
	looper.active=true
	sc.set_base_stat("LazerHitbox.collision_disabled",true)
	$"../LazerLoop".stop()
	rot_lock=null
	$"../Rotater/WeaponHolder/WeaponFlipper/WeaponVisual/Node2D/Count".visible=true
	rotater.aiming=false
	lazering=false
	$"../Visuals/Default".set_visual("Default")
	lazer_collision.disabled=true
	var retract_tween := create_tween()
	sc.set_base_stat("Rotater.rotation_rate",2.6)
	sc.set_base_stat("Rotater.bounce_spin_boost",10.0)
	sc.set_base_stat("Ball.velocity",500)
	sc.set_base_stat("Mood.disabled",false)
	retract_tween.tween_property(self, "lazer_scale", 0.01, 0.12)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_IN)
	await retract_tween.finished
	lazer_area.scale.y=0.01
	lazer_area.visible=false
	active=false

var lazer_scale = 0.0
@export var base_width := 0.8
@export var amplitude := 0.2
@export var speed := 28.0
@onready var meter_manager = $"../MeterManager"

var lazer_tick=0.0


func _physics_process(delta):
	if HitstopManager.hitstopped:
		return
	
	## If sequence is active dynamically calculate visual for lazer
	if active:
		var t := Time.get_ticks_msec() / 1000.0
		var width = base_width + sin(t * speed) * amplitude
		width = width * lazer_scale
		lazer_area.scale.y=width
		lazer_tick+=delta
		
		## If lazer beam is firing, lose meter and adjust the aiming strength of rotater.
		## rotater.aim_speed is not tracked by stat_controller so we adjust directly
		if lazering:
			meter_manager.lose_meter(17.5*delta)
			
			rotater.aim_speed=lerpf(rotater.aim_speed,0.004,0.3*delta)
			if meter_manager.meter<=0:
				lazer_end()
	else:
		## While not shooting lazer, check if meter is full to trigger lazer
		if meter_manager.meter==meter_manager.max_meter and lazering==false and rot_lock==null:
			lazer()
	
	## If we are shooting lazer, add velocity pushback on ball opposite to direction
	## Of the rotater
	if lazering:
		var dir = -rotater.vec_dir()
		ball.add_velocity(dir*650*delta)

	lazer_hit=false

## If bullet connects, gain meter
func bullet_connect(amt:float,bullet):
	if active:
		return
	if bullet.team==ball.team:
		meter_manager.gain_meter(amt)

## Script for shooting bullets and aiming
func shoot():
	if active==true:
		return
	var dir = Global.dir_closest_ball(ball,rotater.vec_dir())
	rot_lock = dir.angle()
	var diff = wrapf(rot_lock - rotater.rotation, -PI, PI)
	if sign(sc.get_stat("Rotater.angular_velocity"))!=sign(diff):
		rotater.flipper()
	
	sc.set_base_stat("Rotater.locked",true)
	sc.set_base_stat("Rotater.rotation_rate",0.01)
	sc.set_base_stat("Rotater.bounce_spin_boost",0.0)
	sc.set_base_stat("Rotater.angular_velocity",sign(sc.get_stat("Rotater.angular_velocity")))
		
	Global.rotate_to(rotater,rot_lock,0.07)
	await delay(0.07)
	
	if !Global.can_act(ball):
		shoot_end()
		return
			
	var shoot_amounts=shot_count
	for i in range(shoot_amounts):
		shoot_bullet()
		await delay(0.2)
		if !Global.can_act(ball):
			shoot_end()
			return
	shoot_end()
		
func shoot_end():
	sc.set_base_stat("Rotater.locked",false)
	rot_lock=null
	sc.set_base_stat("Rotater.rotation_rate",2.6)
	sc.set_base_stat("Rotater.bounce_spin_boost",10.0)

func scale_val():
	return pow((min(float(shot_count),20)/20.0),2)

## Spawns bullet
func shoot_bullet():
	SoundQueue.play("res://Sounds/layered-gunshot-7_A_minor.wav",1,0.7)
	var dir =Vector2.RIGHT.rotated(rotater.rotation)
	var newb = spawn_thing(bullet_res)
	newb.set_velocity(dir*1550)
	newb.global_position=$"../Rotater/WeaponHolder/WeaponFlipper/WeaponHitbox".global_position
	
	newb.behaviour_script.hit_gain.meter_manager = meter_manager
	var script=newb.get_node("BulletScript")
	script.connected.connect(bullet_connect.bind(newb))
