extends StatusEffect
@onready var icecube = $Icecube

var lose_value = 1

func set_target(ball, value, data):
	super(ball, value, data)
	set_counter(value)
	icecube.scale = Vector2(1, 1) * baller.ball_scale
	freeze()

func update(value, data):
	set_counter(min(counter + value,max(10,value)))
	return self

func check_apply(ball) -> bool:
	if !super(ball):
		return false
	if ball.is_in_group("AntiFreeze"):
		return false
	return true

func freeze():
	#
	#EventManager.hit.emit({
		#"VICTIM": baller,
		#"TYPE": ["STATUS_EFFECT"],
		#"DAMAGE": 3,
		#"HITSTOP_SCALE": 0.25,
		#"SFX": "res://Sounds/lighter.wav",
		#"ID": "STATUS_FREEZE"
	#})
	SoundQueue.play("res://Sounds/glass-break-pop_F_minor.wav")
	baller.stat_controller.add_modifier("ContactDamager.enabled", 2, false, "FREEZED")
	baller.stat_controller.add_modifier("Hitbox.collision_disabled", 2, true, "FREEZED")
	baller.stat_controller.add_modifier("BehaviourScript.behaviour_active", 2, false, "FREEZED")
	baller.stat_controller.add_modifier("Rotater.bounce_spin_boost", 1, 0.1, "FREEZED")
	baller.stat_controller.add_modifier("Mood.disabled", 2, true, "FREEZED")
	baller.stat_controller.add_modifier("Rotater.locked", 2, true, "FREEZED")
	baller.stat_controller.add_modifier("Ball.velocity", 1, 0.01, "FREEZED")
	baller.stat_controller.add_modifier("Ball.dodge_rate", 1, 0.0, "FREEZED")
	baller.stat_controller.add_modifier("Ball.bounce_speed_boost", 2, 0, "FREEZED")
	baller.stat_controller.add_modifier("Ball.dodge_rate", 2, 0, "FREEZED")
	baller.stat_controller.add_modifier("Rotater.aiming",2,false,"FREEZED")
func _process(delta):
	if is_instance_valid(baller):
		icecube.global_position = baller.global_position

	var mod_a = 0.05 + 0.45 * 2.0
	icecube.modulate.a = clamp(mod_a, 0.0, 1.0)

	set_counter(counter - delta * lose_value)
	if counter <= 0.0:
		queue_free()

func on_leave():
	super()
	if !is_instance_valid(baller):
		return
	baller.stat_controller.remove_modifier("FREEZED")
