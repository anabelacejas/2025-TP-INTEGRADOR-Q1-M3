# This is game.gd
extends Node2D

@export var enemy_scenes: Array[PackedScene] = []

@onready var player_spawn_pos: Marker2D = $PlayerSpawnPos
@onready var player: CharacterBody2D = $Player
@onready var laser_container: Node2D = $LaserContainer
@onready var enemy_laser_container: Node2D = $EnemyLaserContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var timer: Timer = $EnemySpawnTimer
@onready var hud: Control = $UILayer/HUD
@onready var game_over: Control = $UILayer/GameOver
@onready var background: ParallaxBackground = $ParallaxBackground

# SOUNDS
@onready var laser_sound = $SFX/LaserSound
@onready var enemy_laser_sound = $SFX/EnemyLaserSound
@onready var hit_sound = $SFX/HitSound
@onready var explosion_sound = $SFX/ExplodeSound
@onready var lose_sound = $SFX/LoseSound

# THREADING SYSTEM
var save_thread := Thread.new()
var spawn_calculator_thread := Thread.new()
var difficulty_thread := Thread.new()
var background_thread := Thread.new()

# THREAD MUTEXES
var spawn_mutex := Mutex.new()
var difficulty_mutex := Mutex.new()
var background_mutex := Mutex.new()

# THREAD-SAFE DATA
var thread_running = true
var spawn_data = {
	"spawn_rate": 1.7,
	"enemy_weights": [1.0, 0.0, 0.0, 0.0, 0.0],  # Probability weights for each enemy type
	"current_difficulty": 0
}
var difficulty_data = {
	"time_elapsed": 0.0,
	"current_phase": 0,
	"scroll_speed": 100
}

# GAME STATE
var high_score = 0
var score := 0:
	set(value):
		score = value
		hud.score = value
var game_start_time: float
var scroll_speed = 100

# DIFFICULTY CONFIGURATION
var difficulty_phases = [
	{
		"time_threshold": 0,
		"enemy_weights": [1.0, 0.0, 0.0, 0.0, 0.0],
		"spawn_rate": 1.7,
		"scroll_speed": 100,
		"message": "\nSPACE MISSION\nBEGINS!"
	},
	{
		"time_threshold": 15,
		"enemy_weights": [0.5, 0.5, 0.0, 0.0, 0.0],
		"spawn_rate": 1.4,
		"scroll_speed": 120,
		"message": "\nSPEED UNITS\nINBOUND!"
	},
	{
		"time_threshold": 30,
		"enemy_weights": [0.3, 0.3, 0.4, 0.0, 0.0],
		"spawn_rate": 1.2,
		"scroll_speed": 140,
		"message": "\nARMED ENEMIES\nENGAGING!"
	},
	{
		"time_threshold": 50,
		"enemy_weights": [0.1, 0.2, 0.3, 0.4, 0.0],
		"spawn_rate": 1.0,
		"scroll_speed": 160,
		"message": "\nSWARMS OF\nDODGERS\nAPPROACHING!"
	},
	{
		"time_threshold": 60,
		"enemy_weights": [0.1, 0.1, 0.2, 0.2, 0.4],
		"spawn_rate": 0.8,
		"scroll_speed": 180,
		"message": "\nTITAN CLASS\nDETECTED!"
	},
	{
		"time_threshold": 80,
		"enemy_weights": [0.1, 0.2, 0.2, 0.2, 0.3],
		"spawn_rate": 0.6,
		"scroll_speed": 200,
		"message": "\nMAXIMUM THREAT\nLEVEL!"
	}
]

func _ready():
	var save_file = FileAccess.open("res://Saves/save.data",FileAccess.READ)
	if save_file != null:
		high_score = save_file.get_32()
	else:
		high_score = 0
		save_thread.start(_save_game_thread.bind(high_score))
	
	score = 0
	game_start_time = Time.get_ticks_msec() / 1000.0
	assert(player!=null)
	
	# Add player to group so enemies can find it
	player.add_to_group("player")
	player.global_position = player_spawn_pos.global_position
	player.laser_shot.connect(_on_player_laser_shot)
	player.killed.connect(_on_player_killed)
	
	# Start background threads
	_start_background_threads()
	
	# Show initial phase message after a short delay
	await get_tree().create_timer(0.5).timeout
	_show_phase_transition(0, difficulty_phases[0].get("message", ""))

func _start_background_threads():
	"""Start all background computation threads"""
	thread_running = true
	
	# Spawn calculation thread - calculates optimal spawn timing
	spawn_calculator_thread.start(_spawn_calculator_thread)
	
	# Difficulty progression thread - manages game difficulty over time
	difficulty_thread.start(_difficulty_progression_thread)
	
	# Background processing thread - handles scroll and other background tasks
	background_thread.start(_background_processing_thread)

func _spawn_calculator_thread():
	"""Background thread for calculating spawn parameters"""
	while thread_running:
		spawn_mutex.lock()
		
		# Calculate dynamic spawn rate based on score and time
		var time_factor = min(difficulty_data.time_elapsed / 300.0, 1.0)  # Cap at 5 minutes
		var score_factor = min(score / 10000.0, 1.0)  # Cap at 10k score
		var combined_factor = (time_factor + score_factor) / 2.0
		
		# Update spawn rate (faster spawning as difficulty increases)
		spawn_data.spawn_rate = lerp(1.7, 0.6, combined_factor)
		
		# Update enemy type probabilities based on current difficulty phase
		if difficulty_data.current_phase < difficulty_phases.size():
			var phase = difficulty_phases[difficulty_data.current_phase]
			spawn_data.enemy_weights = phase.enemy_weights.duplicate()
		
		spawn_mutex.unlock()
		
		# Update every 100ms for responsive difficulty scaling
		OS.delay_msec(100)

func _difficulty_progression_thread():
	"""Background thread for managing difficulty progression"""
	while thread_running:
		difficulty_mutex.lock()
		
		# Update elapsed time
		difficulty_data.time_elapsed = (Time.get_ticks_msec() / 1000.0) - game_start_time
		
		# Check for phase transitions
		var new_phase = 0
		for i in range(difficulty_phases.size() - 1, -1, -1):
			if difficulty_data.time_elapsed >= difficulty_phases[i].time_threshold:
				new_phase = i
				break
		
		# Update phase if changed
		if new_phase != difficulty_data.current_phase:
			var old_phase = difficulty_data.current_phase
			difficulty_data.current_phase = new_phase
			var phase = difficulty_phases[new_phase]
			difficulty_data.scroll_speed = phase.scroll_speed
			
			# Show phase message on main thread
			call_deferred("_show_phase_transition", new_phase, phase.get("message", ""))
			
			print("Difficulty Phase ", new_phase, " activated! Time: ", difficulty_data.time_elapsed, "s")
		
		difficulty_mutex.unlock()
		
		# Update every 500ms for phase checking
		OS.delay_msec(500)

func _show_phase_transition(phase_number: int, message: String):
	"""Called on main thread to show phase transition message"""
	hud.show_phase_message(phase_number, message)

func _background_processing_thread():
	"""Background thread for scroll speed and other background calculations"""
	while thread_running:
		background_mutex.lock()
		
		# Calculate dynamic scroll speed adjustments
		# Could add screen shake calculations, particle effects, etc.
		var target_scroll_speed = float(difficulty_data.scroll_speed)
		
		# Smooth scroll speed transitions
		scroll_speed = lerp(float(scroll_speed), target_scroll_speed, 0.02)
		
		background_mutex.unlock()
		
		# Update every 50ms for smooth transitions
		OS.delay_msec(50)

func _save_game_thread(score_to_save):
	var file := FileAccess.open("user://save.data", FileAccess.WRITE)
	if file:
		file.store_32(score_to_save)
		file.close()
	print("Score guardado en hilo secundario")

func _process(delta):
	if Input.is_action_just_pressed("Quit"):
		_cleanup_threads()
		get_tree().quit()
	elif Input.is_action_just_pressed("Reset"):
		_cleanup_threads()
		get_tree().reload_current_scene()
	
	# Update timer with calculated spawn rate
	spawn_mutex.lock()
	timer.wait_time = spawn_data.spawn_rate
	spawn_mutex.unlock()
	
	# Update background scroll
	background_mutex.lock()
	var current_scroll_speed = scroll_speed
	background_mutex.unlock()
	
	background.scroll_offset.y += delta * current_scroll_speed
	if background.scroll_offset.y >= 960:
		background.scroll_offset.y = 0

func _cleanup_threads():
	"""Safely stop and cleanup all threads"""
	thread_running = false
	
	# Wait for threads to finish
	if spawn_calculator_thread.is_started():
		spawn_calculator_thread.wait_to_finish()
	if difficulty_thread.is_started():
		difficulty_thread.wait_to_finish()
	if background_thread.is_started():
		background_thread.wait_to_finish()
	if save_thread.is_started():
		save_thread.wait_to_finish()

func _select_enemy_type() -> int:
	"""Select enemy type based on weighted probabilities"""
	spawn_mutex.lock()
	var weights = spawn_data.enemy_weights.duplicate()
	spawn_mutex.unlock()
	
	var total_weight = 0.0
	for weight in weights:
		total_weight += weight
	
	if total_weight <= 0:
		return 0  # Default to first enemy type
	
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	for i in range(weights.size()):
		cumulative_weight += weights[i]
		if random_value <= cumulative_weight:
			return i
	
	return weights.size() - 1  # Fallback to last enemy type

func _on_player_laser_shot(lascer_scene, location):
	var laser = lascer_scene.instantiate()
	laser.global_position = location
	laser_container.add_child(laser)
	laser_sound.play()

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
	# Select enemy type based on current difficulty
	var enemy_type_index = _select_enemy_type()
	
	# Ensure we don't go out of bounds
	if enemy_type_index >= enemy_scenes.size():
		enemy_type_index = enemy_scenes.size() - 1
	
	var enemy = enemy_scenes[enemy_type_index].instantiate()
	enemy.global_position = Vector2(randf_range(50, 500), -50)
	enemy.killed.connect(_on_enemy_killed)
	enemy.hit.connect(_on_enemy_hit)
	
	# Connect signals if available
	if enemy.has_signal("laser_shot"):
		enemy.laser_shot.connect(_on_enemy_laser_shot)
	if enemy.has_signal("small_enemies_spawned"):
		enemy.small_enemies_spawned.connect(_on_small_enemies_spawned)
	
	enemy_container.add_child(enemy)
	
	# Debug info (remove in production)
	difficulty_mutex.lock()
	var phase = difficulty_data.current_phase
	var time_elapsed = difficulty_data.time_elapsed
	difficulty_mutex.unlock()
	
	print("Spawned enemy type ", enemy_type_index, " | Phase: ", phase, " | Time: ", int(time_elapsed), "s")

func _on_enemy_killed(points):
	explosion_sound.play()
	score += points

func _on_enemy_hit():
	hit_sound.play()

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
	
	# Save in background thread
	if save_thread.is_started():
		save_thread.wait_to_finish()
	save_thread.start(_save_game_thread.bind(high_score))
	
	await get_tree().create_timer(0.5).timeout
	lose_sound.play()
	await get_tree().create_timer(1).timeout
	game_over.visible = true

func _exit_tree():
	"""Cleanup when exiting"""
	_cleanup_threads()
