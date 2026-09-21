extends Node2D
class_name Mood
@export var disabled:bool=false
@export var ball:BallBodyBase
@export var trigger_chance:float=0.2
@export var effect_offset:float=100

@export var stat_name: String = "Mood"
var stat_controller:StatController
var e_time:int
var tick_check=0.0
var trigger_time
var tracktime

signal trigger_behaviour
signal behaviour_occured
signal emote_signal

func _enter_tree():
	ball.bounce.connect(bounce_modify)
	stat_controller=ball.stat_controller
	stat_controller.stat_changed.connect(update_stats)
	
	stat_controller.set_base_stat(stat_name+".trigger_chance",trigger_chance)
	stat_controller.set_base_stat(stat_name+".disabled",disabled)
	

func scaled_offset():
	return effect_offset*stat_controller.get_stat("Ball.ball_scale")

func update_stats(_stat_name,new_val):
	if _stat_name == stat_name+".disabled":
		disabled=new_val
	elif _stat_name== stat_name+".trigger_chance":
		trigger_chance=new_val

func _physics_process(delta):
	tick_check=min(60,tick_check+1)

func bounce_modify():
	if randf()<trigger_chance and disabled==false and tick_check ==60:
		trigger_time=Time.get_ticks_usec()
		tracktime=trigger_time
		await STimer.delay(0.3+0.3*randf())
		behaviour()
		tick_check=0.0
		
func behaviour():
	if disabled:
		return true
	if !Global.can_act(ball):
		return true
	if tracktime!=trigger_time:
		return true
