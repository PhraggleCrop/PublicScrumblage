## Default animation player needs at least a default and hurt
## There will be balls that don't use these, it's ok
## Don't delete the sprites tho

extends AnimationPlayer
@onready var v_bod:VisualBody=get_parent()

var hurttime
var ball:BallBodyBase
@export var visuals:Node2D
## Plays hurt sprite on being hurt
@export var hurt_switch:bool=true
signal current_visual

@onready var default: Node2D = $"../Default"
@onready var hurt: Node2D = $"../Hurt"

func _enter_tree():
	ball=visuals.ball
	
func _ready():
	current_visual.emit("Default")
	play("Default")
	ball.got_hit.connect(hurt_visual)
	EventManager.critted.connect(crit_visual)

func hurt_visual(data):
	for i in default.get_children():
		if i.visible==true:
			visuals.add_quake(0.7)
			if i.locked_visual==false and hurt_switch:
				if data["DAMAGE"]==0:
					hurt.visible=true
					default.visible=false
				else:
					play("Hurt")
					hurt.visible=true
					default.visible=false
				
			else:
				if data["DAMAGE"]==0:
					continue
				else:
					play("HurtFlash")
				
				
	current_visual.emit("Hurt")
	
	hurttime=Time.get_ticks_usec()
	var tracktime=hurttime
	v_bod.add_quake(1.0)
	
	await STimer.delay(0.3)
	if !is_instance_valid(ball):
		return
	if tracktime!=hurttime:
		return
	play("Default")
	current_visual.emit("Default")
	
func crit_visual(body):
	if body==ball:
		v_bod.add_quake(3.4)
