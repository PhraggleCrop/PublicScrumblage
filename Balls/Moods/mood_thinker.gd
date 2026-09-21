extends Mood


@onready var resource = load("res://Balls/Moods/MoodAssets/Thinker.png")

func _ready():
	trigger_behaviour.connect(behaviour)


func behaviour():
	if super():
		return
	ball.bounce.emit()
	var speed = (ball.get_velocity().normalized())
	
	ball.set_velocity( speed)

	PopUpManager.emote_effect(ball,resource,scaled_offset())
	behaviour_occured.emit()
