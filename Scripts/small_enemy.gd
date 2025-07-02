extends Enemy

@export var movement_pattern: String = "straight"  # "straight", "zigzag", "sine"
@export var zigzag_amplitude: float = 50.0
@export var sine_frequency: float = 2.0
@export var sine_amplitude: float = 30.0

var initial_x_position: float
var time_alive: float = 0.0

func _ready():
	# Set default values for small enemy
	if hp == 1 and points == 100:  # If still default values
		hp = 1  # Small enemies die in one hit
		points = 50  # Less points than regular enemies
		speed = 180  # Slightly faster than regular enemies
	
	# Store initial position for movement patterns
	initial_x_position = global_position.x

func _physics_process(delta):
	time_alive += delta
	
	# Apply movement pattern
	match movement_pattern:
		"straight":
			# Just use parent movement (straight down)
			super._physics_process(delta)
		"zigzag":
			_apply_zigzag_movement(delta)
		"sine":
			_apply_sine_movement(delta)
		_:
			# Default to straight movement
			super._physics_process(delta)

func _apply_zigzag_movement(delta):
	# Move down normally
	global_position.y += speed * delta
	
	# Add zigzag horizontal movement
	var zigzag_offset = sin(time_alive * 3.0) * zigzag_amplitude
	global_position.x = initial_x_position + zigzag_offset

func _apply_sine_movement(delta):
	# Move down normally
	global_position.y += speed * delta
	
	# Add sine wave horizontal movement
	var sine_offset = sin(time_alive * sine_frequency) * sine_amplitude
	global_position.x = initial_x_position + sine_offset

# Override die function to add special effects if needed
func die():
	# Could add special small explosion effect here
	super.die()
