extends Node2D

@export var enemy_scenes: Array[PackedScene] = []

@onready var player_spawn_pos: Marker2D = $PlayerSpawnPos
@onready var player: CharacterBody2D = $Player
@onready var laser_container: Node2D = $LaserContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var timer: Timer = $EnemySpawnTimer
@onready var hud: Control = $UILayer/HUD

var score := 0:
	set(value):
		score = value
		hud.score = value

func _ready():
	score = 0
	assert(player!=null)
	player.global_position = player_spawn_pos.global_position
	player.laser_shot.connect(_on_player_laser_shot)

func _process(_delta):
	if Input.is_action_just_pressed("Quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("Reset"):
		get_tree().reload_current_scene()

func _on_player_laser_shot(lascer_scene, location):
	var laser = lascer_scene.instantiate()
	laser.global_position = location
	laser_container.add_child(laser)


func _on_enemy_spawn_timer_timeout():
	var enemy = enemy_scenes.pick_random().instantiate()
	enemy.global_position = Vector2(randf_range(50,500),-50)
	enemy.killed.connect(_on_enemy_killed)
	enemy_container.add_child(enemy)
	

func _on_enemy_killed(points):
	score += points
	print(score)
