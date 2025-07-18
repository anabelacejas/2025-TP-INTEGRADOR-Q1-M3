extends Area2D

@export var speed = 150

func _physics_process(delta):
	global_position.y += speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D):
	pass

func _on_body_entered(body: Node2D):
	if body is Player:
		body.activate_heavy_laser()
		queue_free()
