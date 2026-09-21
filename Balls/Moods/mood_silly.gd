extends Mood

@onready var resource = load("res://Balls/Moods/MoodAssets/Silly.png")

func _ready():
	trigger_behaviour.connect(behaviour)


func behaviour():
	if super():
		return
	ball.bounce.emit()
	var rand_behaviour = randf()
	PopUpManager.emote_effect(ball,resource,scaled_offset())
	
	if rand_behaviour>0.2:
		var speed = ball.get_velocity().length() + 45
		ball.set_velocity( Vector2.RIGHT.rotated(randf() * TAU) * speed)

	elif rand_behaviour>0.1:
		var dir = Global.dir_closest_ball(ball)
		if dir == Vector2.ZERO:
			return
		ball.set_velocity(dir*(ball.get_velocity().length()+45))
	elif  rand_behaviour>0.0:
		var dir = Global.dir_closest_ball(ball)
		if dir == Vector2.ZERO:
			return
		ball.set_velocity(-dir*(ball.get_velocity().length()+45))
	
	behaviour_occured.emit()
