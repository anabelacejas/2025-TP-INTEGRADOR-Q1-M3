extends Enemy

@export var movement_pattern: String = "straight"
@export var zigzag_amplitude: float = 50.0
@export var sine_frequency: float = 2.0
@export var sine_amplitude: float = 30.0

var initial_x_position: float
var time_alive: float = 0.0

func _ready():
	if hp == 1 and points == 100:
		hp = 1
		points = 50
		speed = 180
	
	initial_x_position = global_position.x

func _physics_process(delta):
	time_alive += delta
	
	match movement_pattern:
		"straight":
			super._physics_process(delta)
		"zigzag":
			_apply_zigzag_movement(delta)
		"sine":
			_apply_sine_movement(delta)
		_:
			super._physics_process(delta)

func _apply_zigzag_movement(delta):
	global_position.y += speed * delta
	
	var zigzag_offset = sin(time_alive * 3.0) * zigzag_amplitude
	global_position.x = initial_x_position + zigzag_offset

func _apply_sine_movement(delta):
	global_position.y += speed * delta
	
	var sine_offset = sin(time_alive * sine_frequency) * sine_amplitude
	global_position.x = initial_x_position + sine_offset

func die():
	super.die()
