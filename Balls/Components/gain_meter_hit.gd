## Gain meter when ball deals damage

extends Node
@onready var behaviour_script:BehaviourScript=get_parent()

@export var invert:bool=false

## Enabled makes it gain, disable to stop
@export var enabled:bool=true

## Make sure the damage id matches this id to gain meter off of it.
## By default damage id should be blank
@export var id :String=""

## Multiplier to scale meter off the damage
## 3 Damage x 2 multiplier, 6 meter
@export var multiplier:float =1.0
@export var meter_manager:MeterManager

## Gained emitted every time you gain meter using it
signal gained
signal lost
func _ready():
	EventManager._successfully_damaged_.connect(hit_process)

func hit_process(data):
	if !enabled:
		return
	var attacker=data["ATTACKER"]
	var victim = data["VICTIM"]
	var dmg = data["DAMAGE"]
	var _id = data["ID"]
	if attacker==behaviour_script.ball or behaviour_script.spawn_list.has(attacker):
		if attacker.team != behaviour_script.ball.team:
			return
		if _id!=id:
			return
		if victim.is_in_group("AntiInteract"):
			return
		if invert:
			meter_manager.lose_meter(dmg*multiplier*victim.get_value_scale())
			lost.emit(dmg*multiplier*victim.get_value_scale())
		else:
			meter_manager.gain_meter(dmg*multiplier*victim.get_value_scale())
			gained.emit(dmg*multiplier*victim.get_value_scale())
