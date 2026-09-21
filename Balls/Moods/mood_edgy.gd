extends Mood

@onready var resource = load("res://Balls/Moods/MoodAssets/Edgy.png")

func _ready():
	trigger_behaviour.connect(behaviour)


func behaviour():
	if super():
		return
	
	ball.bounce.emit()
	var dir_to_center = ball.global_position.direction_to(Global.center)

	var speed = (ball.get_velocity().length())
	
	ball.set_velocity( -dir_to_center * speed)

	behaviour_occured.emit()
	PopUpManager.emote_effect(ball,resource,scaled_offset())

func scaled_offset():
	return effect_offset*ball.ball_scale
