extends Mood
func _ready():
	trigger_behaviour.connect(behaviour)

var resource = load("res://Balls/Moods/0771.png")
func behaviour():
	trigger_time=Time.get_ticks_usec()
	var tracktime=trigger_time
	await STimer.delay(0.3+0.3*randf())
	if !Global.can_act(ball):
		return
	if tracktime!=trigger_time:
		return
	
	
	var dir = Global.dir_closest_ball(ball)
	PopUpManager.emote_effect(ball,resource,effect_offset)
	behaviour_occured.emit()
	if dir == Vector2.ZERO:
		return
	ball.set_velocity(-dir*(ball.get_velocity().length()+45))
	
	
