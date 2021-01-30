extends Node2D

signal preparation_done

onready var slots = get_tree().get_nodes_in_group("slots")
onready var cards = get_tree().get_nodes_in_group("cards")
onready var timer = $Timer

var occupiedSlotsCounter = 0

func _ready():
	for slot in slots:
		slot.connect("slot_occupied", self, "_on_slot_occupied")
	for card in cards:
		card.setup(self)

func _on_Timer_timeout():
	print("restarting current scene")
	get_tree().reload_current_scene()

func _draw():
	draw_circle(Vector2.ZERO, 2000, Color("#56445d"))

func _on_slot_occupied():
	occupiedSlotsCounter = occupiedSlotsCounter + 1

	if (occupiedSlotsCounter == slots.size()):
		emit_signal("preparation_done")
		timer.start()
