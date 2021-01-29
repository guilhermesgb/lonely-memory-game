extends Node2D

onready var touchInputDetector = $Sprite/TouchInputDetector

func _ready():
	touchInputDetector.setup(self)

func _on_TouchInputDetector_dragging(position):
	set_position(position)

func _on_TouchInputDetector_dragged():
	print("DRAG")

func _on_TouchInputDetector_tapped():
	print("SINGLE_TAP")

func _on_TouchInputDetector_long_pressed():
	print("LONG_PRESS")
