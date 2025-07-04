class_name Player extends CharacterBody2D

@export var speed = 300
@export var firing_rate = 0.25
@export var heavy_laser_duration = 5.0

@onready var aim = $Aim
@onready var anim_sprite = $AnimatedSprite2D
@onready var invuln_timer = $InvulnerabilityTimer

var colour = "black"

signal laser_shot(lascer_scene, location)
signal killed
signal damaged

var default_laser_scene = preload("res://Scenes/laser.tscn")
var heavy_laser_scene = preload("res://Scenes/heavy_laser.tscn")
var lascer_scene
var shoot_cd := false

var heavy_laser_timer: Timer
var has_heavy_laser = false

var max_lives = 3
var current_lives := 0:
	set(value):
		current_lives = value
var is_invulnerable := false

func _ready():
	colour = GameData.player_colour  
	lascer_scene = default_laser_scene
	current_lives = max_lives
	
	heavy_laser_timer = Timer.new()
	heavy_laser_timer.wait_time = heavy_laser_duration
	heavy_laser_timer.one_shot = true
	heavy_laser_timer.timeout.connect(_on_heavy_laser_timeout)
	add_child(heavy_laser_timer)

func _process(delta):
	if Input.is_action_pressed("shoot"):
		if(!shoot_cd):
			shoot_cd = true
			if(heavy_laser_timer.time_left > 0):
				shoot("heavy")
			else:
				shoot("normal")
			await get_tree().create_timer(firing_rate).timeout
			shoot_cd = false

func _physics_process(_delta):
	var direction = Vector2(Input.get_axis("move_left","move_right"),Input.get_axis("move_up","move_down"))
	velocity = direction * speed
	move_and_slide()
	
	if direction.x > 0:
		anim_sprite.play(colour + "_right")
	elif direction.x < 0:
		anim_sprite.play(colour + "_left")
	else:
		anim_sprite.play(colour + "_default")
	
	var margin = Vector2(26,26)
	global_position = global_position.clamp(margin,get_viewport_rect().size - margin)

func shoot(type):
	laser_shot.emit(lascer_scene, aim.global_position,type)

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

func take_damage():
	if is_invulnerable:
		return
	current_lives -= 1
	if(current_lives == 0):
		die()
		killed.emit()
	else:
		damaged.emit()
		_start_invulnerability()

func set_colour(c):
	colour = c

func _start_invulnerability():
	is_invulnerable = true
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate:a", 0.3, 0.2)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	set_meta("invuln_tween", tween)
	invuln_timer.start()

func _stop_invulnerability():
	if has_meta("invuln_tween"):
		var tween = get_meta("invuln_tween")
		if tween:
			tween.kill()
		remove_meta("invuln_tween")
	modulate.a = 1.0

func get_current_lives() -> int:
	return current_lives

func get_max_lives() -> int:
	return max_lives

func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false
	_stop_invulnerability()
