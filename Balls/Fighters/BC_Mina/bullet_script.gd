extends BehaviourScript
signal connected
var bounce_count:int=1
var special:bool=false

@export
var effect: Resource = preload("uid://du07hj18sqtx7")

func _ready():
	super()
	await delay(0.1)
	ball.bounce_wall.connect(bounced.unbind(1))

## If we are special, set our stats differently
func set_special():
	sc.set_base_stat("Ball.ball_scale",1.5)
	sc.set_base_stat("Ball.velocity",500)
	sc.set_base_stat("HitboxDamager.damage",10)
	sc.set_base_stat("HitboxDamager.crit_chance",1)
	sc.set_base_stat("HitboxDamager.knockback",300)
	bounce_count=3
	special=true

func bounced():
	bounce_count-=1
	if bounce_count<=0:
		ball.set_wall_collide(false)

##Triggers when something get's damaged
func hit_process(data):
	var attacker=data["ATTACKER"]
	var victim = data["VICTIM"]
	##If we did the damage, then delete our bullet
	if attacker==ball:
		if special:
			spawn_thing(effect,true,false)
		connected.emit()
		delete()


##Delete our bullet object
func delete():
	ball.queue_free()
