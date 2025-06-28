extends Enemy

# Export variables for the spawned enemies
@export var small_enemy_scene: PackedScene
@export var spawn_count: int = 3
@export var spawn_spread: float = 100.0  # How far apart the small enemies spawn
@export var spawn_speed_multiplier: float = 0.8  # Speed multiplier for spawned enemies

signal small_enemies_spawned(enemies_data)  # New signal to communicate with Game

func _ready():
	
	# Set default values for big enemy if not set in editor
	if hp == 1:  # Default enemy hp
		hp = 3  # Big enemies are tougher
	if points == 100:  # Default enemy points
		points = 200  # Big enemies give more points

func die():
	# Spawn small enemies before dying
	spawn_small_enemies()
	# Call parent die function
	super.die()

func spawn_small_enemies():
	if not small_enemy_scene:
		print("Warning: No small enemy scene assigned to BigEnemy")
		return
	
	var spawn_data = []
	
	for i in spawn_count:
		# Calculate spawn position with some spread
		var angle = (i * 2.0 * PI) / spawn_count  # Evenly distribute around circle
		var offset = Vector2(cos(angle), sin(angle)) * spawn_spread
		var spawn_pos = global_position + offset
		
		# Create data for the small enemy
		var enemy_data = {
			"scene": small_enemy_scene,
			"position": spawn_pos,
			"speed_multiplier": spawn_speed_multiplier
		}
		spawn_data.append(enemy_data)
	
	# Emit signal so Game can handle the spawning
	small_enemies_spawned.emit(spawn_data)
