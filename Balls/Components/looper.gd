## Loops can emits trigger signals every so often
## Behaviour script will use looper to trigger looping behaviours

extends Node
var timer:float=0.0
## If the timer is active
## Disable to pause timer basically
@export var active:bool=true

## Delay time is base time you must wait for next trigger
@export var delay_time :float= 0.3

## Randomization of added time to base
@export var added_rand_time :float = 0.0

## Connect to trigger to make something happen when timer is filled
signal trigger

var target_time:float

func _ready():
	target_time=(delay_time+randf()*added_rand_time)
	
func _process(delta):
	if HitstopManager.hitstopped or !active:
		return
	timer+=delta
	if timer>target_time:
		timer=0.0
		trigger.emit()
		target_time=delay_time+(randf()*added_rand_time)

func set_delay(val):
	delay_time=val
	target_time=(delay_time+randf()*added_rand_time)
	
func progress_scale():
	return timer/target_time
