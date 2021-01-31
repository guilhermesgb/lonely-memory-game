extends Node2D

const Global = preload("Global.gd")

enum CardState {
	SELECTABLE,
	SELECTED_FOR_REVEAL,
	SELECTED_FOR_WIN,
	BLOCKED_FOR_SELECTION,
	REVEALED_AS_PAIR
}

signal card_destroyed(name)
signal select_for_reveal_updated(card, selected)
signal select_for_win_updated(card, selected)

onready var noise = OpenSimplexNoise.new()

onready var sprite = $Sprite
onready var touchInputDetector = $Sprite/TouchInputDetector
onready var slots = get_tree().get_nodes_in_group("slots")
onready var cards = get_tree().get_nodes_in_group("cards")

var targetSlot
var isLockedToSlot

var assignedType = Global.CardType.NONE

var currentState = CardState.SELECTABLE

var rng

func setup(board, randomNumberGenerator):
	rng = randomNumberGenerator
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 20
	noise.persistence = 0.8

	board.connect("preparation_done", self, "_on_preparation_done")

	for card in cards:
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

func get_assigned_type():
	return assignedType

func set_assigned_type(typeToAssign):
	assignedType = typeToAssign

func set_as_selectable(propagateUpdate):
	do_set_state(CardState.SELECTABLE, propagateUpdate)

func is_selected_for_reveal():
	return currentState == CardState.SELECTED_FOR_REVEAL

func is_selected_for_win():
	return currentState == CardState.SELECTED_FOR_WIN

func set_selected_for_win(propagateUpdate):
	do_set_state(CardState.SELECTED_FOR_WIN, propagateUpdate)

func is_blocked_for_selection():
	return currentState == CardState.BLOCKED_FOR_SELECTION

func set_blocked_for_selection():
	set_state(CardState.BLOCKED_FOR_SELECTION)

func is_revealed_as_pair():
	return currentState == CardState.REVEALED_AS_PAIR

func set_revealed_as_pair():
	set_state(CardState.REVEALED_AS_PAIR)

func set_state(state):
	do_set_state(state, false)

func do_set_state(state, propagateUpdate):
	var previousState = currentState
	currentState = state

	if currentState == CardState.SELECTED_FOR_WIN and propagateUpdate:
		emit_signal("select_for_win_updated", self, true)

	elif currentState == CardState.SELECTED_FOR_REVEAL and propagateUpdate:
		emit_signal("select_for_reveal_updated", self, true)

	elif currentState == CardState.SELECTABLE and propagateUpdate:
		if previousState == CardState.SELECTED_FOR_WIN:
			emit_signal("select_for_win_updated", self, false)

		elif previousState == CardState.SELECTED_FOR_REVEAL:
			emit_signal("select_for_reveal_updated", self, false)

func render_selected_state():
	if currentState == CardState.REVEALED_AS_PAIR:
		sprite.modulate = Color("#B44E39")
		touchInputDetector.disable()

	elif currentState == CardState.BLOCKED_FOR_SELECTION:
		sprite.modulate = Color("#C7B074")
		touchInputDetector.disable()

	elif currentState == CardState.SELECTED_FOR_WIN:
		sprite.modulate = Color("#EE8A44")
		touchInputDetector.enable()
		touchInputDetector.DRAG_ENABLED = true

	elif currentState == CardState.SELECTED_FOR_REVEAL:
		sprite.modulate = Color("#FAD758")
		touchInputDetector.enable()
		touchInputDetector.DRAG_ENABLED = false

	else:
		sprite.modulate = Color.white
		touchInputDetector.enable()
		touchInputDetector.DRAG_ENABLED = false

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
	print("DRAG - " + name + "(" + String(assignedType) + ")")
	if isLockedToSlot:
		targetSlot.deoccupy()
		set_z_index(1)
	find_nearest_unoccupied_slot()

func _on_TouchInputDetector_tapped():
	print("TAP - " + name + "(" + String(assignedType) + ")")
	if currentState == CardState.SELECTED_FOR_WIN or currentState == CardState.SELECTED_FOR_REVEAL:
		do_set_state(CardState.SELECTABLE, true)

	else:
		do_set_state(CardState.SELECTED_FOR_REVEAL, true)

func _on_TouchInputDetector_long_pressed():
	print("LONG_PRESS - " + name + "(" + String(assignedType) + ")")
	do_set_state(CardState.SELECTED_FOR_WIN, true)
