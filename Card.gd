extends Node2D

const Global = preload("Global.gd")

signal card_destroyed(name)
signal select_for_reveal_updated(name)
signal select_for_win_updated(name)

onready var noise = OpenSimplexNoise.new()

onready var sprite = $Sprite
onready var touchInputDetector = $Sprite/TouchInputDetector
onready var slots = get_tree().get_nodes_in_group("slots")
onready var cards = get_tree().get_nodes_in_group("cards")

var targetSlot
var isLockedToSlot
var isSelectedForReveal
var isSelectedForWin
var assignedType = Global.CardType.NONE

var rng

func setup(board, randomNumberGenerator):
	rng = randomNumberGenerator
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 20
	noise.persistence = 0.8

	board.connect("preparation_done", self, "_on_preparation_done")

	for card in cards:
		card.connect("select_for_reveal_updated", self, "_on_select_for_reveal_updated")
		card.connect("select_for_win_updated", self, "_on_select_for_win_updated")
		card.connect("card_destroyed", self, "_on_card_destroyed")

	touchInputDetector.setup(self)
	touchInputDetector.disable()

func destroy():
	emit_signal("card_destroyed", self.name)
	queue_free()

func _on_preparation_done():
	touchInputDetector.enable()
	touchInputDetector.DRAG_ENABLED = false

func has_assigned_type():
	return assignedType != Global.CardType.NONE

func set_assigned_type(typeToAssign):
	assignedType = typeToAssign

func is_selected_for_reveal():
	return isSelectedForReveal

func set_selected_for_reveal(selected):
	isSelectedForReveal = selected

	if isSelectedForReveal:
		emit_signal("select_for_reveal_updated", self.name)

func is_selected_for_win():
	return isSelectedForWin

func set_selected_for_win(selected):
	isSelectedForWin = selected

	if isSelectedForWin:
		emit_signal("select_for_win_updated", self.name)

func _on_select_for_reveal_updated(_name):
	set_selected_for_win(false)

func _on_select_for_win_updated(_name):
	if name == self.name:
		return

	set_selected_for_reveal(false)
	set_selected_for_win(false)

func render_selected_state():
	if isSelectedForWin:
		sprite.modulate = Color("#B44E39")

	elif isSelectedForReveal:
		sprite.modulate = Color("#C7B074")

	else:
		sprite.modulate = Color.white

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
			var variation = noise.get_noise_1d(rng.randf_range(-1.0, 1.0))
			set_rotation(variation * 0.523599)
			set_z_index(get_z_index() + 1)

	if targetSlot == null:
		destroy()

func is_close_enough_to_target_slot():
	var difference = position - targetSlot.global_position
	return abs(difference.x) < 15 and abs(difference.y) < 15

func lock_to_unoccupied_slot():
	if not targetSlot.is_occupied():
		isLockedToSlot = true
		targetSlot.occupy()
		set_z_index(0)
		print("LOCK")

func _on_card_destroyed(_name):
	cards = get_tree().get_nodes_in_group("cards")

func _physics_process(delta):
	if is_queued_for_deletion():
		return

	render_selected_state()

	if touchInputDetector.is_detecting_touch():
		return
	elif not isLockedToSlot and (targetSlot == null or targetSlot.is_occupied()):
		find_nearest_unoccupied_slot()

	if targetSlot == null:
		return

	set_position(lerp(global_position, targetSlot.global_position, rng.randf_range(0.8, 16) * delta))
	set_rotation(lerp_angle(rotation, 0, rng.randf_range(0.8, 8) * delta))

	if is_close_enough_to_target_slot():
		lock_to_unoccupied_slot()

func _on_TouchInputDetector_dragging(position):
	sprite.modulate = Color("#ccffffff")
	set_position(position)
	var variation = noise.get_noise_1d(rng.randf_range(-1.0, 1.0))
	set_rotation(lerp_angle(rotation, variation * 0.261799, rng.randf_range(0, 1)))
	set_z_index(2)

func _on_TouchInputDetector_dragged():
	if isLockedToSlot:
		targetSlot.deoccupy()
		set_z_index(1)
	find_nearest_unoccupied_slot()
	print("DRAG - " + String(assignedType))

func _on_TouchInputDetector_tapped():
	set_selected_for_reveal(!isSelectedForReveal)
	print("TAP - " + String(assignedType))

func _on_TouchInputDetector_long_pressed():
	set_selected_for_win(!isSelectedForWin)
	print("LONG_PRESS - " + String(assignedType))
