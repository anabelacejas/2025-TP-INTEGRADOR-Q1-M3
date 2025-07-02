class_name Enemy extends Area2D

@export var speed = 150
@export var hp = 1
@export var points = 100

signal killed
signal hit

func _physics_process(delta):
	global_position.y += speed * delta

func die():
	queue_free()

func take_damage(amount):
	hp -= amount
	if(hp <= 0):
		die()
		killed.emit(points)
	else:
		hit.emit()

func _on_body_entered(body: Node2D):
	if body is Player:
		body.take_damage()
		die()

func _on_visible_on_screen_notifier_2d_screen_exited():
	die()
