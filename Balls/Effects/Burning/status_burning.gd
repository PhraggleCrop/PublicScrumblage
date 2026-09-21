extends StatusEffect
var delay=1.0

@export var gpu_particles_2d:CPUParticles2D
var exploded=false


func on_leave():
	set_icon(icon_effect,-1)

func set_target(ball,value,data):
	if exploded:
		return
	super(ball,value,data)
	
	
	set_counter(value)
	
	burn(ball)
	if gpu_particles_2d.emitting!=true:
		gpu_particles_2d.emitting=true
	if counter>=10:
		explode()
	scale_flames()
@onready var explosion = $Node2D

func set_source(source):

	ball_source=source
	$Node2D/DangerZone.ball=source

func explode():
	if exploded:
		return
	exploded=true
	explosion.global_position=baller.global_position
	explosion.visible=true
	$Node2D/DangerZone.ignore_list.append(baller)
	$Node2D/DangerZone/HitboxDamager.damage=counter
	$Node2D/Boom2/AnimationPlayer.play("Boom")
	$Node2D/DangerZone.detect_tick()
	SoundQueue.play("res://Assets/deltarune explosion.mp3")
	gpu_particles_2d.emitting=false
	
	EventManager.hit.emit({"ATTACKER":ball_source.get_root_creator(),"VICTIM":baller,"TYPE":["STATUS_EFFECT"],"CRIT_CHANCE":1,"CRIT_MULTIPLIER":1,"DAMAGE":counter,"HITSTOP_SCALE":0.5,
	"ID":"STATUS_BURNING"})
	
	
	set_icon(icon_effect,counter)
	await $Node2D/Boom2/AnimationPlayer.animation_finished
	
	set_counter(0)
	queue_free()

func update(value,data):
	if exploded:
		return
	
	set_counter(counter+value)
	set_icon(icon_effect,counter)
	if counter>=10:
		explode()
	scale_flames()
	return self
	

func check_apply(ball)->bool:
	
	if !super(ball):
		return false
	if ball.is_in_group("AntiBurn"):
		return false
	return true
	
func burn(ball):
	if exploded:
		return
	baller=ball
	if counter<=0:
		queue_free()
		return
	set_counter(counter)
	await STimer.delay(1)
	if exploded:
		return
	if !is_instance_valid(ball):
		return
	EventManager.hit.emit({"ATTACKER":ball_source,"VICTIM":ball,"TYPE":["STATUS_EFFECT"],"DAMAGE":1,"HITSTOP_SCALE":0.01,"SFX":"res://Sounds/lighter.wav",
	"ID":"STATUS_BURNING"})
	
	set_counter(counter-1)
	set_icon(icon_effect,counter)
	burn(ball)
	scale_flames()
	
func _physics_process(delta):
	if baller!=null and is_instance_valid(baller):
		gpu_particles_2d.global_position=baller.global_position
		overlay.global_position=baller.global_position
		
@onready var overlay = $Overlay

	

func scale_flames():
	var scale_val=pow(min(1.0,counter/10.0),1)
	gpu_particles_2d.speed_scale=0.3+4*pow(scale_val,1.4)
	gpu_particles_2d.scale_amount_max=0.4+scale_val*2
	gpu_particles_2d.scale_amount_min=0.6+scale_val*2
	gpu_particles_2d.color.a=0.2+pow(scale_val*0.8,0.6)
	gpu_particles_2d.initial_velocity_min=100+200*scale_val
	gpu_particles_2d.initial_velocity_max=300+200*scale_val
	
	
