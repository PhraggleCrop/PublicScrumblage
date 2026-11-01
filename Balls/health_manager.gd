## Tracks and manages health
## Balls without this component won't die, can still "get hit" though

extends Node2D
class_name HealthManager
@onready var ball=get_parent()

@export var hitprocessor:HitProcessor

## If disabled, won't emit to destroy ball when health == 0
@export var defeat_when_0:bool=true

## Set max health
@export var max_health:float=100
@export var health:float=-1
@export var overhealth:float=0.0
@export var armor:float=0

var stat_name:String="HealthManager"

signal health_lost
signal health_changed
signal zero_health
signal set_enable
signal damaged
signal health_setted
signal overhealth_changed 
signal armor_changed
signal custom_death

var stat_controller:StatController

var has_custom_death: bool = false

func health_scale():
	return health/max_health

func set_armor(val):
	stat_controller.set_base_stat(stat_name+".armor",max(val,0))


func add_armor(val):
	stat_controller.set_base_stat(stat_name+".armor",armor+val)
	

func add_overhealth(val):
	stat_controller.set_base_stat(stat_name+".overhealth",overhealth+val)
	
func set_overhealth(val):
	stat_controller.set_base_stat(stat_name+".overhealth",val)
	
func _ready():
	if health==-1:
		health=max_health
	stat_controller=ball.stat_controller
	await get_tree().process_frame
	health_changed.emit(health)
	health_changed.connect(check_dead)
	health_setted.emit()
	EventManager._successfully_damaged_.connect(hurt)
	stat_controller.stat_changed.connect(update_stats)
	
	stat_controller.set_base_stat(stat_name+".health",health)
	stat_controller.add_alias("HealthManager.health", "HealthManager.health")
	
	stat_controller.set_base_stat(stat_name+".max_health",max_health)
	stat_controller.add_alias("HealthManager.max_health", "HealthManager.max_health")
	
	stat_controller.set_base_stat(stat_name+".overhealth",overhealth)
	stat_controller.add_alias("HealthManager.overhealth", "HealthManager.overhealth")
	
	stat_controller.set_base_stat(stat_name+".armor",armor)
	stat_controller.add_alias("HealthManager.armor", "HealthManager.armor")
	
	EventManager.round_end.connect(decay_destruct)
	ball.revive.connect(revive_function)
	
	for child in get_children():
		if child is CustomDeathAnimation:
			child.ball = ball
			has_custom_death = true
			custom_death.connect(child._on_death)

var decay_val=0

func _physics_process(delta: float) -> void:
	if HitstopManager.hitstopped:
		return
	var diff = overhealth-lerpf(overhealth,0.0,0.2*delta)
	diff = diff+0.85*delta
	
	set_overhealth(overhealth-diff)
	
## Called during overtime, health will tick down slow, then fast
func decay_destruct():
	decay_val+=1
	var group_nodes = get_tree().get_nodes_in_group("Main")
	var check_array = []
	for i in group_nodes:
		if i.team!=ball.team:
			check_array.append(i)
	if check_array.size()<=0:
		return
	await get_tree().create_timer(max(0.05,0.25-decay_val*0.0075)).timeout
	update_health(health-1)
	decay_destruct()
	
func update_stats(stat,new_val):
	if stat_name+".health"==stat:
		health=min(floor(new_val * 10.0) / 10.0,max_health)
		health_lost.emit(health)
		health_changed.emit(health)
	elif stat_name+".max_health"==stat:
		max_health=new_val
	elif stat_name+".overhealth"==stat:
		#overhealth=floor(new_val * 10.0) / 10.0
		overhealth = max(new_val,0)
		overhealth_changed.emit(overhealth)
	elif stat_name+".armor"==stat:
		armor=new_val
		armor_changed.emit(armor)

func hurt(data):
	if !EventManager.round_ongoing:
		return
	var victim = data["VICTIM"]
	
	if victim != ball:
		return
	var critted = data["CRIT"]
	var dmg = data["DAMAGE"]
	var sfx = data["SFX"]
	var type = data["TYPE"]
	
	var volume_mod=1.0
	var pitch_mod=1.0
	var negated_damage = data["NEGATED_DMG"]
	if negated_damage>0.0:
		volume_mod=0.65
		pitch_mod=0.7
	
	var calc_dmg = dmg
	if overhealth > 0 and calc_dmg>0 and !valid_type(type):
		var diff = max(0,dmg - ceil(overhealth))
		stat_controller.set_base_stat(stat_name + ".overhealth", max(overhealth - calc_dmg, 0))
		
		calc_dmg = diff
		if sfx=="res://Sounds/hurt_sfx.wav" and diff==0:
			sfx = "res://Sounds/industrial-metal-clang-harsh.wav"
	
	
	if armor > 0 and calc_dmg>0 and !valid_type(type):
		if calc_dmg<=1:
			#set_armor(round((armor-calc_dmg*0.25)*10.0)/10.0)
			set_armor(armor-calc_dmg)
			
		else:
			stat_controller.set_base_stat(stat_name + ".armor", max(armor - 1, 0))
			calc_dmg=0
			
		if armor==0:
			if sfx=="res://Sounds/hurt_sfx.wav":
				sfx = "res://Sounds/hard-metal-clang-sfx_70bpm_G_major.wav"
	if calc_dmg>0:
		stat_controller.set_base_stat(stat_name + ".health", max(health - calc_dmg, 0))
		
	if !critted:
		SoundQueue.play(sfx,pitch_mod+0.25*(randf()-0.5),volume_mod)
		
	damaged.emit(calc_dmg)
	health_lost.emit(health)
	health_changed.emit(health)
	
	ball.got_hit.emit(data)

func valid_type(type:Array):
	return type.has("PIERCING_DAMAGE")


func set_max_health(val):
	max_health=val
	health_setted.emit()

func update_health(val):
	stat_controller.set_base_stat(stat_name+".health",val)
	

func increase_health(val):
	stat_controller.set_base_stat(stat_name+".health",health+val)

func decrease_health(val):
	stat_controller.set_base_stat(stat_name+".health",health-val)
	
## Check if we have died
func check_dead(health):
	if health<=0:
		if defeat_when_0==true:
			if has_custom_death:
				custom_death.emit()
				return
			if special_dead==true :
				return
				
			if ball.is_in_group("Main") and EventManager.round_time>0:
				special_dead=true
				ball.pre_defeated.emit()
				Global.quake_trigger.emit(1)
				EventManager.special_move(ball,null,"res://Sounds/death_boom.mp3")
				await HitstopManager.resume
			ball.defeated.emit()
		zero_health.emit()
			
var special_dead = false


func revive_function():
	special_dead=false
	return
