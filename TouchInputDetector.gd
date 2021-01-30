extends Node2D

signal tapped
signal long_pressed
signal dragging(position)
signal dragged

export(bool) var DRAG_ENABLED = true

onready var longPressTimer = $LongPressTimer

enum TouchType {NONE, SIMPLE_TAP, LONG_PRESS, DRAG}

var startedTouchPress = false
var isStillTouchPressing = false
var isPerformingDragging = false

var touchType = TouchType.NONE
var currentPosition = Vector2()
var deltaPosition = Vector2()

var isEnabled = false
var user

func setup(user):
	self.user = user

func disable():
	isEnabled = false

func enable():
	isEnabled = true

func is_detecting_touch():
	return isEnabled and (startedTouchPress or isStillTouchPressing or isPerformingDragging)

func _on_TouchInputArea_pressed():
	if not isEnabled:
		return

	currentPosition = user.get_position()
	startedTouchPress = true

func _input(event):
	if not startedTouchPress:
		return

	elif event is InputEventScreenDrag and DRAG_ENABLED:
		isPerformingDragging = true
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
	if not isEnabled:
		return

	isStillTouchPressing = startedTouchPress and Input.is_mouse_button_pressed(BUTTON_LEFT)

func _on_LongPressTimer_timeout():
	if startedTouchPress and isStillTouchPressing:
		touchType = TouchType.LONG_PRESS

func _on_TouchInputArea_released():
	if not isEnabled:
		return

	startedTouchPress = false
	isStillTouchPressing = false
	isPerformingDragging = false
	longPressTimer.stop()

	if touchType == TouchType.DRAG:
		emit_signal("dragged")

	elif touchType == TouchType.SIMPLE_TAP:
		emit_signal("tapped")

	elif touchType == TouchType.LONG_PRESS:
		emit_signal("long_pressed")
