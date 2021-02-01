extends Position2D

signal slot_occupied(card)

export(int) var MIN_LEVEL = 0

var isOccupied = false

#func _draw():
#	draw_circle(Vector2.ZERO, 15, Color("#b1876c"))

func setup(current_level):
	if current_level >= MIN_LEVEL:
		deoccupy()

	else:
		occupy(null)

func occupy(card):
	emit_signal("slot_occupied", card)
#	modulate = Color("#8a5939")
	isOccupied = true

func deoccupy():
#	modulate = Color.white
	isOccupied = false

func is_occupied():
	return isOccupied
