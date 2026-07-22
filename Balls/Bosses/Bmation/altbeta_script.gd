extends BehaviourScript
@onready var meter_manager = $"../MeterManager"
@onready var aggressive = $"../Aggressive"

@onready var looper: Node = $looper

var active=false

@onready var spawn_animation: AnimationPlayer = $"../SpawnAnimation"
@onready var banner_animation = $"../BANNER/BannerAnimation"
@onready var beta_spawn_animation: AnimationPlayer = $"../BETASpawnAnimationAssets/BETASpawnAnimation"

# make sure the following signals and variable are named exactly this. but its okay if they dont have these
# raid mode is coded in a way that you can actually place normal ball characters into the boss res
# but if you want a special intro or a way to shake a camera be sure to use these.
signal intro_finished # lets the gamemode know when to start the round
signal banner_finished
signal shake_camera(amount : float) # shakes the camera

@export var hasIntro : bool = true # the main raid gd checks to see if this variable exists and if it's true or not
# you can turn this off to skip the intro

func open_banner():
	banner_animation.play('banner_anim')
	await banner_animation.animation_finished
	banner_finished.emit()
	

func start_intro(): # plays the animation
	print('intro playing')
	beta_spawn_animation.play('spawn_animation')
	await beta_spawn_animation.animation_finished
	$"../Scaler/GPUParticles2D".emitting=true
	intro_finished.emit() # waits for the animation to finish before beginning the round
	
func _ready():
	super()
	sc=ball.stat_controller
	ball.bounce.connect(shake)
	update_scale()
	looper.trigger.connect(spawn_betaling)
	
func shake():
	if active==false:
		return
	Global.quake_trigger.emit(0.25)
	
func hit_process(data):
	var attacker=data["ATTACKER"]
	var victim = data["VICTIM"]
	if attacker==ball and active==false:
		if !victim.is_in_group("Main"):
			return
		update_scale()
		
var beta_scale = 1.65
var scl=0.5
var peak_scale := 0.0
var base_speed := 240.0
var min_speed := 30.0 
var additional_damage :=0.0
func update_scale():
	var s = peak_scale / 100.0
	sc.set_base_stat("Ball.ball_scale", beta_scale + scl * s)
	
	aggressive.effect_offset = 80 * (1 + scl * s)
	#sc.set_base_stat("HitProcessor.damage_scale", 1.0 - min(0.5,0.5 * s))
	sc.set_base_stat("HitProcessor.damage_scale", 1.0-0.75*scaler())
	
	var speed = max(base_speed / (1.0 + s * 0.5), min_speed)
	if not active:
		sc.set_base_stat("Ball.velocity", speed)
	additional_damage = floor(s)
	if active:
		sc.set_base_stat("HitboxDamager.damage", ability_damage)
	else:
		sc.set_base_stat("HitboxDamager.damage", base_damage)
const BALL_BALTMINION = preload("res://Balls/Bosses/Bmation/bmationminion.tscn")
@onready var health_manager: HealthManager = $"../HealthManager"

func spawn_betaling():
	if health_manager.health<350:
		var thing=spawn_thing(BALL_BALTMINION)
		SoundQueue.play("res://Balls/Bosses/Beta_alt/big-burp-bass_F_minor.wav",0.7,0.7)
	if health_manager.health<100:
		$looper.added_rand_time=3.0

func _physics_process(delta):
	if HitstopManager.hitstopped:
		return
	if active:
		meter_manager.lose_meter(lose_meter_rate * delta)
		update_scale()
		if meter_manager.meter == 0.0:
			ability_end()
	if not active:
		burst_timer += delta
		var in_burst = fmod(burst_timer, burst_interval) < burst_duration
		var rate = burst_rate if in_burst else base_rate
		meter_manager.gain_meter(rate * delta)
		peak_scale += rate * delta  # mirrors meter gain exactly
		update_scale()
	if meter_manager.is_full():
		ability()

var base_damage = 2
var ability_damage = 4

func scaler():
	return (meter_manager.meter/100.0)
	
@onready var default: Node2D = $"../Visuals/Default"
signal ability_start_s
signal ability_end_s
var runthrough=true

func ability():
	if active==false:
		ability_start_s.emit()
		SoundQueue.play("res://Balls/Bosses/Beta_alt/beta raor.wav")
		if runthrough:
			ball.bouncable=false
		default.set_visual("Rampage")
		ball.bounce_sfx = "res://Sounds/heavy_bounce.wav"
		active=true
		sc.set_base_stat("ContactDamage.enabled",true)
		
		sc.set_base_stat("Ball.mass",12)
		sc.set_base_stat("ClashBouncer.cleave",true)
		sc.set_base_stat("Rotater.rotation_rate",10)
		sc.set_base_stat("Rotater.bounce_spin_boost",0.0)
		sc.set_base_stat("Ball.velocity",750)
		sc.set_base_stat("HitboxDamager.crit_chance",0.0)
		sc.set_base_stat("Ball.self_knockback",0.0)
		sc.set_base_stat("HitboxDamager.knockback",200.0)
		sc.set_base_stat("HitboxDamager.self_knockback",0.0)
		sc.set_base_stat("HitProcessor.knockback_scale",0.0)
		
		sc.set_base_stat("ClashBouncer.disable",true)


		
func ability_end():
	if runthrough:
		ball.bouncable=true
		
	ability_end_s.emit()
	default.set_visual("Default")
	ball.bounce_sfx="res://Sounds/chopwoodz-bounce.wav"
	sc.set_base_stat("ContactDamage.enabled",false)
	sc.set_base_stat("Ball.mass",5)
	sc.set_base_stat("ClashBouncer.cleave",false)
	sc.set_base_stat("Rotater.rotation_rate",0.65)
	sc.set_base_stat("Rotater.bounce_spin_boost",6.0)
	sc.set_base_stat("HitboxDamager.crit_chance",0.00)
	sc.set_base_stat("Ball.velocity",360)
	sc.set_base_stat("Ball.self_knockback",0.0)
	sc.set_base_stat("HitboxDamager.knockback",100.0)
	sc.set_base_stat("HitProcessor.knockback_scale",1.0)
	sc.set_base_stat("HitboxDamager.self_knockback",35.0)
	active=false
	
	sc.set_base_stat("ClashBouncer.disable",false)
	
var lose_meter_rate := 22.5
var burst_timer := 0.0
var burst_interval: = 1.5 
var burst_duration := 0.2
var base_rate: = 3.5
var burst_rate: = 25.0
