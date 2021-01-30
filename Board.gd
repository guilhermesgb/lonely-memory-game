extends Node2D

onready var timer = $Timer

func _ready():
	timer.start()

func _on_Timer_timeout():
	print("restarting current scene")
	get_tree().reload_current_scene()

func _draw():
	draw_circle(Vector2.ZERO, 2000, Color("#c2efcd"))
