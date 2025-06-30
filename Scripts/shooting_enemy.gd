extends Enemy

@export var firing_rate: float = 1.5
@export var shoot_range: float = 700

# Shooting components (only used if can_shoot = true)
@onready var aim = $Aim if has_node("Aim") else null
@onready var shoot_timer = $ShootTimer if has_node("ShootTimer") else null

signal laser_shot(laser_scene, location)  # NEW

var enemy_laser_scene = preload("res://Scenes/enemy_laser.tscn")
var can_shoot_now = true

func _ready():
	shoot_timer.wait_time = firing_rate
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()

func _physics_process(delta):
	super._physics_process(delta)
	# NEW - Shooting logic
	_try_shoot_at_player()

func _try_shoot_at_player():
	if not can_shoot_now or not aim:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance < shoot_range and player.global_position.y > global_position.y:
			shoot()

func shoot():
	if not can_shoot_now:
		return
	can_shoot_now = false
	laser_shot.emit(enemy_laser_scene, aim.global_position)
	if shoot_timer:
		shoot_timer.start()

func _on_shoot_timer_timeout():
	can_shoot_now = true
