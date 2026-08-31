extends StatusEffect
var delay=1.0

@export var cpu_particles_2d:CPUParticles2D


func check_apply(ball)->bool:
	if !super(ball):
		return false
	if ball.is_in_group("AntiStun"):
		return false
	return true
	
func update_scale():
	if baller:
		cpu_particles_2d.scale = Vector2(1,1)*baller.stat_controller.get_stat("Ball.ball_scale")
	
func set_target(ball,value,data):
	super(ball,value,data)
	if !ball:
		queue_free()
		return
	update_scale()
	if data.get("SFXMUTE",false)==false:
		SoundQueue.play("res://Sounds/knockedout.wav")
	ball.update_scale.connect(update_scale)
	set_counter(value)
	baller=ball
	baller.stat_controller.add_modifier("ContactDamager.enabled",2,false,"STUNNED")
	
	baller.stat_controller.add_modifier("HitProcessor.immune",2,false,"STUNNED")
	baller.stat_controller.add_modifier("Hitbox.collision_disabled",2,true,"STUNNED")
	baller.stat_controller.add_modifier("BehaviourScript.behaviour_active",2,false,"STUNNED")
	baller.stat_controller.add_modifier("Rotater.bounce_spin_boost",1,0.1,"STUNNED")
	
	baller.stat_controller.add_modifier("Ball.dodge_rate",2,0,"STUNNED")
	baller.stat_controller.add_modifier("Mood.disabled",2,true,"STUNNED")
	
	baller.stat_controller.add_modifier("Rotater.aiming",2,false,"STUNNED")
	baller.stat_controller.add_modifier("Rotater.rotation_rate",1,(0.1),"STUNNED")
	baller.stat_controller.add_modifier("Ball.velocity",1,0.1,"STUNNED")
	baller.stat_controller.add_modifier("Ball.bounce_speed_boost",1,0.0,"STUNNED")
	baller.set_velocity(baller.get_velocity().normalized()*baller.get_velocity().length()*3/4.0) 
	if cpu_particles_2d.emitting!=true:
		cpu_particles_2d.emitting=true
	
	EventManager._successfully_damaged_.connect(hit_process)
	

func hit_process(data):
	var victim = data["VICTIM"]
	if victim==baller:
		set_counter(counter-1)
		
	
func unstun():
	var done=true
	await STimer.delay(0.15)
	if is_instance_valid(baller):
		baller.stat_controller.remove_modifier("STUNNED")
	queue_free()
	
var done=false

func update(value,data):
	set_counter(counter+value)
	return self

func _physics_process(delta):
	if baller==null or !is_instance_valid(baller):
		return
	cpu_particles_2d.global_position=baller.global_position
	if done:
		return
	
	set_counter(counter-delta)
	
	if counter<=0:
		unstun()
		
