extends StatusEffect
class_name InstaShock

@export var gpu_particles_2d:GPUParticles2D
var ongoing_stuns=0
var stun_id=0
var queing=false

func _init():
	EventManager._successfully_damaged_.connect(stuncheck)

func on_leave():
	super()
	if !is_instance_valid(baller):
		return
	for i in mod_list:
		baller.stat_controller.remove_modifier("STUNSTOP"+str(i))

func check_apply(ball)->bool:
	if !super(ball):
		return false
	if ball.is_in_group("AntiElectrocuted"):
		return false
	return true

func set_target(ball,value,data):
	super(ball,value,data)
	shock(ball,value)

func update(value,data):
	shock(baller,value)
	return self

func shock(ball:BallBodyBase,strength:int):
	if !is_instance_valid(ball):
		return
	
	if baller.is_in_group("AntiElectrocuted") or baller.is_in_group("AntiStatus"):
		return
	
	ongoing_stuns+=1
	
	EventManager.hit.emit({
		"ATTACKER":ball_source,
		"VICTIM":ball,
		"HITSTOP_SCALE":0.01,
		"TYPE":["STATUS_EFFECT"],
		"DAMAGE":strength,
		"SFX":"res://Sounds/civilian-stun-gun-taser-zap_F_major.wav",
		"ID":"STATUS_SHOCK",
		"MISC":[self]
	})

var mod_list=[]

func stuncheck(data):
	if !is_instance_valid(baller):
		return
	var attacker = data["ATTACKER"]
	var strength = data["DAMAGE"]
	var type = data["TYPE"]
	var id= data["ID"]
	var misc=data.get("MISC",[])
	if !misc.has(self):
		return
	if !type.has("STATUS_EFFECT") or !id=="STATUS_SHOCK":
		return
	
	stun_id+=1
	var stun_id_local = stun_id
	gpu_particles_2d.amount+=strength
	gpu_particles_2d.global_position=baller.global_position
	gpu_particles_2d.lifetime+=0.05*strength
	if gpu_particles_2d.emitting!=true:
		gpu_particles_2d.emitting=true
		
	baller.set_velocity(baller.get_velocity().normalized())
	baller.stat_controller.add_modifier("Ball.velocity",2,1,"STUNSTOP"+str(stun_id_local))
	baller.stat_controller.add_modifier("Rotater.angular_velocity",2,0.1,"STUNSTOP"+str(stun_id_local))
	baller.stat_controller.add_modifier("Ball.dodge_rate",2,0,"STUNSTOP"+str(stun_id_local))
	baller.stat_controller.add_modifier("Hitbox.collision_disabled",2,true,"STUNSTOP"+str(stun_id_local))
	baller.stat_controller.add_modifier("Rotater.aiming",2,false,"STUNSTOP")
	mod_list.append("STUNSTOP"+str(stun_id_local))
	
	await STimer.delay(0.15+0.1*strength)
	if is_instance_valid(baller):
		baller.stat_controller.remove_modifier("STUNSTOP"+str(stun_id_local))
		mod_list.erase("STUNSTOP"+str(stun_id_local))
	ongoing_stuns-=1
	if ongoing_stuns<=0:
		set_counter(-1)
		queing=true
		queue_free()

func _process(delta):
	if baller!=null and !queing:
		gpu_particles_2d.global_position=baller.global_position
		set_counter(ongoing_stuns)
