class_name Player extends CharacterBody2D

@export var speed = 300
@export var firing_rate = 0.25
@export var heavy_laser_duration = 5.0  # Duration in seconds for heavy laser power-up

@onready var aim = $Aim
@onready var anim_sprite = $AnimatedSprite2D

signal laser_shot(lascer_scene, location)
signal killed

var default_laser_scene = preload("res://Scenes/laser.tscn")
var heavy_laser_scene = preload("res://Scenes/heavy_laser.tscn")
var lascer_scene
var shoot_cd := false

var heavy_laser_timer: Timer
var has_heavy_laser = false

func _ready():
	# Initialize with default laser
	lascer_scene = default_laser_scene
	
	# Create timer for heavy laser duration
	heavy_laser_timer = Timer.new()
	heavy_laser_timer.wait_time = heavy_laser_duration
	heavy_laser_timer.one_shot = true
	heavy_laser_timer.timeout.connect(_on_heavy_laser_timeout)
	add_child(heavy_laser_timer)

func _process(delta):
	if Input.is_action_pressed("shoot"):
		if(!shoot_cd):
			shoot_cd = true
			shoot()
			await get_tree().create_timer(firing_rate).timeout
			shoot_cd = false

func _physics_process(_delta):
	var direction = Vector2(Input.get_axis("move_left","move_right"),Input.get_axis("move_up","move_down"))
	velocity = direction * speed
	move_and_slide()
	
	if direction.x > 0:
			anim_sprite.play("right")
	elif direction.x < 0:
			anim_sprite.play("left")
	else:
			anim_sprite.play("default")
	
	var margin = Vector2(26,26)
	global_position = global_position.clamp(margin,get_viewport_rect().size - margin)

func shoot():
	laser_shot.emit(lascer_scene, aim.global_position)

func activate_heavy_laser():
	"""Activate heavy laser power-up for a limited time"""
	has_heavy_laser = true
	lascer_scene = heavy_laser_scene
	heavy_laser_timer.start()
	print("Heavy laser activated for ", heavy_laser_duration, " seconds!")

func _on_heavy_laser_timeout():
	"""Called when heavy laser duration expires"""
	has_heavy_laser = false
	lascer_scene = default_laser_scene
	print("Heavy laser power-up expired")

func die():
	queue_free()
	killed.emit()
