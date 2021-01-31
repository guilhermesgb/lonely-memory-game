extends Node2D

const Global = preload("Global.gd")

signal preparation_done

export(int) var CURRENT_LEVEL = 1

onready var rng = RandomNumberGenerator.new()
onready var slots = get_tree().get_nodes_in_group("slots")
onready var cards = get_tree().get_nodes_in_group("cards")
onready var timer = $Timer

var availableSlotsCounter = 0
var occupiedSlotsCounter = 0

func _ready():
	rng.randomize()
	occupy_excess_slots()
	keep_unoccupied_slots()
	free_excess_cards()

func occupy_excess_slots():
	for slot in slots:
		slot.connect("slot_occupied", self, "_on_slot_occupied")
		slot.setup(CURRENT_LEVEL)

func keep_unoccupied_slots():
	for slot in slots:
		if not slot.is_occupied():
			availableSlotsCounter = availableSlotsCounter + 1

func free_excess_cards():
	var cardsToFree = []
	var cardsToSetup = []

	var cardIndex = rng.randi_range(0, 4)
	for count in cards.size():

		if (cardsToSetup.size() < availableSlotsCounter):
			cardsToSetup.append(cards[cardIndex])

		else:
			cardsToFree.append(cards[cardIndex])

		cardIndex = (cardIndex + 1) % cards.size()

	for card in cardsToFree:
		card.destroy()

	for card in cardsToSetup:
		card.setup(self, rng)

	cards = cardsToSetup

func _on_Timer_timeout():
	print("restarting current scene")
	get_tree().reload_current_scene()

func _draw():
	draw_circle(Vector2.ZERO, 2000, Color("#56445d"))

func _on_slot_occupied():
	occupiedSlotsCounter = occupiedSlotsCounter + 1

	if (occupiedSlotsCounter == slots.size()):
		assign_types_to_cards()
		emit_signal("preparation_done")
		timer.start()

func assign_types_to_cards():
	var typesToAssign = Global.CardType.values()
	var typesToAssignCount = ceil(cards.size() / 2.0)
	var usedTypes = [Global.CardType.NONE]

	while typesToAssignCount > 0:
		var typeToAssign = find_available_type(typesToAssign, usedTypes)

		if typesToAssignCount == 1:
			find_unassigned_card().set_assigned_type(typeToAssign)

		else:
			find_unassigned_card().set_assigned_type(typeToAssign)
			find_unassigned_card().set_assigned_type(typeToAssign)

		usedTypes.append(typeToAssign)
		typesToAssignCount = typesToAssignCount - 1

func find_available_type(typesToAssign, usedTypes):
	var availableTypes = []

	for type in typesToAssign:
		if type in usedTypes:
			continue
		availableTypes.append(type)

	return availableTypes[rng.randi_range(0, availableTypes.size() - 1)]

func find_unassigned_card():
	var unassignedCards = []

	for card in cards:
		if card.has_assigned_type():
			continue
		unassignedCards.append(card)

	return unassignedCards[rng.randi_range(0, unassignedCards.size() - 1)]
