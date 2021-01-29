extends Node2D

onready var touchInputDetector = $Sprite/TouchInputDetector
onready var slots = get_tree().get_nodes_in_group("slots")

var targetSlot
var isLockedToSlot

func _ready():
	touchInputDetector.setup(self)
	find_nearest_unoccupied_slot()

func find_nearest_unoccupied_slot():
	isLockedToSlot = false
	targetSlot = null
	var shortestDistance = 1000000000

	for slot in slots:
		if slot.is_occupied():
			continue

		var distance = global_position.distance_to(slot.global_position)

		if (distance < shortestDistance):
			targetSlot = slot
			shortestDistance = distance

func is_close_enough_to_target_slot():
	var difference = position - targetSlot.global_position
	return abs(difference.x) < 30 and abs(difference.y) < 30

func lock_to_unoccupied_slot():
	if not targetSlot.is_occupied():
		isLockedToSlot = true
		targetSlot.occupy()
		print("LOCK")

func _physics_process(delta):
	if touchInputDetector.is_detecting_touch():
		return
	elif not isLockedToSlot and (targetSlot == null or targetSlot.is_occupied()):
		find_nearest_unoccupied_slot()

	set_position(lerp(global_position, targetSlot.global_position, 15 * delta))

	if is_close_enough_to_target_slot():
		lock_to_unoccupied_slot()

func _on_TouchInputDetector_dragging(position):
	set_position(position)

func _on_TouchInputDetector_dragged():
	if isLockedToSlot:
		targetSlot.deoccupy()
	find_nearest_unoccupied_slot()
	print("DRAG")

func _on_TouchInputDetector_tapped():
	print("SINGLE_TAP")

func _on_TouchInputDetector_long_pressed():
	print("LONG_PRESS")
