extends Node2D

@export var game_scene: PackedScene

@onready var high_score
@onready var menu_player := $Player

var color_cycle := ["blue", "red", "black"]
var current_index := 0


func _ready():
	var save_file = FileAccess.open("res://Saves/save.data",FileAccess.READ)
	if save_file != null:
		high_score = save_file.get_32()
	else:
		high_score = 0
	set_high_score(high_score)
	
	# Reinforce plaay button for lost cases
	$PlayButton.pressed.connect(_on_play_button_pressed, CONNECT_DEFERRED)
	$PlayButton.disabled = false

func _on_play_button_pressed():
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		push_error("No se asignó la escena del juego")

func _on_exit_button_pressed():
	get_tree().quit()

func set_high_score(value):
	$HighScore.text = "Highest Score:\n" + str(value)
	
func _process(delta):
	if Input.is_action_just_pressed("Quit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("Reset"):
		get_tree().reload_current_scene()

func update_colour():
	var color_name = color_cycle[current_index]
	GameData.player_colour = color_name
	menu_player.set_colour(color_name)


func _on_player_colour_button_pressed():
	current_index = (current_index + 1) % color_cycle.size()
	update_colour()
