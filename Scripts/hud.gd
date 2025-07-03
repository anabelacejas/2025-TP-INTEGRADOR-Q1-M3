extends Control

@onready var score_label = $Score
@onready var phase_message = $PhaseMessage
@onready var phase_timer = $PhaseTimer
@onready var hearts_container = $Lives

@export var heart_full: Texture2D
@export var heart_empty: Texture2D

var score = 0:
	set(value):
		score = value
		score_label.text = str(value)
var lives = 3:
	set(value):
		lives = value

func show_phase_message(phase_number: int, message: String = ""):
	"""Display a phase transition message"""
	var phase_text = "PHASE %d" % (phase_number + 1)
	var display_message = ""
	
	if message.is_empty():
		display_message = phase_text + " ACTIVATED!"
	else:
		display_message = phase_text + "\n" + message
	
	phase_message.text = display_message
	phase_message.visible = true
	
	var tween = create_tween()
	phase_message.modulate.a = 0.0
	tween.tween_property(phase_message, "modulate:a", 1.0, 0.3)
	
	phase_timer.start(3.0)

func _on_phase_timer_timeout():
	"""Hide the phase message with fade-out effect"""
	var tween = create_tween()
	tween.tween_property(phase_message, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): phase_message.visible = false)

func update_hearts():
	for heart_id in hearts_container.get_child_count():
		var heart = hearts_container.get_child(heart_id)
		if heart_id < lives:
			heart.texture = heart_full
		else:
			heart.texture = heart_empty
