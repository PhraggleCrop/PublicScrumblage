extends Mood
@export var aggress:bool=false

@onready var resource = load("res://Balls/Moods/MoodAssets/Sneaky.png")


func _ready():
	trigger_behaviour.connect(behaviour)


func behaviour():
	if super():
		return
	ball.bounce.emit()
	var dir = Global.dir_closest_ball(ball)
	PopUpManager.emote_effect(ball,resource,scaled_offset())
	if dir == Vector2.ZERO:
		return
		
	if !aggress:
		dir*=-1
	ball.set_velocity(dir*(ball.get_velocity().length()+45))
	behaviour_occured.emit()

		
