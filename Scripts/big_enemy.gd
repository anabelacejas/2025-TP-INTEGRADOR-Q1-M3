extends Enemy

@export var small_enemy_scene: PackedScene
@export var spawn_count: int = 3
@export var spawn_spread: float = 100.0
@export var spawn_speed_multiplier: float = 0.8 

signal small_enemies_spawned(enemies_data)

func _ready():
	
	if hp == 1:
		hp = 3
	if points == 100:
		points = 200 

func die():
	spawn_small_enemies()
	super.die()

func spawn_small_enemies():
	if not small_enemy_scene:
		print("Warning: No small enemy scene assigned to BigEnemy")
		return
	
	var spawn_data = []
	
	for i in spawn_count:
		var angle = (i * 2.0 * PI) / spawn_count
		var offset = Vector2(cos(angle), sin(angle)) * spawn_spread
		var spawn_pos = global_position + offset
		
		var enemy_data = {
			"scene": small_enemy_scene,
			"position": spawn_pos,
			"speed_multiplier": spawn_speed_multiplier
		}
		spawn_data.append(enemy_data)
	
	small_enemies_spawned.emit(spawn_data)
