extends Control
@export var ball_stat_display:Node
var health_manager:HealthManager

var frail_amount: float = 0.0
@onready var healthbar: TextureProgressBar = $Healthbar
@onready var frailbar: TextureProgressBar = $Frail
@onready var health_chaser: TextureProgressBar = $HealthChaser
@onready var overhealth: TextureProgressBar = $Overhealth
@onready var health_label:Node=$Healthbar/HealthLabel
@onready var armor: TextureProgressBar = $Armor
var default_tint_progress:Color=Color("00b88a")
func _ready() -> void:
	await get_tree().process_frame
	health_manager=ball_stat_display.health_manager
	health_manager.armor_changed.connect(_update_bars.unbind(1))
	health_manager.overhealth_changed.connect(_update_bars.unbind(1))
	health_manager.health_changed.connect(health_changed)
	health_changed(health_manager.health)
	default_tint_progress=healthbar.tint_progress
	
func health_changed(health):
	
	health = floor(health * 10.0) / 10.0
	if health == floor(health):
		health = int(health)
	
	health_label.text = str(health)
	_update_bars()
	
func _update_bars():
	## max_value of healthbar
	## effectively where we sit at
	var current_size = health_manager.health + health_manager.overhealth + health_manager.armor * 5
	## By dividing current size by max_health
	var scaled = current_size / health_manager.max_health
	
	var display_max = max(current_size,health_manager.max_health)
	
	armor.max_value = display_max
	healthbar.max_value = display_max
	frailbar.max_value = display_max
	health_chaser.max_value = display_max
	overhealth.max_value = display_max
	
	
	var overhealth_val = health_manager.overhealth
	
	var sub_frail = frail_amount
	var display_overhealth = overhealth_val
	var display_health = health_manager.health
	var display_armor = health_manager.armor
	
	if sub_frail>0.0:
		## Lower overhealth by frail value
		## If it's positive, then we ussed up subfrail
		## If negative, we have leftovers
		display_overhealth -= sub_frail
		if display_overhealth>0:
			sub_frail=0.0
		else:
			sub_frail=abs(display_overhealth)
			display_overhealth=0.0
			
	plate_manager.plate_display(display_armor)
	
	if sub_frail>0.0 and display_armor>0:
		display_armor-=1
		sub_frail=0.0
	
	
	if sub_frail>0.0:
		display_health-=sub_frail
	
	display_armor *= 5
	armor.value = display_health+display_armor
	healthbar.value = display_health
	overhealth.value = display_health +display_armor+ display_overhealth

	frailbar.value =  health_manager.health + overhealth_val + display_armor
	
@onready var plate_manager: Control = $PlateManager


func health_setted():
	var display_max = health_manager.max_health + max(health_manager.overhealth, 0.0)
	healthbar.max_value = display_max
	frailbar.max_value = display_max
	health_chaser.max_value = display_max
	overhealth.max_value = display_max
	health_chaser.value = display_max

func _update_bar_color():
	if not ball_stat_display.hit_processor.immune:
		healthbar.tint_progress = default_tint_progress

	
func _process(_delta):
	if ball_stat_display.ball==null:
		return
	var target = healthbar.value
	health_chaser.value = max(target, health_chaser.value - 0.15)
	
	if ball_stat_display.hit_processor.immune:
		var hue = fmod(Time.get_ticks_msec() / 300.0 * 0.25, 1.0)
		healthbar.tint_progress = Color.from_hsv(hue, 0.85, 1.0)


## EVERYTHING UNDER HERE IS SPECIFIC SPECIAL VISUAL EFFECTS FOR STATUS
func purple_bar(value):
	if value == -1:
		frail_amount = 0.0
	else:
		frail_amount = value
	if health_manager:
		_update_bars()
