extends Node2D

const Global = preload("Global.gd")

signal preparation_done
signal earnable_points_updated(points)

export(int) var CURRENT_LEVEL = 1

onready var rng = RandomNumberGenerator.new()
onready var slots = get_tree().get_nodes_in_group("slots")
onready var cards = get_tree().get_nodes_in_group("cards")
onready var timer = $Timer

var availableSlotsCounter = 0
var occupiedSlotsCounter = 0

var cardsSelectedForReveal = []
var cardSelectedForWin = null

var earnablePoints = 0
var earnedPeeks = 0
var fullPassesCount = 0

func _ready():
	rng.randomize()
	calculate_earnable_points()
	occupy_excess_slots()
	keep_unoccupied_slots()
	free_excess_cards()

func calculate_earnable_points():
	earnablePoints = 50 * CURRENT_LEVEL

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
		card.connect("select_for_reveal_updated", self, "_on_card_select_for_reveal_updated")
		card.connect("select_for_win_updated", self, "_on_card_select_for_win_updated")
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
		emit_signal("earnable_points_updated", earnablePoints)
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

func _on_card_select_for_reveal_updated(card, selected):
	clear_selected_cards_for_win()

	var selection = update_selected_cards_for_reveal(card, selected)

	if (has_enough_cards_to_reveal(selection)):
		if revealed_cards_form_pair(selection):
			block_revealed_cards(selection)

			punish_by_decreasing_earnable_points()

		else:
			block_selected_cards(selection)

		clear_selected_cards_for_reveal()

		var remainingCards = get_remaining_selectable_cards()
		if singled_out_some_card(remainingCards):
			if not unblock_cards_for_selection():
				win_with_remaining_card(remainingCards[0])

func update_selected_cards_for_reveal(card, selected):
	if selected:
		cardsSelectedForReveal.append(card)

	elif card in cardsSelectedForReveal:
		cardsSelectedForReveal.remove(cardsSelectedForReveal.find(card))

	return cardsSelectedForReveal

func has_enough_cards_to_reveal(selection):
	return selection.size() == 2

func revealed_cards_form_pair(selection):
	return selection[0].get_assigned_type() == selection[1].get_assigned_type()

func block_revealed_cards(selection):
	for card in selection:
		card.set_revealed_as_pair()

func block_selected_cards(selection):
	for card in selection:
		card.set_blocked_for_selection()

func clear_selected_cards_for_reveal():
	cardsSelectedForReveal.clear()

	for card in cards:
		if card.is_selected_for_reveal():
			card.set_as_selectable(false)

func get_remaining_selectable_cards():
	var selectableCards = []

	for card in cards:
		if card.is_blocked_for_selection() or card.is_revealed_as_pair():
			continue

		selectableCards.append(card)

	return selectableCards

func singled_out_some_card(remainingCards):
	return remainingCards.size() == 1

func unblock_cards_for_selection():
	var thereWereCardsToUnblock = false

	for card in cards:
		if card.is_blocked_for_selection() or card.is_selected_for_win():
			card.set_as_selectable(false)
			thereWereCardsToUnblock = true

			fullPassesCount = fullPassesCount + 1

	return thereWereCardsToUnblock

func win_with_remaining_card(card):
	card.set_locked_for_win(true)

func _on_card_select_for_win_updated(card, selected):
	clear_selected_cards_for_reveal()

	for cardIndex in cards.size():
		if card.name == cards[cardIndex].name:
			continue

		elif selected and cards[cardIndex].is_selected_for_win():
			cards[cardIndex].set_as_selectable(false)

func clear_selected_cards_for_win():
	for card in cards:
		if card.is_selected_for_win():
			card.set_as_selectable(false)

func punish_by_decreasing_earnable_points():
	var totalEarnablePoints = 50 * CURRENT_LEVEL

	earnablePoints = earnablePoints - (floor(totalEarnablePoints / cards.size()) * 2)
	emit_signal("earnable_points_updated", earnablePoints)
