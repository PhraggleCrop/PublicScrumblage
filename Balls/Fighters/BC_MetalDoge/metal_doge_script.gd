## Behaviour script for smacky
## BHs should contain all the unique functionality of ball

extends BehaviourScript

## Grabbing reference to elements manipulated/referenced from in code
@onready var meter_manager = $"../MeterManager"
@onready var weapon_hitbox = $"../Rotater/WeaponHolder/WeaponFlipper/WeaponHitbox"
@onready var rotater = $"../Rotater"
@onready var hit_processor = $"../HitProcessor"
@onready var gain_hit: Node = $GainHit

## Flag for if we are using our ability
var rampaging:bool=false

## On ready, connect to our gain_hit node
## Link to a check, so every time we gain meter
## we check if we are full to trigger ability
func _ready():
	super()
	gain_hit.gained.connect(super_check)

## If meter is full trigger
func super_check(meter_value):
	if meter_value>=100 and !rampaging:
		rampage()

## We set flag, and disable our gain_hit node
## Use StatControll (sc) to update our stat values

func rampage():
	rampaging=true
	gain_hit.enabled=false
	sc.set_base_stat("Ball.velocity",1500)
	sc.set_base_stat("Ball.bounce_speed_boost",500)
	sc.set_base_stat("HitboxDamager.damage",6)
	# sc.set_base_stat("ClashBouncer.cleave",true)

## Resets our stat values to default
func unrampage():
	rampaging=false
	gain_hit.enabled=true
	sc.set_base_stat("Ball.velocity",650)
	sc.set_base_stat("Ball.bounce_speed_boost",400)
	sc.set_base_stat("HitboxDamager.damage",4)
	# sc.set_base_stat("ClashBouncer.cleave",false)

## Every frame check if we are big
## If we are big lose meter and update our scale to match
## Else shrink
func _physics_process(delta):
	if HitstopManager.hitstopped:
		return

	if rampaging:
		meter_manager.lose_meter(18*delta)
		## If our meter is empty, unbiggify
		if meter_manager.meter<=0:
			unrampage()
