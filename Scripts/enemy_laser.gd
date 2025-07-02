extends Area2D

@export var speed = 400

func _physics_process(delta):
	global_position.y += speed * delta  # Goes down (positive Y)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D):
	# Enemy lasers don't hit other enemies, only player
	pass

func _on_body_entered(body: Node2D):
	if body is Player:
		body.take_damage()
		queue_free()
