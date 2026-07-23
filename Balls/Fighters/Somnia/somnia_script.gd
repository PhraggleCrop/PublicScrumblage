extends BehaviourScript
@onready var health_manager = $"../HealthManager"
@onready var vision_rotater = $"../VisionRotater"
@onready var vision_sprite = $"../VisionRotater/PointLight2D"
@onready var rotater = $"../Rotater"
@onready var hitbox = $"../Rotater/WeaponHolder/WeaponFlipper/WeaponHitbox"
@onready var hitbox_damager = $"../Rotater/WeaponHolder/WeaponFlipper/WeaponHitbox/HitboxDamager"
@onready var vision_area = $"../VisionRotater/Area2D"
@onready var point_light_2d = $"../VisionRotater/PointLight2D"
@onready var meter_manager = $"../MeterManager"

var counter:float=0.0
var slept:Array=[]
var sleep_strength:float=1.5

func _ready():
	super()
	$"../Rotater/WeaponHolder/WeaponFlipper/WeaponHitbox/HitboxDamager".local_hit.connect(prehit)
	sleep_text()
	EventManager.status_effected.connect(status_update)
	ball.team_setted.connect(sleep_check.unbind(1))

func status_update(data):
	sleep_check()

## Whenever anything is applied status, we check for super form
func sleep_check():
	var list = StatusEffectManager.get_balls_with_status("SLEEPING")
	list.erase(ball)
	list = list.filter(func(i):return i.team != ball.team)
	
	if list.size()>0:
		enter_form()
	else:
		exit_form()


var form_speed = 485
var form_rr = 6
func enter_form():
	$"../Visuals/Default".set_visual("Special")
	$AfterImager.active=true
	sc.set_base_stat("Ball.ball_collide",false)
	sc.set_base_stat("Ball.velocity",form_speed)
	sc.set_base_stat("Mood.disabled",true)
	sc.set_base_stat("HitProcessor.immune",true)
	sc.set_base_stat("Rotater.rotation_rate",form_rr)
	sc.set_base_stat("Rotater.bounce_spin_boost",0)
	sc.set_base_stat("ClashBouncer.ignore_clash",true)
	sc.set_base_stat("ClashBouncer.ignorable",true)
	sc.set_base_stat("ClashBouncer.cleave",true)
	sc.set_base_stat("HitboxDamager.self_knockback",0)
	

func exit_form():
	$"../Visuals/Default".set_visual("Default")
	$AfterImager.active=false
	sc.set_base_stat("Mood.disabled",false)
	sc.set_base_stat("Ball.ball_collide",true)
	sc.set_base_stat("Ball.velocity",550)
	sc.set_base_stat("HitProcessor.immune",false)
	sc.set_base_stat("Rotater.bounce_spin_boost",7)
	sc.set_base_stat("Rotater.rotation_rate",3.5)
	sc.set_base_stat("ClashBouncer.ignore_clash",false)
	sc.set_base_stat("ClashBouncer.ignorable",false)
	sc.set_base_stat("ClashBouncer.cleave",false)
	sc.set_base_stat("HitboxDamager.self_knockback",75)
	
func update_skin():
	if ball.skin == "Summer":
		$"../VisionRotater/PointLight2D".texture=load("res://Balls/Fighters/Somnia/VisionConeOcean.png")
		$"../VisionRotater/PointLight2D".color=Color(0.28, 0.11, 0.009, 1.0)


##Override onhit for hitbox to make sleeping targets get critted.
func prehit(data_dict):
	var body = data_dict["VICTIM"]
	if body.team==ball.team:
		return
	
	var crit_chance=0.0
	if StatusEffectManager.get_effects(body).has("SLEEPING"):
		crit_chance=1.0
	
	data_dict["CRIT_CHANCE"] = crit_chance
	
	EventManager.hit.emit(data_dict)
	
var flashing=0.0

func flash():
	sleep_amount+=sleep_gain
	SoundQueue.play("res://Sounds/synthwave-pack-music-box-synth_C_minor.wav",0.85,0.6)
	slept.clear()
	point_light_2d.energy=2
	var tween = create_tween()
	tween.tween_property(point_light_2d,"energy",0.6,0.5)
	flashing=0.3
	sleep_strength=sleep_val()
	sleep_text()
	
	

func sleep_text():
	var future_val=sleep_val()
	future_val=round(future_val*100.0)/100.0
	%LV.text="SLEEP: "+str(future_val)

var sleep_amount=1
func sleep_val():
	return sleep_amount
	


var sleep_gain:float=0.25

func gain_sleep(value):
	sleep_amount+=value
	sleep_text()

func _physics_process(delta):
	if ball.freezed:
		return
	
	if meter_manager.meter>=meter_manager.max_meter:
		flash()
		meter_manager.clear_meter()
	if flashing>0.0:
		flashing-=delta
		var sleep_val=0.0
		for i in vision_area.get_overlapping_bodies():
			if i is BallBodyBase:
				
				if i.is_in_group("AntiInteract") or ball.is_in_group("Invisible"):
					continue
				if i.team!=ball.team and !slept.has(i):
					##If our status effect can't apply
					if StatusEffectManager.set_effect(ball,i,"SLEEPING",sleep_strength)==null:
						continue
					slept.append(i)
					sleep_val=max(sleep_val,sleep_gain*i.get_value_scale())
		gain_sleep(sleep_val)
				
	
	var dir = Global.dir_closest_ball(ball)
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT.rotated(rotater.rotation)
	vision_rotater.rotation=lerp_angle(vision_rotater.rotation,dir.angle(),seek_strength)
var seek_strength = 0.045
