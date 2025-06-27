extends Area2D

@export var speed = 150

func _physics_process(delta):
	global_position.y += speed * delta

func die():
	queue_free()
