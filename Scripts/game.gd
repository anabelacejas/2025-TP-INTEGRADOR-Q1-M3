extends Node2D

@export var enemy_scenes: Array[PackedScene] = []

@onready var player_spawn_pos: Marker2D = $PlayerSpawnPos
@onready var player: CharacterBody2D = $Player
@onready var laser_container: Node2D = $LaserContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var timer: Timer = $EnemySpawnTimer
@onready var hud: Control = $UILayer/HUD
@onready var game_over: Control = $UILayer/GameOver

var high_score = 0
var score := 0:
	set(value):
		score = value
		hud.score = value

func _ready():
	var save_file = FileAccess.open("res://Saves/save.data",FileAccess.READ)
	if save_file != null:
		high_score = save_file.get_32()
	else:
		high_score = 0
		save_game()
	score = 0
	assert(player!=null)
	player.global_position = player_spawn_pos.global_position
	player.laser_shot.connect(_on_player_laser_shot)
	player.killed.connect(_on_player_killed)
	
func save_game():
	var save_file = FileAccess.open("res://Saves/save.data",FileAccess.WRITE)
	save_file.store_32(high_score)

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
	
func _on_player_killed():
	game_over.set_score(score)
	game_over.set_high_score(high_score)
	if(score > high_score):
		high_score = score
		game_over.set_high_score(score)
	save_game()
	await get_tree().create_timer(1.5).timeout
	game_over.visible = true
	
