extends BehaviourScript

@onready var fire_hitbox = $"../Scaler/FireHitbox"
signal connected
var fb_dmg=3

func _ready():
	super()
	ball.bounce_wall.connect(bounced.unbind(1))
	
var bounce_count=3
func bounced():
	bounce_count-=1
	if bounce_count<=0:
		ball.set_wall_collide(false)
		
		
func hit_process(data):
	var fireball_meter:float=25
	var attacker=data["ATTACKER"]
	var victim = data["VICTIM"]
	var critted = data["CRIT"]
	if attacker==ball:
		if !critted:
			StatusEffectManager.set_effect(ball.get_root_creator(),victim,"BURNING",fb_dmg,{"SOURCE":attacker})
		else:
			StatusEffectManager.set_effect(ball.get_root_creator(),victim,"BURNING",fb_dmg*2,{"SOURCE":attacker})
		delete()
		connected.emit(fireball_meter*victim.get_value_scale())
		

func delete():
	await get_tree().process_frame
	ball.queue_free()
