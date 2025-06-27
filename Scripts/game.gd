extends Node2D

@onready var player_spawn_pos: Marker2D = $PlayerSpawnPos
@onready var player: CharacterBody2D = $Player
@onready var laser_container: Node2D = $LaserContainer

func _ready():
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
