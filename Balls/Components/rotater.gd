## Rotater is used for weapons that rotate around the ball
extends Node2D
class_name Rotater

@export var ball: BallBodyBase
var stat_controller: StatController

## Locks rotation in place, no movement
@export var locked: bool = false

## Base rate at which it rotates
@export var rotation_rate: float = 3.5

var angular_velocity: float
var prefreeze_a_velocity: float

## Rate at which rotation returns to base rotation_rate
@export var normalizer_rate: float = 11.0

## This is the spin boost added on bouncing
@export var bounce_spin_boost: float = 6

## When weapons clash, this is min speed at which it goes the other way
## Use sparingly for weapons, but makes them bounce back to other side faster
## Good for combo fast hitting weapons
@export var flipper_min: float = 1.0

## If cleaving, increase or decrease speed by this amount
@export var cleave_boost:float=0

@export var cleave_cap:float=14

## Aiming flag overrides base behaviour, makes rotater aim at nearest enemy
@export var aiming: bool = false
@export_enum( "Nearest To Self","Closest To Direction") var aim_mode: String = "Nearest To Self"
@export var aim_speed: float = 0.1

## This is direction rotater starts spinning
## 0 is random, else if -1 or 1 makes it consistent
@export var spin_dir: float = 0.0

@export var sync_stats:bool=true
@export var stat_name: String = "Rotater"


signal angulize

var base_scale: Vector2 = Vector2(1, 1)

func _ready():
	if spin_dir == 0.0:
		if randf() > 0.5:
			spin_dir = -1.0 
		else:
			spin_dir = 1.0 
	angulize.emit(spin_dir)
	connect_signals()
	set_a_velocity(spin_dir * rotation_rate)
	rotation_degrees = randf() * 360

func connect_signals():
	var waiting := get_children()
	while not waiting.size()==0:
		var node := waiting.pop_back() as Node
		waiting.append_array(node.get_children())
		if node is ClashBouncer:
			node.flip.connect(flipper)
			node.cleave_hit.connect(boost_cleave)
	ball.bounce.connect(spin_bounce_boost)
	ball.hitstop.connect(hitstop_effect)
	ball.update_scale.connect(update_scale)
	
	if sync_stats:
		stat_controller = ball.stat_controller
		stat_controller.stat_changed.connect(update_stats)
		
		stat_controller.set_base_stat(stat_name + ".locked", locked)
		stat_controller.add_alias(stat_name + ".locked", "Rotater.locked")
		
		stat_controller.set_base_stat(stat_name + ".rotation_rate", rotation_rate)
		stat_controller.add_alias(stat_name + ".rotation_rate", "Rotater.rotation_rate")
		
		stat_controller.set_base_stat(stat_name + ".normalizer_rate", normalizer_rate)
		stat_controller.add_alias(stat_name + ".normalizer_rate", "Rotater.normalizer_rate")
		
		stat_controller.set_base_stat(stat_name + ".bounce_spin_boost", bounce_spin_boost)
		stat_controller.add_alias(stat_name + ".bounce_spin_boost", "Rotater.bounce_spin_boost")
		
		stat_controller.set_base_stat(stat_name + ".visible", visible)
		stat_controller.add_alias(stat_name + ".visible", "Rotater.visible")
		
		stat_controller.set_base_stat(stat_name + ".scale", scale)
		stat_controller.add_alias(stat_name + ".scale", "Rotater.scale")
		
		stat_controller.set_base_stat(stat_name + ".flipper_min", flipper_min)
		stat_controller.add_alias(stat_name + ".flipper_min", "Rotater.flipper_min")
	
func boost_cleave():
	angular_velocity = sign(angular_velocity)*min(max(abs(angular_velocity)+cleave_boost,0),cleave_cap)
	
func update_stats(stat, new_val):
	if !sync_stats:
		return
	if stat == stat_name + ".angular_velocity":
		if ball.freezed:
			prefreeze_a_velocity = new_val
		else:
			angular_velocity = new_val
	elif stat == stat_name + ".rotation_rate":
		rotation_rate = new_val
	elif stat == stat_name + ".locked":
		locked = new_val
	elif stat == stat_name + ".normalizer_rate":
		normalizer_rate = new_val
	elif stat == stat_name + ".bounce_spin_boost":
		bounce_spin_boost = new_val
	elif stat == stat_name + ".visible":
		visible = new_val
	elif stat == stat_name + ".scale":
		base_scale = new_val
		update_scale()
	elif stat == stat_name + ".flipper_min":
		flipper_min = new_val

## Rotates a rotater to an angle over a duration
## Used to aimed shooting
func rotate_to(target_angle: float, duration: float):
	var start_angle = rotation
	var tween = create_tween()
	tween.tween_method(
		func(t):
			rotation = lerp_angle(start_angle, target_angle, t),0.0,1.0,duration)
	await tween.finished
	return
	
func update_scale():
	scale = ball.ball_scale * base_scale

## Returns vector direction of rotater
func vec_dir():
	return Vector2.RIGHT.rotated(rotation)

## Returns angle dir of rotater
func angle_dir():
	return Vector2.RIGHT.rotated(rotation).angle()

## Called when weapon flips
func flipper():
	if locked:
		return
	
	## Use magnitude to calculate speed then apply flip
	var speed = max(abs(get_a_velocity()), flipper_min)
	spin_dir *= -1.0
	
	set_a_velocity(speed * spin_dir)

	angulize.emit(spin_dir)

func _physics_process(delta):
	if ball.freezed:
		return
	
	if locked or HitstopManager.hitstopped:
		return
		
	
	var can_aim = aiming
	if ball.behaviour_script:
			if ball.behaviour_script.behaviour_active==false:
				can_aim=false
	if can_aim:
		var dir 
		if aim_mode=="Nearest To Self":
			dir = Global.dir_closest_ball(ball)
		elif aim_mode == "Closest To Direction":
			dir = Global.closest_to_dir(ball,vec_dir(),ball.global_position,true)
			if dir==null:
				dir = vec_dir()
			else:
				dir = ball.global_position.direction_to(dir.global_position)
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT.rotated(rotation)
		rotation = lerp_angle(rotation, dir.angle(), aim_speed)
	else:
		rotation_degrees += angular_velocity

	var current_speed = abs(angular_velocity)
	var target_speed = rotation_rate
	var new_speed = move_toward(current_speed, target_speed, normalizer_rate * delta)

	set_a_velocity(new_speed * spin_dir)


func spin_bounce_boost():
	var speed = max(0, rotation_rate + bounce_spin_boost)
	if !bounce_spin_boost<0:
		speed = max(speed,abs(get_a_velocity()))
	set_a_velocity(speed * spin_dir)

func hitstop_effect(truefalse):
	if truefalse:
		prefreeze_a_velocity = angular_velocity
		angular_velocity = 0.0
	else:
		angular_velocity = prefreeze_a_velocity

## Gets the angular velocity
func get_a_velocity(absolute=false):
	if ball.freezed:
		if absolute:
			return abs(prefreeze_a_velocity)
		return prefreeze_a_velocity
	else:
		if absolute:
			return abs(angular_velocity)
		return angular_velocity

## Sets the angular velocity
func set_a_velocity(val):
	if locked:
		return
	stat_controller.set_base_stat(stat_name + ".angular_velocity", val)

## Adds to the angular velocity
func add_a_velocity(val):
	if locked:
		return
	var speed = abs(get_a_velocity()) + val
	set_a_velocity(speed * spin_dir)

## Set a velocity to certain strength, keep direction
func adjust_a_velocity(val):
	if locked:
		return
	stat_controller.set_base_stat(stat_name + ".angular_velocity", val * spin_dir)
