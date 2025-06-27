class_name Player extends CharacterBody2D

@export var speed = 300
@export var firing_rate = 0.25

@onready var aim = $Aim

signal laser_shot(lascer_scene, location)

var lascer_scene = preload("res://Scenes/laser.tscn")
var shoot_cd := false

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
	
	var margin = Vector2(26,26)
	global_position = global_position.clamp(margin,get_viewport_rect().size - margin)

func shoot():
	laser_shot.emit(lascer_scene, aim.global_position)
	
func die():
	queue_free()
