extends Mood
var resource = load("res://Balls/Moods/MoodAssets/Aggressive.png")

func behaviour():
	if super():
		return
	ball.bounce.emit()
	var dir = Global.dir_closest_ball(ball)
	PopUpManager.emote_effect(ball,resource,scaled_offset())
	behaviour_occured.emit()
	if dir == Vector2.ZERO:
		return
	
	ball.set_velocity(dir*(ball.get_velocity().length()+65))

		
