extends Node2D

@export var enemy_scenes: Array[PackedScene] = []

@onready var player_spawn_pos: Marker2D = $PlayerSpawnPos
@onready var player: CharacterBody2D = $Player
@onready var laser_container: Node2D = $LaserContainer
@onready var enemy_laser_container: Node2D = $EnemyLaserContainer  # NEW - Add this node to your scene
@onready var enemy_container: Node2D = $EnemyContainer
@onready var timer: Timer = $EnemySpawnTimer
@onready var hud: Control = $UILayer/HUD
@onready var game_over: Control = $UILayer/GameOver
@onready var background: ParallaxBackground = $ParallaxBackground

# SOUNDS
@onready var laser_sound = $SFX/LaserSound
@onready var enemy_laser_sound = $SFX/EnemyLaserSound  # NEW - Optional, add if you want different sound
@onready var hit_sound = $SFX/HitSound
@onready var explosion_sound = $SFX/ExplodeSound
@onready var lose_sound = $SFX/LoseSound

var save_thread := Thread.new()

var high_score = 0
var score := 0:
	set(value):
		score = value
		hud.score = value
var scroll_speed = 100

func _ready():
	var save_file = FileAccess.open("res://Saves/save.data",FileAccess.READ)
	if save_file != null:
		high_score = save_file.get_32()
	else:
		high_score = 0
		save_thread.start(_save_game_thread.bind(high_score))
	score = 0
	assert(player!=null)
	
	# Add player to group so enemies can find it
	player.add_to_group("player")  # NEW
	
	player.global_position = player_spawn_pos.global_position
	player.laser_shot.connect(_on_player_laser_shot)
	player.killed.connect(_on_player_killed)

func _save_game_thread(score_to_save):
	var file := FileAccess.open("user://save.data", FileAccess.WRITE)
	if file:
		file.store_32(score_to_save)
		file.close()
	print("Score guardado en hilo secundario")

func _process(delta):
	if Input.is_action_just_pressed("Quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("Reset"):
		get_tree().reload_current_scene()
	# Timer for Spawn Rate
	if(timer.wait_time>0.5):
		timer.wait_time -= delta*0.005
	elif timer.wait_time < 0.5:
		timer.wait_time = 0.5
	# Background Movement
	background.scroll_offset.y += delta*scroll_speed
	if background.scroll_offset.y >= 960:
		background.scroll_offset.y = 0

func _on_player_laser_shot(lascer_scene, location):
	var laser = lascer_scene.instantiate()
	laser.global_position = location
	laser_container.add_child(laser)
	laser_sound.play()

# NEW FUNCTION - Handle enemy laser shots
func _on_enemy_laser_shot(laser_scene, location):
	var laser = laser_scene.instantiate()
	laser.global_position = location
	enemy_laser_container.add_child(laser)
	# Play enemy laser sound (or reuse laser_sound if you don't have a separate one)
	if enemy_laser_sound:
		enemy_laser_sound.play()
	else:
		laser_sound.play()

func _on_enemy_spawn_timer_timeout():
	var enemy = enemy_scenes.pick_random().instantiate()
	enemy.global_position = Vector2(randf_range(50,500),-50)
	enemy.killed.connect(_on_enemy_killed)
	enemy.hit.connect(_on_enemy_hit)
	
	# NEW - Connect laser_shot signal for shooting enemies
	if enemy.has_signal("laser_shot"):
		enemy.laser_shot.connect(_on_enemy_laser_shot)
	
	# NEW - Connect small_enemies_spawned signal for big enemies
	if enemy.has_signal("small_enemies_spawned"):
		enemy.small_enemies_spawned.connect(_on_small_enemies_spawned)
	
	enemy_container.add_child(enemy)

func _on_enemy_killed(points):
	explosion_sound.play()
	score += points
	
func _on_enemy_hit():
	hit_sound.play()

# NEW - Handle spawning of small enemies from big enemies
func _on_small_enemies_spawned(enemies_data):
	for enemy_data in enemies_data:
		var small_enemy = enemy_data.scene.instantiate()
		small_enemy.global_position = enemy_data.position
		
		# Apply speed multiplier if specified
		if "speed_multiplier" in enemy_data:
			small_enemy.speed *= enemy_data.speed_multiplier
		
		# Connect signals
		small_enemy.killed.connect(_on_enemy_killed)
		small_enemy.hit.connect(_on_enemy_hit)
		
		if small_enemy.has_signal("laser_shot"):
			small_enemy.laser_shot.connect(_on_enemy_laser_shot)
		
		# Add to enemy container
		enemy_container.add_child(small_enemy)
		
		# Add slight delay between spawns for visual effect
		await get_tree().create_timer(0.1).timeout

func _on_player_killed():
	explosion_sound.play()
	game_over.set_score(score)
	game_over.set_high_score(high_score)
	if(score > high_score):
		high_score = score
		game_over.set_high_score(score)
	save_thread.start(_save_game_thread.bind(high_score))
	await get_tree().create_timer(0.5).timeout
	lose_sound.play()
	await get_tree().create_timer(1).timeout
	game_over.visible = true
