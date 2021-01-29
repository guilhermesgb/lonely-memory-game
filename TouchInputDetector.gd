extends Node2D

signal tapped
signal long_pressed
signal dragging(position)
signal dragged

export(bool) var DRAG_ENABLED = true

onready var longPressTimer = $LongPressTimer

enum TouchType {NONE, SIMPLE_TAP, LONG_PRESS, DRAG}

var startedPressingButton = false
var isStillPressingButton = false

var touchType = TouchType.NONE
var currentPosition = Vector2()
var deltaPosition = Vector2()

func setup(owner):
	currentPosition = owner.get_position()

func _on_TouchInputArea_pressed():
	startedPressingButton = true

func _input(event):
	if not startedPressingButton:
		return

	elif event is InputEventScreenDrag and DRAG_ENABLED:
		touchType = TouchType.DRAG
		var updatedPosition = Vector2(
			event.get_position().x - deltaPosition.x,
			event.get_position().y - deltaPosition.y
		)
		currentPosition = updatedPosition
		emit_signal("dragging", updatedPosition)
		return

	elif not event is InputEventScreenTouch:
		return

	if event.is_pressed():
		touchType = TouchType.SIMPLE_TAP
		deltaPosition = Vector2(
			event.get_position().x - currentPosition.x,
			event.get_position().y - currentPosition.y
		)
		longPressTimer.start()

func _process(_delta):
	isStillPressingButton = Input.is_mouse_button_pressed(BUTTON_LEFT)

func _on_LongPressTimer_timeout():
	if startedPressingButton and isStillPressingButton:
		touchType = TouchType.LONG_PRESS

func _on_TouchInputArea_released():
	startedPressingButton = false
	longPressTimer.stop()

	if touchType == TouchType.DRAG:
		emit_signal("dragged")

	elif touchType == TouchType.SIMPLE_TAP:
		emit_signal("tapped")

	elif touchType == TouchType.LONG_PRESS:
		emit_signal("long_pressed")
