extends BehaviourScript
@onready var meter_manager = $"../MeterManager"
@onready var aggressive = $"../Aggressive"


var active=false
func _ready():
	super()
	sc=ball.stat_controller

	ball.bounce.connect(shake)
	update_scale()
	
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
		#meter_manager.gain_meter(12-9*pow(scaler(),1.3))
		update_scale()
		
var beta_scale = 1.3
var scl=0.4
func update_scale():
	
	sc.set_base_stat("HitProcessor.damage_scale", 1.0-0.5*scaler())
	sc.set_base_stat("Ball.ball_scale",(beta_scale+scl*scaler()))
	
	aggressive.effect_offset=80*(1+scl*scaler())
	bonus_damage = 1 * scaler()
	#sc.set_base_stat("HitProcessor.damage_scale",1.0-0.3*scaler())
	#$"../StatsUI/BallStatDisplay/Box/BattleBar/DMGREDUCE".text="RESISTANCE: "+str(  int((0.3*scaler())*100)  ) + "%"

	if active:
		sc.set_base_stat("HitboxDamager.damage",ability_damage)
	else:
		var dmg_add=3.0
		sc.set_base_stat("HitboxDamager.damage",base_damage + bonus_damage)
		

var base_damage = 2
var ability_damage = 4
var bonus_damage=0
func scaler():
	return (meter_manager.meter/100.0)
	
@onready var default: Node2D = $"../Visuals/Default"

var runthrough=true
func ability():
	if active==false:
		if runthrough:
			#ball.set_collision_mask_value(5,false)
			#ball.set_collision_layer_value(1,true)
			ball.bouncable=false
		default.set_visual("Rampage")
		ball.bounce_sfx = "res://Sounds/heavy_bounce.wav"
		active=true
		sc.set_base_stat("ContactDamage.enabled",true)
		
		sc.set_base_stat("Ball.mass",9)
		sc.set_base_stat("ClashBouncer.cleave",true)
		sc.set_base_stat("Rotater.rotation_rate",10)
		sc.set_base_stat("Rotater.bounce_spin_boost",0.0)
		sc.set_base_stat("Ball.velocity",750)
		sc.set_base_stat("HitboxDamager.crit_chance",0.25)
		sc.set_base_stat("Ball.self_knockback",0.0)
		sc.set_base_stat("HitboxDamager.knockback",10.0)
		sc.set_base_stat("HitboxDamager.self_knockback",0.0)
		sc.set_base_stat("HitProcessor.knockback_scale",0.0)
		
		sc.set_base_stat("Mood.disabled",true)
		sc.set_base_stat("ClashBouncer.disable",true)
		
		
func ability_end():
	if runthrough:
		#ball.set_collision_mask_value(5,true)
		#ball.set_collision_layer_value(1,false)
		ball.bouncable=true
	default.set_visual("Default")
	ball.bounce_sfx="res://Sounds/chopwoodz-bounce.wav"
	sc.set_base_stat("ContactDamage.enabled",false)
	sc.set_base_stat("Ball.mass",3)
	sc.set_base_stat("ClashBouncer.cleave",false)
	sc.set_base_stat("Rotater.rotation_rate",0.8)
	sc.set_base_stat("Rotater.bounce_spin_boost",6.0)
	sc.set_base_stat("HitboxDamager.crit_chance",0.00)
	sc.set_base_stat("Ball.velocity",360)
	sc.set_base_stat("Ball.self_knockback",35.0)
	sc.set_base_stat("HitboxDamager.knockback",70.0)
	sc.set_base_stat("HitProcessor.knockback_scale",1.0)
	sc.set_base_stat("HitboxDamager.self_knockback",35.0)
	active=false
	
	sc.set_base_stat("Mood.disabled",false)
	sc.set_base_stat("ClashBouncer.disable",false)

var lose_meter_rate=12.5
var gain_meter_rate=4
func _physics_process(delta):
	if HitstopManager.hitstopped:
		return
	if active:
		meter_manager.lose_meter(lose_meter_rate*delta)
		update_scale()
		if meter_manager.meter==0.0:
			ability_end()
		
	if active==false:
		meter_manager.gain_meter(gain_meter_rate*delta)
		update_scale()
	
	if meter_manager.is_full():
		ability()
