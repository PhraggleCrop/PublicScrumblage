## Meter gained when ball takes damage

extends Node
@onready var behaviour_script:BehaviourScript=get_parent()

@export var invert:bool=false
## Disable/enable the behaviour
@export var enabled:bool=true

## Multiplier multipliers the damage taken as meter
@export var multiplier:float =1.0
@export var meter_manager:MeterManager
signal gained
signal lost
func _ready():
	EventManager._successfully_damaged_.connect(hit_process)

func hit_process(data):
	if !enabled:
		return
	var victim = data["VICTIM"]
	var dmg = data["DAMAGE"]
	if victim==behaviour_script.ball:
		if invert:
			meter_manager.lose_meter(dmg*multiplier)
			lost.emit(dmg*multiplier)
		else:
			meter_manager.gain_meter(dmg*multiplier)
			gained.emit(dmg*multiplier)
	
