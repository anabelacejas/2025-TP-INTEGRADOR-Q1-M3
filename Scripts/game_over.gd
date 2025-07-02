extends Control

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func set_score(value):
	$Panel/Score.text = "Score: " + str(value)
	

func set_high_score(value):
	$Panel/HighScore.text = "H-Score: " + str(value)

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
