extends Mood
var poof = load("res://Balls/Moods/MoodAssets/enigmatic_poof.tscn")
var resource = load("res://Balls/Moods/MoodAssets/Enigmatic.png")

var exit_direction: Vector2
var count = 8

func behaviour():
	if super():
		return
	ball.bounce.emit()
	PopUpManager.emote_effect(ball, resource, scaled_offset())
	var start=global_position
	var exit_position=Global.get_random_position_in_arena(start)
	await get_tree().physics_frame

	spawn_poof(start)
	spawn_poof(exit_position)
	behaviour_occured.emit()

	ball.global_position = exit_position
	SoundQueue.play("res://Assets/tboi-repentance-sound-teleport-uc-0-azw.wav", 1, 0.7)

func spawn_poof(pos: Vector2):
	var instance = poof.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = pos
	instance.emitting=true
	await get_tree().create_timer(2).timeout
	instance.queue_free()
