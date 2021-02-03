extends Node2D

const Global = preload("Global.gd")

signal preparation_done
signal earnable_points_updated(points)
signal peek_count_updated(count)
signal player_won(points)
signal player_lost()

onready var rng = RandomNumberGenerator.new()

var currentLevel = 0

var destroyedCardNames = []

var availableSlotsCounter = 0
var occupiedSlotsCounter = 0

var cardsSelectedForReveal = []
var cardSelectedForWin = null

var earnablePoints = 0

var successiveNoPairRevealsCount = 0
var earnedPeeksCount = 0

var fullPassesCount = 0

func setup(level):
	currentLevel = level

func _ready():
	rng.randomize()
	calculate_earnable_points()
	setup_slots_based_on_level()
	count_unoccupied_slots()
	free_excess_cards()

func group_slots(groupName):
	for childIndex in get_child_count():
		var child = get_child(childIndex)

		if child.name.begins_with("Slot"):
			child.add_to_group(groupName)

func get_card_slots():
	return do_get_card_slots(false)

func do_get_card_slots(groupSlots):
	var groupName = "slots" + String(currentLevel)

	if groupSlots:
		group_slots(groupName)

	var slots = []
	for slot in get_tree().get_nodes_in_group(groupName):

		if slot == null or slot.is_queued_for_deletion():
			continue

		slots.append(slot)

	return slots

func get_win_slot():
	return $WinSlot

func group_cards(groupName):
	for childIndex in get_child_count():
		var child = get_child(childIndex)

		if child.name.begins_with("Card"):
			child.add_to_group(groupName)

func get_cards():
	return do_get_cards(false)

func do_get_cards(groupCards):
	var groupName = "cards" + String(currentLevel)

	if groupCards:
		group_cards(groupName)

	var cards = []
	for card in get_tree().get_nodes_in_group(groupName):

		if card == null or card.is_queued_for_deletion() or card.name in destroyedCardNames:
			continue

		cards.append(card)

	return cards

func get_other_cards(name):
	var cards = []
	for card in get_cards():

		if card.name == name:
			continue

		cards.append(card)

	return cards

func calculate_earnable_points():
	earnablePoints = get_total_earnable_points()

func get_total_earnable_points():
	return 50 * currentLevel

func setup_slots_based_on_level():
	for slot in do_get_card_slots(true):
		slot.connect("slot_occupied", self, "_on_slot_occupied")
		slot.setup(currentLevel)

func count_unoccupied_slots():
	for slot in get_card_slots():
		if not slot.is_occupied():
			availableSlotsCounter = availableSlotsCounter + 1

func free_excess_cards():
	var cards = do_get_cards(true)
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
		card.connect("card_destroyed", self, "_on_card_destroyed")
		card.connect("select_for_reveal_updated", self, "_on_card_select_for_reveal_updated")
		card.connect("select_for_win_updated", self, "_on_card_select_for_win_updated")
		card.connect("tapped_while_blocked", self, "_on_card_tapped_while_blocked")
		card.setup(self, rng)

	cards = cardsToSetup

func _on_card_destroyed(name):
	destroyedCardNames.append(name)

func _on_Timer_timeout():
	print("restarting current scene")
	get_tree().reload_current_scene()

func _draw():
	draw_circle(Vector2.ZERO, 2000, Color("#493e3e"))

func _on_slot_occupied(_card):
	occupiedSlotsCounter = occupiedSlotsCounter + 1

	if (occupiedSlotsCounter == get_card_slots().size()):
		prepare_win_slot()
		assign_types_to_cards()
		emit_signal("preparation_done")
		emit_signal("earnable_points_updated", earnablePoints)
		emit_signal("peek_count_updated", earnedPeeksCount)

func prepare_win_slot():
	get_win_slot().connect("slot_occupied", self, "_on_win_slot_occupied")

func assign_types_to_cards():
	var cards = get_cards()
	var typesToAssign = Global.CardType.values()
	var typesToAssignCount = ceil(cards.size() / 2.0)
	var usedTypes = [Global.CardType.NONE]

	while typesToAssignCount > 0:
		var typeToAssign = find_available_type(typesToAssign, usedTypes)

		if typesToAssignCount == 1:
			cardSelectedForWin = find_unassigned_card(cards)
			cardSelectedForWin.set_assigned_type(typeToAssign)

		else:
			find_unassigned_card(cards).set_assigned_type(typeToAssign)
			find_unassigned_card(cards).set_assigned_type(typeToAssign)

		usedTypes.append(typeToAssign)
		typesToAssignCount = typesToAssignCount - 1

func find_available_type(typesToAssign, usedTypes):
	var availableTypes = []

	for type in typesToAssign:
		if type in usedTypes:
			continue
		availableTypes.append(type)

	return availableTypes[rng.randi_range(0, availableTypes.size() - 1)]

func find_unassigned_card(cards):
	var unassignedCards = []

	for card in cards:
		if card.has_assigned_type():
			continue
		unassignedCards.append(card)

	return unassignedCards[rng.randi_range(0, unassignedCards.size() - 1)]

func _on_card_select_for_reveal_updated(card, selected):
	var cards = get_cards()
	clear_selected_cards_for_win(cards)

	var selection = update_selected_cards_for_reveal(card, selected)

	if (has_enough_cards_to_reveal(selection)):
		if revealed_cards_form_pair(selection):
			block_revealed_cards(selection)

			punish_by_decreasing_earnable_points(cards)

		else:
			block_selected_cards(cards, selection)

		clear_selected_cards_for_reveal(cards)

		var remainingCards = get_remaining_selectable_cards(cards)
		if singled_out_some_card(remainingCards):
			if not unblock_cards_for_selection(cards):
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

	successiveNoPairRevealsCount = 0

func block_selected_cards(cards, selection):
	for card in selection:
		card.set_blocked_for_selection(true)

	successiveNoPairRevealsCount = successiveNoPairRevealsCount + 1

	var existingPairsCount = (cards.size() - 1) / 2.0
	if successiveNoPairRevealsCount == ceil(existingPairsCount / 2) and earnedPeeksCount < 3:
		successiveNoPairRevealsCount = 0
		earnedPeeksCount = earnedPeeksCount + 1
		emit_signal("peek_count_updated", earnedPeeksCount)

func clear_selected_cards_for_reveal(cards):
	cardsSelectedForReveal.clear()

	for card in cards:
		if card.is_selected_for_reveal():
			card.set_as_selectable(false)

func get_remaining_selectable_cards(cards):
	var selectableCards = []

	for card in cards:
		if card.is_blocked_for_selection() or card.is_revealed_as_pair():
			continue

		selectableCards.append(card)

	return selectableCards

func singled_out_some_card(remainingCards):
	return remainingCards.size() == 1

func unblock_cards_for_selection(cards):
	var thereWereCardsToUnblock = false

	for card in cards:
		if card.is_blocked_for_selection() or card.is_selected_for_win():

			card.set_as_selectable(false)
			thereWereCardsToUnblock = true

	if thereWereCardsToUnblock:
		fullPassesCount = fullPassesCount + 1
		successiveNoPairRevealsCount = 0

	return thereWereCardsToUnblock

func win_with_remaining_card(card):
	card.set_locked_for_win(true)

func _on_card_select_for_win_updated(card, selected):
	var cards = get_cards()
	clear_selected_cards_for_reveal(cards)

	for cardIndex in cards.size():
		if card.name == cards[cardIndex].name:
			continue

		elif selected and cards[cardIndex].is_selected_for_win():
			if cards[cardIndex].is_blocked_for_selection():
				cards[cardIndex].set_blocked_for_selection(false)

			else:
				cards[cardIndex].set_as_selectable(false)

func clear_selected_cards_for_win(cards):
	for card in cards:
		if card.is_selected_for_win():
			if card.is_blocked_for_selection():
				card.set_blocked_for_selection(false)

			else:
				card.set_as_selectable(false)

func punish_by_decreasing_earnable_points(cards):
	var totalEarnablePoints = get_total_earnable_points()

	earnablePoints = earnablePoints - (floor(totalEarnablePoints / cards.size()) * 2)
	emit_signal("earnable_points_updated", earnablePoints)

func _on_card_tapped_while_blocked(card):
	if earnedPeeksCount > 0:
		earnedPeeksCount = earnedPeeksCount - 1
		card.set_blocked_for_selection(true)
		emit_signal("peek_count_updated", earnedPeeksCount)

func _on_win_slot_occupied(card):
	if cardSelectedForWin != null and card.name == cardSelectedForWin.name:
		for otherCard in get_cards():
			if (otherCard.name == card.name):
				continue

			otherCard.set_revealed_as_pair()

		card.set_winner_found()
		emit_signal("player_won", earnablePoints)

	else:
		card.set_revealed_as_pair()
		emit_signal("player_lost")
