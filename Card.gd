extends Node2D

const Global = preload("Global.gd")

enum CardState {
	SELECTABLE,
	SELECTED_FOR_REVEAL,
	SELECTED_FOR_WIN,
	BLOCKED_FOR_SELECTION,
	BLOCKED_SELECTED_FOR_WIN,
	REVEALED_AS_PAIR,
	LOCKED_FOR_WIN,
	WINNER_FOUND
}

signal card_destroyed(name)
signal select_for_reveal_updated(card, selected)
signal select_for_win_updated(card, selected)
signal tapped_while_blocked(card)

onready var noise = OpenSimplexNoise.new()

onready var sprite = $Sprite
onready var touchInputDetector = $Sprite/TouchInputDetector
onready var animationPlayer = $AnimationPlayer
onready var debugInfo = $DebugContainer/DebugInfo

var textureBack = preload("res://card_back.png")
var textureFront = preload("res://card_front.png")

var rng

var targetSlot
var isLockedToSlot = false
var canLockToWinSlot = false

var assignedType = Global.CardType.NONE

var currentState = CardState.SELECTABLE

var board

func setup(gameBoard, randomNumberGenerator):
	board = gameBoard
	rng = randomNumberGenerator
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 20
	noise.persistence = 0.8

	board.connect("preparation_done", self, "_on_preparation_done")

	touchInputDetector.setup(self)
	touchInputDetector.disable()

func destroy():
	emit_signal("card_destroyed", self.name)
	queue_free()

func _on_preparation_done():
	touchInputDetector.enable(false)
	canLockToWinSlot = true

func has_assigned_type():
	return assignedType != Global.CardType.NONE

func get_assigned_type():
	return assignedType

func set_assigned_type(typeToAssign):
	assignedType = typeToAssign

func set_as_selectable(propagateUpdate):
	do_set_state(CardState.SELECTABLE, propagateUpdate)

	sprite.set_texture(textureBack)

func is_selected_for_reveal():
	return currentState == CardState.SELECTED_FOR_REVEAL

func is_selected_for_win():
	return currentState == CardState.SELECTED_FOR_WIN or currentState == CardState.LOCKED_FOR_WIN or currentState == CardState.BLOCKED_SELECTED_FOR_WIN

func set_selected_for_win(propagateUpdate):
	do_set_state(CardState.SELECTED_FOR_WIN, propagateUpdate)

	sprite.set_texture(textureBack)

func set_locked_for_win(propagateUpdate):
	do_set_state(CardState.LOCKED_FOR_WIN, propagateUpdate)

	sprite.set_texture(textureBack)

func is_blocked_for_selection():
	return currentState == CardState.BLOCKED_FOR_SELECTION or currentState == CardState.BLOCKED_SELECTED_FOR_WIN

func set_blocked_for_selection(playAnimation):
	set_state(CardState.BLOCKED_FOR_SELECTION)

	if playAnimation:
		animationPlayer.play("RevealTemporarily")
	sprite.set_texture(textureBack)

func is_revealed_as_pair():
	return currentState == CardState.REVEALED_AS_PAIR

func set_revealed_as_pair():
	set_state(CardState.REVEALED_AS_PAIR)

	animationPlayer.play("RevealForever")
	sprite.set_texture(textureFront)

func set_winner_found():
	set_state(CardState.WINNER_FOUND)

	animationPlayer.play("RevealForever")
	sprite.set_texture(textureFront)

func set_state(state):
	do_set_state(state, false)

func do_set_state(state, propagateUpdate):
	var previousState = currentState
	currentState = state

	if currentState == CardState.SELECTED_FOR_WIN or currentState == CardState.BLOCKED_SELECTED_FOR_WIN or currentState == CardState.LOCKED_FOR_WIN and propagateUpdate:
		emit_signal("select_for_win_updated", self, true)

	elif currentState == CardState.SELECTED_FOR_REVEAL and propagateUpdate:
		emit_signal("select_for_reveal_updated", self, true)

	elif currentState == CardState.SELECTABLE and propagateUpdate:
		if previousState == CardState.SELECTED_FOR_WIN or previousState == CardState.BLOCKED_SELECTED_FOR_WIN or previousState == CardState.LOCKED_FOR_WIN:
			emit_signal("select_for_win_updated", self, false)

		elif previousState == CardState.SELECTED_FOR_REVEAL:
			emit_signal("select_for_reveal_updated", self, false)

func render_selected_state():
	if currentState == CardState.WINNER_FOUND:
		apply_tint(Color("#FAD758"))
		touchInputDetector.disable()
		debugInfo.text = String(assignedType)
		debugInfo.modulate = Color.white

	elif currentState == CardState.REVEALED_AS_PAIR:
		apply_tint(Color("#B44E39"))
		touchInputDetector.disable()
		debugInfo.text = String(assignedType)
		debugInfo.modulate = Color.white

	elif currentState == CardState.BLOCKED_FOR_SELECTION:
		apply_tint(Color("#C7B074"))
		touchInputDetector.enable(false)
		debugInfo.text = String(assignedType)
		debugInfo.modulate = Color.transparent

	elif currentState == CardState.SELECTED_FOR_WIN or currentState == CardState.BLOCKED_SELECTED_FOR_WIN or currentState == CardState.LOCKED_FOR_WIN:
		apply_tint(Color("#EE8A44"))
		touchInputDetector.enable(true)
		debugInfo.text = String(assignedType)
		debugInfo.modulate = Color.transparent

	elif currentState == CardState.SELECTED_FOR_REVEAL:
		apply_tint(Color("#FAD758"))
		touchInputDetector.enable(false)
		debugInfo.text = String(assignedType)
		debugInfo.modulate = Color.transparent

	else:
		apply_tint(Color.white)
		touchInputDetector.enable(false)
		debugInfo.text = String(assignedType)
		debugInfo.modulate = Color.transparent

func apply_tint(color):
	sprite.modulate = color

func find_nearest_unoccupied_slot():
	isLockedToSlot = false
	targetSlot = null
	var shortestDistance = 1000000000

	var slots = board.get_card_slots()
	if canLockToWinSlot:
		slots.append(board.get_win_slot())

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
		targetSlot.occupy(self)
		set_z_index(0)

		if not targetSlot.name == "WinSlot":
			animationPlayer.play("Dust")

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

	set_position(lerp(global_position, targetSlot.global_position, rng.randf_range(6, 8) * delta))
	set_rotation(lerp_angle(rotation, 0, rng.randf_range(0.8, 8) * delta))

	if is_close_enough_to_target_slot():
		lock_to_unoccupied_slot()

func _on_TouchInputDetector_dragging(position):
	set_position(position)
	var variation = noise.get_noise_1d(rng.randf_range(-1.0, 1.0))
	set_rotation(lerp_angle(rotation, variation * 0.261799, rng.randf_range(0, 1)))
	set_z_index(2)

func _on_TouchInputDetector_dragged():
	if isLockedToSlot:
		targetSlot.deoccupy()
		set_z_index(1)
	find_nearest_unoccupied_slot()

func _on_TouchInputDetector_tapped():
	if currentState == CardState.BLOCKED_FOR_SELECTION:
		emit_signal("tapped_while_blocked", self)

	elif currentState == CardState.BLOCKED_SELECTED_FOR_WIN:
		do_set_state(CardState.BLOCKED_FOR_SELECTION, true)

	elif currentState == CardState.SELECTED_FOR_WIN or currentState == CardState.SELECTED_FOR_REVEAL:
		do_set_state(CardState.SELECTABLE, true)

	elif currentState == CardState.SELECTABLE:
		do_set_state(CardState.SELECTED_FOR_REVEAL, true)

func _on_TouchInputDetector_long_pressed():
	if currentState == CardState.BLOCKED_FOR_SELECTION:
		do_set_state(CardState.BLOCKED_SELECTED_FOR_WIN, true)
		return

	do_set_state(CardState.SELECTED_FOR_WIN, true)
