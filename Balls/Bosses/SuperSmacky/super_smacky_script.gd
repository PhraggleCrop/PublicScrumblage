extends "res://Balls/Fighters/Smacky/smacky_script.gd"
# this is just to show what the differences between a boss and normal ball is

@onready var super_smacky_ball: BallBodyBase = $".."

@onready var spawn_animation: AnimationPlayer = $"../SpawnAnimation"
@onready var banner_animation = $"../BANNER/BannerAnimation"

# make sure the following signals and variable are named exactly this. but its okay if they dont have these
# raid mode is coded in a way that you can actually place normal ball characters into the boss res
# but if you want a special intro or a way to shake a camera be sure to use these.
signal intro_finished # lets the gamemode know when to start the round
signal banner_finished
signal shake_camera(amount : float) # shakes the camera

@export var hasIntro : bool = true # the main raid gd checks to see if this variable exists and if it's true or not
# you can turn this off to skip the intro

func _ready():
	super()
	if !hasIntro || Global.game_mode != 1: # to skip intro
		super_smacky_ball.visible = true
	# if anything is set to be invisible for your spawn animation MAKE SURE to set them to visible if the hasIntro is set to false
	# or if the gamemode is different. atm since raidmode just reuses teammode, you'll need to turn off hasIntro for 2v2
@onready var beta_spawn_animation = $"../BETASpawnAnimationAssets/BETASpawnAnimation"

func start_intro(): # plays the animation
	print('intro playing')
	beta_spawn_animation.play('spawn_animation')
	await beta_spawn_animation.animation_finished
	intro_finished.emit() # waits for the animation to finish before beginning the round

func open_banner():
	banner_animation.play('banner_anim')
	await banner_animation.animation_finished
	banner_finished.emit()

func camera_shake(amount : float):
	shake_camera.emit(amount)

# USE THE FOLLOWING IF YOU WANT TO HAVE A CUSTOM ARENA
#var arena_size=1.0
#var new_arena_size = 1.0
#
#func shrink_arena(target_size):
	#new_arena_size = target_size
#
#func _process(delta): #replace the $".. with whatever node holds your arena!
	#arena_size = lerpf(arena_size, new_arena_size, 0.5 * delta)
	#$"../DarkWorld/Control".scale = arena_size * Vector2(1,1) 
