extends Node2D

onready var rng = RandomNumberGenerator.new()
onready var touchInputDetector = $Sprite/TouchInputDetector
onready var slots = get_tree().get_nodes_in_group("slots")

var targetSlot
var isLockedToSlot

func _ready():
	rng.randomize()
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
			set_z_index(get_z_index() + 1)

func is_close_enough_to_target_slot():
	var difference = position - targetSlot.global_position
	return abs(difference.x) < 15 and abs(difference.y) < 15

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

	set_position(lerp(global_position, targetSlot.global_position, rng.randf_range(0.8, 8) * delta))
	set_rotation(lerp_angle(rotation, 0, rng.randf_range(0.8, 8) * delta))

	if is_close_enough_to_target_slot():
		set_z_index(lerp(z_index, 0, rng.randf_range(0.8, 8) * delta))
		lock_to_unoccupied_slot()

func _on_TouchInputDetector_dragging(position):
	set_position(position)
	look_at(position)
	set_z_index(1)

func _on_TouchInputDetector_dragged():
	if isLockedToSlot:
		targetSlot.deoccupy()
	find_nearest_unoccupied_slot()
	print("DRAG")

func _on_TouchInputDetector_tapped():
	print("SINGLE_TAP")

func _on_TouchInputDetector_long_pressed():
	print("LONG_PRESS")
